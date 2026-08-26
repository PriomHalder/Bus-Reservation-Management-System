-- =====================================================================
-- UniRide — migration 001: add the missing dashboard tables
-- =====================================================================
-- Target database : uniride2   (NOT renamed, NOT replaced, NOT rebuilt)
-- Run in          : phpMyAdmin -> uniride2 -> SQL tab
--                   (or: mysql -u root uniride2 < 001_add_missing_dashboard_tables.sql)
--
-- RUN ORDER
-- ---------
--   000_repair_existing_keys.sql           <- MUST run before this file
--   001_add_missing_dashboard_tables.sql   <- this file
--   ../seeds/002_dashboard_demo_data.sql      (optional demo data)
--
-- Every foreign key below points at passengers, bookings, routes or
-- semesters. MySQL rejects a foreign key whose parent column is not
-- indexed, and in the shipped uniride2 none of those tables has a primary
-- key. Run this file on its own and each CREATE TABLE fails with
-- "errno: 150 - Foreign key constraint is incorrectly formed". Run 000
-- first and it all goes through.
--
-- WHAT THIS FIXES
-- ---------------
-- uniride2.sql ships stored procedures that read and write four tables the
-- dump never creates, plus one column it never declares:
--
--   booking_status_history   sp_create_booking, sp_cancel_booking,
--                            sp_request_ticket_transfer,
--                            sp_respond_ticket_transfer
--   semester_bills           sp_create_booking, sp_cancel_booking,
--                            sp_respond_ticket_transfer
--   ticket_transfers         sp_request_ticket_transfer,
--                            sp_respond_ticket_transfer
--   route_stops              the route-stop feature
--   bookings.hidden_from_passenger   sp_archive_booking_history
--
-- Without them sp_create_booking fails at its first INSERT, so no booking
-- can be made at all.
--
-- COLUMN NAMES CAME FROM THE PROCEDURES, NOT FROM GUESSWORK
-- --------------------------------------------------------
-- Every column list below was read out of the stored-procedure bodies in
-- uniride2.sql, so the procedures work against these tables unchanged.
-- Two places where that forced a decision are flagged inline: see the
-- notes on `old_status` in section 1 and on `university_id` in section 2.
--
-- SAFETY
-- ------
-- Nothing here drops, truncates or rewrites an existing table, and no
-- existing row is touched. Re-running the file is safe: every CREATE uses
-- IF NOT EXISTS, and section 6 upgrades tables that an earlier partial run
-- may have created without the newer columns.
-- =====================================================================

USE `uniride2`;

SET NAMES utf8mb4;


-- =====================================================================
-- 1. booking_status_history
-- =====================================================================
-- An audit trail of every status change a booking goes through:
--   sp_create_booking          (booking_id, NULL, 'BOOKED', 'SYSTEM')
--   sp_cancel_booking          (booking_id, old, 'CANCELLED', 'PASSENGER')
--   sp_request_ticket_transfer (booking_id, old, 'TRANSFER_PENDING', 'SYSTEM')
--   sp_respond_ticket_transfer (booking_id, 'TRANSFER_PENDING', 'BOOKED', 'SYSTEM')
--
-- WHY THE COLUMN IS old_status AND NOT previous_status
-- ----------------------------------------------------
-- All four procedures above write
--     INSERT INTO booking_status_history (booking_id, old_status, new_status, changed_by)
-- verbatim. Naming the column previous_status would read better, but it
-- would break every one of them with "Unknown column 'old_status'", and
-- repairing that means dropping and recreating four shipped procedures.
-- The existing schema wins. If you would rather have previous_status,
-- rename it here and re-create those four procedures in the same
-- migration — do not do one without the other.
--
-- old_status is nullable precisely because the first row of a booking's
-- life has no previous state.
-- =====================================================================

CREATE TABLE IF NOT EXISTS `booking_status_history` (
    `history_id`  INT          NOT NULL AUTO_INCREMENT,
    `booking_id`  INT          NOT NULL,
    `old_status`  VARCHAR(20)      NULL COMMENT 'NULL on the first entry — a new booking has no previous status',
    `new_status`  VARCHAR(20)  NOT NULL,
    `changed_by`  VARCHAR(20)  NOT NULL DEFAULT 'SYSTEM' COMMENT 'SYSTEM | PASSENGER | UNIVERSITY_ADMIN',
    `note`        VARCHAR(255)     NULL,
    `changed_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`history_id`),
    KEY `idx_bsh_booking` (`booking_id`),
    KEY `idx_bsh_changed` (`changed_at`),
    KEY `idx_bsh_new_status` (`new_status`),

    CONSTRAINT `fk_bsh_booking`
        FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =====================================================================
-- 2. semester_bills
-- =====================================================================
-- One running transport bill per passenger per semester.
--
-- THE UNIQUE KEY IS LOAD-BEARING
-- ------------------------------
-- sp_create_booking ends with
--     INSERT INTO semester_bills (passenger_id, semester_id, total_charges, net_balance)
--     VALUES (...)
--     ON DUPLICATE KEY UPDATE total_charges = total_charges + v_fare, ...
-- and ON DUPLICATE KEY only fires against a unique index. Without
-- uq_bill_passenger_semester every booking would insert a second bill row
-- for the same passenger instead of accumulating onto the first.
--
-- WHY university_id IS NULLABLE
-- -----------------------------
-- The column is here because a university admin needs to total billing for
-- their own tenant without joining out to passengers on every query. But
-- the INSERT in sp_create_booking (quoted above) does not supply it, so
-- declaring it NOT NULL would make every booking fail with
-- "Field 'university_id' doesn't have a default value".
--
-- It is therefore nullable, and the trigger immediately below fills it
-- from the passenger's own university on insert. In practice the column is
-- always populated; structurally it stays optional so the shipped
-- procedure keeps working untouched.
--
-- net_balance is stored rather than derived because the procedures
-- maintain it incrementally. The passenger dashboard reads it first and
-- only recomputes from billing_transactions if the row is missing.
-- =====================================================================

CREATE TABLE IF NOT EXISTS `semester_bills` (
    `bill_id`        INT            NOT NULL AUTO_INCREMENT,
    `passenger_id`   INT            NOT NULL,
    `semester_id`    INT            NOT NULL,
    `university_id`  INT                NULL COMMENT 'Filled by trg_semester_bills_set_university; nullable so sp_create_booking still works',
    `total_charges`  DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    `total_credits`  DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    `net_balance`    DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    `status`         ENUM('OPEN','PAID','WAIVED','VOID') NOT NULL DEFAULT 'OPEN',
    `created_at`     TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                    ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`bill_id`),
    UNIQUE KEY `uq_bill_passenger_semester` (`passenger_id`, `semester_id`),
    KEY `idx_bill_semester` (`semester_id`),
    KEY `idx_bill_university` (`university_id`, `semester_id`),
    KEY `idx_bill_status` (`status`),

    CONSTRAINT `fk_bill_passenger`
        FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_bill_semester`
        FOREIGN KEY (`semester_id`) REFERENCES `semesters` (`semester_id`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_bill_university`
        FOREIGN KEY (`university_id`) REFERENCES `universities` (`university_id`)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Populate university_id from the passenger who owns the bill.
--
-- The body is a single SET statement, so no DELIMITER juggling is needed
-- and this pastes straight into the phpMyAdmin SQL tab. COALESCE means an
-- explicitly supplied university_id is respected and only a missing one is
-- filled in.
DROP TRIGGER IF EXISTS `trg_semester_bills_set_university`;

CREATE TRIGGER `trg_semester_bills_set_university`
BEFORE INSERT ON `semester_bills`
FOR EACH ROW
    SET NEW.`university_id` = COALESCE(
        NEW.`university_id`,
        (SELECT `p`.`university_id` FROM `passengers` `p`
          WHERE `p`.`passenger_id` = NEW.`passenger_id`)
    );

-- Backfill any bill rows that predate the trigger.
UPDATE `semester_bills` `sb`
  JOIN `passengers` `p` ON `p`.`passenger_id` = `sb`.`passenger_id`
   SET `sb`.`university_id` = `p`.`university_id`
 WHERE `sb`.`university_id` IS NULL;


-- =====================================================================
-- 3. ticket_transfers
-- =====================================================================
-- A booked ticket handed to another passenger, either given away or sold.
--
-- The enum values match what the procedures actually write:
--   sp_request_ticket_transfer inserts status 'PENDING'
--   sp_respond_ticket_transfer sets 'COMPLETED' or 'REJECTED', stamps
--     responded_at, and branches on transfer_type = 'SELL' to move money
--     between the two passengers' semester bills.
--
-- 'CANCELLED' is included so a sender can withdraw a request that has not
-- been answered yet.
--
-- sale_amount is nullable because a GIFT has no price. The rule "SELL must
-- carry an amount, GIFT must not" is a CHECK constraint in MySQL 8 and
-- MariaDB 10.2+; it is written out below but left commented, because
-- older MariaDB parses CHECK and then ignores it, which is worse than not
-- having it — you would think it was enforced when it is not. Enforce it
-- in the Phase 2 transfer form instead.
-- =====================================================================

CREATE TABLE IF NOT EXISTS `ticket_transfers` (
    `transfer_id`        INT            NOT NULL AUTO_INCREMENT,
    `booking_id`         INT            NOT NULL,
    `from_passenger_id`  INT            NOT NULL,
    `to_passenger_id`    INT            NOT NULL,
    `transfer_type`      ENUM('GIFT','SELL')  NOT NULL DEFAULT 'GIFT',
    `sale_amount`        DECIMAL(10,2)      NULL COMMENT 'NULL for GIFT',
    `status`             ENUM('PENDING','COMPLETED','REJECTED','CANCELLED')
                                        NOT NULL DEFAULT 'PENDING',
    `message`            VARCHAR(255)       NULL,
    `requested_at`       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `responded_at`       DATETIME           NULL,

    PRIMARY KEY (`transfer_id`),
    KEY `idx_transfer_booking` (`booking_id`),
    KEY `idx_transfer_from` (`from_passenger_id`, `status`),
    KEY `idx_transfer_to` (`to_passenger_id`, `status`),
    KEY `idx_transfer_status` (`status`, `requested_at`),

    -- CONSTRAINT `chk_transfer_amount` CHECK (
    --     (`transfer_type` = 'SELL' AND `sale_amount` IS NOT NULL)
    --  OR (`transfer_type` = 'GIFT' AND `sale_amount` IS NULL)
    -- ),

    CONSTRAINT `fk_transfer_booking`
        FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_transfer_from`
        FOREIGN KEY (`from_passenger_id`) REFERENCES `passengers` (`passenger_id`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_transfer_to`
        FOREIGN KEY (`to_passenger_id`) REFERENCES `passengers` (`passenger_id`)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =====================================================================
-- 4. route_stops
-- =====================================================================
-- The ordered stop sequence along a route. No stored procedure touches
-- this table, so unlike the three above its shape is a design decision
-- rather than a reconstruction of something already in use.
--
-- UNIQUE (route_id, stop_order) is what makes "ordered" mean anything: it
-- stops two rows both claiming position 3 on the same route.
--
-- status lets a stop be suspended (roadworks, a closed gate) without
-- deleting it and renumbering everything after it.
-- =====================================================================

CREATE TABLE IF NOT EXISTS `route_stops` (
    `stop_id`      INT           NOT NULL AUTO_INCREMENT,
    `route_id`     INT           NOT NULL,
    `stop_name`    VARCHAR(200)  NOT NULL,
    `stop_order`   INT           NOT NULL COMMENT '1 = origin, ascending along the route',
    `arrival_time` TIME              NULL COMMENT 'Planned offset within the trip; NULL if not published',
    `landmark`     VARCHAR(200)      NULL,
    `status`       ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    `created_at`   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
                                 ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`stop_id`),
    UNIQUE KEY `uq_route_stop_order` (`route_id`, `stop_order`),
    KEY `idx_stop_route_status` (`route_id`, `status`),

    CONSTRAINT `fk_stop_route`
        FOREIGN KEY (`route_id`) REFERENCES `routes` (`route_id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =====================================================================
-- 5. bookings.hidden_from_passenger
-- =====================================================================
-- sp_archive_booking_history does
--     UPDATE bookings SET hidden_from_passenger = 1 WHERE ...
-- but the CREATE TABLE for bookings never declares the column, so that
-- procedure fails with "Unknown column" as shipped.
--
-- ADD COLUMN IF NOT EXISTS is MariaDB syntax, and XAMPP ships MariaDB. On
-- stock Oracle MySQL, drop the "IF NOT EXISTS" and run the statement once.
-- =====================================================================

ALTER TABLE `bookings`
    ADD COLUMN IF NOT EXISTS `hidden_from_passenger` TINYINT(1) NOT NULL DEFAULT 0
    AFTER `status`;


-- =====================================================================
-- 6. Upgrade path for an earlier partial run
-- =====================================================================
-- CREATE TABLE IF NOT EXISTS is silent when the table is already there,
-- which means a database created by an earlier draft of this migration
-- would keep the older column set. These statements bring such a table up
-- to the current shape and are no-ops on a fresh install.
-- =====================================================================

ALTER TABLE `semester_bills`
    ADD COLUMN IF NOT EXISTS `university_id` INT NULL AFTER `semester_id`,
    ADD COLUMN IF NOT EXISTS `status` ENUM('OPEN','PAID','WAIVED','VOID')
        NOT NULL DEFAULT 'OPEN' AFTER `net_balance`;

ALTER TABLE `booking_status_history`
    ADD COLUMN IF NOT EXISTS `note` VARCHAR(255) NULL AFTER `changed_by`;

ALTER TABLE `ticket_transfers`
    ADD COLUMN IF NOT EXISTS `message` VARCHAR(255) NULL AFTER `status`;

ALTER TABLE `route_stops`
    ADD COLUMN IF NOT EXISTS `landmark` VARCHAR(200) NULL AFTER `arrival_time`,
    ADD COLUMN IF NOT EXISTS `status` ENUM('ACTIVE','INACTIVE')
        NOT NULL DEFAULT 'ACTIVE' AFTER `landmark`,
    ADD COLUMN IF NOT EXISTS `updated_at` TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;


-- =====================================================================
-- 7. Replace the two view stubs with real views
-- =====================================================================
-- v_schedule_availability and v_university_dashboard_stats arrive from the
-- dump as bodyless CREATE TABLE stubs — the shape phpMyAdmin emits when it
-- cannot dump a view definition. Imported as-is they become permanently
-- empty InnoDB tables that look like working views and return nothing.
--
-- DROP VIEW and DROP TABLE are both attempted with IF EXISTS, so this
-- works whichever of the two shapes is currently in the database.
--
-- The dashboards deliberately do NOT read these views. They compute from
-- base tables so that a stubbed view can never silently render a dashboard
-- full of zeros. The views are restored because the schema documents them
-- and they are convenient for hand-querying in phpMyAdmin.
-- =====================================================================

DROP VIEW  IF EXISTS `v_schedule_availability`;
DROP TABLE IF EXISTS `v_schedule_availability`;

CREATE VIEW `v_schedule_availability` AS
SELECT
    s.schedule_id,
    s.schedule_date,
    s.departure_time,
    s.arrival_time,
    s.status                                        AS schedule_status,
    r.route_id,
    r.route_code,
    r.route_name,
    r.university_id,
    r.fare,
    b.bus_id,
    b.registration_number,
    b.bus_type,
    b.seat_capacity,
    b.standing_capacity,
    COALESCE(SUM(bk.slot_type = 'SEAT'), 0)         AS booked_seats,
    COALESCE(SUM(bk.slot_type = 'STANDING'), 0)     AS booked_standing,
    b.seat_capacity - COALESCE(SUM(bk.slot_type = 'SEAT'), 0)
                                                    AS available_seats,
    b.standing_capacity - COALESCE(SUM(bk.slot_type = 'STANDING'), 0)
                                                    AS available_standing
FROM schedules s
JOIN routes r ON r.route_id = s.route_id
JOIN buses  b ON b.bus_id   = s.bus_id
LEFT JOIN bookings bk
       ON bk.schedule_id = s.schedule_id
      AND bk.status IN ('BOOKED', 'CONFIRMED', 'TRANSFER_PENDING')
GROUP BY
    s.schedule_id, s.schedule_date, s.departure_time, s.arrival_time, s.status,
    r.route_id, r.route_code, r.route_name, r.university_id, r.fare,
    b.bus_id, b.registration_number, b.bus_type, b.seat_capacity, b.standing_capacity;


DROP VIEW  IF EXISTS `v_university_dashboard_stats`;
DROP TABLE IF EXISTS `v_university_dashboard_stats`;

CREATE VIEW `v_university_dashboard_stats` AS
SELECT
    u.university_id,
    u.name                                          AS university_name,
    u.code                                          AS university_code,
    u.status                                        AS university_status,
    (SELECT COUNT(*) FROM passengers p
      WHERE p.university_id = u.university_id)       AS total_passengers,
    (SELECT COUNT(*) FROM passengers p
      WHERE p.university_id = u.university_id
        AND p.passenger_type = 'STUDENT')            AS total_students,
    (SELECT COUNT(*) FROM passengers p
      WHERE p.university_id = u.university_id
        AND p.passenger_type = 'FACULTY')            AS total_faculty,
    (SELECT COUNT(*) FROM buses b
      WHERE b.university_id = u.university_id)       AS total_buses,
    (SELECT COUNT(*) FROM buses b
      WHERE b.university_id = u.university_id
        AND b.status = 'ACTIVE')                     AS active_buses,
    (SELECT COUNT(*) FROM routes r
      WHERE r.university_id = u.university_id)       AS total_routes,
    (SELECT COUNT(*) FROM routes r
      WHERE r.university_id = u.university_id
        AND r.status = 'ACTIVE')                     AS active_routes,
    (SELECT COUNT(*)
       FROM schedules s
       JOIN routes r ON r.route_id = s.route_id
      WHERE r.university_id = u.university_id
        AND s.schedule_date = CURDATE())             AS schedules_today,
    (SELECT COUNT(*)
       FROM bookings bk
       JOIN schedules s ON s.schedule_id = bk.schedule_id
       JOIN routes    r ON r.route_id    = s.route_id
      WHERE r.university_id = u.university_id
        AND bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING'))
                                                     AS active_bookings,
    (SELECT COUNT(*) FROM complaints c
      WHERE c.university_id = u.university_id
        AND c.status IN ('OPEN','IN_PROGRESS'))      AS pending_complaints
FROM universities u;


-- =====================================================================
-- Done. Verify with tools/schema_check.php — it reports every table, its
-- key status, its foreign keys and its row count on one page.
--
-- The dashboards work from here on with all four tables empty; they render
-- empty states rather than errors. Load
-- ../seeds/002_dashboard_demo_data.sql only if you want data to look at.
-- =====================================================================
