-- =====================================================================
-- UniRide — migration 000: repair keys on the existing tables
-- =====================================================================
-- Target database : uniride2   (NOT renamed, NOT replaced, NOT rebuilt)
-- Run in          : phpMyAdmin -> uniride2 -> SQL tab
--                   (or: mysql -u root uniride2 < 000_repair_existing_keys.sql)
--
-- RUN ORDER
-- ---------
--   000_repair_existing_keys.sql        <- this file, FIRST
--   001_add_missing_dashboard_tables.sql
--   ../seeds/002_dashboard_demo_data.sql   (optional demo data)
--
-- WHY THIS RUNS BEFORE 001
-- ------------------------
-- Migration 001 creates four tables whose foreign keys point at
-- passengers, bookings, routes and semesters. MySQL will not accept a
-- foreign key whose parent column is not indexed, and in the shipped
-- uniride2 not one of those tables has a primary key. Run 001 first and
-- every CREATE TABLE fails with errno 150. Hence 000.
--
-- WHY THE KEYS ARE MISSING AT ALL
-- -------------------------------
-- uniride2.sql contains no ALTER TABLE statements. The dump ends at COMMIT
-- with every table defined but not one PRIMARY KEY, AUTO_INCREMENT,
-- FOREIGN KEY or UNIQUE constraint. phpMyAdmin normally emits those in a
-- trailing "Indexes for dumped tables" / "Constraints for dumped tables"
-- section; in this dump that section is absent.
--
-- What that costs in practice:
--   * No AUTO_INCREMENT, so an INSERT that omits the id writes 0, and the
--     second one writes 0 again. Registration and booking both break as
--     soon as a second row is created.
--   * No PRIMARY KEY, so nothing prevents duplicate rows — and the dump
--     has already hit this (see section 1).
--   * No FOREIGN KEY, so a booking can reference a schedule that does not
--     exist, and deleting a university leaves orphaned passengers.
--   * No UNIQUE on email, so two accounts can share an address and login
--     becomes ambiguous.
--
-- WHAT THIS FILE DOES NOT DO
-- --------------------------
-- It does not drop, recreate or rebuild a single table, and it does not
-- touch uniride2.sql. It only adds keys to tables that already exist. The
-- one exception is section 1, which deletes duplicated rows — read it
-- before running, and export uniride2 from phpMyAdmin first.
--
-- IDEMPOTENCE
-- -----------
-- Sections 1, 3, 4 and 5 are re-runnable: every ADD is preceded by a
-- DROP ... IF EXISTS (MariaDB syntax, which is what XAMPP ships).
-- Section 2 is NOT re-runnable, because ADD PRIMARY KEY has no
-- IF NOT EXISTS form. If tools/schema_check.php already reports a primary
-- key on a table, delete or comment out that line. Running it twice is
-- harmless in effect but stops with "Multiple primary key defined".
-- =====================================================================

USE `uniride2`;

SET NAMES utf8mb4;


-- =====================================================================
-- 1. Remove duplicated passenger rows
-- =====================================================================
-- uniride2.sql contains the passengers INSERT twice. The first block
-- (line 689) covers passenger_id 1-160. The second block (line 850)
-- repeats 127-160 verbatim — line 851 is byte-identical to line 816.
--
-- Because the dump defines no primary key, MySQL accepts both copies
-- silently. The result is 34 duplicated AIUB passengers, which inflates
-- the AIUB passenger count and the platform total on the dashboards, and
-- makes ADD PRIMARY KEY (passenger_id) in section 2 fail outright with
-- "Duplicate entry '127' for key 'PRIMARY'".
--
-- The two copies are identical in every column, so there is no "correct"
-- one to keep and no information is lost by collapsing them. Since the
-- table has no key to identify a row by, this adds a temporary
-- AUTO_INCREMENT surrogate, keeps the lowest surrogate per passenger_id,
-- then drops it again.
--
-- If your copy of the database has no duplicates, the DELETE removes 0
-- rows and the whole section is a no-op.
-- =====================================================================

-- Want to see the damage first? Run this on its own:
--     SELECT COUNT(*) - COUNT(DISTINCT passenger_id) AS duplicate_rows
--       FROM passengers;

ALTER TABLE `passengers`
    ADD COLUMN `_dedup_id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;

DELETE FROM `passengers`
 WHERE `_dedup_id` NOT IN (
     -- The derived table is required: MySQL cannot read the table being
     -- deleted from in a bare subquery.
     SELECT `keep_id` FROM (
         SELECT MIN(`_dedup_id`) AS `keep_id`
           FROM `passengers`
          GROUP BY `passenger_id`
     ) AS `keepers`
 );

-- Dropping the column drops the temporary primary key with it, leaving
-- the table ready for its real key in section 2.
ALTER TABLE `passengers`
    DROP COLUMN `_dedup_id`;


-- =====================================================================
-- 2. Primary keys and AUTO_INCREMENT
-- =====================================================================
-- Two statements per table: the key, then the identity. Adding
-- AUTO_INCREMENT sets the counter to MAX(id) + 1 automatically, so every
-- existing id is preserved and the next insert continues from there.
-- Nothing is renumbered.
--
-- password_reset_tokens is deliberately absent: it ships from
-- database/password_reset_tokens.sql with its keys already declared.
--
-- NOT re-runnable — see the header note.
-- =====================================================================

ALTER TABLE `universities`          ADD PRIMARY KEY (`university_id`);
ALTER TABLE `universities`          MODIFY `university_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `semesters`             ADD PRIMARY KEY (`semester_id`);
ALTER TABLE `semesters`             MODIFY `semester_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `admins`                ADD PRIMARY KEY (`admin_id`);
ALTER TABLE `admins`                MODIFY `admin_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `university_users`      ADD PRIMARY KEY (`university_user_id`);
ALTER TABLE `university_users`      MODIFY `university_user_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `passengers`            ADD PRIMARY KEY (`passenger_id`);
ALTER TABLE `passengers`            MODIFY `passenger_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `students`              ADD PRIMARY KEY (`student_id`);
ALTER TABLE `students`              MODIFY `student_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `faculty`               ADD PRIMARY KEY (`faculty_id`);
ALTER TABLE `faculty`               MODIFY `faculty_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `buses`                 ADD PRIMARY KEY (`bus_id`);
ALTER TABLE `buses`                 MODIFY `bus_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `routes`                ADD PRIMARY KEY (`route_id`);
ALTER TABLE `routes`                MODIFY `route_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `bus_route_assignments` ADD PRIMARY KEY (`assignment_id`);
ALTER TABLE `bus_route_assignments` MODIFY `assignment_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `schedules`             ADD PRIMARY KEY (`schedule_id`);
ALTER TABLE `schedules`             MODIFY `schedule_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `bookings`              ADD PRIMARY KEY (`booking_id`);
ALTER TABLE `bookings`              MODIFY `booking_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `complaints`            ADD PRIMARY KEY (`complaint_id`);
ALTER TABLE `complaints`            MODIFY `complaint_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `favorite_routes`       ADD PRIMARY KEY (`favorite_id`);
ALTER TABLE `favorite_routes`       MODIFY `favorite_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `notifications`         ADD PRIMARY KEY (`notification_id`);
ALTER TABLE `notifications`         MODIFY `notification_id` INT NOT NULL AUTO_INCREMENT;

ALTER TABLE `billing_transactions`  ADD PRIMARY KEY (`transaction_id`);
ALTER TABLE `billing_transactions`  MODIFY `transaction_id` INT NOT NULL AUTO_INCREMENT;


-- =====================================================================
-- 3. Unique constraints
-- =====================================================================
-- These encode business rules, not tidiness.
--
-- The two that matter most to the ER model are uq_student_passenger and
-- uq_faculty_passenger. PASSENGER is a superclass with disjoint subtypes
-- STUDENT and FACULTY, and a 1:1 subtype relationship is only actually
-- enforced when the foreign key in the subtype table is unique. Without
-- them, one passenger could hold two student records.
-- =====================================================================

ALTER TABLE `universities`      DROP INDEX IF EXISTS `uq_university_code`;
ALTER TABLE `universities`      ADD UNIQUE KEY `uq_university_code` (`code`);

ALTER TABLE `admins`            DROP INDEX IF EXISTS `uq_admin_email`;
ALTER TABLE `admins`            ADD UNIQUE KEY `uq_admin_email` (`email`);

ALTER TABLE `university_users`  DROP INDEX IF EXISTS `uq_university_user_email`;
ALTER TABLE `university_users`  ADD UNIQUE KEY `uq_university_user_email` (`email`);

ALTER TABLE `passengers`        DROP INDEX IF EXISTS `uq_passenger_email`;
ALTER TABLE `passengers`        ADD UNIQUE KEY `uq_passenger_email` (`email`);

-- Disjoint subtype: exactly one student record per passenger.
ALTER TABLE `students`          DROP INDEX IF EXISTS `uq_student_passenger`;
ALTER TABLE `students`          ADD UNIQUE KEY `uq_student_passenger` (`passenger_id`);

ALTER TABLE `students`          DROP INDEX IF EXISTS `uq_student_identifier`;
ALTER TABLE `students`          ADD UNIQUE KEY `uq_student_identifier` (`student_identifier`);

-- Disjoint subtype: exactly one faculty record per passenger.
ALTER TABLE `faculty`           DROP INDEX IF EXISTS `uq_faculty_passenger`;
ALTER TABLE `faculty`           ADD UNIQUE KEY `uq_faculty_passenger` (`passenger_id`);

ALTER TABLE `faculty`           DROP INDEX IF EXISTS `uq_faculty_identifier`;
ALTER TABLE `faculty`           ADD UNIQUE KEY `uq_faculty_identifier` (`faculty_identifier`);

ALTER TABLE `buses`             DROP INDEX IF EXISTS `uq_bus_registration`;
ALTER TABLE `buses`             ADD UNIQUE KEY `uq_bus_registration` (`registration_number`);

-- Route codes are unique per university, not globally: BRACU-R01 and
-- NSU-R01 must both be allowed to exist.
ALTER TABLE `routes`            DROP INDEX IF EXISTS `uq_route_code`;
ALTER TABLE `routes`            ADD UNIQUE KEY `uq_route_code` (`university_id`, `route_code`);

ALTER TABLE `bus_route_assignments` DROP INDEX IF EXISTS `uq_bus_route`;
ALTER TABLE `bus_route_assignments` ADD UNIQUE KEY `uq_bus_route` (`bus_id`, `route_id`);

-- ONE BUS, ONE TRIP AT A TIME — NOT ENFORCED, AND HERE IS WHY.
-- The natural constraint would be
--     ADD UNIQUE KEY uq_bus_departure (bus_id, schedule_date, departure_time)
-- but the shipped demo data already violates it: schedule_id 1 (route 1)
-- and schedule_id 2 (route 2) both put bus_id 1 on 2026-08-20 at 17:20,
-- so bus DHA-1234 is double-booked across two routes at the same moment.
-- Adding the constraint would fail with "Duplicate entry
-- '1-2026-08-20-17:20:00'", and forcing it through would mean deleting one
-- of the existing schedules — which this migration is not willing to do.
--
-- A plain index goes in instead, so the lookup stays fast and the rule can
-- be enforced in the Phase 2 scheduling form, or promoted to UNIQUE once
-- the conflicting rows are corrected by hand.
ALTER TABLE `schedules`         DROP INDEX IF EXISTS `idx_bus_departure`;
ALTER TABLE `schedules`         ADD KEY `idx_bus_departure` (`bus_id`, `schedule_date`, `departure_time`);

ALTER TABLE `bookings`          DROP INDEX IF EXISTS `uq_booking_reference`;
ALTER TABLE `bookings`          ADD UNIQUE KEY `uq_booking_reference` (`booking_reference`);

ALTER TABLE `bookings`          DROP INDEX IF EXISTS `uq_booking_qr`;
ALTER TABLE `bookings`          ADD UNIQUE KEY `uq_booking_qr` (`qr_token`);

ALTER TABLE `favorite_routes`   DROP INDEX IF EXISTS `uq_favorite`;
ALTER TABLE `favorite_routes`   ADD UNIQUE KEY `uq_favorite` (`passenger_id`, `route_id`);

-- NOTE ON SEAT UNIQUENESS
-- "One seat per schedule" cannot be a plain UNIQUE KEY, because a seat
-- must become bookable again after its holder cancels, and MySQL has no
-- partial/filtered indexes. That rule is therefore enforced by the two
-- triggers already in the schema (trg_chk_dup_booking_ins / _upd), which
-- only consider rows with status IN ('BOOKED','CONFIRMED',
-- 'TRANSFER_PENDING'). Adding UNIQUE (schedule_id, seat_number) here would
-- wrongly block re-selling a cancelled seat.


-- =====================================================================
-- 4. Foreign keys between existing tables
-- =====================================================================
-- Foreign keys for the four NEW tables live in migration 001, declared
-- inline in their CREATE TABLE statements.
--
-- ON DELETE choices are deliberate:
--   CASCADE  where the child cannot exist alone and carries no history
--            worth keeping (subtype records, favourites, notifications).
--   RESTRICT where deletion would destroy financial or operational
--            history (bookings, transactions, schedules).
--   SET NULL for billing_transactions.booking_id, which is already
--            nullable — a cancellation credit outlives its booking.
-- =====================================================================

-- Passengers belong to a university.
ALTER TABLE `passengers` DROP FOREIGN KEY IF EXISTS `fk_passenger_university`;
ALTER TABLE `passengers`
    ADD CONSTRAINT `fk_passenger_university`
    FOREIGN KEY (`university_id`) REFERENCES `universities` (`university_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Subtypes of PASSENGER.
ALTER TABLE `students` DROP FOREIGN KEY IF EXISTS `fk_student_passenger`;
ALTER TABLE `students`
    ADD CONSTRAINT `fk_student_passenger`
    FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `faculty` DROP FOREIGN KEY IF EXISTS `fk_faculty_passenger`;
ALTER TABLE `faculty`
    ADD CONSTRAINT `fk_faculty_passenger`
    FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Transport office accounts.
ALTER TABLE `university_users` DROP FOREIGN KEY IF EXISTS `fk_university_user_university`;
ALTER TABLE `university_users`
    ADD CONSTRAINT `fk_university_user_university`
    FOREIGN KEY (`university_id`) REFERENCES `universities` (`university_id`)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Fleet and network are owned by a university. These two constraints are
-- what make the dashboards' tenancy fence structural, rather than just a
-- WHERE clause the application has to remember to write.
ALTER TABLE `buses` DROP FOREIGN KEY IF EXISTS `fk_bus_university`;
ALTER TABLE `buses`
    ADD CONSTRAINT `fk_bus_university`
    FOREIGN KEY (`university_id`) REFERENCES `universities` (`university_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `routes` DROP FOREIGN KEY IF EXISTS `fk_route_university`;
ALTER TABLE `routes`
    ADD CONSTRAINT `fk_route_university`
    FOREIGN KEY (`university_id`) REFERENCES `universities` (`university_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `bus_route_assignments` DROP FOREIGN KEY IF EXISTS `fk_assignment_bus`;
ALTER TABLE `bus_route_assignments`
    ADD CONSTRAINT `fk_assignment_bus`
    FOREIGN KEY (`bus_id`) REFERENCES `buses` (`bus_id`)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `bus_route_assignments` DROP FOREIGN KEY IF EXISTS `fk_assignment_route`;
ALTER TABLE `bus_route_assignments`
    ADD CONSTRAINT `fk_assignment_route`
    FOREIGN KEY (`route_id`) REFERENCES `routes` (`route_id`)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `schedules` DROP FOREIGN KEY IF EXISTS `fk_schedule_route`;
ALTER TABLE `schedules`
    ADD CONSTRAINT `fk_schedule_route`
    FOREIGN KEY (`route_id`) REFERENCES `routes` (`route_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `schedules` DROP FOREIGN KEY IF EXISTS `fk_schedule_bus`;
ALTER TABLE `schedules`
    ADD CONSTRAINT `fk_schedule_bus`
    FOREIGN KEY (`bus_id`) REFERENCES `buses` (`bus_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Bookings.
ALTER TABLE `bookings` DROP FOREIGN KEY IF EXISTS `fk_booking_passenger`;
ALTER TABLE `bookings`
    ADD CONSTRAINT `fk_booking_passenger`
    FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `bookings` DROP FOREIGN KEY IF EXISTS `fk_booking_schedule`;
ALTER TABLE `bookings`
    ADD CONSTRAINT `fk_booking_schedule`
    FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`schedule_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Service and engagement.
ALTER TABLE `complaints` DROP FOREIGN KEY IF EXISTS `fk_complaint_passenger`;
ALTER TABLE `complaints`
    ADD CONSTRAINT `fk_complaint_passenger`
    FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `complaints` DROP FOREIGN KEY IF EXISTS `fk_complaint_university`;
ALTER TABLE `complaints`
    ADD CONSTRAINT `fk_complaint_university`
    FOREIGN KEY (`university_id`) REFERENCES `universities` (`university_id`)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `favorite_routes` DROP FOREIGN KEY IF EXISTS `fk_favorite_passenger`;
ALTER TABLE `favorite_routes`
    ADD CONSTRAINT `fk_favorite_passenger`
    FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `favorite_routes` DROP FOREIGN KEY IF EXISTS `fk_favorite_route`;
ALTER TABLE `favorite_routes`
    ADD CONSTRAINT `fk_favorite_route`
    FOREIGN KEY (`route_id`) REFERENCES `routes` (`route_id`)
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `notifications` DROP FOREIGN KEY IF EXISTS `fk_notification_passenger`;
ALTER TABLE `notifications`
    ADD CONSTRAINT `fk_notification_passenger`
    FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Billing.
ALTER TABLE `billing_transactions` DROP FOREIGN KEY IF EXISTS `fk_transaction_passenger`;
ALTER TABLE `billing_transactions`
    ADD CONSTRAINT `fk_transaction_passenger`
    FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `billing_transactions` DROP FOREIGN KEY IF EXISTS `fk_transaction_semester`;
ALTER TABLE `billing_transactions`
    ADD CONSTRAINT `fk_transaction_semester`
    FOREIGN KEY (`semester_id`) REFERENCES `semesters` (`semester_id`)
    ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `billing_transactions` DROP FOREIGN KEY IF EXISTS `fk_transaction_booking`;
ALTER TABLE `billing_transactions`
    ADD CONSTRAINT `fk_transaction_booking`
    FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`)
    ON DELETE SET NULL ON UPDATE CASCADE;


-- =====================================================================
-- 5. Indexes for the dashboard queries
-- =====================================================================
-- Foreign keys create their own indexes, so these cover only the filters
-- the dashboards additionally sort and group by.
-- =====================================================================

-- "What runs today / next?" — the most-used lookup on the university admin
-- dashboard and in the passenger schedule preview.
ALTER TABLE `schedules`     DROP INDEX IF EXISTS `idx_schedule_date_status`;
ALTER TABLE `schedules`     ADD KEY `idx_schedule_date_status` (`schedule_date`, `status`);

-- Occupancy counting: bookings for one schedule, filtered by status.
ALTER TABLE `bookings`      DROP INDEX IF EXISTS `idx_booking_schedule_status`;
ALTER TABLE `bookings`      ADD KEY `idx_booking_schedule_status` (`schedule_id`, `status`);

-- "My bookings", newest first.
ALTER TABLE `bookings`      DROP INDEX IF EXISTS `idx_booking_passenger_status`;
ALTER TABLE `bookings`      ADD KEY `idx_booking_passenger_status` (`passenger_id`, `status`);

-- Roster counts split by type, per university.
ALTER TABLE `passengers`    DROP INDEX IF EXISTS `idx_passenger_university_type`;
ALTER TABLE `passengers`    ADD KEY `idx_passenger_university_type` (`university_id`, `passenger_type`, `status`);

-- Complaint triage queue.
ALTER TABLE `complaints`    DROP INDEX IF EXISTS `idx_complaint_university_status`;
ALTER TABLE `complaints`    ADD KEY `idx_complaint_university_status` (`university_id`, `status`);

-- Unread notification badge.
ALTER TABLE `notifications` DROP INDEX IF EXISTS `idx_notification_passenger_read`;
ALTER TABLE `notifications` ADD KEY `idx_notification_passenger_read` (`passenger_id`, `is_read`);

-- Active-route listing per university.
ALTER TABLE `routes`        DROP INDEX IF EXISTS `idx_route_university_status`;
ALTER TABLE `routes`        ADD KEY `idx_route_university_status` (`university_id`, `status`);

-- Eligible-bus filtering by passenger type.
ALTER TABLE `buses`         DROP INDEX IF EXISTS `idx_bus_university_type`;
ALTER TABLE `buses`         ADD KEY `idx_bus_university_type` (`university_id`, `bus_type`, `status`);


-- =====================================================================
-- Done. Re-run tools/schema_check.php: every table should now report a
-- primary key, and the passenger count should have dropped by the number
-- of duplicates section 1 removed.
--
-- Next: 001_add_missing_dashboard_tables.sql
-- =====================================================================
