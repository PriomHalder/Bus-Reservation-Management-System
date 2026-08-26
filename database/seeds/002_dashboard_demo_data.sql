-- =====================================================================
-- UniRide — seed 002: optional dashboard demo data
-- =====================================================================
-- Target database : uniride2
-- Run in          : phpMyAdmin -> uniride2 -> SQL tab
--
-- RUN ORDER
-- ---------
--   ../migrations/000_repair_existing_keys.sql
--   ../migrations/001_add_missing_dashboard_tables.sql
--   002_dashboard_demo_data.sql              <- this file, LAST
--
-- THIS FILE IS OPTIONAL AND IS NOT A DEPENDENCY
-- ---------------------------------------------
-- The dashboards are correct with every one of these tables empty — they
-- render empty states, not errors. This file exists only so there is
-- something to look at while marking or demonstrating the project. You can
-- run the two migrations and never run this, and nothing breaks.
--
-- WHAT IT DOES NOT DO
-- -------------------
--   * It never modifies or deletes a row that shipped in uniride2.sql.
--   * It never touches the seven historical schedules dated 2026-08-20.
--     Those are left exactly as they are, and are used as-is to give
--     passengers a genuine past-trip history.
--   * It creates no universities, passengers, students, faculty, routes or
--     admin accounts. It books the people and routes that already exist.
--
-- HOW IT STAYS SAFE TO RE-RUN
-- ---------------------------
-- Every row it creates is marked, and section 0 removes only marked rows:
--   bookings              booking_reference LIKE 'DEMO-%'
--   billing_transactions  joined to a DEMO- booking, or description
--                         starting 'DEMO '
--   schedules / buses /
--   bus_route_assignments / notifications / complaints
--                         id >= 9000
--   booking_status_history
--   ticket_transfers      removed automatically by ON DELETE CASCADE when
--                         the DEMO- bookings go
--   favorite_routes       INSERT IGNORE against uq_favorite
--   route_stops           INSERT IGNORE against uq_route_stop_order
--   semester_bills        recomputed from the ledger, never incremented
--
-- Nothing that shipped in uniride2.sql carries an id at or above 9000 or a
-- DEMO- reference, so section 0 cannot reach your real data.
--
-- DATES ARE RELATIVE
-- ------------------
-- Every date is CURDATE() or DATE_ADD(CURDATE(), INTERVAL n DAY), so the
-- demo is always "today and the next three days" whenever you run it.
-- Nothing here goes stale the way 2026-08-20 did.
--
-- REQUIRES: MariaDB 10.2+ / MySQL 8+ (window functions). XAMPP is fine.
-- =====================================================================

USE `uniride2`;

SET NAMES utf8mb4;


-- =====================================================================
-- 0. Remove data from any previous run of this file
-- =====================================================================
-- Child rows first, so the foreign keys added by migration 000/001 are
-- satisfied at every step.
--
-- The two DELETEs on 'BKG-SEED%' and the bus/schedule id ranges 7-24 clear
-- up after an earlier draft of this seed (database/phase1_seed_demo.sql,
-- now retired to a stub). They are no-ops unless you ran that draft.
-- =====================================================================

DELETE `bt` FROM `billing_transactions` `bt`
  JOIN `bookings` `b` ON `b`.`booking_id` = `bt`.`booking_id`
 WHERE `b`.`booking_reference` LIKE 'DEMO-%'
    OR `b`.`booking_reference` LIKE 'BKG-SEED%';

DELETE FROM `billing_transactions`
 WHERE `description` LIKE 'DEMO %';

-- booking_status_history and ticket_transfers both cascade from bookings.
DELETE FROM `bookings`
 WHERE `booking_reference` LIKE 'DEMO-%'
    OR `booking_reference` LIKE 'BKG-SEED%';

DELETE FROM `notifications`      WHERE `notification_id` >= 9000;
DELETE FROM `complaints`         WHERE `complaint_id`    >= 9000;
DELETE FROM `schedules`          WHERE `schedule_id`     >= 9000;
DELETE FROM `bus_route_assignments` WHERE `assignment_id` >= 9000;
DELETE FROM `buses`              WHERE `bus_id`          >= 9000;

-- Superseded draft used ids 7-24 for its own schedules/buses.
DELETE FROM `schedules`             WHERE `schedule_id`   BETWEEN 8 AND 24;
DELETE FROM `bus_route_assignments` WHERE `assignment_id` BETWEEN 7 AND 8;
DELETE FROM `buses`                 WHERE `bus_id`        BETWEEN 7 AND 8;


-- =====================================================================
-- 1. Helper tables
-- =====================================================================
-- _seed_seq is a plain 1..60 counter. It turns "fill 36 seats" into one
-- INSERT ... SELECT instead of 36 hand-typed rows, which is why this file
-- can seed ~250 bookings without becoming unreadable.
--
-- _seed_plan is the whole demo expressed as data: one row per block of
-- seats to sell. Read it and you know exactly what the dashboards will
-- show. Both tables are dropped again in section 9.
-- =====================================================================

DROP TABLE IF EXISTS `_seed_seq`;
CREATE TABLE `_seed_seq` (
    `n` INT NOT NULL,
    PRIMARY KEY (`n`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `_seed_seq` (`n`)
SELECT `t`.`n` FROM (
    SELECT `a`.`d` + `b`.`d` * 10 + 1 AS `n`
      FROM (SELECT 0 AS `d` UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
            UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
            UNION ALL SELECT 8 UNION ALL SELECT 9) `a`
     CROSS JOIN
           (SELECT 0 AS `d` UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
            UNION ALL SELECT 4 UNION ALL SELECT 5) `b`
) `t`;


DROP TABLE IF EXISTS `_seed_plan`;
CREATE TABLE `_seed_plan` (
    `plan_id`          INT          NOT NULL AUTO_INCREMENT,
    `schedule_id`      INT          NOT NULL,
    `university_id`    INT          NOT NULL,
    `passenger_type`   VARCHAR(10)  NOT NULL COMMENT 'Must match the bus_type rule: STUDENT on STUDENT_ONLY/STANDARD, FACULTY on FACULTY_ONLY/STANDARD',
    `seat_from`        INT          NOT NULL DEFAULT 1,
    `seat_to`          INT          NOT NULL DEFAULT 0 COMMENT '0 means no seat bookings for this block',
    `stand_from`       INT          NOT NULL DEFAULT 1,
    `stand_to`         INT          NOT NULL DEFAULT 0,
    `booking_status`   VARCHAR(20)  NOT NULL DEFAULT 'CONFIRMED',
    `passenger_offset` INT          NOT NULL DEFAULT 0 COMMENT 'Shifts which passengers get picked, so trips do not all carry the same faces',
    `days_ago`         INT          NOT NULL DEFAULT 1 COMMENT 'How long ago the booking was made',
    PRIMARY KEY (`plan_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =====================================================================
-- 2. Two STANDARD buses, one for NSU and one for AIUB
-- =====================================================================
-- Every bus that ships is STUDENT_ONLY except bus 3 (FACULTY_ONLY, BRACU).
-- So NSU and AIUB faculty have nothing they are allowed to board:
-- sp_create_booking rejects a FACULTY passenger on a STUDENT_ONLY bus, and
-- the passenger dashboard filters the schedule list by the same rule. A
-- faculty login at those two universities therefore shows an empty trip
-- list — correct behaviour that looks like a bug.
--
-- A STANDARD bus is open to both passenger types, which fixes that and
-- exercises the third value of the bus_type enum.
--
-- Bus 9002 is deliberately 45 seats and 12 standing rather than the usual
-- 40/10. It proves the dashboards read capacity from the bus row instead
-- of assuming 40 (spec section 17).
-- =====================================================================

INSERT INTO `buses`
    (`bus_id`, `university_id`, `registration_number`, `tax_number`,
     `seat_capacity`, `standing_capacity`, `bus_type`, `status`, `created_at`)
VALUES
    (9001, 2, 'DHA-2201', NULL, 40, 10, 'STANDARD', 'ACTIVE', NOW()),
    (9002, 3, 'DHA-3301', NULL, 45, 12, 'STANDARD', 'ACTIVE', NOW());

INSERT INTO `bus_route_assignments` (`assignment_id`, `bus_id`, `route_id`, `created_at`)
VALUES
    (9001, 9001, 6, NOW()),   -- NSU  STANDARD bus -> NSU-R01
    (9002, 9002, 7, NOW());   -- AIUB STANDARD bus -> AIUB-R01


-- =====================================================================
-- 3. Upcoming schedules
-- =====================================================================
-- The seven shipped schedules stay on 2026-08-20, untouched. These are new
-- rows at id 9000+, covering today through today + 3.
--
-- Both morning and evening departures are included on purpose. Every
-- shipped schedule departs between 17:00 and 19:30, so if you happen to
-- open the dashboard after 8pm nothing qualifies as "upcoming" and the
-- next-trip card empties out for the wrong reason. Morning trips on future
-- dates mean there is always a next trip regardless of the clock.
--
-- Bus 4 (DHA-3456) is never scheduled: it is in MAINTENANCE, and putting a
-- bus under repair into service would contradict the fleet panel.
-- =====================================================================

INSERT INTO `schedules`
    (`schedule_id`, `route_id`, `bus_id`, `schedule_date`, `departure_time`, `arrival_time`, `status`, `created_at`)
VALUES
    -- ---- BRACU, today: the four occupancy tiers ----
    (9001, 1, 1, CURDATE(),                              '07:30:00', '09:00:00', 'SCHEDULED', NOW()),
    (9002, 2, 2, CURDATE(),                              '08:00:00', '09:10:00', 'SCHEDULED', NOW()),
    (9003, 3, 1, CURDATE(),                              '13:30:00', '14:30:00', 'SCHEDULED', NOW()),
    (9004, 1, 2, CURDATE(),                              '17:20:00', '18:50:00', 'SCHEDULED', NOW()),
    (9005, 4, 3, CURDATE(),                              '07:40:00', '09:05:00', 'SCHEDULED', NOW()),

    -- ---- BRACU, tomorrow ----
    (9006, 1, 1, DATE_ADD(CURDATE(), INTERVAL 1 DAY),    '07:30:00', '09:00:00', 'SCHEDULED', NOW()),
    (9007, 2, 2, DATE_ADD(CURDATE(), INTERVAL 1 DAY),    '08:00:00', '09:10:00', 'SCHEDULED', NOW()),
    (9008, 4, 3, DATE_ADD(CURDATE(), INTERVAL 1 DAY),    '07:40:00', '09:05:00', 'SCHEDULED', NOW()),

    -- ---- BRACU, in two days ----
    (9009, 1, 1, DATE_ADD(CURDATE(), INTERVAL 2 DAY),    '07:30:00', '09:00:00', 'SCHEDULED', NOW()),
    (9010, 3, 2, DATE_ADD(CURDATE(), INTERVAL 2 DAY),    '17:20:00', '18:20:00', 'SCHEDULED', NOW()),

    -- ---- BRACU, in three days ----
    (9011, 1, 1, DATE_ADD(CURDATE(), INTERVAL 3 DAY),    '07:30:00', '09:00:00', 'SCHEDULED', NOW()),
    -- Cancelled on purpose, so the admin attention banner and the
    -- CANCELLED badge both have something real to report.
    (9012, 5, 2, DATE_ADD(CURDATE(), INTERVAL 3 DAY),    '19:30:00', '20:40:00', 'CANCELLED', NOW()),

    -- ---- NSU ----
    (9020, 6, 5,    CURDATE(),                           '07:30:00', '08:30:00', 'SCHEDULED', NOW()),
    (9021, 6, 5,    DATE_ADD(CURDATE(), INTERVAL 1 DAY), '07:30:00', '08:30:00', 'SCHEDULED', NOW()),
    (9022, 6, 5,    DATE_ADD(CURDATE(), INTERVAL 2 DAY), '07:30:00', '08:30:00', 'SCHEDULED', NOW()),
    (9023, 6, 9001, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '08:00:00', '09:00:00', 'SCHEDULED', NOW()),

    -- ---- AIUB ----
    (9030, 7, 6,    CURDATE(),                           '07:15:00', '08:15:00', 'SCHEDULED', NOW()),
    (9031, 7, 6,    DATE_ADD(CURDATE(), INTERVAL 1 DAY), '07:15:00', '08:15:00', 'SCHEDULED', NOW()),
    (9032, 7, 6,    DATE_ADD(CURDATE(), INTERVAL 2 DAY), '07:15:00', '08:15:00', 'SCHEDULED', NOW()),
    (9033, 7, 9002, DATE_ADD(CURDATE(), INTERVAL 1 DAY), '08:10:00', '09:10:00', 'SCHEDULED', NOW());


-- =====================================================================
-- 4. The booking plan
-- =====================================================================
-- Occupancy is written as seat ranges rather than percentages so it stays
-- honest: the dashboards divide seats sold by the capacity on the bus row,
-- and these numbers are what that division will produce.
--
-- Buses 1, 2, 5 and 6 carry 40 seats; bus 9002 carries 45.
--
--   Tier A  schedule 9001   10 / 40  =  25%
--   Tier B  schedule 9002   26 / 40  =  65%
--   Tier C  schedule 9003   36 / 40  =  90%
--   Tier D  schedule 9004   40 / 40  = 100% seated, plus 6 of 10 standing
--
-- Standing slots appear only on 9004, and only because its seats are
-- completely sold. That mirrors sp_create_booking, which refuses to open
-- standing room until every seat on the trip is gone — seeding standing
-- passengers on a half-empty bus would put data in the database that the
-- application's own rules could never have produced.
--
-- passenger_type must match the bus. Students ride STUDENT_ONLY and
-- STANDARD buses; faculty ride FACULTY_ONLY and STANDARD. This is the same
-- check sp_create_booking performs, so every row below would also be
-- accepted through the real booking flow.
--
-- BRACU has 54 active students and 2 faculty, NSU 51 students and 1
-- faculty, AIUB 51 students and 1 faculty (after migration 000 removes the
-- duplicated rows), so the seat counts below always find enough people.
-- =====================================================================

INSERT INTO `_seed_plan`
    (`schedule_id`, `university_id`, `passenger_type`,
     `seat_from`, `seat_to`, `stand_from`, `stand_to`,
     `booking_status`, `passenger_offset`, `days_ago`)
VALUES
    -- ---------- BRACU today: the four occupancy tiers ----------
    (9001, 1, 'STUDENT',  1, 10, 1, 0, 'CONFIRMED',  0, 3),
    (9002, 1, 'STUDENT',  1, 26, 1, 0, 'CONFIRMED',  0, 3),
    (9003, 1, 'STUDENT',  1, 36, 1, 0, 'CONFIRMED',  6, 2),
    (9004, 1, 'STUDENT',  1, 40, 1, 6, 'CONFIRMED',  0, 2),
    -- BRACU faculty shuttle. Only 2 faculty exist, so 2 seats is a full
    -- honest load rather than an artificially padded one.
    (9005, 1, 'FACULTY',  1,  2, 1, 0, 'CONFIRMED',  0, 2),

    -- ---------- BRACU tomorrow: the "upcoming trip" cards ----------
    (9006, 1, 'STUDENT',  1, 12, 1, 0, 'CONFIRMED',  0, 1),
    (9007, 1, 'STUDENT',  1, 24, 1, 0, 'BOOKED',     0, 1),
    (9008, 1, 'FACULTY',  1,  2, 1, 0, 'CONFIRMED',  0, 1),

    -- ---------- BRACU + 2 ----------
    (9009, 1, 'STUDENT',  1,  8, 1, 0, 'BOOKED',     0, 0),
    -- Offset 12 keeps passengers 1 and 2 off this trip, so the ticket
    -- transfers in section 7 can hand them a seat they do not already own.
    (9010, 1, 'STUDENT',  1, 18, 1, 0, 'BOOKED',    12, 0),

    -- ---------- BRACU + 3 ----------
    (9011, 1, 'STUDENT',  1,  5, 1, 0, 'BOOKED',     0, 0),

    -- ---------- Past trips: booking history ----------
    -- These attach to the shipped schedules dated 2026-08-20. The
    -- schedules themselves are not modified in any way; only new bookings
    -- point at them.
    (   1, 1, 'STUDENT',  1,  6, 1, 0, 'COMPLETED',  0, 6),
    (   3, 1, 'STUDENT',  1,  4, 1, 0, 'COMPLETED',  0, 7),
    -- Three cancellations, at seats well clear of the completed block
    -- above, so the cancellation credits in section 6 have a real cause.
    (   1, 1, 'STUDENT', 30, 32, 1, 0, 'CANCELLED',  0, 6),

    -- ---------- NSU ----------
    (9020, 2, 'STUDENT',  1, 26, 1, 0, 'CONFIRMED',  0, 2),
    (9021, 2, 'STUDENT',  1, 12, 1, 0, 'BOOKED',     0, 1),
    (9022, 2, 'STUDENT',  1,  6, 1, 0, 'BOOKED',     4, 0),
    (9023, 2, 'FACULTY',  1,  1, 1, 0, 'CONFIRMED',  0, 1),
    (   6, 2, 'STUDENT',  1,  5, 1, 0, 'COMPLETED',  0, 6),

    -- ---------- AIUB ----------
    (9030, 3, 'STUDENT',  1, 36, 1, 0, 'CONFIRMED',  0, 2),
    (9031, 3, 'STUDENT',  1, 16, 1, 0, 'BOOKED',     0, 1),
    (9032, 3, 'STUDENT',  1,  9, 1, 0, 'BOOKED',     4, 0),
    (9033, 3, 'FACULTY',  1,  1, 1, 0, 'CONFIRMED',  0, 1),
    (   7, 3, 'STUDENT',  1,  5, 1, 0, 'COMPLETED',  0, 6);


-- =====================================================================
-- 5. Bookings
-- =====================================================================
-- Two statements: seated passengers, then standing passengers.
--
-- fare_charged is read from the route rather than typed, so it can never
-- disagree with what the route actually costs.
--
-- Seat numbers are plain integers. fn_seat_label() in the database and
-- seat_label() in includes/dashboard_helpers.php both map them to A1..J4
-- across ten rows of four, so seat 1 is A1, seat 5 is B1 and seat 12 is C4.
--
-- Every seat number is distinct within its schedule, which matters because
-- trg_chk_dup_booking_ins rejects a second active booking on an occupied
-- seat. A careless seed would abort halfway through.
-- =====================================================================

INSERT INTO `bookings`
    (`booking_reference`, `passenger_id`, `schedule_id`, `slot_type`,
     `seat_number`, `standing_slot`, `fare_charged`, `qr_token`,
     `status`, `booking_date`, `created_at`)
SELECT
    CONCAT('DEMO-', `p`.`schedule_id`, '-S', LPAD(`q`.`n`, 2, '0')),
    `elig`.`passenger_id`,
    `p`.`schedule_id`,
    'SEAT',
    `q`.`n`,
    NULL,
    `r`.`fare`,
    CONCAT('demo-', `p`.`schedule_id`, '-s', `q`.`n`, '-', UNIX_TIMESTAMP()),
    `p`.`booking_status`,
    NOW() - INTERVAL `p`.`days_ago` DAY,
    NOW() - INTERVAL `p`.`days_ago` DAY
FROM `_seed_plan` `p`
JOIN `schedules` `s`  ON `s`.`schedule_id` = `p`.`schedule_id`
JOIN `routes`    `r`  ON `r`.`route_id`    = `s`.`route_id`
JOIN `_seed_seq` `q`  ON `q`.`n` BETWEEN `p`.`seat_from` AND `p`.`seat_to`
JOIN (
    -- Rank the eligible people once per university and passenger type, so
    -- seat 1 goes to the first of them, seat 2 to the second, and so on.
    SELECT `pa`.`passenger_id`,
           `pa`.`university_id`,
           `pa`.`passenger_type`,
           ROW_NUMBER() OVER (PARTITION BY `pa`.`university_id`, `pa`.`passenger_type`
                              ORDER BY `pa`.`passenger_id`) AS `rn`
      FROM `passengers` `pa`
     WHERE `pa`.`status` = 'ACTIVE'
) `elig`
  ON `elig`.`university_id`  = `p`.`university_id`
 AND `elig`.`passenger_type` = `p`.`passenger_type`
 AND `elig`.`rn`             = `q`.`n` - `p`.`seat_from` + 1 + `p`.`passenger_offset`
WHERE `p`.`seat_to` >= `p`.`seat_from`;


INSERT INTO `bookings`
    (`booking_reference`, `passenger_id`, `schedule_id`, `slot_type`,
     `seat_number`, `standing_slot`, `fare_charged`, `qr_token`,
     `status`, `booking_date`, `created_at`)
SELECT
    CONCAT('DEMO-', `p`.`schedule_id`, '-T', LPAD(`q`.`n`, 2, '0')),
    `elig`.`passenger_id`,
    `p`.`schedule_id`,
    'STANDING',
    NULL,
    `q`.`n`,
    `r`.`fare`,
    CONCAT('demo-', `p`.`schedule_id`, '-t', `q`.`n`, '-', UNIX_TIMESTAMP()),
    `p`.`booking_status`,
    NOW() - INTERVAL `p`.`days_ago` DAY,
    NOW() - INTERVAL `p`.`days_ago` DAY
FROM `_seed_plan` `p`
JOIN `schedules` `s`  ON `s`.`schedule_id` = `p`.`schedule_id`
JOIN `routes`    `r`  ON `r`.`route_id`    = `s`.`route_id`
JOIN `_seed_seq` `q`  ON `q`.`n` BETWEEN `p`.`stand_from` AND `p`.`stand_to`
JOIN (
    SELECT `pa`.`passenger_id`,
           `pa`.`university_id`,
           `pa`.`passenger_type`,
           ROW_NUMBER() OVER (PARTITION BY `pa`.`university_id`, `pa`.`passenger_type`
                              ORDER BY `pa`.`passenger_id`) AS `rn`
      FROM `passengers` `pa`
     WHERE `pa`.`status` = 'ACTIVE'
) `elig`
  ON `elig`.`university_id`  = `p`.`university_id`
 AND `elig`.`passenger_type` = `p`.`passenger_type`
 -- Standing passengers are picked from further down the roster, so they
 -- are not the same people already holding a seat on the same trip.
 AND `elig`.`rn`             = `q`.`n` + 40
WHERE `p`.`stand_to` >= `p`.`stand_from`;


-- =====================================================================
-- 6. Booking status history
-- =====================================================================
-- What sp_create_booking and sp_cancel_booking would have written had
-- these bookings been made through the application: every booking starts
-- BOOKED, and anything past that records the step it took.
-- =====================================================================

INSERT INTO `booking_status_history` (`booking_id`, `old_status`, `new_status`, `changed_by`, `note`, `changed_at`)
SELECT `booking_id`, NULL, 'BOOKED', 'SYSTEM', 'Demo seed', `booking_date`
  FROM `bookings`
 WHERE `booking_reference` LIKE 'DEMO-%';

INSERT INTO `booking_status_history` (`booking_id`, `old_status`, `new_status`, `changed_by`, `note`, `changed_at`)
SELECT `booking_id`, 'BOOKED', 'CONFIRMED', 'SYSTEM', 'Demo seed', `booking_date` + INTERVAL 10 MINUTE
  FROM `bookings`
 WHERE `booking_reference` LIKE 'DEMO-%' AND `status` IN ('CONFIRMED', 'COMPLETED');

INSERT INTO `booking_status_history` (`booking_id`, `old_status`, `new_status`, `changed_by`, `note`, `changed_at`)
SELECT `booking_id`, 'CONFIRMED', 'COMPLETED', 'SYSTEM', 'Demo seed', `booking_date` + INTERVAL 1 DAY
  FROM `bookings`
 WHERE `booking_reference` LIKE 'DEMO-%' AND `status` = 'COMPLETED';

INSERT INTO `booking_status_history` (`booking_id`, `old_status`, `new_status`, `changed_by`, `note`, `changed_at`)
SELECT `booking_id`, 'BOOKED', 'CANCELLED', 'PASSENGER', 'Demo seed', `booking_date` + INTERVAL 2 HOUR
  FROM `bookings`
 WHERE `booking_reference` LIKE 'DEMO-%' AND `status` = 'CANCELLED';


-- =====================================================================
-- 7. Ticket transfers
-- =====================================================================
-- sp_request_ticket_transfer only permits a transfer between two
-- passengers of the same university AND the same passenger type, so both
-- of these are one BRACU student handing a ticket to another.
--
-- Both target seats on schedule 9010, which was seeded with
-- passenger_offset 12 precisely so that passengers 1 and 2 are not already
-- travelling on it. Passengers 1 and 2 are the first two BRACU students in
-- the shipped data (Samiha Tasnim and Samir Hossain).
--
-- The sender is read from the booking rather than assumed, so these rows
-- stay correct even if the roster changes.
-- =====================================================================

-- A PENDING request, so passenger 1 has an offer waiting on their
-- dashboard and the university admin sees a seat held mid-handover.
INSERT INTO `ticket_transfers`
    (`booking_id`, `from_passenger_id`, `to_passenger_id`, `transfer_type`,
     `sale_amount`, `status`, `message`, `requested_at`, `responded_at`)
SELECT `b`.`booking_id`, `b`.`passenger_id`, 1, 'SELL',
       `b`.`fare_charged`, 'PENDING',
       'Cannot travel that evening — happy to pass the seat on.',
       NOW() - INTERVAL 40 MINUTE, NULL
  FROM `bookings` `b`
 WHERE `b`.`booking_reference` = 'DEMO-9010-S05';

-- TRANSFER_PENDING is how the status enum represents a ticket awaiting
-- handover. The seat still counts against occupancy while the offer is
-- open, which is correct — it has not been released.
UPDATE `bookings`
   SET `status` = 'TRANSFER_PENDING'
 WHERE `booking_reference` = 'DEMO-9010-S05';

-- A COMPLETED transfer, so the same panel shows a finished handover too.
-- On acceptance sp_respond_ticket_transfer moves the booking to the
-- recipient, which is why the UPDATE below changes passenger_id.
INSERT INTO `ticket_transfers`
    (`booking_id`, `from_passenger_id`, `to_passenger_id`, `transfer_type`,
     `sale_amount`, `status`, `message`, `requested_at`, `responded_at`)
SELECT `b`.`booking_id`, `b`.`passenger_id`, 2, 'GIFT',
       NULL, 'COMPLETED', 'All yours.',
       NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 2 DAY + INTERVAL 25 MINUTE
  FROM `bookings` `b`
 WHERE `b`.`booking_reference` = 'DEMO-9010-S06';

UPDATE `bookings`
   SET `passenger_id` = 2
 WHERE `booking_reference` = 'DEMO-9010-S06';

INSERT INTO `booking_status_history` (`booking_id`, `old_status`, `new_status`, `changed_by`, `note`, `changed_at`)
SELECT `booking_id`, 'BOOKED', 'TRANSFER_PENDING', 'SYSTEM', 'Demo seed — transfer requested', NOW() - INTERVAL 2 DAY
  FROM `bookings` WHERE `booking_reference` = 'DEMO-9010-S06';

INSERT INTO `booking_status_history` (`booking_id`, `old_status`, `new_status`, `changed_by`, `note`, `changed_at`)
SELECT `booking_id`, 'TRANSFER_PENDING', 'BOOKED', 'SYSTEM', 'Demo seed — transfer accepted', NOW() - INTERVAL 2 DAY + INTERVAL 25 MINUTE
  FROM `bookings` WHERE `booking_reference` = 'DEMO-9010-S06';


-- =====================================================================
-- 8. Billing
-- =====================================================================
-- Derived from the bookings themselves rather than hand-typed, so the
-- ledger can never drift out of step with section 5.
--
-- A cancellation is written as a negative CANCELLATION_CREDIT, which is
-- the sign convention sp_cancel_booking uses.
--
-- Everything joins to the active semester. If no semester has is_active = 1
-- these statements insert zero rows rather than failing, and the billing
-- panel falls back to its empty state.
-- =====================================================================

INSERT INTO `billing_transactions`
    (`passenger_id`, `semester_id`, `booking_id`, `transaction_type`, `amount`, `description`, `transaction_date`)
SELECT `bk`.`passenger_id`,
       `sem`.`semester_id`,
       `bk`.`booking_id`,
       'BOOKING_CHARGE',
       `bk`.`fare_charged`,
       CONCAT('DEMO Charge for booking ', `bk`.`booking_reference`, ' on ', `r`.`route_code`),
       `bk`.`booking_date`
  FROM `bookings`  `bk`
  JOIN `schedules` `s`   ON `s`.`schedule_id` = `bk`.`schedule_id`
  JOIN `routes`    `r`   ON `r`.`route_id`    = `s`.`route_id`
  JOIN `semesters` `sem` ON `sem`.`is_active` = 1
 WHERE `bk`.`booking_reference` LIKE 'DEMO-%';

INSERT INTO `billing_transactions`
    (`passenger_id`, `semester_id`, `booking_id`, `transaction_type`, `amount`, `description`, `transaction_date`)
SELECT `bk`.`passenger_id`,
       `sem`.`semester_id`,
       `bk`.`booking_id`,
       'CANCELLATION_CREDIT',
       -`bk`.`fare_charged`,
       CONCAT('DEMO Credit for cancelled booking ', `bk`.`booking_reference`),
       `bk`.`booking_date` + INTERVAL 2 HOUR
  FROM `bookings`  `bk`
  JOIN `semesters` `sem` ON `sem`.`is_active` = 1
 WHERE `bk`.`booking_reference` LIKE 'DEMO-%'
   AND `bk`.`status` = 'CANCELLED';

-- The sold transfer moves money: the buyer is charged, the seller credited.
INSERT INTO `billing_transactions`
    (`passenger_id`, `semester_id`, `booking_id`, `transaction_type`, `amount`, `description`, `transaction_date`)
SELECT `t`.`to_passenger_id`, `sem`.`semester_id`, `t`.`booking_id`,
       'TRANSFER_CHARGE', `t`.`sale_amount`,
       'DEMO Purchased ticket transfer', `t`.`requested_at`
  FROM `ticket_transfers` `t`
  JOIN `semesters` `sem` ON `sem`.`is_active` = 1
 WHERE `t`.`transfer_type` = 'SELL'
   AND `t`.`status` = 'COMPLETED'
   AND `t`.`sale_amount` IS NOT NULL;

INSERT INTO `billing_transactions`
    (`passenger_id`, `semester_id`, `booking_id`, `transaction_type`, `amount`, `description`, `transaction_date`)
SELECT `t`.`from_passenger_id`, `sem`.`semester_id`, `t`.`booking_id`,
       'TRANSFER_CREDIT', -`t`.`sale_amount`,
       'DEMO Sold ticket transfer', `t`.`requested_at`
  FROM `ticket_transfers` `t`
  JOIN `semesters` `sem` ON `sem`.`is_active` = 1
 WHERE `t`.`transfer_type` = 'SELL'
   AND `t`.`status` = 'COMPLETED'
   AND `t`.`sale_amount` IS NOT NULL;


-- Roll the ledger up into one bill per passenger per semester.
--
-- ON DUPLICATE KEY UPDATE here *recomputes* rather than increments, so
-- running this file twice cannot double a bill. The bill is always exactly
-- the sum of the transactions behind it, which is what a bill should be.
-- university_id is left out of the column list on purpose:
-- trg_semester_bills_set_university fills it from the passenger.
INSERT INTO `semester_bills`
    (`passenger_id`, `semester_id`, `total_charges`, `total_credits`, `net_balance`, `status`)
SELECT `passenger_id`,
       `semester_id`,
       COALESCE(SUM(CASE WHEN `amount` > 0 THEN  `amount` ELSE 0 END), 0),
       COALESCE(SUM(CASE WHEN `amount` < 0 THEN -`amount` ELSE 0 END), 0),
       COALESCE(SUM(`amount`), 0),
       'OPEN'
  FROM `billing_transactions`
 GROUP BY `passenger_id`, `semester_id`
    ON DUPLICATE KEY UPDATE
       `total_charges` = VALUES(`total_charges`),
       `total_credits` = VALUES(`total_credits`),
       `net_balance`   = VALUES(`net_balance`);


-- =====================================================================
-- 9. Favourite routes
-- =====================================================================
-- INSERT IGNORE against uq_favorite (passenger_id, route_id), so this is
-- naturally idempotent and needs no cleanup in section 0.
--
-- Every passenger favourites a route their own university actually
-- operates: routes 1-5 are BRACU, 6 is NSU, 7 is AIUB.
-- =====================================================================

INSERT IGNORE INTO `favorite_routes` (`passenger_id`, `route_id`, `created_at`)
VALUES
    ( 1, 1, NOW() - INTERVAL 12 DAY),
    ( 1, 3, NOW() - INTERVAL  9 DAY),
    ( 1, 5, NOW() - INTERVAL  3 DAY),
    ( 2, 1, NOW() - INTERVAL  8 DAY),
    ( 2, 2, NOW() - INTERVAL  6 DAY),
    ( 3, 1, NOW() - INTERVAL  5 DAY),
    ( 4, 2, NOW() - INTERVAL  5 DAY),
    ( 5, 4, NOW() - INTERVAL 10 DAY),
    ( 6, 4, NOW() - INTERVAL  4 DAY),
    ( 7, 6, NOW() - INTERVAL  7 DAY),
    ( 8, 6, NOW() - INTERVAL  6 DAY),
    ( 9, 7, NOW() - INTERVAL  7 DAY),
    (10, 7, NOW() - INTERVAL  2 DAY);


-- =====================================================================
-- 10. Notifications
-- =====================================================================
-- A mix of read and unread, so both the sidebar count and the unread
-- styling have something to show. notification_type and reference_id
-- follow the convention already used by trg_complaint_response_notification.
-- =====================================================================

INSERT INTO `notifications`
    (`notification_id`, `passenger_id`, `title`, `message`, `notification_type`, `reference_id`, `is_read`, `read_at`, `created_at`)
VALUES
    (9001,  1, 'Booking confirmed',
            'Your seat A1 on BRACU-R01 is confirmed for tomorrow at 7:30 AM.',
            'BOOKING', NULL, 0, NULL, NOW() - INTERVAL 2 HOUR),
    (9002,  1, 'Ticket offered to you',
            'A classmate has offered you their seat on the BRACU-R03 evening trip.',
            'TRANSFER', NULL, 0, NULL, NOW() - INTERVAL 40 MINUTE),
    (9003,  1, 'Cancellation credit applied',
            'A credit has been applied to your transport bill for this semester.',
            'BILLING', NULL, 0, NULL, NOW() - INTERVAL 1 DAY),
    (9004,  1, 'Trip completed',
            'Thanks for travelling on BRACU-R01. Your trip is now marked complete.',
            'BOOKING', NULL, 1, NOW() - INTERVAL 3 DAY, NOW() - INTERVAL 4 DAY),
    (9005,  1, 'Welcome to UniRide',
            'Your BRAC University transport account is active. Book your first trip from the dashboard.',
            'GENERAL', NULL, 1, NOW() - INTERVAL 10 DAY, NOW() - INTERVAL 11 DAY),

    (9006,  2, 'Ticket transfer accepted',
            'You accepted a ticket for the BRACU-R03 evening trip. The seat is now yours.',
            'TRANSFER', NULL, 0, NULL, NOW() - INTERVAL 2 DAY),
    (9007,  2, 'Booking confirmed',
            'Your seat B1 on BRACU-R01 is confirmed for tomorrow at 7:30 AM.',
            'BOOKING', NULL, 0, NULL, NOW() - INTERVAL 5 HOUR),
    (9008,  2, 'Welcome to UniRide',
            'Your BRAC University transport account is active.',
            'GENERAL', NULL, 1, NOW() - INTERVAL 9 DAY, NOW() - INTERVAL 10 DAY),

    (9009,  3, 'Seat reserved',
            'Your seat on BRACU-R01 is held. Confirm it before departure.',
            'BOOKING', NULL, 0, NULL, NOW() - INTERVAL 6 HOUR),
    (9010,  4, 'Schedule change',
            'The BRACU-R05 evening trip in three days has been cancelled. Please rebook.',
            'SCHEDULE', 9012, 0, NULL, NOW() - INTERVAL 3 HOUR),

    (9011,  5, 'Faculty shuttle confirmed',
            'Your seat A1 on BRACU-R04 is confirmed for tomorrow at 7:40 AM.',
            'BOOKING', NULL, 0, NULL, NOW() - INTERVAL 8 HOUR),
    (9012,  6, 'Faculty shuttle confirmed',
            'Your seat A2 on BRACU-R04 is confirmed for tomorrow at 7:40 AM.',
            'BOOKING', NULL, 1, NOW() - INTERVAL 1 HOUR, NOW() - INTERVAL 8 HOUR),

    (9013,  7, 'Booking confirmed',
            'Your seat A1 on NSU-R01 is confirmed for tomorrow at 7:30 AM.',
            'BOOKING', NULL, 0, NULL, NOW() - INTERVAL 7 HOUR),
    (9014,  8, 'New shuttle available',
            'A standard shuttle (DHA-2201) now serves NSU-R01 and is open to faculty.',
            'GENERAL', NULL, 0, NULL, NOW() - INTERVAL 30 MINUTE),

    (9015,  9, 'Booking confirmed',
            'Your seat A1 on AIUB-R01 is confirmed for tomorrow at 7:15 AM.',
            'BOOKING', NULL, 0, NULL, NOW() - INTERVAL 7 HOUR),
    (9016, 10, 'New shuttle available',
            'A standard shuttle (DHA-3301) now serves AIUB-R01 and is open to faculty.',
            'GENERAL', NULL, 1, NOW() - INTERVAL 1 HOUR, NOW() - INTERVAL 2 HOUR);


-- =====================================================================
-- 11. Complaints
-- =====================================================================
-- The two shipped complaints are RESOLVED and IN_PROGRESS, so nothing is
-- OPEN and the admin triage queue reads zero. These add a live queue for
-- all three universities.
--
-- university_response stays NULL on every row, which keeps
-- trg_complaint_response_notification out of it — that trigger fires on
-- UPDATE when a response is written, and it is the admin reply flow in
-- Phase 2 that should trigger it, not this seed.
-- =====================================================================

INSERT INTO `complaints`
    (`complaint_id`, `passenger_id`, `university_id`, `subject`, `description`, `status`, `university_response`, `submitted_at`, `updated_at`)
VALUES
    (9001, 1, 1, 'Morning BRACU-R01 departed early',
           'The 7:30 AM service left at 7:24 and several of us at the Rampura stop missed it. Could the driver be asked to hold to the published time?',
           'OPEN', NULL, NOW() - INTERVAL 5 HOUR, NOW() - INTERVAL 5 HOUR),
    (9002, 3, 1, 'Standing room oversold on the 5:20 PM trip',
           'The evening BRACU-R01 was full to the door yesterday. It felt unsafe on the flyover.',
           'OPEN', NULL, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY),
    (9003, 4, 1, 'Request a stop at Badda Link Road',
           'Many of us walk 15 minutes from the current stop. A Link Road halt would help.',
           'IN_PROGRESS', NULL, NOW() - INTERVAL 3 DAY, NOW() - INTERVAL 2 DAY),
    (9004, 7, 2, 'NSU-R01 seat cushions need repair',
           'Two seats in the rear row have torn cushions on bus DHA-7777.',
           'OPEN', NULL, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 2 DAY),
    (9005, 9, 3, 'AIUB-R01 arrives late most mornings',
           'The 7:15 AM service has reached campus after 8:30 for most of this week.',
           'OPEN', NULL, NOW() - INTERVAL 6 HOUR, NOW() - INTERVAL 6 HOUR);


-- =====================================================================
-- 12. Route stops
-- =====================================================================
-- A published stop sequence for the busiest route at each university.
-- INSERT IGNORE against uq_route_stop_order (route_id, stop_order) makes
-- this idempotent, so section 0 does not need to clear it.
-- =====================================================================

INSERT IGNORE INTO `route_stops` (`route_id`, `stop_name`, `stop_order`, `arrival_time`, `landmark`, `status`, `created_at`)
VALUES
    (1, 'BRACU Campus, Merul Badda', 1, '07:30:00', 'Main gate',            'ACTIVE', NOW()),
    (1, 'Rampura Bridge',            2, '07:50:00', 'Under the flyover',    'ACTIVE', NOW()),
    (1, 'Mohakhali',                 3, '08:15:00', 'Wireless Gate',        'ACTIVE', NOW()),
    (1, 'Kazipara',                  4, '08:40:00', 'Metro pillar 271',     'ACTIVE', NOW()),
    (1, 'Mirpur 12',                 5, '09:00:00', 'Bus stand',            'ACTIVE', NOW()),

    (2, 'BRACU Campus, Merul Badda', 1, '08:00:00', 'Main gate',            'ACTIVE', NOW()),
    (2, 'Malibagh',                  2, '08:20:00', 'Rail crossing',        'ACTIVE', NOW()),
    (2, 'Shahbagh',                  3, '08:45:00', 'National Museum',      'ACTIVE', NOW()),
    (2, 'Dhanmondi 27',              4, '09:10:00', 'Genetic Plaza',        'ACTIVE', NOW()),

    (6, 'NSU Campus, Bashundhara',   1, '07:30:00', 'Gate 1',               'ACTIVE', NOW()),
    (6, 'Kuril Bishwa Road',         2, '07:45:00', 'Flyover foot',         'ACTIVE', NOW()),
    (6, 'Banani Chairman Bari',      3, '08:05:00', NULL,                   'ACTIVE', NOW()),
    (6, 'Mohakhali Bus Stand',       4, '08:30:00', NULL,                   'ACTIVE', NOW()),

    (7, 'AIUB Campus, Kuratoli',     1, '07:15:00', 'Main gate',            'ACTIVE', NOW()),
    (7, 'Jamuna Future Park',        2, '07:30:00', 'North entrance',       'ACTIVE', NOW()),
    (7, 'Natun Bazar',               3, '07:45:00', NULL,                   'ACTIVE', NOW()),
    (7, 'Gulshan 2 Circle',          4, '08:15:00', NULL,                   'ACTIVE', NOW());


-- =====================================================================
-- 13. Tidy up
-- =====================================================================

DROP TABLE IF EXISTS `_seed_plan`;
DROP TABLE IF EXISTS `_seed_seq`;


-- =====================================================================
-- OPTIONAL: undo an earlier draft's change to the historical schedules
-- =====================================================================
-- An earlier draft of this seed (database/phase1_seed_demo.sql, now
-- retired to a stub) rolled schedules 1-7 forward with
--     UPDATE schedules SET schedule_date = CURDATE() WHERE schedule_id <= 7;
-- If you ran it, those seven rows are no longer on their original date.
--
-- This is left commented out rather than run automatically, because by now
-- you may have edited those schedules deliberately and this file has no
-- business overwriting that. Uncomment only if you want the shipped dates
-- back.
--
-- UPDATE `schedules` SET `schedule_date` = '2026-08-20'
--  WHERE `schedule_id` BETWEEN 1 AND 7;


-- =====================================================================
-- WHAT YOU SHOULD SEE
-- =====================================================================
-- Passenger — samiha.tasnim@g.bracu.ac.bd
--   Upcoming trip tomorrow 07:30, seat A1 on BRACU-R01
--   3 favourite routes, 3 unread notifications
--   A Fall 2026 bill with charges and a cancellation credit
--   Past trips on BRACU-R01 and BRACU-R03
--   One ticket transfer offered to her, still pending
--
-- Passenger — samir.hossain@g.bracu.ac.bd
--   The same, plus one completed transfer he accepted
--
-- University admin — BRAC University
--   5 trips today, ~114 seats sold today
--   Occupancy tiers of 25%, 65%, 90% and 100% + 6 standing
--   3 active buses in service, 1 in maintenance, 5 routes
--   2 open complaints and 1 in progress
--   1 cancelled trip flagged in the attention banner
--
-- University admin — NSU / AIUB
--   Their own trips and bookings only, never BRACU's
--
-- System admin
--   3 universities, 8 buses, 7 routes, ~250 bookings
--   Per-university passenger, bus, route and trip counts
-- =====================================================================
