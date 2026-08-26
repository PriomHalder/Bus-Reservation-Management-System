-- ============================================================================
-- UniRide — OPTIONAL University Admin dashboard demo seed
-- Database: uniride2
--
-- Run AFTER:
-- database/migrations/001_add_missing_dashboard_tables.sql
--
-- Uses CURDATE() / DATE_ADD() so the dashboard remains demonstrable later.
-- It does NOT replace the real application workflow; it only gives local XAMPP
-- development enough synthetic activity to exercise dashboard panels.
-- ============================================================================

USE `uniride2`;

SET @ACTIVE_SEMESTER_ID := (
    SELECT semester_id
    FROM semesters
    WHERE is_active = 1
    ORDER BY start_date DESC
    LIMIT 1
);

-- ---------------------------------------------------------------------------
-- Route-stop demonstration data. INSERT IGNORE makes this rerunnable because
-- route_id + stop_order is unique after the migration.
-- ---------------------------------------------------------------------------

INSERT IGNORE INTO route_stops (route_id,stop_name,stop_order,pickup_offset_minutes)
SELECT route_id,start_location,1,0 FROM routes;

INSERT IGNORE INTO route_stops (route_id,stop_name,stop_order,pickup_offset_minutes)
SELECT route_id,
       CASE route_code
           WHEN 'BRACU-R01' THEN 'Kawran Bazar'
           WHEN 'BRACU-R02' THEN 'Mohakhali'
           WHEN 'BRACU-R03' THEN 'Airport'
           WHEN 'BRACU-R04' THEN 'Malibagh'
           WHEN 'BRACU-R05' THEN 'Agargaon'
           WHEN 'NSU-R01' THEN 'Bashundhara Gate'
           WHEN 'AIUB-R01' THEN 'Khilkhet'
           ELSE CONCAT(route_name,' Midpoint')
       END,
       2,20
FROM routes;

INSERT IGNORE INTO route_stops (route_id,stop_name,stop_order,pickup_offset_minutes)
SELECT route_id,
       CASE route_code
           WHEN 'BRACU-R01' THEN 'Kazipara'
           WHEN 'BRACU-R02' THEN 'Farmgate'
           WHEN 'BRACU-R03' THEN 'Uttara'
           WHEN 'BRACU-R04' THEN 'Motijheel'
           WHEN 'BRACU-R05' THEN 'Taltola'
           WHEN 'NSU-R01' THEN 'Airport'
           WHEN 'AIUB-R01' THEN 'Banani'
           ELSE CONCAT(route_name,' Stop')
       END,
       3,40
FROM routes;

INSERT IGNORE INTO route_stops (route_id,stop_name,stop_order,pickup_offset_minutes)
SELECT route_id,end_location,4,60 FROM routes;

-- ---------------------------------------------------------------------------
-- Today: two schedules per active university.
-- Tomorrow: one schedule per active university.
-- Uses the first active route and first active bus for each university.
-- ---------------------------------------------------------------------------

INSERT INTO schedules (route_id,bus_id,schedule_date,departure_time,arrival_time,status)
SELECT r.route_id,b.bus_id,CURDATE(),'07:30:00','08:30:00','SCHEDULED'
FROM universities u
JOIN routes r ON r.route_id=(SELECT MIN(r2.route_id) FROM routes r2 WHERE r2.university_id=u.university_id AND r2.status='ACTIVE')
JOIN buses b ON b.bus_id=(SELECT MIN(b2.bus_id) FROM buses b2 WHERE b2.university_id=u.university_id AND b2.status='ACTIVE')
WHERE u.status='ACTIVE'
  AND NOT EXISTS (
      SELECT 1 FROM schedules s2 JOIN routes r3 ON r3.route_id=s2.route_id
      WHERE r3.university_id=u.university_id AND s2.schedule_date=CURDATE() AND s2.departure_time='07:30:00'
  );

INSERT INTO schedules (route_id,bus_id,schedule_date,departure_time,arrival_time,status)
SELECT r.route_id,b.bus_id,CURDATE(),'14:30:00','15:30:00','SCHEDULED'
FROM universities u
JOIN routes r ON r.route_id=(SELECT MIN(r2.route_id) FROM routes r2 WHERE r2.university_id=u.university_id AND r2.status='ACTIVE')
JOIN buses b ON b.bus_id=(SELECT MIN(b2.bus_id) FROM buses b2 WHERE b2.university_id=u.university_id AND b2.status='ACTIVE')
WHERE u.status='ACTIVE'
  AND NOT EXISTS (
      SELECT 1 FROM schedules s2 JOIN routes r3 ON r3.route_id=s2.route_id
      WHERE r3.university_id=u.university_id AND s2.schedule_date=CURDATE() AND s2.departure_time='14:30:00'
  );

INSERT INTO schedules (route_id,bus_id,schedule_date,departure_time,arrival_time,status)
SELECT r.route_id,b.bus_id,DATE_ADD(CURDATE(),INTERVAL 1 DAY),'08:00:00','09:00:00','SCHEDULED'
FROM universities u
JOIN routes r ON r.route_id=(SELECT MIN(r2.route_id) FROM routes r2 WHERE r2.university_id=u.university_id AND r2.status='ACTIVE')
JOIN buses b ON b.bus_id=(SELECT MIN(b2.bus_id) FROM buses b2 WHERE b2.university_id=u.university_id AND b2.status='ACTIVE')
WHERE u.status='ACTIVE'
  AND NOT EXISTS (
      SELECT 1 FROM schedules s2 JOIN routes r3 ON r3.route_id=s2.route_id
      WHERE r3.university_id=u.university_id
        AND s2.schedule_date=DATE_ADD(CURDATE(),INTERVAL 1 DAY)
        AND s2.departure_time='08:00:00'
  );

-- ---------------------------------------------------------------------------
-- Helper: seed a chosen current-day schedule with a target number of seats and
-- optional standing slots. It respects bus passenger type and creates the
-- supporting billing/history/notification rows expected by UniRide.
-- ---------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS `__uniride_seed_schedule_load`;
DELIMITER $$
CREATE PROCEDURE `__uniride_seed_schedule_load`(
    IN p_schedule_id INT,
    IN p_university_id INT,
    IN p_target_seats INT,
    IN p_target_standing INT
)
seed_block: BEGIN
    DECLARE v_i INT DEFAULT 1;
    DECLARE v_last_passenger INT DEFAULT 0;
    DECLARE v_passenger_id INT DEFAULT NULL;
    DECLARE v_booking_id INT DEFAULT NULL;
    DECLARE v_bus_type VARCHAR(30) DEFAULT NULL;
    DECLARE v_seat_capacity INT DEFAULT 0;
    DECLARE v_standing_capacity INT DEFAULT 0;
    DECLARE v_fare DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_existing INT DEFAULT 0;
    DECLARE v_booking_ref VARCHAR(20);

    IF p_schedule_id IS NULL THEN
        LEAVE seed_block;
    END IF;

    SELECT b.bus_type,b.seat_capacity,b.standing_capacity,r.fare
      INTO v_bus_type,v_seat_capacity,v_standing_capacity,v_fare
      FROM schedules s
      JOIN routes r ON r.route_id=s.route_id
      JOIN buses b ON b.bus_id=s.bus_id
     WHERE s.schedule_id=p_schedule_id
     LIMIT 1;

    SET p_target_seats = LEAST(p_target_seats,v_seat_capacity);
    SET p_target_standing = LEAST(p_target_standing,v_standing_capacity);

    seat_loop: WHILE v_i <= p_target_seats DO
        SELECT COUNT(*) INTO v_existing
        FROM bookings
        WHERE schedule_id=p_schedule_id
          AND slot_type='SEAT'
          AND seat_number=v_i
          AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING');

        IF v_existing = 0 THEN
            SET v_passenger_id = NULL;
            SELECT MIN(p.passenger_id) INTO v_passenger_id
            FROM passengers p
            WHERE p.university_id=p_university_id
              AND p.status='ACTIVE'
              AND p.passenger_id>v_last_passenger
              AND (
                  v_bus_type='STANDARD'
                  OR (v_bus_type='STUDENT_ONLY' AND p.passenger_type='STUDENT')
                  OR (v_bus_type='FACULTY_ONLY' AND p.passenger_type='FACULTY')
              )
              AND NOT EXISTS (
                  SELECT 1 FROM bookings bx
                  WHERE bx.schedule_id=p_schedule_id
                    AND bx.passenger_id=p.passenger_id
                    AND bx.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')
              );

            IF v_passenger_id IS NULL THEN
                LEAVE seat_loop;
            END IF;

            SET v_last_passenger=v_passenger_id;
            SET v_booking_ref=CONCAT('D-',UPPER(SUBSTRING(REPLACE(UUID(),'-',''),1,14)));

            INSERT INTO bookings (
                booking_reference,passenger_id,schedule_id,slot_type,seat_number,
                standing_slot,fare_charged,qr_token,status
            ) VALUES (
                v_booking_ref,v_passenger_id,p_schedule_id,'SEAT',v_i,
                NULL,v_fare,UUID(),'CONFIRMED'
            );
            SET v_booking_id=LAST_INSERT_ID();

            INSERT INTO booking_status_history (booking_id,old_status,new_status,changed_by)
            VALUES (v_booking_id,NULL,'CONFIRMED','DEMO_SEED');

            IF @ACTIVE_SEMESTER_ID IS NOT NULL THEN
                INSERT INTO semester_bills (passenger_id,semester_id,total_charges,total_credits,net_balance)
                VALUES (v_passenger_id,@ACTIVE_SEMESTER_ID,v_fare,0.00,v_fare)
                ON DUPLICATE KEY UPDATE
                    total_charges=total_charges+VALUES(total_charges),
                    net_balance=net_balance+VALUES(net_balance);

                INSERT INTO billing_transactions (
                    passenger_id,semester_id,booking_id,transaction_type,amount,description
                ) VALUES (
                    v_passenger_id,@ACTIVE_SEMESTER_ID,v_booking_id,
                    'BOOKING_CHARGE',v_fare,CONCAT('Dashboard demo booking ',v_booking_ref)
                );
            END IF;

            INSERT INTO notifications (passenger_id,title,message,notification_type,reference_id)
            VALUES (v_passenger_id,'Booking Confirmed',CONCAT('Your demo booking ',v_booking_ref,' is confirmed.'),'BOOKING',v_booking_id);
        END IF;

        SET v_i=v_i+1;
    END WHILE seat_loop;

    -- Standing is only seeded if all seats are occupied, matching UniRide rules.
    IF p_target_standing > 0 THEN
        SELECT COUNT(DISTINCT booking_id) INTO v_existing
        FROM bookings
        WHERE schedule_id=p_schedule_id
          AND slot_type='SEAT'
          AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING');

        IF v_existing >= v_seat_capacity THEN
            SET v_i=1;
            SET v_last_passenger=0;

            standing_loop: WHILE v_i <= p_target_standing DO
                SELECT COUNT(*) INTO v_existing
                FROM bookings
                WHERE schedule_id=p_schedule_id
                  AND slot_type='STANDING'
                  AND standing_slot=v_i
                  AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING');

                IF v_existing=0 THEN
                    SET v_passenger_id=NULL;
                    SELECT MIN(p.passenger_id) INTO v_passenger_id
                    FROM passengers p
                    WHERE p.university_id=p_university_id
                      AND p.status='ACTIVE'
                      AND p.passenger_id>v_last_passenger
                      AND (
                          v_bus_type='STANDARD'
                          OR (v_bus_type='STUDENT_ONLY' AND p.passenger_type='STUDENT')
                          OR (v_bus_type='FACULTY_ONLY' AND p.passenger_type='FACULTY')
                      )
                      AND NOT EXISTS (
                          SELECT 1 FROM bookings bx
                          WHERE bx.schedule_id=p_schedule_id
                            AND bx.passenger_id=p.passenger_id
                            AND bx.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')
                      );

                    IF v_passenger_id IS NULL THEN
                        LEAVE standing_loop;
                    END IF;

                    SET v_last_passenger=v_passenger_id;
                    SET v_booking_ref=CONCAT('D-',UPPER(SUBSTRING(REPLACE(UUID(),'-',''),1,14)));

                    INSERT INTO bookings (
                        booking_reference,passenger_id,schedule_id,slot_type,seat_number,
                        standing_slot,fare_charged,qr_token,status
                    ) VALUES (
                        v_booking_ref,v_passenger_id,p_schedule_id,'STANDING',NULL,
                        v_i,v_fare,UUID(),'CONFIRMED'
                    );
                    SET v_booking_id=LAST_INSERT_ID();

                    INSERT INTO booking_status_history (booking_id,old_status,new_status,changed_by)
                    VALUES (v_booking_id,NULL,'CONFIRMED','DEMO_SEED');

                    IF @ACTIVE_SEMESTER_ID IS NOT NULL THEN
                        INSERT INTO semester_bills (passenger_id,semester_id,total_charges,total_credits,net_balance)
                        VALUES (v_passenger_id,@ACTIVE_SEMESTER_ID,v_fare,0.00,v_fare)
                        ON DUPLICATE KEY UPDATE
                            total_charges=total_charges+VALUES(total_charges),
                            net_balance=net_balance+VALUES(net_balance);

                        INSERT INTO billing_transactions (
                            passenger_id,semester_id,booking_id,transaction_type,amount,description
                        ) VALUES (
                            v_passenger_id,@ACTIVE_SEMESTER_ID,v_booking_id,
                            'BOOKING_CHARGE',v_fare,CONCAT('Dashboard demo standing booking ',v_booking_ref)
                        );
                    END IF;

                    INSERT INTO notifications (passenger_id,title,message,notification_type,reference_id)
                    VALUES (v_passenger_id,'Booking Confirmed',CONCAT('Your demo booking ',v_booking_ref,' is confirmed.'),'BOOKING',v_booking_id);
                END IF;

                SET v_i=v_i+1;
            END WHILE standing_loop;
        END IF;
    END IF;
END$$
DELIMITER ;

SET @BRACU_AM := (SELECT s.schedule_id FROM schedules s JOIN routes r ON r.route_id=s.route_id JOIN universities u ON u.university_id=r.university_id WHERE u.code='BRACU' AND s.schedule_date=CURDATE() AND s.departure_time='07:30:00' ORDER BY s.schedule_id DESC LIMIT 1);
SET @BRACU_PM := (SELECT s.schedule_id FROM schedules s JOIN routes r ON r.route_id=s.route_id JOIN universities u ON u.university_id=r.university_id WHERE u.code='BRACU' AND s.schedule_date=CURDATE() AND s.departure_time='14:30:00' ORDER BY s.schedule_id DESC LIMIT 1);
SET @NSU_AM := (SELECT s.schedule_id FROM schedules s JOIN routes r ON r.route_id=s.route_id JOIN universities u ON u.university_id=r.university_id WHERE u.code='NSU' AND s.schedule_date=CURDATE() AND s.departure_time='07:30:00' ORDER BY s.schedule_id DESC LIMIT 1);
SET @NSU_PM := (SELECT s.schedule_id FROM schedules s JOIN routes r ON r.route_id=s.route_id JOIN universities u ON u.university_id=r.university_id WHERE u.code='NSU' AND s.schedule_date=CURDATE() AND s.departure_time='14:30:00' ORDER BY s.schedule_id DESC LIMIT 1);
SET @AIUB_AM := (SELECT s.schedule_id FROM schedules s JOIN routes r ON r.route_id=s.route_id JOIN universities u ON u.university_id=r.university_id WHERE u.code='AIUB' AND s.schedule_date=CURDATE() AND s.departure_time='07:30:00' ORDER BY s.schedule_id DESC LIMIT 1);
SET @AIUB_PM := (SELECT s.schedule_id FROM schedules s JOIN routes r ON r.route_id=s.route_id JOIN universities u ON u.university_id=r.university_id WHERE u.code='AIUB' AND s.schedule_date=CURDATE() AND s.departure_time='14:30:00' ORDER BY s.schedule_id DESC LIMIT 1);

CALL `__uniride_seed_schedule_load`(@BRACU_AM,1,12,0);
CALL `__uniride_seed_schedule_load`(@BRACU_PM,1,40,4);
CALL `__uniride_seed_schedule_load`(@NSU_AM,2,26,0);
CALL `__uniride_seed_schedule_load`(@NSU_PM,2,36,0);
CALL `__uniride_seed_schedule_load`(@AIUB_AM,3,16,0);
CALL `__uniride_seed_schedule_load`(@AIUB_PM,3,8,0);

DROP PROCEDURE `__uniride_seed_schedule_load`;

-- One open synthetic complaint per active university, if absent.
INSERT INTO complaints (passenger_id,university_id,subject,description,status,university_response)
SELECT
    (SELECT MIN(p.passenger_id) FROM passengers p WHERE p.university_id=u.university_id AND p.status='ACTIVE'),
    u.university_id,
    CONCAT('Demo: ',u.code,' morning service feedback'),
    'Synthetic dashboard demonstration complaint. Review and update this complaint from the University Admin dashboard.',
    'OPEN',NULL
FROM universities u
WHERE u.status='ACTIVE'
  AND NOT EXISTS (
      SELECT 1 FROM complaints c
      WHERE c.university_id=u.university_id
        AND c.subject=CONCAT('Demo: ',u.code,' morning service feedback')
  );

-- One pending NSU transfer, when an eligible booking and recipient exist.
SET @TRANSFER_BOOKING_ID := (
    SELECT bk.booking_id
    FROM bookings bk JOIN schedules s ON s.schedule_id=bk.schedule_id
    JOIN routes r ON r.route_id=s.route_id JOIN universities u ON u.university_id=r.university_id
    WHERE u.code='NSU' AND s.schedule_date=CURDATE() AND bk.status IN ('BOOKED','CONFIRMED')
    ORDER BY bk.booking_id LIMIT 1
);
SET @TRANSFER_FROM := (SELECT passenger_id FROM bookings WHERE booking_id=@TRANSFER_BOOKING_ID LIMIT 1);
SET @TRANSFER_SCHEDULE := (SELECT schedule_id FROM bookings WHERE booking_id=@TRANSFER_BOOKING_ID LIMIT 1);
SET @TRANSFER_TO := (
    SELECT MIN(p.passenger_id)
    FROM passengers p
    WHERE p.university_id=2 AND p.passenger_type='STUDENT' AND p.status='ACTIVE'
      AND p.passenger_id<>@TRANSFER_FROM
      AND NOT EXISTS (
          SELECT 1 FROM bookings bx
          WHERE bx.passenger_id=p.passenger_id AND bx.schedule_id=@TRANSFER_SCHEDULE
            AND bx.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')
      )
);

INSERT INTO ticket_transfers (booking_id,from_passenger_id,to_passenger_id,transfer_type,sale_amount,status)
SELECT @TRANSFER_BOOKING_ID,@TRANSFER_FROM,@TRANSFER_TO,'SHARE',NULL,'PENDING'
WHERE @TRANSFER_BOOKING_ID IS NOT NULL AND @TRANSFER_FROM IS NOT NULL AND @TRANSFER_TO IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM ticket_transfers WHERE booking_id=@TRANSFER_BOOKING_ID AND status='PENDING');

UPDATE bookings
SET status='TRANSFER_PENDING'
WHERE booking_id=@TRANSFER_BOOKING_ID
  AND EXISTS (SELECT 1 FROM ticket_transfers WHERE booking_id=@TRANSFER_BOOKING_ID AND status='PENDING');

INSERT INTO booking_status_history (booking_id,old_status,new_status,changed_by)
SELECT @TRANSFER_BOOKING_ID,'CONFIRMED','TRANSFER_PENDING','DEMO_SEED'
WHERE @TRANSFER_BOOKING_ID IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM booking_status_history
      WHERE booking_id=@TRANSFER_BOOKING_ID AND new_status='TRANSFER_PENDING' AND changed_by='DEMO_SEED'
  );

INSERT INTO notifications (passenger_id,title,message,notification_type,reference_id)
SELECT @TRANSFER_TO,'Ticket Transfer Request','A passenger wants to share a ticket with you.','TRANSFER',tt.transfer_id
FROM ticket_transfers tt
WHERE tt.booking_id=@TRANSFER_BOOKING_ID AND tt.status='PENDING' AND @TRANSFER_TO IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM notifications n
      WHERE n.passenger_id=@TRANSFER_TO AND n.notification_type='TRANSFER' AND n.reference_id=tt.transfer_id
  )
LIMIT 1;

SELECT 'Optional UniRide dashboard demo seed completed.' AS message,
       CURDATE() AS demo_date,
       DATABASE() AS active_database;
