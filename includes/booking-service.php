<?php
declare(strict_types=1);

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

function uniride_log_optional_booking_error(string $stage, Throwable $error): void
{
    error_log('[UniRide booking ' . $stage . '] ' . $error->getMessage());
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
             WHERE p.passenger_id=?
               AND s.schedule_date>=CURDATE()
             LIMIT 1
             FOR UPDATE"
        );
        $stmt->execute([$scheduleId, $passengerId]);
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
