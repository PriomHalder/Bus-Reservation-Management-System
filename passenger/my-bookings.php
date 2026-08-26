<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

$message = '';
$messageType = '';

// Unified POST Handler for Cancel & Archive Actions
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    $bookingId = (int)($_POST['booking_id'] ?? 0);

    if ($bookingId > 0 && $action === 'cancel') {
        try {
            // Direct UPDATE query bypassing stored procedure
            $stmt = $pdo->prepare("
                UPDATE bookings 
                SET status = 'CANCELLED' 
                WHERE booking_id = ? AND passenger_id = ?
            ");
            $stmt->execute([$bookingId, $ppPassengerId]);

            if ($stmt->rowCount() > 0) {
                $message = 'Booking cancelled successfully.';
                $messageType = 'success';
            } else {
                $message = 'Cancellation failed: Booking not found or does not belong to your account.';
                $messageType = 'error';
            }
        } catch (PDOException $e) {
            $message = 'Cancellation failed: ' . $e->getMessage();
            $messageType = 'error';
        }
    } elseif ($bookingId > 0 && $action === 'archive') {
        try {
            // Soft-delete / hide fallback
            $stmt = $pdo->prepare("
                UPDATE bookings 
                SET status = 'COMPLETED' 
                WHERE booking_id = ? AND passenger_id = ?
            ");
            $stmt->execute([$bookingId, $ppPassengerId]);

            $message = 'Booking updated in history.';
            $messageType = 'success';
        } catch (PDOException $e) {
            $message = 'Archive failed: ' . $e->getMessage();
            $messageType = 'error';
        }
    }
}

// Debug Variable for SQL Errors
$sqlErrorMsg = '';

// Fetch Active Bookings
$activeBookings = [];
try {
    $stmt = $pdo->prepare("
        SELECT 
            b.booking_id,
            b.booking_reference,
            b.status AS booking_status,
            b.slot_type,
            b.seat_number,
            b.standing_slot,
            b.fare_charged,
            b.booking_reference AS qr_token,
            s.schedule_date,
            s.departure_time,
            r.route_code,
            r.route_name,
            r.start_location,
            r.end_location
        FROM bookings b
        INNER JOIN schedules s ON b.schedule_id = s.schedule_id
        INNER JOIN routes r ON s.route_id = r.route_id
        WHERE b.passenger_id = ?
          AND UPPER(b.status) IN ('BOOKED', 'CONFIRMED', 'PENDING')
        Group By b.booking_reference  
        ORDER BY s.schedule_date ASC, s.departure_time ASC
    ");

    $stmt->execute([$ppPassengerId]);
    $activeBookings = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $sqlErrorMsg .= 'Active Query Error: ' . $e->getMessage() . '<br>';
}

// Fetch Booking History (Cancelled or Past Schedules)
$historyBookings = [];
try {
    $stmt = $pdo->prepare("
        SELECT 
            b.booking_id,
            b.booking_reference,
            b.slot_type,
            b.seat_number,
            b.standing_slot,
            b.fare_charged,
            b.status AS booking_status,
            b.booking_date,
            s.schedule_date,
            s.departure_time,
            r.route_code,
            r.route_name
        FROM bookings b
        INNER JOIN schedules s ON s.schedule_id = b.schedule_id
        INNER JOIN routes r ON r.route_id = s.route_id
        WHERE b.passenger_id = ?
          AND (UPPER(b.status) IN ('CANCELLED', 'COMPLETED') OR s.schedule_date < CURDATE())
        ORDER BY s.schedule_date DESC, s.departure_time DESC
    ");
    $stmt->execute([$ppPassengerId]);
    $historyBookings = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $sqlErrorMsg .= 'History Query Error: ' . $e->getMessage() . '<br>';
}

pp_render_start(
    'My Bookings',
    'my-bookings',
    'Travel Dashboard',
    'Manage your active bus reservations, view ticket QR codes, or review your past trip history.'
);
?>

<style>
    .bk-alert { padding: 12px 16px; border-radius: 8px; margin-bottom: 20px; font-weight: 600; font-size: 13px; }
    .bk-alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
    .bk-alert-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
    
    .section-title { font-size: 16px; font-weight: 800; color: var(--pp-blue); margin: 28px 0 14px; display: flex; align-items: center; justify-content: space-between; }
    .bk-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 16px; }
    
    .bk-card { background: #fff; border: 1px solid var(--pp-line); border-radius: 12px; padding: 18px; position: relative; }
    .bk-card-header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 1px solid var(--pp-line); padding-bottom: 12px; margin-bottom: 12px; }
    .bk-badge { padding: 4px 8px; border-radius: 6px; font-size: 10px; font-weight: 800; text-transform: uppercase; }
    .bk-badge-booked { background: #e3f2fd; color: #0d47a1; }
    .bk-badge-cancelled { background: #ffebee; color: #c62828; }
    .bk-badge-completed { background: #e8f5e9; color: #1b5e20; }
    
    .bk-info { font-size: 12px; display: grid; gap: 6px; color: #334155; }
    .bk-actions { margin-top: 16px; padding-top: 12px; border-top: 1px dashed var(--pp-line); display: flex; gap: 10px; }
    .btn-cancel { background: #fff; border: 1px solid #dc3545; color: #dc3545; padding: 6px 12px; border-radius: 6px; font-size: 11px; font-weight: 700; cursor: pointer; }
    .btn-cancel:hover { background: #dc3545; color: #fff; }
    
    .qr-modal { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 100; place-items: center; }
    .qr-modal-content { background: #fff; padding: 24px; border-radius: 16px; text-align: center; max-width: 320px; width: 90%; }
</style>

<?php if (!empty($sqlErrorMsg)): ?>
    <div class="bk-alert bk-alert-error">
        <strong>Database Debug Warning:</strong><br><?= $sqlErrorMsg ?>
    </div>
<?php endif; ?>

<?php if ($message): ?>
    <div class="bk-alert bk-alert-<?= pp_h($messageType) ?>">
        <?= pp_h($message) ?>
    </div>
<?php endif; ?>

<!-- Active Bookings Section -->
<div class="section-title">
    <span>Active Reservations (<?= count($activeBookings) ?>)</span>
    <a href="book_ticket.php" class="pp-primary-button">+ Book New Ticket</a>
</div>

<?php if (empty($activeBookings)): ?>
    <div class="bk-card" style="text-align:center; padding:32px; color:var(--pp-muted);">
        <p>No active bookings found. <a href="book_ticket.php" style="color:var(--pp-blue); font-weight:700;">Book a ticket now</a>.</p>
    </div>
<?php else: ?>
    <div class="bk-grid">
        <?php foreach ($activeBookings as $bkg): ?>
            <div class="bk-card">
                <div class="bk-card-header">
                    <div>
                        <strong style="font-size:14px; color:var(--pp-blue);"><?= pp_h($bkg['route_code']) ?></strong>
                        <div style="font-size:11px; color:#64748b;"><?= pp_h($bkg['route_name']) ?></div>
                    </div>
                    <span class="bk-badge bk-badge-booked"><?= pp_h($bkg['booking_status']) ?></span>
                </div>

                <div class="bk-info">
                    <div><strong>Ref:</strong> <?= pp_h($bkg['booking_reference']) ?></div>
                    <div><strong>Route:</strong> <?= pp_h($bkg['start_location']) ?> → <?= pp_h($bkg['end_location']) ?></div>
                    <div><strong>Date & Time:</strong> <?= pp_h($bkg['schedule_date']) ?> @ <?= pp_h($bkg['departure_time']) ?></div>
                    <div><strong>Assigned Slot:</strong> <?= $bkg['slot_type'] === 'SEAT' ? 'Seat ' . pp_h((string)($bkg['seat_number'] ?? 'Assigned')) : 'Standing Slot S-' . pp_h((string)$bkg['standing_slot']) ?></div>
                    <div><strong>Fare:</strong> BDT <?= pp_h((string)$bkg['fare_charged']) ?></div>
                </div>

                <div class="bk-actions">
                    <button 
                        type="button" 
                        class="pp-primary-button" 
                        style="padding:6px 12px; font-size:11px;"
                        onclick="showQrModal('<?= pp_h($bkg['booking_reference']) ?>', '<?= urlencode($bkg['qr_token']) ?>')"
                    >
                        View QR Code
                    </button>

                <form method="POST" action="" onsubmit="return confirm('Are you sure you want to cancel this booking?');">
    <input type="hidden" name="action" value="cancel">
    <input type="hidden" name="booking_id" value="<?php echo (int)($bkg['booking_id'] ?? $bkg['id'] ?? 0); ?>">
    <button type="submit" class="btn-cancel">Cancel Ticket</button>
</form>    
                </div>
            </div>
        <?php endforeach; ?>
    </div>
<?php endif; ?>

<!-- Booking History Section -->
<div class="section-title">
    <span>Booking History & Past Trips</span>
</div>

<?php if (empty($historyBookings)): ?>
    <div class="bk-card" style="text-align:center; padding:24px; color:var(--pp-muted);">
        <p>No past booking history available.</p>
    </div>
<?php else: ?>
    <div class="bk-grid">
        <?php foreach ($historyBookings as $hb): ?>
            <div class="bk-card" style="opacity: 0.85;">
                <div class="bk-card-header">
                    <div>
                        <strong><?= pp_h($hb['route_code']) ?> — <?= pp_h($hb['route_name']) ?></strong>
                        <div style="font-size:10px; color:var(--pp-muted);"><?= pp_h($hb['booking_reference']) ?></div>
                    </div>
                    <span class="bk-badge bk-badge-<?= strtolower($hb['booking_status']) === 'cancelled' ? 'cancelled' : 'completed' ?>">
                        <?= pp_h($hb['booking_status']) ?>
                    </span>
                </div>

                <div class="bk-info">
                    <div><strong>Date:</strong> <?= pp_h($hb['schedule_date']) ?></div>
                    <div><strong>Slot:</strong> <?= $hb['slot_type'] === 'SEAT' ? 'Seat ' . pp_h((string)($hb['seat_number'] ?? 'N/A')) : 'Standing Slot S-' . pp_h((string)$hb['standing_slot']) ?></div>
                    <div><strong>Fare:</strong> BDT <?= pp_h((string)$hb['fare_charged']) ?></div>
                </div>

                <div class="bk-actions">
                    <form method="POST" action="">
                        <input type="hidden" name="action" value="archive">
                        <input type="hidden" name="booking_id" value="<?= $hb['booking_id'] ?>">
                        <button type="submit" style="background:none; border:none; color:var(--pp-muted); font-size:11px; cursor:pointer; text-decoration:underline;">
                            Archive from view
                        </button>
                    </form>
                </div>
            </div>
        <?php endforeach; ?>
    </div>
<?php endif; ?>

<!-- QR Code Modal -->
<div class="qr-modal" id="qrModal" onclick="if(event.target === this) hideQrModal()">
    <div class="qr-modal-content">
        <h4 style="margin:0; color:var(--pp-blue);" id="modalRef">Booking QR</h4>
        <img id="modalQrImg" src="" alt="QR Code" style="width:180px; height:180px; margin:12px 0;">
        <br>
        <button type="button" class="pp-primary-button" onclick="hideQrModal()">Close</button>
    </div>
</div>

<script>
function showQrModal(ref, token) {
    document.getElementById('modalRef').innerText = 'Reference: ' + ref;
    document.getElementById('modalQrImg').src = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=' + token;
    document.getElementById('qrModal').style.display = 'grid';
}

function hideQrModal() {
    document.getElementById('qrModal').style.display = 'none';
}
</script>

<?php
pp_render_end();