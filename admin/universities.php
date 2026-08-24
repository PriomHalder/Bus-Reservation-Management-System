<?php
declare(strict_types=1);

require_once __DIR__ . '/_admin_context.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!sys_verify_csrf($_POST['csrf_token'] ?? null)) {
        sys_flash('error', 'Your session expired. Please try again.');
        sys_redirect('universities.php');
    }

    $action = (string)($_POST['action'] ?? '');

    if ($action === 'create_university') {
        $name = trim((string)($_POST['name'] ?? ''));
        $code = strtoupper(trim((string)($_POST['code'] ?? '')));
        $domain = strtolower(trim((string)($_POST['academic_domain'] ?? '')));
        $address = trim((string)($_POST['address'] ?? ''));
        $contactEmail = strtolower(trim((string)($_POST['contact_email'] ?? '')));
        $status = strtoupper((string)($_POST['status'] ?? 'ACTIVE'));
        $adminName = trim((string)($_POST['admin_name'] ?? ''));
        $adminEmail = strtolower(trim((string)($_POST['admin_email'] ?? '')));
        $adminPassword = (string)($_POST['admin_password'] ?? '');

        $validDomain = $domain === ''
            || (bool)preg_match('/^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$/', $domain);

        if ($name === '' || strlen($name) > 200) {
            sys_flash('error', 'Enter a valid university name.');
            sys_redirect('universities.php?new=1');
        }
        if (!preg_match('/^[A-Z0-9][A-Z0-9_-]{1,19}$/', $code)) {
            sys_flash('error', 'Use a unique 2–20 character university code containing letters, numbers, hyphens or underscores.');
            sys_redirect('universities.php?new=1');
        }
        if (!$validDomain) {
            sys_flash('error', 'Enter a valid academic domain, such as university.edu.');
            sys_redirect('universities.php?new=1');
        }
        if ($contactEmail !== '' && !filter_var($contactEmail, FILTER_VALIDATE_EMAIL)) {
            sys_flash('error', 'Enter a valid university contact email.');
            sys_redirect('universities.php?new=1');
        }
        if (!in_array($status, ['ACTIVE', 'INACTIVE'], true)) {
            $status = 'ACTIVE';
        }
        if ($adminName === '' || !filter_var($adminEmail, FILTER_VALIDATE_EMAIL)) {
            sys_flash('error', 'Enter the first University Admin’s name and a valid email.');
            sys_redirect('universities.php?new=1');
        }
        if (strlen($adminPassword) < 8) {
            sys_flash('error', 'The first University Admin password must contain at least 8 characters.');
            sys_redirect('universities.php?new=1');
        }

        try {
            $pdo->beginTransaction();

            if ((int)sys_scalar($pdo, 'SELECT COUNT(*) FROM universities WHERE code=? OR name=?', [$code, $name]) > 0) {
                throw new RuntimeException('A university with this name or code already exists.');
            }
            if ((int)sys_scalar($pdo, 'SELECT COUNT(*) FROM university_users WHERE LOWER(email)=LOWER(?)', [$adminEmail]) > 0) {
                throw new RuntimeException('A University Admin with this email already exists.');
            }

            $stmt = $pdo->prepare(
                'INSERT INTO universities
                    (name, code, academic_domain, address, contact_email, status)
                 VALUES (?, ?, ?, ?, ?, ?)'
            );
            $stmt->execute([
                $name,
                $code,
                $domain !== '' ? $domain : null,
                $address !== '' ? $address : null,
                $contactEmail !== '' ? $contactEmail : null,
                $status,
            ]);

            $universityId = (int)$pdo->lastInsertId();
            if ($universityId <= 0) {
                throw new RuntimeException('University IDs are not configured for automatic generation. Import the integrity migration first.');
            }

            $stmt = $pdo->prepare(
                "INSERT INTO university_users
                    (university_id, name, email, password_hash, role, status)
                 VALUES (?, ?, ?, ?, 'ADMIN', 'ACTIVE')"
            );
            $stmt->execute([
                $universityId,
                $adminName,
                $adminEmail,
                password_hash($adminPassword, PASSWORD_DEFAULT),
            ]);

            $pdo->commit();
            sys_flash(
                'success',
                $name . ' was created with its first University Admin. The complete shared dashboard and all role features are available immediately.'
            );
            sys_redirect('universities.php');
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            error_log('[UniRide create university] ' . $e->getMessage());
            $message = $e instanceof RuntimeException
                ? $e->getMessage()
                : 'The university could not be created. Check duplicate values and database migrations.';
            sys_flash('error', $message);
            sys_redirect('universities.php?new=1');
        }
    }

    if ($action === 'set_status') {
        $universityId = (int)($_POST['university_id'] ?? 0);
        $status = strtoupper((string)($_POST['status'] ?? ''));

        if ($universityId <= 0 || !in_array($status, ['ACTIVE', 'INACTIVE'], true)) {
            sys_flash('error', 'Invalid university status request.');
            sys_redirect('universities.php');
        }

        try {
            $stmt = $pdo->prepare('UPDATE universities SET status=? WHERE university_id=?');
            $stmt->execute([$status, $universityId]);
            sys_flash('success', 'University status updated.');
        } catch (Throwable $e) {
            error_log('[UniRide university status] ' . $e->getMessage());
            sys_flash('error', 'The university status could not be updated.');
        }
        sys_redirect('universities.php');
    }
}

$universities = [];
$pageError = '';

try {
    $universities = sys_all(
        $pdo,
        "SELECT
            u.university_id, u.name, u.code, u.academic_domain, u.contact_email,
            u.status, u.created_at,
            COUNT(DISTINCT uu.university_user_id) AS admin_count,
            COUNT(DISTINCT p.passenger_id) AS passenger_count,
            COUNT(DISTINCT b.bus_id) AS bus_count,
            COUNT(DISTINCT r.route_id) AS route_count
         FROM universities u
         LEFT JOIN university_users uu ON uu.university_id=u.university_id
         LEFT JOIN passengers p ON p.university_id=u.university_id
         LEFT JOIN buses b ON b.university_id=u.university_id
         LEFT JOIN routes r ON r.university_id=u.university_id
         GROUP BY u.university_id, u.name, u.code, u.academic_domain,
                  u.contact_email, u.status, u.created_at
         ORDER BY u.name"
    );
} catch (Throwable $e) {
    error_log('[UniRide universities list] ' . $e->getMessage());
    $pageError = 'University information is temporarily unavailable.';
}

sys_page_start(
    'Universities',
    'universities',
    'Create a university once; the shared UniAdmin dashboard and every subtask apply automatically.'
);
?>
<?php if ($pageError): ?>
    <div class="alert error"><?= sys_h($pageError) ?></div>
<?php endif; ?>

<div class="admin-page-actions">
    <a class="button button-dark button-small" href="universities.php?new=1">Add university</a>
    <a class="button button-light button-small" href="administrators.php">Manage administrators</a>
</div>

<?php if (isset($_GET['new'])): ?>
<section class="admin-card admin-card-accent">
    <div class="admin-card-heading">
        <div><p class="kicker">Automatic onboarding</p><h2>New university and first administrator</h2></div>
        <a href="universities.php">Cancel</a>
    </div>
    <p class="admin-help">No dashboard files are copied. The new administrator signs into the same shared UniAdmin application, scoped automatically by the new university ID.</p>
    <form method="post" class="admin-form-grid">
        <input type="hidden" name="csrf_token" value="<?= sys_h(sys_csrf()) ?>">
        <input type="hidden" name="action" value="create_university">
        <label><span>University name</span><input name="name" maxlength="200" required></label>
        <label><span>Code</span><input name="code" maxlength="20" placeholder="SEU" required></label>
        <label><span>Academic domain</span><input name="academic_domain" placeholder="seu.edu.bd"></label>
        <label><span>Contact email</span><input type="email" name="contact_email"></label>
        <label class="wide"><span>Address</span><textarea name="address" rows="3"></textarea></label>
        <label><span>University status</span><select name="status"><option value="ACTIVE">Active</option><option value="INACTIVE">Inactive</option></select></label>
        <div class="admin-form-divider wide"><strong>First University Admin</strong><span>This account receives the shared dashboard automatically.</span></div>
        <label><span>Administrator name</span><input name="admin_name" maxlength="200" required></label>
        <label><span>Administrator email</span><input type="email" name="admin_email" maxlength="200" required></label>
        <label><span>Temporary password</span><input type="password" name="admin_password" minlength="8" autocomplete="new-password" required></label>
        <div class="admin-form-actions wide"><button class="button button-dark" type="submit">Create university</button></div>
    </form>
</section>
<?php endif; ?>

<section class="admin-card">
    <div class="admin-card-heading"><div><p class="kicker">Database-driven tenants</p><h2>All universities</h2></div><span><?= number_format(count($universities)) ?> total</span></div>
    <?php if (!$universities): ?>
        <div class="admin-empty"><strong>No universities found.</strong><p>Add the first university to activate its shared dashboard.</p></div>
    <?php else: ?>
        <div class="admin-table-wrap"><table class="admin-table"><thead><tr><th>University</th><th>Domain</th><th>Admins</th><th>Passengers</th><th>Buses</th><th>Routes</th><th>Status</th><th>Action</th></tr></thead><tbody>
        <?php foreach ($universities as $university): ?>
            <tr>
                <td><strong><?= sys_h($university['name']) ?></strong><small><?= sys_h($university['code']) ?> · ID <?= (int)$university['university_id'] ?></small></td>
                <td><?= sys_h($university['academic_domain'] ?: '—') ?></td>
                <td><?= number_format((int)$university['admin_count']) ?></td>
                <td><?= number_format((int)$university['passenger_count']) ?></td>
                <td><?= number_format((int)$university['bus_count']) ?></td>
                <td><?= number_format((int)$university['route_count']) ?></td>
                <td><span class="status-pill <?= sys_h(sys_status_class($university['status'])) ?>"><?= sys_h($university['status']) ?></span></td>
                <td><form method="post" class="inline-form"><input type="hidden" name="csrf_token" value="<?= sys_h(sys_csrf()) ?>"><input type="hidden" name="action" value="set_status"><input type="hidden" name="university_id" value="<?= (int)$university['university_id'] ?>"><input type="hidden" name="status" value="<?= $university['status'] === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE' ?>"><button type="submit"><?= $university['status'] === 'ACTIVE' ? 'Deactivate' : 'Activate' ?></button></form></td>
            </tr>
        <?php endforeach; ?>
        </tbody></table></div>
    <?php endif; ?>
</section>

<?php sys_page_end(); ?>
