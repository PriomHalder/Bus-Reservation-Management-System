<?php
declare(strict_types=1);

require_once __DIR__ . '/_university_shell.php';

$q = trim((string)($_GET['q'] ?? ''));
$status = strtoupper((string)($_GET['status'] ?? 'ALL'));
$allowed = ['ALL', 'BOOKED', 'CONFIRMED', 'TRANSFER_PENDING', 'CANCELLED', 'COMPLETED'];
if (!in_array($status, $allowed, true)) {
    $status = 'ALL';
}

$returnParams = [];
if ($q !== '') {
    $returnParams['q'] = $q;
}
if ($status !== 'ALL') {
    $returnParams['status'] = $status;
}
$returnUrl = 'bookings.php' . ($returnParams ? '?' . http_build_query($returnParams) : '');

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'cancel_booking') {
    if (!u_verify_csrf($_POST['csrf_token'] ?? null)) {
        u_flash('error', 'Your session expired. Refresh the page and try again.');
        u_redirect($returnUrl);
    }

    $bookingId = (int)($_POST['booking_id'] ?? 0);
    $reason = trim((string)($_POST['cancellation_reason'] ?? ''));

    try {
        $cancelled = uniride_cancel_booking_by_university_admin(
            $pdo,
            $uAdminId,
            $uUniversityId,
            $bookingId,
            $reason
        );
        u_flash(
            'success',
            'Booking ' . $cancelled['booking_reference'] . ' was cancelled and the passenger was notified.'
        );
    } catch (RuntimeException $error) {
        u_flash('error', $error->getMessage());
    } catch (Throwable $error) {
        error_log('[UniRide University Admin booking cancellation] ' . $error->getMessage());
        u_flash('error', 'The booking could not be cancelled. No changes were saved.');
    }

    u_redirect($returnUrl);
}

$sql = "SELECT DISTINCT
            bk.booking_id,
            bk.booking_reference,
            bk.slot_type,
            bk.seat_number,
            bk.standing_slot,
            bk.fare_charged,
            bk.status,
            bk.booking_date,
            p.name AS passenger_name,
            p.passenger_type,
            r.route_code,
            r.route_name,
            s.schedule_date,
            s.departure_time
        FROM bookings bk
        INNER JOIN passengers p ON p.passenger_id = bk.passenger_id
        INNER JOIN schedules s ON s.schedule_id = bk.schedule_id
        INNER JOIN routes r ON r.route_id = s.route_id
        INNER JOIN buses b ON b.bus_id = s.bus_id
        WHERE p.university_id = ?
          AND r.university_id = ?
          AND b.university_id = ?";
$params = [$uUniversityId, $uUniversityId, $uUniversityId];

if ($q !== '') {
    $sql .= " AND (bk.booking_reference LIKE ? OR p.name LIKE ? OR r.route_code LIKE ?)";
    $like = '%' . $q . '%';
    array_push($params, $like, $like, $like);
}
if ($status !== 'ALL') {
    $sql .= ' AND bk.status = ?';
    $params[] = $status;
}
$sql .= ' ORDER BY bk.booking_date DESC LIMIT 250';

$rows = [];
try {
    $rows = u_all($pdo, $sql, $params);
} catch (Throwable $error) {
    error_log('[UniRide bookings] ' . $error->getMessage());
}

u_render_start(
    'Bookings',
    'bookings',
    'Operations',
    'Booking records associated with this university’s passengers and schedules.'
);
u_render_actions('<a class="up-button-secondary" href="occupancy.php">View Occupancy</a>');
u_render_heading_end();
?>

<style>
    .booking-admin-actions {
        display: flex;
        align-items: center;
        justify-content: flex-end;
        gap: 8px;
    }
    .booking-cancel-button {
        min-height: 30px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        padding: 0 10px;
        border: 1px solid #c93a35;
        border-radius: 7px;
        background: #fff1ef;
        color: #a5241a;
        font-size: 9px;
        font-weight: 850;
        cursor: pointer;
    }
    .booking-cancel-button:hover {
        border-color: #a5241a;
        background: #a5241a;
        color: #ffffff;
    }
    .booking-cancel-dialog {
        width: min(480px, calc(100% - 32px));
        padding: 0;
        border: 1px solid var(--ui-line, #e1e7ee);
        border-radius: 14px;
        background: var(--ui-surface, #ffffff);
        color: var(--ui-ink, #17191c);
        box-shadow: 0 24px 70px rgba(11, 47, 97, .20);
    }
    .booking-cancel-dialog::backdrop {
        background: rgba(8, 17, 29, .58);
        backdrop-filter: blur(2px);
    }
    .booking-cancel-dialog form {
        display: grid;
        gap: 16px;
        padding: 22px;
    }
    .booking-cancel-dialog h2,
    .booking-cancel-dialog p {
        margin: 0;
    }
    .booking-cancel-dialog h2 {
        font-family: var(--ui-display, Georgia, serif);
        font-size: 25px;
        font-weight: 500;
    }
    .booking-cancel-warning {
        padding: 12px;
        border: 1px solid #e7b8b4;
        border-radius: 9px;
        background: var(--ui-danger-bg, #fff1ef);
        color: var(--ui-danger, #a5241a);
        font-size: 11px;
        line-height: 1.55;
    }
    .booking-cancel-field {
        display: grid;
        gap: 6px;
    }
    .booking-cancel-field span {
        color: var(--ui-text, #46505a);
        font-size: 10px;
        font-weight: 800;
    }
    .booking-cancel-field textarea {
        width: 100%;
        min-height: 96px;
        resize: vertical;
        padding: 10px 11px;
        border: 1px solid var(--ui-line-strong, #d2dce7);
        border-radius: 9px;
        background: var(--ui-surface, #ffffff);
        color: var(--ui-ink, #17191c);
    }
    .booking-cancel-field textarea:focus {
        border-color: var(--ui-navy, #123f7c);
        box-shadow: 0 0 0 3px rgba(18, 63, 124, .10);
        outline: none;
    }
    .booking-cancel-dialog-actions {
        display: flex;
        justify-content: flex-end;
        gap: 8px;
    }
    html[data-theme="dark"] .booking-cancel-button {
        border-color: #6e353b;
        background: #351c20;
        color: #ff9e98;
    }
    html[data-theme="dark"] .booking-cancel-button:hover {
        border-color: #ff9e98;
        background: #7b2928;
        color: #ffffff;
    }
    html[data-theme="dark"] .booking-cancel-warning {
        border-color: #6e353b;
    }
    @media (max-width: 720px) {
        .booking-admin-actions {
            justify-content: flex-start;
        }
        .booking-cancel-dialog-actions {
            flex-direction: column-reverse;
        }
        .booking-cancel-dialog-actions button {
            width: 100%;
        }
    }
</style>

<form method="get" class="up-filter">
    <input type="search" name="q" value="<?= u_h($q) ?>" placeholder="Booking reference, passenger or route">
    <select name="status">
        <?php foreach ($allowed as $filterStatus): ?>
            <option value="<?= u_h($filterStatus) ?>" <?= $filterStatus === $status ? 'selected' : '' ?>>
                <?= u_h($filterStatus) ?>
            </option>
        <?php endforeach; ?>
    </select>
    <button class="up-button-secondary" type="submit">Filter</button>
</form>

<?php if (!$rows): ?>
    <div class="up-empty">
        <div>
            <strong>No matching bookings.</strong>
            <p>Passenger bookings for this university will appear here.</p>
        </div>
    </div>
<?php else: ?>
    <div class="up-table-wrap">
        <table class="up-table">
            <thead>
                <tr>
                    <th>Reference</th>
                    <th>Passenger</th>
                    <th>Route</th>
                    <th>Schedule</th>
                    <th>Seat / Slot</th>
                    <th>Fare</th>
                    <th>Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($rows as $row): ?>
                <?php $canCancel = in_array(strtoupper((string)$row['status']), ['BOOKED', 'CONFIRMED'], true); ?>
                <tr>
                    <td>
                        <strong><?= u_h($row['booking_reference']) ?></strong>
                        <small><?= u_h(u_date($row['booking_date'], 'd M · g:i A')) ?></small>
                    </td>
                    <td>
                        <strong><?= u_h($row['passenger_name']) ?></strong>
                        <small><?= u_h(ucfirst(strtolower($row['passenger_type']))) ?></small>
                    </td>
                    <td><?= u_h($row['route_code']) ?></td>
                    <td><?= u_h(u_date($row['schedule_date'], 'd M')) ?> · <?= u_h(u_time($row['departure_time'])) ?></td>
                    <td><?= u_h(u_seat_label($row)) ?></td>
                    <td>৳<?= number_format((float)$row['fare_charged'], 0) ?></td>
                    <td>
                        <span class="up-status <?= u_h(u_status_class($row['status'])) ?>">
                            <?= u_h($row['status']) ?>
                        </span>
                    </td>
                    <td>
                        <div class="booking-admin-actions">
                            <?php if ($canCancel): ?>
                                <button
                                    class="booking-cancel-button"
                                    type="button"
                                    data-cancel-booking
                                    data-booking-id="<?= (int)$row['booking_id'] ?>"
                                    data-booking-reference="<?= u_h($row['booking_reference']) ?>"
                                    data-passenger-name="<?= u_h($row['passenger_name']) ?>"
                                    aria-haspopup="dialog"
                                >
                                    Cancel Booking
                                </button>
                            <?php else: ?>
                                <span aria-label="No action available">—</span>
                            <?php endif; ?>
                        </div>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
<?php endif; ?>

<dialog class="booking-cancel-dialog" id="bookingCancelDialog" aria-labelledby="bookingCancelTitle">
    <form method="post" action="<?= u_h($returnUrl) ?>" id="bookingCancelForm">
        <input type="hidden" name="csrf_token" value="<?= u_h(u_csrf()) ?>">
        <input type="hidden" name="action" value="cancel_booking">
        <input type="hidden" name="booking_id" id="cancelBookingId" value="">

        <div>
            <h2 id="bookingCancelTitle">Cancel booking</h2>
            <p class="muted">This action changes the reservation status and releases its seat or standing slot.</p>
        </div>

        <p class="booking-cancel-warning" id="bookingCancelWarning" role="alert">
            Confirm the booking you want to cancel.
        </p>

        <label class="booking-cancel-field">
            <span>Cancellation reason</span>
            <textarea
                name="cancellation_reason"
                id="cancellationReason"
                minlength="5"
                maxlength="255"
                required
                placeholder="Explain why this booking is being cancelled."
            ></textarea>
        </label>

        <div class="booking-cancel-dialog-actions">
            <button class="up-button-secondary" type="button" data-cancel-dialog-close>Keep Booking</button>
            <button class="booking-cancel-button" type="submit">Confirm Cancellation</button>
        </div>
    </form>
</dialog>

<script>
(() => {
    const dialog = document.getElementById('bookingCancelDialog');
    const form = document.getElementById('bookingCancelForm');
    const bookingId = document.getElementById('cancelBookingId');
    const warning = document.getElementById('bookingCancelWarning');
    const reason = document.getElementById('cancellationReason');

    if (!dialog || !form || !bookingId || !warning || !reason) return;

    const closeDialog = () => {
        if (typeof dialog.close === 'function') {
            dialog.close();
        } else {
            dialog.removeAttribute('open');
            form.reset();
            bookingId.value = '';
            warning.textContent = 'Confirm the booking you want to cancel.';
        }
    };

    document.querySelectorAll('[data-cancel-booking]').forEach((button) => {
        button.addEventListener('click', () => {
            bookingId.value = button.dataset.bookingId || '';
            const reference = button.dataset.bookingReference || 'the selected booking';
            const passenger = button.dataset.passengerName || 'the passenger';
            warning.textContent = `You are about to cancel ${reference} for ${passenger}. The passenger will be notified immediately.`;
            if (typeof dialog.showModal === 'function') {
                dialog.showModal();
            } else {
                dialog.setAttribute('open', '');
            }
            reason.focus();
        });
    });

    document.querySelectorAll('[data-cancel-dialog-close]').forEach((button) => {
        button.addEventListener('click', closeDialog);
    });

    dialog.addEventListener('close', () => {
        form.reset();
        bookingId.value = '';
        warning.textContent = 'Confirm the booking you want to cancel.';
    });
})();
</script>

<?php u_render_end(); ?>
