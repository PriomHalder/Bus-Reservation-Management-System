<?php
declare(strict_types=1);

require_once __DIR__ . '/schedule-policy.php';

/*
|--------------------------------------------------------------------------
| UniRide shared Passenger booking service
|--------------------------------------------------------------------------
| The project uses one flat fare for Student and Faculty passengers. Booking
| is performed here instead of depending on a database stored procedure, so
| an existing installation works even when sp_create_booking is unavailable.
*/

const UNIRIDE_TICKET_FARE = 110.00;

function uniride_ticket_fare(): float
{
    return UNIRIDE_TICKET_FARE;
}

function uniride_booking_table_exists(PDO $pdo, string $table): bool
{
    static $cache = [];

    if (!preg_match('/^[a-zA-Z0-9_]+$/', $table)) {
        return false;
    }

    if (array_key_exists($table, $cache)) {
        return $cache[$table];
    }

    try {
        $stmt = $pdo->prepare(
            'SELECT COUNT(*) FROM information_schema.tables '
            . 'WHERE table_schema=DATABASE() AND table_name=?'
        );
        $stmt->execute([$table]);
        $cache[$table] = (bool)$stmt->fetchColumn();
    } catch (Throwable $error) {
        uniride_log_optional_booking_error('schema check', $error);
        $cache[$table] = false;
    }

    return $cache[$table];
}

function uniride_booking_column_exists(PDO $pdo, string $table, string $column): bool
{
    static $cache = [];
    $key = $table . '.' . $column;

    if (!preg_match('/^[a-zA-Z0-9_]+$/', $table . $column)) {
        return false;
    }
    if (array_key_exists($key, $cache)) {
        return $cache[$key];
    }

    try {
        $stmt = $pdo->prepare(
            'SELECT COUNT(*) FROM information_schema.columns '
            . 'WHERE table_schema=DATABASE() AND table_name=? AND column_name=?'
        );
        $stmt->execute([$table, $column]);
        $cache[$key] = (bool)$stmt->fetchColumn();
    } catch (Throwable $error) {
        uniride_log_optional_booking_error('schema check', $error);
        $cache[$key] = false;
    }

    return $cache[$key];
}

function uniride_log_optional_booking_error(string $stage, Throwable $error): void
{
    error_log('[UniRide booking ' . $stage . '] ' . $error->getMessage());
}

/** Return the application clock used by schedule creation and Passenger visibility. */
function uniride_schedule_clock(): DateTimeImmutable
{
    return new DateTimeImmutable('now', new DateTimeZone('Asia/Dhaka'));
}

/**
 * Load current schedule rows for one authenticated Passenger university.
 *
 * Both Passenger schedule pages consume this function so a newly created or
 * edited University Admin schedule is evaluated by one consistent set of
 * tenant, assignment, status, shift, eligibility and time rules.
 *
 * @return array{
 *   schedules:array<int,array<string,mixed>>,
 *   candidate_count:int,
 *   departed_count:int,
 *   ineligible_count:int,
 *   invalid_shift_count:int
 * }
 */
function uniride_load_passenger_schedules(
    PDO $pdo,
    int $universityId,
    string $passengerType,
    string $serviceDate
): array {
    $passengerType = strtoupper(trim($passengerType));
    $date = DateTimeImmutable::createFromFormat('!Y-m-d', $serviceDate);

    if (
        $universityId <= 0
        || !in_array($passengerType, ['STUDENT', 'FACULTY'], true)
        || !$date
        || $date->format('Y-m-d') !== $serviceDate
    ) {
        throw new RuntimeException('The requested schedule context is invalid.');
    }
    if (
        !uniride_booking_column_exists($pdo, 'schedules', 'shift_name')
        || !uniride_booking_column_exists($pdo, 'bus_route_assignments', 'is_active')
    ) {
        throw new RuntimeException('Fixed-shift scheduling is not configured.');
    }

    $stmt = $pdo->prepare(
        "SELECT
            s.schedule_id,
            s.schedule_date,
            s.departure_time,
            s.arrival_time,
            s.shift_name,
            r.route_id,
            r.route_code,
            r.route_name,
            r.start_location,
            r.end_location,
            b.bus_id,
            b.registration_number,
            b.bus_type,
            b.seat_capacity,
            b.standing_capacity
         FROM schedules s
         INNER JOIN routes r ON r.route_id=s.route_id
         INNER JOIN buses b ON b.bus_id=s.bus_id
         INNER JOIN bus_route_assignments bra
            ON bra.bus_id=s.bus_id
           AND bra.route_id=s.route_id
           AND bra.is_active=1
         WHERE r.university_id=?
           AND b.university_id=?
           AND s.schedule_date=?
           AND s.status='SCHEDULED'
           AND r.status='ACTIVE'
           AND b.status='ACTIVE'
         ORDER BY r.route_code ASC,
                  CASE s.shift_name WHEN 'NOON' THEN 1 WHEN 'EVENING' THEN 2 ELSE 3 END ASC,
                  s.schedule_id DESC"
    );
    $stmt->execute([$universityId, $universityId, $serviceDate]);
    $candidates = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $capacityStmt = $pdo->prepare(
        "SELECT
            COALESCE(SUM(CASE WHEN slot_type='SEAT' THEN 1 ELSE 0 END),0) booked_seats,
            COALESCE(SUM(CASE WHEN slot_type='STANDING' THEN 1 ELSE 0 END),0) booked_standing
         FROM bookings
         WHERE schedule_id=?
           AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')"
    );

    $result = [
        'schedules' => [],
        'candidate_count' => count($candidates),
        'departed_count' => 0,
        'ineligible_count' => 0,
        'invalid_shift_count' => 0,
    ];
    $now = uniride_schedule_clock();
    $today = $now->format('Y-m-d');
    $currentTime = $now->format('H:i:s');

    foreach ($candidates as $schedule) {
        if (!uniride_schedule_is_fixed_shift(
            (string)$schedule['shift_name'],
            (string)$schedule['departure_time']
        )) {
            $result['invalid_shift_count']++;
            continue;
        }
        if ($serviceDate < $today || (
            $serviceDate === $today
            && (string)$schedule['departure_time'] <= $currentTime
        )) {
            $result['departed_count']++;
            continue;
        }

        $busType = strtoupper(trim((string)$schedule['bus_type']));
        $eligible = $busType === 'STANDARD'
            || ($passengerType === 'STUDENT' && $busType === 'STUDENT_ONLY')
            || ($passengerType === 'FACULTY' && $busType === 'FACULTY_ONLY');
        if (!$eligible) {
            $result['ineligible_count']++;
            continue;
        }

        $capacityStmt->execute([(int)$schedule['schedule_id']]);
        $capacity = $capacityStmt->fetch(PDO::FETCH_ASSOC) ?: [];
        $schedule['booked_seats'] = (int)($capacity['booked_seats'] ?? 0);
        $schedule['booked_standing'] = (int)($capacity['booked_standing'] ?? 0);
        $schedule['available_seats'] = max(
            0,
            (int)$schedule['seat_capacity'] - $schedule['booked_seats']
        );
        $schedule['available_standing'] = max(
            0,
            (int)$schedule['standing_capacity'] - $schedule['booked_standing']
        );
        $result['schedules'][] = $schedule;
    }

    return $result;
}

/**
 * Create one tenant-safe booking for the authenticated Passenger.
 *
 * @return array<string,mixed>
 */
function uniride_create_booking(
    PDO $pdo,
    int $passengerId,
    int $scheduleId,
    string $slotType,
    int $slotNumber
): array {
    $slotType = strtoupper(trim($slotType));

    if ($passengerId <= 0 || $scheduleId <= 0 || $slotNumber <= 0) {
        throw new RuntimeException('Choose an available seat or standing slot.');
    }
    if (!in_array($slotType, ['SEAT', 'STANDING'], true)) {
        throw new RuntimeException('The selected booking type is invalid.');
    }
    if (
        !uniride_booking_column_exists($pdo, 'schedules', 'shift_name')
        || !uniride_booking_column_exists($pdo, 'bus_route_assignments', 'is_active')
    ) {
        throw new RuntimeException('Fixed-shift scheduling is not configured. Ask an administrator to import migration 007.');
    }

    $clock = uniride_schedule_clock();
    $today = $clock->format('Y-m-d');
    $currentTime = $clock->format('H:i:s');

    $pdo->beginTransaction();

    try {
        /* Lock the schedule so simultaneous requests cannot claim one slot. */
        $stmt = $pdo->prepare(
            "SELECT
                p.passenger_id,
                p.university_id AS passenger_university_id,
                p.passenger_type,
                p.status AS passenger_status,
                p.in_app_notifications,
                u.status AS university_status,
                s.schedule_id,
                s.schedule_date,
                s.departure_time,
                s.shift_name,
                s.status AS schedule_status,
                r.route_id,
                r.route_code,
                r.university_id AS route_university_id,
                r.status AS route_status,
                b.bus_id,
                b.university_id AS bus_university_id,
                b.bus_type,
                b.status AS bus_status,
                b.seat_capacity,
                b.standing_capacity
             FROM passengers p
             INNER JOIN universities u ON u.university_id=p.university_id
             INNER JOIN schedules s ON s.schedule_id=?
             INNER JOIN routes r ON r.route_id=s.route_id
             INNER JOIN buses b ON b.bus_id=s.bus_id
             INNER JOIN bus_route_assignments bra
                ON bra.bus_id=s.bus_id
               AND bra.route_id=s.route_id
               AND bra.is_active=1
             WHERE p.passenger_id=?
               AND (
                    s.schedule_date>?
                    OR (s.schedule_date=? AND s.departure_time>?)
               )
             LIMIT 1
             FOR UPDATE"
        );
        $stmt->execute([$scheduleId, $passengerId, $today, $today, $currentTime]);
        $context = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$context) {
            throw new RuntimeException('This schedule is no longer available for booking.');
        }

        $passengerType = strtoupper((string)$context['passenger_type']);
        $busType = strtoupper((string)$context['bus_type']);
        $passengerUniversity = (int)$context['passenger_university_id'];

        if (
            strtoupper((string)$context['passenger_status']) !== 'ACTIVE'
            || strtoupper((string)$context['university_status']) !== 'ACTIVE'
        ) {
            throw new RuntimeException('This Passenger account is not available for booking.');
        }
        if (
            $passengerUniversity !== (int)$context['route_university_id']
            || $passengerUniversity !== (int)$context['bus_university_id']
        ) {
            throw new RuntimeException('This schedule does not belong to your university.');
        }
        if (
            strtoupper((string)$context['schedule_status']) !== 'SCHEDULED'
            || strtoupper((string)$context['route_status']) !== 'ACTIVE'
            || strtoupper((string)$context['bus_status']) !== 'ACTIVE'
        ) {
            throw new RuntimeException('This schedule is not currently open for booking.');
        }
        if (!uniride_schedule_is_fixed_shift(
            (string)$context['shift_name'],
            (string)$context['departure_time']
        )) {
            throw new RuntimeException('This trip is not a valid Noon or Evening schedule.');
        }
        if (
            !in_array($passengerType, ['STUDENT', 'FACULTY'], true)
            || ($busType === 'STUDENT_ONLY' && $passengerType !== 'STUDENT')
            || ($busType === 'FACULTY_ONLY' && $passengerType !== 'FACULTY')
        ) {
            throw new RuntimeException('This bus is not available for your Passenger type.');
        }

        $stmt = $pdo->prepare(
            "SELECT COUNT(*) FROM bookings
             WHERE passenger_id=? AND schedule_id=?
               AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')"
        );
        $stmt->execute([$passengerId, $scheduleId]);
        if ((int)$stmt->fetchColumn() > 0) {
            throw new RuntimeException('You already have an active booking for this schedule.');
        }

        $seatCapacity = max(0, (int)$context['seat_capacity']);
        $standingCapacity = max(0, (int)$context['standing_capacity']);

        $stmt = $pdo->prepare(
            "SELECT
                SUM(CASE WHEN slot_type='SEAT' THEN 1 ELSE 0 END) AS booked_seats,
                SUM(CASE WHEN slot_type='STANDING' THEN 1 ELSE 0 END) AS booked_standing
             FROM bookings
             WHERE schedule_id=?
               AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')"
        );
        $stmt->execute([$scheduleId]);
        $load = $stmt->fetch(PDO::FETCH_ASSOC) ?: [];
        $bookedSeats = (int)($load['booked_seats'] ?? 0);
        $bookedStanding = (int)($load['booked_standing'] ?? 0);

        if ($slotType === 'SEAT') {
            if ($slotNumber > $seatCapacity || $bookedSeats >= $seatCapacity) {
                throw new RuntimeException('The selected seat is not available.');
            }
            $stmt = $pdo->prepare(
                "SELECT COUNT(*) FROM bookings
                 WHERE schedule_id=? AND slot_type='SEAT' AND seat_number=?
                   AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')"
            );
            $stmt->execute([$scheduleId, $slotNumber]);
        } else {
            if ($bookedSeats < $seatCapacity) {
                throw new RuntimeException('Standing slots open only after all seats are occupied.');
            }
            if ($slotNumber > $standingCapacity || $bookedStanding >= $standingCapacity) {
                throw new RuntimeException('The selected standing slot is not available.');
            }
            $stmt = $pdo->prepare(
                "SELECT COUNT(*) FROM bookings
                 WHERE schedule_id=? AND slot_type='STANDING' AND standing_slot=?
                   AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')"
            );
            $stmt->execute([$scheduleId, $slotNumber]);
        }

        if ((int)$stmt->fetchColumn() > 0) {
            throw new RuntimeException('That seat or standing slot was just booked. Choose another one.');
        }

        $bookingReference = 'BKG-' . strtoupper(bin2hex(random_bytes(6)));
        $qrToken = bin2hex(random_bytes(32));
        $fare = uniride_ticket_fare();

        $stmt = $pdo->prepare(
            "INSERT INTO bookings
                (booking_reference,passenger_id,schedule_id,slot_type,
                 seat_number,standing_slot,fare_charged,qr_token,status)
             VALUES (?,?,?,?,?,?,?,?,'BOOKED')"
        );
        $stmt->execute([
            $bookingReference,
            $passengerId,
            $scheduleId,
            $slotType,
            $slotType === 'SEAT' ? $slotNumber : null,
            $slotType === 'STANDING' ? $slotNumber : null,
            $fare,
            $qrToken,
        ]);
        $bookingId = (int)$pdo->lastInsertId();

        /* Keep the selected route's stored fare consistent with the flat fare. */
        $stmt = $pdo->prepare('UPDATE routes SET fare=? WHERE route_id=? AND fare<>?');
        $stmt->execute([$fare, (int)$context['route_id'], $fare]);

        if (uniride_booking_table_exists($pdo, 'booking_status_history')) {
            try {
                $stmt = $pdo->prepare(
                    "INSERT INTO booking_status_history
                        (booking_id,old_status,new_status,changed_by)
                     VALUES (?,NULL,'BOOKED','PASSENGER')"
                );
                $stmt->execute([$bookingId]);
            } catch (Throwable $error) {
                uniride_log_optional_booking_error('history', $error);
            }
        }

        if (
            uniride_booking_table_exists($pdo, 'semesters')
            && uniride_booking_table_exists($pdo, 'billing_transactions')
        ) {
            try {
                $stmt = $pdo->query(
                    'SELECT semester_id FROM semesters '
                    . 'WHERE is_active=1 ORDER BY start_date DESC LIMIT 1'
                );
                $semesterId = (int)($stmt->fetchColumn() ?: 0);

                if ($semesterId > 0) {
                    $stmt = $pdo->prepare(
                        "INSERT INTO billing_transactions
                            (passenger_id,semester_id,booking_id,transaction_type,amount,description)
                         VALUES (?,?,?,'BOOKING_CHARGE',?,?)"
                    );
                    $stmt->execute([
                        $passengerId,
                        $semesterId,
                        $bookingId,
                        $fare,
                        'Charge for booking ' . $bookingReference,
                    ]);

                    if (uniride_booking_table_exists($pdo, 'semester_bills')) {
                        $stmt = $pdo->prepare(
                            "INSERT INTO semester_bills
                                (passenger_id,semester_id,total_charges,total_credits,net_balance)
                             VALUES (?,?,?,0,?)
                             ON DUPLICATE KEY UPDATE
                                total_charges=total_charges+VALUES(total_charges),
                                net_balance=net_balance+VALUES(net_balance)"
                        );
                        $stmt->execute([$passengerId, $semesterId, $fare, $fare]);
                    }
                }
            } catch (Throwable $error) {
                uniride_log_optional_booking_error('billing', $error);
            }
        }

        if (
            (int)($context['in_app_notifications'] ?? 1) === 1
            && uniride_booking_table_exists($pdo, 'notifications')
        ) {
            try {
                $stmt = $pdo->prepare(
                    "INSERT INTO notifications
                        (passenger_id,title,message,notification_type,reference_id)
                     VALUES (?,'Booking Confirmed',?,'BOOKING',?)"
                );
                $stmt->execute([
                    $passengerId,
                    'Your booking ' . $bookingReference . ' is confirmed at BDT 110.00.',
                    $bookingId,
                ]);
            } catch (Throwable $error) {
                uniride_log_optional_booking_error('notification', $error);
            }
        }

        $pdo->commit();

        return [
            'booking_id' => $bookingId,
            'booking_reference' => $bookingReference,
            'qr_token' => $qrToken,
            'slot_type' => $slotType,
            'seat_number' => $slotType === 'SEAT' ? $slotNumber : null,
            'standing_slot' => $slotType === 'STANDING' ? $slotNumber : null,
            'fare_charged' => number_format($fare, 2, '.', ''),
            'status' => 'BOOKED',
        ];
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $error;
    }
}

/**
 * Cancel one active booking owned by the authenticated University Admin's
 * university. The booking status, history, billing credit, notification and
 * administrator audit entry are committed together.
 *
 * @return array{booking_id:int,booking_reference:string,passenger_name:string}
 */
function uniride_cancel_booking_by_university_admin(
    PDO $pdo,
    int $universityAdminId,
    int $universityId,
    int $bookingId,
    string $reason
): array {
    $reason = trim((string)preg_replace('/\s+/u', ' ', $reason));
    $reasonLength = function_exists('mb_strlen') ? mb_strlen($reason) : strlen($reason);

    if ($universityAdminId <= 0 || $universityId <= 0 || $bookingId <= 0) {
        throw new RuntimeException('The selected booking is invalid.');
    }
    if ($reasonLength < 5 || $reasonLength > 255) {
        throw new RuntimeException('Enter a cancellation reason between 5 and 255 characters.');
    }
    if (
        !uniride_booking_table_exists($pdo, 'booking_status_history')
        || !uniride_booking_table_exists($pdo, 'notifications')
    ) {
        throw new RuntimeException('Booking cancellation is not configured. Ask the System Admin to complete the existing database migrations.');
    }

    $pdo->beginTransaction();

    try {
        $stmt = $pdo->prepare(
            "SELECT
                bk.booking_id,
                bk.booking_reference,
                bk.passenger_id,
                bk.fare_charged,
                bk.status AS booking_status,
                p.name AS passenger_name,
                p.university_id AS passenger_university_id,
                s.schedule_date,
                s.departure_time,
                r.route_code,
                r.route_name,
                r.university_id AS route_university_id,
                b.university_id AS bus_university_id,
                u.status AS university_status,
                ua.status AS administrator_status
             FROM bookings bk
             INNER JOIN passengers p ON p.passenger_id = bk.passenger_id
             INNER JOIN schedules s ON s.schedule_id = bk.schedule_id
             INNER JOIN routes r ON r.route_id = s.route_id
             INNER JOIN buses b ON b.bus_id = s.bus_id
             INNER JOIN universities u ON u.university_id = p.university_id
             INNER JOIN university_users ua
                ON ua.university_user_id = ?
               AND ua.university_id = p.university_id
             WHERE bk.booking_id = ?
               AND p.university_id = ?
               AND r.university_id = ?
               AND b.university_id = ?
             LIMIT 1
             FOR UPDATE"
        );
        $stmt->execute([
            $universityAdminId,
            $bookingId,
            $universityId,
            $universityId,
            $universityId,
        ]);
        $booking = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$booking) {
            throw new RuntimeException('The booking was not found or does not belong to your university.');
        }
        if (
            strtoupper((string)$booking['administrator_status']) !== 'ACTIVE'
            || strtoupper((string)$booking['university_status']) !== 'ACTIVE'
        ) {
            throw new RuntimeException('This account or university is not currently allowed to cancel bookings.');
        }
        if (
            (int)$booking['passenger_university_id'] !== $universityId
            || (int)$booking['route_university_id'] !== $universityId
            || (int)$booking['bus_university_id'] !== $universityId
        ) {
            throw new RuntimeException('The booking does not belong to your university.');
        }

        $oldStatus = strtoupper((string)$booking['booking_status']);
        if ($oldStatus === 'TRANSFER_PENDING') {
            throw new RuntimeException('A booking with a pending ticket transfer cannot be cancelled from this page.');
        }
        if (!in_array($oldStatus, ['BOOKED', 'CONFIRMED'], true)) {
            throw new RuntimeException('Only active booked or confirmed reservations can be cancelled.');
        }

        $stmt = $pdo->prepare(
            "UPDATE bookings
             SET status = 'CANCELLED'
             WHERE booking_id = ? AND status = ?"
        );
        $stmt->execute([$bookingId, $oldStatus]);
        if ($stmt->rowCount() !== 1) {
            throw new RuntimeException('The booking status changed before cancellation. Refresh the page and try again.');
        }

        if (uniride_booking_column_exists($pdo, 'booking_status_history', 'note')) {
            $stmt = $pdo->prepare(
                "INSERT INTO booking_status_history
                    (booking_id,old_status,new_status,changed_by,note)
                 VALUES (?,?,'CANCELLED','UNIVERSITY_ADMIN',?)"
            );
            $stmt->execute([$bookingId, $oldStatus, $reason]);
        } else {
            $stmt = $pdo->prepare(
                "INSERT INTO booking_status_history
                    (booking_id,old_status,new_status,changed_by)
                 VALUES (?,?,'CANCELLED','UNIVERSITY_ADMIN')"
            );
            $stmt->execute([$bookingId, $oldStatus]);
        }

        if (
            uniride_booking_table_exists($pdo, 'billing_transactions')
            && uniride_booking_table_exists($pdo, 'semester_bills')
        ) {
            $stmt = $pdo->prepare(
                "SELECT transaction_id,semester_id,ABS(amount) AS charged_amount
                 FROM billing_transactions
                 WHERE booking_id = ?
                   AND passenger_id = ?
                   AND transaction_type = 'BOOKING_CHARGE'
                 ORDER BY transaction_id DESC
                 LIMIT 1
                 FOR UPDATE"
            );
            $stmt->execute([$bookingId, (int)$booking['passenger_id']]);
            $charge = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($charge) {
                $stmt = $pdo->prepare(
                    "SELECT COUNT(*)
                     FROM billing_transactions
                     WHERE booking_id = ?
                       AND passenger_id = ?
                       AND transaction_type = 'CANCELLATION_CREDIT'"
                );
                $stmt->execute([$bookingId, (int)$booking['passenger_id']]);

                if ((int)$stmt->fetchColumn() === 0) {
                    $credit = (float)$charge['charged_amount'];
                    $stmt = $pdo->prepare(
                        "INSERT INTO billing_transactions
                            (passenger_id,semester_id,booking_id,transaction_type,amount,description)
                         VALUES (?,?,?,'CANCELLATION_CREDIT',?,?)"
                    );
                    $stmt->execute([
                        (int)$booking['passenger_id'],
                        (int)$charge['semester_id'],
                        $bookingId,
                        -$credit,
                        'University Admin cancellation credit for ' . $booking['booking_reference'],
                    ]);

                    $stmt = $pdo->prepare(
                        "UPDATE semester_bills
                         SET total_credits = total_credits + ?,
                             net_balance = net_balance - ?
                         WHERE passenger_id = ? AND semester_id = ?"
                    );
                    $stmt->execute([
                        $credit,
                        $credit,
                        (int)$booking['passenger_id'],
                        (int)$charge['semester_id'],
                    ]);
                    if ($stmt->rowCount() !== 1) {
                        throw new RuntimeException('The booking billing record could not be updated. No changes were saved.');
                    }
                }
            }
        }

        $departureTimestamp = strtotime((string)$booking['departure_time']);
        $departureLabel = $departureTimestamp
            ? date('g:i A', $departureTimestamp)
            : (string)$booking['departure_time'];
        $notificationMessage = sprintf(
            'Your booking %s for %s — %s on %s at %s was cancelled by your University Admin. Reason: %s Review My Bookings for the updated status.',
            (string)$booking['booking_reference'],
            (string)$booking['route_code'],
            (string)$booking['route_name'],
            (string)$booking['schedule_date'],
            $departureLabel,
            $reason
        );
        $stmt = $pdo->prepare(
            "INSERT INTO notifications
                (passenger_id,title,message,notification_type,reference_id,is_read)
             VALUES (?,'Booking Cancelled',?,'BOOKING',?,0)"
        );
        $stmt->execute([
            (int)$booking['passenger_id'],
            $notificationMessage,
            $bookingId,
        ]);

        if (uniride_booking_table_exists($pdo, 'user_security_events')) {
            $eventDescription = substr(
                'Cancelled booking ' . $booking['booking_reference']
                . ' for passenger ' . $booking['passenger_name']
                . ' in university ' . $universityId
                . '. Reason: ' . $reason,
                0,
                500
            );
            $clientIp = function_exists('profile_client_ip') ? profile_client_ip() : '';
            $userAgent = function_exists('profile_user_agent') ? profile_user_agent() : '';
            $stmt = $pdo->prepare(
                "INSERT INTO user_security_events
                    (user_type,user_id,event_type,event_description,ip_address,user_agent)
                 VALUES ('UNIVERSITY_ADMIN',?,'BOOKING_CANCELLED',?,?,?)"
            );
            $stmt->execute([$universityAdminId, $eventDescription, $clientIp, $userAgent]);
        }

        $pdo->commit();

        return [
            'booking_id' => $bookingId,
            'booking_reference' => (string)$booking['booking_reference'],
            'passenger_name' => (string)$booking['passenger_name'],
        ];
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $error;
    }
}
