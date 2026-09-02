<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

function psb_table_exists(PDO $pdo, string $table): bool
{
    $stmt = $pdo->prepare(
        'SELECT COUNT(*) FROM information_schema.tables
         WHERE table_schema=DATABASE() AND table_name=?'
    );
    $stmt->execute([$table]);

    return (int)$stmt->fetchColumn() > 0;
}

function psb_column_exists(PDO $pdo, string $table, string $column): bool
{
    $stmt = $pdo->prepare(
        'SELECT COUNT(*) FROM information_schema.columns
         WHERE table_schema=DATABASE() AND table_name=? AND column_name=?'
    );
    $stmt->execute([$table, $column]);

    return (int)$stmt->fetchColumn() > 0;
}

function psb_date(?string $value, string $format = 'd M Y'): string
{
    if (!$value) {
        return '—';
    }

    $timestamp = strtotime($value);
    return $timestamp ? date($format, $timestamp) : $value;
}

function psb_type_label(string $type): string
{
    return ucwords(strtolower(str_replace('_', ' ', $type)));
}

$billTableReady = psb_table_exists($pdo, 'semester_bills');
$semesterTableReady = psb_table_exists($pdo, 'semesters');
$transactionTableReady = psb_table_exists($pdo, 'billing_transactions');
$billUniversityReady = $billTableReady && psb_column_exists($pdo, 'semester_bills', 'university_id');
$billStatusReady = $billTableReady && psb_column_exists($pdo, 'semester_bills', 'status');
$billCreditsReady = $billTableReady && psb_column_exists($pdo, 'semester_bills', 'total_credits');

$bills = [];
$transactions = [];
$loadError = '';
$totals = ['charges' => 0.0, 'credits' => 0.0, 'balance' => 0.0];

if ($billTableReady && $semesterTableReady) {
    try {
        $statusExpression = $billStatusReady ? 'sb.status' : "'OPEN'";
        $creditsExpression = $billCreditsReady ? 'sb.total_credits' : '0.00';
        $sql = "SELECT
                    sb.bill_id,
                    sb.semester_id,
                    sb.total_charges,
                    {$creditsExpression} AS total_credits,
                    sb.net_balance,
                    {$statusExpression} AS status,
                    sb.created_at,
                    sb.updated_at,
                    sem.semester_name,
                    sem.start_date,
                    sem.end_date,
                    sem.is_active
                FROM semester_bills sb
                INNER JOIN passengers p
                    ON p.passenger_id=sb.passenger_id
                INNER JOIN semesters sem
                    ON sem.semester_id=sb.semester_id
                WHERE sb.passenger_id=?
                  AND p.university_id=?";
        $params = [$ppPassengerId, $ppUniversityId];

        if ($billUniversityReady) {
            $sql .= ' AND (sb.university_id=? OR sb.university_id IS NULL)';
            $params[] = $ppUniversityId;
        }

        $sql .= ' ORDER BY sem.is_active DESC, sem.start_date DESC, sb.bill_id DESC';

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $bills = $stmt->fetchAll();

        foreach ($bills as $bill) {
            $totals['charges'] += (float)$bill['total_charges'];
            $totals['credits'] += (float)$bill['total_credits'];
            $totals['balance'] += (float)$bill['net_balance'];
        }

        if ($transactionTableReady) {
            $stmt = $pdo->prepare(
                "SELECT
                    bt.transaction_id,
                    bt.transaction_type,
                    bt.amount,
                    bt.description,
                    bt.transaction_date,
                    sem.semester_name
                 FROM billing_transactions bt
                 INNER JOIN passengers p
                    ON p.passenger_id=bt.passenger_id
                 INNER JOIN semesters sem
                    ON sem.semester_id=bt.semester_id
                 WHERE bt.passenger_id=?
                   AND p.university_id=?
                 ORDER BY bt.transaction_date DESC, bt.transaction_id DESC
                 LIMIT 200"
            );
            $stmt->execute([$ppPassengerId, $ppUniversityId]);
            $transactions = $stmt->fetchAll();
        }
    } catch (Throwable $e) {
        error_log('[UniRide semester billing] ' . $e->getMessage());
        $loadError = 'Semester billing could not be loaded right now.';
    }
}

pp_render_start(
    'Semester Billing',
    'semester-billing',
    'Account',
    'Review your university-scoped transport charges, credits and semester balances.'
);
?>

<style>
    .psb-note { margin-bottom:20px; padding:14px 16px; border:1px solid var(--ui-line); border-left:3px solid var(--ui-navy); border-radius:10px; background:var(--ui-navy-pale); color:var(--ui-text); font-size:12px; line-height:1.65; }
    .psb-note.is-error { border-color:#f0c7c1; border-left-color:var(--ui-danger); background:var(--ui-danger-bg); color:var(--ui-danger); }
    .psb-section { margin-top:28px; }
    .psb-section-heading { margin-bottom:14px; }
    .psb-section-heading h2 { margin:0 0 5px; color:var(--ui-ink); font-family:var(--ui-display); font-size:25px; font-weight:500; letter-spacing:-.035em; }
    .psb-section-heading p { margin:0; color:var(--ui-muted); font-size:11px; }
    .psb-amount-positive { color:var(--ui-danger); font-weight:800; }
    .psb-amount-credit { color:var(--ui-success); font-weight:800; }
    .psb-empty { padding:28px; border:1px dashed var(--ui-line-strong); border-radius:12px; background:var(--ui-surface); color:var(--ui-muted); text-align:center; }
    .psb-section .up-table { min-width:760px; }
    .psb-section .up-table td small { display:block; margin-top:3px; color:var(--ui-muted); font-size:10px; }
    @media (max-width:640px) { .psb-section { margin-top:22px; } }
</style>

<?php if (!$billTableReady || !$semesterTableReady): ?>
    <div class="psb-note is-error" role="alert">
        <strong>Semester billing setup is incomplete.</strong>
        Import <code>database/migrations/006_core_schema_consistency.sql</code>
        in phpMyAdmin. No existing billing data will be removed.
    </div>
<?php elseif (!$billUniversityReady): ?>
    <div class="psb-note" role="status">
        <strong>University ownership migration required.</strong>
        This page is currently scoped through your authenticated passenger record,
        but migration <code>006_core_schema_consistency.sql</code> must be imported
        to add and backfill <code>semester_bills.university_id</code>.
    </div>
<?php endif; ?>

<?php if ($loadError !== ''): ?>
    <div class="psb-note is-error" role="alert"><?= pp_h($loadError) ?></div>
<?php elseif ($billTableReady && $semesterTableReady): ?>
    <section class="metric-grid" aria-label="Semester billing totals">
        <article class="metric-card">
            <p>Total charges</p>
            <strong>৳<?= number_format($totals['charges'], 2) ?></strong>
            <span>Across <?= count($bills) ?> semester<?= count($bills) === 1 ? '' : 's' ?></span>
        </article>
        <article class="metric-card">
            <p>Total credits</p>
            <strong>৳<?= number_format($totals['credits'], 2) ?></strong>
            <span>Recorded cancellations and adjustments</span>
        </article>
        <article class="metric-card">
            <p>Net balance</p>
            <strong>৳<?= number_format($totals['balance'], 2) ?></strong>
            <span>Your current recorded transport balance</span>
        </article>
    </section>

    <section class="psb-section">
        <div class="psb-section-heading">
            <h2>Semester statements</h2>
            <p>Only bills owned by your authenticated passenger account are shown.</p>
        </div>

        <?php if ($bills === []): ?>
            <div class="psb-empty">
                <strong>No semester bills yet.</strong>
                <div>Booking charges will appear here after your first eligible booking.</div>
            </div>
        <?php else: ?>
            <div class="up-table-wrap">
                <table class="up-table">
                    <thead><tr><th>Semester</th><th>Period</th><th>Status</th><th>Charges</th><th>Credits</th><th>Balance</th><th>Updated</th></tr></thead>
                    <tbody>
                    <?php foreach ($bills as $bill): ?>
                        <tr>
                            <td><strong><?= pp_h($bill['semester_name']) ?></strong><?php if ((int)$bill['is_active'] === 1): ?><small>Active semester</small><?php endif; ?></td>
                            <td><?= pp_h(psb_date($bill['start_date'])) ?> – <?= pp_h(psb_date($bill['end_date'])) ?></td>
                            <td><?= pp_h($bill['status']) ?></td>
                            <td>৳<?= number_format((float)$bill['total_charges'], 2) ?></td>
                            <td>৳<?= number_format((float)$bill['total_credits'], 2) ?></td>
                            <td><strong>৳<?= number_format((float)$bill['net_balance'], 2) ?></strong></td>
                            <td><?= pp_h(psb_date($bill['updated_at'], 'd M Y · g:i A')) ?></td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </section>

    <section class="psb-section">
        <div class="psb-section-heading">
            <h2>Billing activity</h2>
            <p>Charges and credits recorded against your semester account.</p>
        </div>

        <?php if (!$transactionTableReady): ?>
            <div class="psb-empty">Billing transaction history is not available.</div>
        <?php elseif ($transactions === []): ?>
            <div class="psb-empty">No billing transactions have been recorded.</div>
        <?php else: ?>
            <div class="up-table-wrap">
                <table class="up-table">
                    <thead><tr><th>Date</th><th>Semester</th><th>Type</th><th>Description</th><th>Amount</th></tr></thead>
                    <tbody>
                    <?php foreach ($transactions as $transaction): ?>
                        <?php $amount = (float)$transaction['amount']; ?>
                        <tr>
                            <td><?= pp_h(psb_date($transaction['transaction_date'], 'd M Y · g:i A')) ?></td>
                            <td><?= pp_h($transaction['semester_name']) ?></td>
                            <td><?= pp_h(psb_type_label((string)$transaction['transaction_type'])) ?></td>
                            <td><?= pp_h($transaction['description'] ?: 'Transport billing entry') ?></td>
                            <td class="<?= $amount < 0 ? 'psb-amount-credit' : 'psb-amount-positive' ?>"><?= $amount < 0 ? '−' : '+' ?>৳<?= number_format(abs($amount), 2) ?></td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </section>
<?php endif; ?>

<?php pp_render_end(); ?>
