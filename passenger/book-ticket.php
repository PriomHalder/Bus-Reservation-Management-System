<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';
require_once __DIR__ . '/../includes/auth.php';

$message = '';
$messageType = '';
$confirmedBooking = null;

// Handle Booking Submission
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'book') {
    $scheduleId = (int)($_POST['schedule_id'] ?? 0);
    $slotType = strtoupper(trim((string)($_POST['slot_type'] ?? 'SEAT')));
    $slotNumber = (int)($_POST['slot_number'] ?? 0);

    if (!verifyCsrf((string)($_POST['csrf_token'] ?? ''))) {
        $message = 'Your session expired. Refresh the page and try again.';
        $messageType = 'error';
    } elseif ($scheduleId <= 0 || $slotNumber <= 0 || !in_array($slotType, ['SEAT', 'STANDING'], true)) {
        $message = 'Invalid booking parameters provided or no seat selected.';
        $messageType = 'error';
    } else {
        try {
            $confirmedBooking = uniride_create_booking(
                $pdo,
                $ppPassengerId,
                $scheduleId,
                $slotType,
                $slotNumber
            );
            $message = 'Booking confirmed successfully!';
            $messageType = 'success';
        } catch (RuntimeException $e) {
            $message = 'Booking failed: ' . $e->getMessage();
            $messageType = 'error';
        } catch (Throwable $e) {
            error_log('[UniRide create booking] ' . $e->getMessage());
            $message = 'Booking failed. Please reload the schedule and try again.';
            $messageType = 'error';
        }
    }
}

// Fetch available upcoming schedules for user's university
$schedules = [];
try {
    $stmt = $pdo->prepare(
        "SELECT 
            s.schedule_id,
            s.schedule_date,
            s.departure_time,
            s.arrival_time,
            r.route_code,
            r.route_name,
            r.start_location,
            r.end_location,
            r.fare,
            b.registration_number,
            b.bus_type,
            b.seat_capacity,
            b.standing_capacity
         FROM schedules s
         INNER JOIN routes r ON r.route_id = s.route_id
         INNER JOIN buses b ON b.bus_id = s.bus_id
         WHERE r.university_id = ?
           AND r.status = 'ACTIVE'
           AND b.status = 'ACTIVE'
           AND s.status = 'SCHEDULED'
           AND s.schedule_date >= CURDATE()
           AND (
                b.bus_type = 'STANDARD'
                OR (? = 'STUDENT' AND b.bus_type = 'STUDENT_ONLY')
                OR (? = 'FACULTY' AND b.bus_type = 'FACULTY_ONLY')
           )
         ORDER BY s.schedule_date ASC, s.departure_time ASC"
    );
    $stmt->execute([
        $ppUniversityId,
        (string)$ppProfile['passenger_type'],
        (string)$ppProfile['passenger_type'],
    ]);
    $schedules = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    error_log('[book_ticket.php] ' . $e->getMessage());
}

// Selected Schedule context
$selectedScheduleId = (int)($_GET['schedule_id'] ?? ($_POST['schedule_id'] ?? ($schedules[0]['schedule_id'] ?? 0)));
$currentSchedule = null;

foreach ($schedules as $sch) {
    if ((int)$sch['schedule_id'] === $selectedScheduleId) {
        $currentSchedule = $sch;
        break;
    }
}

// Fetch occupied slots for selected schedule
$bookedSeats = [];
$bookedStanding = [];

if ($currentSchedule) {
    try {
        $stmt = $pdo->prepare(
            "SELECT slot_type, seat_number, standing_slot 
             FROM bookings 
             WHERE schedule_id = ? 
               AND status IN ('BOOKED', 'CONFIRMED', 'TRANSFER_PENDING')"
        );
        $stmt->execute([$currentSchedule['schedule_id']]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($rows as $row) {
            if ($row['slot_type'] === 'SEAT' && $row['seat_number'] !== null) {
                $bookedSeats[] = (int)$row['seat_number'];
            } elseif ($row['slot_type'] === 'STANDING' && $row['standing_slot'] !== null) {
                $bookedStanding[] = (int)$row['standing_slot'];
            }
        }
    } catch (PDOException $e) {
        error_log('[book_ticket.php occupied slots] ' . $e->getMessage());
    }
}

$seatCapacity = (int)($currentSchedule['seat_capacity'] ?? 40);
$standingCapacity = (int)($currentSchedule['standing_capacity'] ?? 10);
$totalSeatsBooked = count($bookedSeats);
$allSeatsFilled = ($totalSeatsBooked >= $seatCapacity);

pp_render_start(
    'Book a Ticket',
    'book-ticket',
    'Seat Selection',
    'Select a bus schedule, view route details, and reserve your seat or standing slot.'
);
?>

<style>
    .bt-container { display: grid; grid-template-columns: 1fr 340px; gap: 24px; margin-top: 24px; }
    .bt-card { background: #ffffff; border: 1px solid var(--pp-line, #e2e8f0); border-radius: 12px; padding: 20px; color: #1e293b; }
    .bt-card h3, .bt-card h4 { color: #0f172a !important; }
    .bt-alert { padding: 12px 16px; border-radius: 8px; margin-bottom: 20px; font-weight: 600; font-size: 13px; }
    .bt-alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
    .bt-alert-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
    
    .route-header { 
        background: #f0f9ff !important; 
        border: 1px solid #bae6fd !important; 
        border-radius: 10px; 
        padding: 16px; 
        margin-bottom: 20px; 
    }
    .route-header h3 { color: #0369a1 !important; font-weight: 800; }
    .route-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: 12px; margin-top: 10px; }
    .route-stat { display: flex; flex-direction: column; }
    .route-stat label { font-size: 10px; text-transform: uppercase; color: #475569 !important; font-weight: 700; }
    .route-stat span { font-weight: 700; font-size: 13px; color: #0f172a !important; }

    /* Interactive Bus Layout (10 rows x 4 cols) */
    .bus-wrapper { background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 24px; padding: 24px 20px; max-width: 360px; margin: 0 auto; }
    .bus-driver { text-align: right; padding-bottom: 12px; border-bottom: 2px dashed #cbd5e1; margin-bottom: 18px; color: #64748b; font-size: 11px; font-weight: 700; text-transform: uppercase; }
    .bus-grid { display: grid; grid-template-columns: 1fr 1fr 30px 1fr 1fr; gap: 8px; align-items: center; }
    .bus-aisle { text-align: center; color: #94a3b8; font-size: 10px; font-weight: 700; }
    
    /* Pure CSS Radio Seat Selection */
    .seat-option { position: relative; }
    .seat-option input[type="radio"] {
        position: absolute;
        opacity: 0;
        width: 0;
        height: 0;
    }
    .seat-label {
        height: 38px; border-radius: 8px; border: 1px solid #cbd5e1; background: #ffffff;
        font-size: 11px; font-weight: 700; cursor: pointer; transition: all 0.15s ease;
        display: flex; align-items: center; justify-content: center; color: #16a34a;
        background-color: #f0fdf4; border-color: #16a34a; user-select: none;
    }
    .seat-label:hover { background-color: #16a34a; color: #ffffff; }
    
    /* Checked State Styling */
    .seat-option input[type="radio"]:checked + .seat-label {
        background-color: var(--pp-blue, #0284c7) !important;
        border-color: var(--pp-blue, #0284c7) !important;
        color: #ffffff !important;
        box-shadow: 0 0 0 3px rgba(2,132,199,0.25);
    }

    /* Occupied State Styling */
    .seat-option input[type="radio"]:disabled + .seat-label {
        background-color: #e2e8f0 !important;
        border-color: #cbd5e1 !important;
        color: #94a3b8 !important;
        cursor: not-allowed;
    }

    /* Standing Slots */
    .standing-box { margin-top: 20px; padding: 16px; border: 1px dashed #f59e0b; background: #fffbeb; border-radius: 10px; }
    .standing-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 8px; margin-top: 10px; }

    /* Legend */
    .bus-legend { display: flex; justify-content: space-around; gap: 8px; margin-top: 18px; padding-top: 14px; border-top: 1px solid #e2e8f0; color: #334155; }
    .legend-item { display: flex; align-items: center; gap: 6px; font-size: 11px; font-weight: 600; }
    .legend-dot { width: 14px; height: 14px; border-radius: 4px; border: 1px solid; }
    .legend-dot.avail { background: #f0fdf4; border-color: #16a34a; }
    .legend-dot.occ { background: #e2e8f0; border-color: #cbd5e1; }
    .legend-dot.sel { background: var(--pp-blue, #0284c7); border-color: var(--pp-blue, #0284c7); }

    /* QR Code Card */
    .qr-card { text-align: center; background: #ffffff; border: 2px solid var(--pp-blue, #0284c7); border-radius: 16px; padding: 24px; margin-bottom: 24px; color: #1e293b; }
    .qr-card img { width: 180px; height: 180px; border-radius: 8px; border: 1px solid #e2e8f0; margin: 12px 0; }

    @media (max-width: 850px) { .bt-container { grid-template-columns: 1fr; } }
</style>

<?php if ($message): ?>
    <div class="bt-alert bt-alert-<?= pp_h($messageType) ?>">
        <?= pp_h($message) ?>
    </div>
<?php endif; ?>

<?php if ($confirmedBooking): ?>
    <!-- Confirmation & QR Code Section -->
    <div class="qr-card">
       <h3 style="margin:0; color: #000000 !important;">🎉 Booking Confirmed!</h3>
        <p style="margin:4px 0 12px; color:#64748b; font-size:12px;">Present this QR code to the conductor when boarding.</p>
        
        <?php
        $qrToken = $confirmedBooking['qr_token'] ?? $confirmedBooking['booking_reference'];
        $qrApiUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=' . urlencode($qrToken);
        ?>
        <img src="<?= pp_h($qrApiUrl) ?>" alt="Booking QR Code">

        <div style="font-size:12px; line-height:1.6; color:#0f172a;">
            <strong>Reference:</strong> <?= pp_h($confirmedBooking['booking_reference']) ?><br>
            <strong>Slot:</strong> <?= pp_h($confirmedBooking['slot_type']) ?> #<?= pp_h((string)($confirmedBooking['seat_number'] ?? $confirmedBooking['standing_slot'])) ?><br>
            <strong>Fare Charged:</strong> BDT <?= pp_h(number_format((float)$confirmedBooking['fare_charged'], 2)) ?>
        </div>

        <a class="pp-primary-button" href="my-bookings.php" style="margin-top:16px; display:inline-flex;">
            View All My Bookings
        </a>
    </div>
<?php endif; ?>

<!-- Schedule Selector Form (Uses standard submit button instead of JS onchange) -->
<form method="GET" action="" style="margin-bottom: 20px; display: flex; gap: 8px; align-items: flex-end;">
    <div style="flex-grow: 1; max-width: 450px;">
        <label style="font-weight:700; font-size:12px; display:block; margin-bottom:6px; color:#f8fafc;">Select Bus Schedule:</label>
        <select name="schedule_id" style="width:100%; padding:10px; border-radius:8px; border:1px solid #cbd5e1; background:#ffffff; color:#0f172a;">
            <?php if (empty($schedules)): ?>
                <option value="0">No active schedules available</option>
            <?php else: ?>
                <?php foreach ($schedules as $sch): ?>
                    <option value="<?= $sch['schedule_id'] ?>" <?= $sch['schedule_id'] == $selectedScheduleId ? 'selected' : '' ?>>
                        <?= pp_h($sch['route_code']) ?> (<?= pp_h($sch['route_name']) ?>) — <?= pp_h($sch['schedule_date']) ?> @ <?= pp_h($sch['departure_time']) ?>
                    </option>
                <?php endforeach; ?>
            <?php endif; ?>
        </select>
    </div>
    <button type="submit" class="pp-primary-button" style="height: 40px;">Load Schedule</button>
</form>

<?php if ($currentSchedule): ?>
<form method="POST" action="">
    <input type="hidden" name="csrf_token" value="<?= pp_h(csrfToken()) ?>">
    <input type="hidden" name="action" value="book">
    <input type="hidden" name="schedule_id" value="<?= $currentSchedule['schedule_id'] ?>">
    <input type="hidden" name="slot_type" value="<?= $allSeatsFilled ? 'STANDING' : 'SEAT' ?>">

    <div class="bt-container">
        <!-- Main Seat Selection Area -->
        <div class="bt-card">
            <!-- Route & Schedule Details -->
            <div class="route-header">
                <h3 style="margin:0; font-size:16px;">
                    <?= pp_h($currentSchedule['route_code']) ?>: <?= pp_h($currentSchedule['route_name']) ?>
                </h3>
                <div class="route-grid">
                    <div class="route-stat">
                        <label>Route</label>
                        <span><?= pp_h($currentSchedule['start_location']) ?> → <?= pp_h($currentSchedule['end_location']) ?></span>
                    </div>
                    <div class="route-stat">
                        <label>Departure</label>
                        <span><?= pp_h($currentSchedule['schedule_date']) ?> @ <?= pp_h($currentSchedule['departure_time']) ?></span>
                    </div>
                    <div class="route-stat">
                        <label>Bus Registration</label>
                        <span><?= pp_h($currentSchedule['registration_number']) ?> (<?= pp_h($currentSchedule['bus_type']) ?>)</span>
                    </div>
                    <div class="route-stat">
                        <label>Fare</label>
                        <span>BDT <?= pp_h(number_format(uniride_ticket_fare(), 2)) ?></span>
                    </div>
                </div>
            </div>

            <?php if (!$allSeatsFilled): ?>
                <h4 style="margin:0 0 12px; font-size:14px; text-align:center; color:#0f172a;">Interactive Seat Layout (10 Rows × 4 Columns)</h4>
                
                <div class="bus-wrapper">
                    <div class="bus-driver">🚍 Front / Driver Side</div>
                    
                    <div class="bus-grid">
                        <?php
                        for ($row = 1; $row <= 10; $row++):
                            $rowLetter = chr(64 + $row);
                            for ($col = 1; $col <= 4; $col++):
                                $seatNum = (($row - 1) * 4) + $col;
                                $isOccupied = in_array($seatNum, $bookedSeats, true);
                                $seatLabel = $rowLetter . $col;

                                if ($col === 3): ?>
                                    <div class="bus-aisle"><?= $row ?></div>
                                <?php endif; ?>

                                <div class="seat-option">
                                    <input 
                                        type="radio" 
                                        name="slot_number" 
                                        id="seat_<?= $seatNum ?>" 
                                        value="<?= $seatNum ?>" 
                                        <?= $isOccupied ? 'disabled' : '' ?>
                                        required
                                    >
                                    <label for="seat_<?= $seatNum ?>" class="seat-label">
                                        <?= $seatLabel ?>
                                    </label>
                                </div>
                            <?php endfor; ?>
                        <?php endfor; ?>
                    </div>

                    <div class="bus-legend">
                        <div class="legend-item"><div class="legend-dot avail"></div> Available</div>
                        <div class="legend-item"><div class="legend-dot occ"></div> Booked</div>
                        <div class="legend-item"><div class="legend-dot sel"></div> Selected</div>
                    </div>
                </div>
            <?php else: ?>
                <!-- All Seats Filled -> Opt-in Standing Slot -->
                <div class="standing-box">
                    <h4 style="margin:0; color:#b45309;">⚠️ All 40 Seats Are Occupied!</h4>
                    <p style="margin:4px 0 12px; font-size:12px; color:#b45309;">
                        All physical seats are taken for this bus schedule. You can opt-in to book a <strong>Standing Capacity Slot</strong> below.
                    </p>

                    <label style="font-weight:700; font-size:12px; color:#b45309;">Select Standing Slot (1 to <?= $standingCapacity ?>):</label>
                    <div class="standing-grid">
                        <?php for ($s = 1; $s <= $standingCapacity; $s++): 
                            $isStandOccupied = in_array($s, $bookedStanding, true);
                        ?>
                            <div class="seat-option">
                                <input 
                                    type="radio" 
                                    name="slot_number" 
                                    id="stand_<?= $s ?>" 
                                    value="<?= $s ?>" 
                                    <?= $isStandOccupied ? 'disabled' : '' ?>
                                    required
                                >
                                <label for="stand_<?= $s ?>" class="seat-label">
                                    S-<?= $s ?>
                                </label>
                            </div>
                        <?php endfor; ?>
                    </div>
                </div>
            <?php endif; ?>
        </div>

        <!-- Right Summary Sidebar -->
        <div>
            <div class="bt-card" style="position:sticky; top:80px;">
                <h3 style="margin:0 0 16px; font-size:15px; border-bottom:1px solid #e2e8f0; padding-bottom:10px; color:#0f172a;">Booking Summary</h3>
                
                <div style="display:grid; gap:12px; font-size:13px; margin-bottom:20px;">
                    <div style="display:flex; justify-content:space-between; align-items:center;">
                        <span style="color:#64748b; font-weight:600;">Slot Type:</span>
                        <strong style="color:#0f172a; font-weight:700;"><?= $allSeatsFilled ? 'STANDING' : 'SEAT' ?></strong>
                    </div>
                    <div style="display:flex; justify-content:space-between; align-items:center;">
                        <span style="color:#64748b; font-weight:600;">Total Fare:</span>
                        <strong style="font-size:15px; color:#0f172a; font-weight:800;">BDT <?= pp_h(number_format(uniride_ticket_fare(), 2)) ?></strong>
                    </div>
                </div>

                <button 
                    type="submit" 
                    class="pp-primary-button" 
                    style="width:100%; text-align:center; height:42px;"
                >
                    Confirm & Pay
                </button>
            </div>
        </div>
    </div>
</form>
<?php endif; ?>

<?php
pp_render_end();
