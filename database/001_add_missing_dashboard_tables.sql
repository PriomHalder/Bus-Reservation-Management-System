-- ============================================================================
-- UniRide — University Admin dashboard schema migration
-- Database: uniride2
-- Run ONCE before the optional dashboard demo seed.
-- ============================================================================

USE `uniride2`;

SET @OLD_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------------
-- Some older uniride2 exports contain a repeated block of exact passenger rows.
-- If no PRIMARY KEY exists yet, preserve one copy of every exact row before
-- adding the key. If conflicting duplicate passenger IDs remain, stop safely.
-- ---------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS `__uniride_prepare_passengers`;
DELIMITER $$
CREATE PROCEDURE `__uniride_prepare_passengers`()
BEGIN
    DECLARE v_table_exists INT DEFAULT 0;
    DECLARE v_pk_exists INT DEFAULT 0;
    DECLARE v_total BIGINT DEFAULT 0;
    DECLARE v_distinct BIGINT DEFAULT 0;
    DECLARE v_distinct_ids BIGINT DEFAULT 0;

    SELECT COUNT(*) INTO v_table_exists
    FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name = 'passengers';

    IF v_table_exists = 1 THEN
        SELECT COUNT(*) INTO v_pk_exists
        FROM information_schema.table_constraints
        WHERE table_schema = DATABASE()
          AND table_name = 'passengers'
          AND constraint_type = 'PRIMARY KEY';

        IF v_pk_exists = 0 THEN
            SELECT COUNT(*) INTO v_total FROM passengers;
            SELECT COUNT(*) INTO v_distinct
            FROM (
                SELECT DISTINCT passenger_id,university_id,name,email,password_hash,
                       passenger_type,phone,email_notifications,in_app_notifications,
                       status,created_at
                FROM passengers
            ) x;

            IF v_total > v_distinct THEN
                DROP TEMPORARY TABLE IF EXISTS `__uniride_unique_passengers`;
                CREATE TEMPORARY TABLE `__uniride_unique_passengers` AS
                SELECT DISTINCT passenger_id,university_id,name,email,password_hash,
                       passenger_type,phone,email_notifications,in_app_notifications,
                       status,created_at
                FROM passengers;

                DELETE FROM passengers;
                INSERT INTO passengers (
                    passenger_id,university_id,name,email,password_hash,passenger_type,
                    phone,email_notifications,in_app_notifications,status,created_at
                )
                SELECT passenger_id,university_id,name,email,password_hash,passenger_type,
                       phone,email_notifications,in_app_notifications,status,created_at
                FROM `__uniride_unique_passengers`;
                DROP TEMPORARY TABLE `__uniride_unique_passengers`;
            END IF;

            SELECT COUNT(*) INTO v_total FROM passengers;
            SELECT COUNT(DISTINCT passenger_id) INTO v_distinct_ids FROM passengers;

            IF v_total <> v_distinct_ids THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Conflicting duplicate passenger IDs remain. Resolve them before continuing the UniRide migration.';
            END IF;
        END IF;
    END IF;
END$$
DELIMITER ;

CALL `__uniride_prepare_passengers`();
DROP PROCEDURE `__uniride_prepare_passengers`;

-- ---------------------------------------------------------------------------
-- Repair missing PRIMARY KEY / AUTO_INCREMENT definitions from the current
-- SQL export. This is required by LAST_INSERT_ID()-based booking procedures.
-- ---------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS `__uniride_ensure_pk_ai`;
DELIMITER $$
CREATE PROCEDURE `__uniride_ensure_pk_ai`(
    IN p_table VARCHAR(64),
    IN p_column VARCHAR(64)
)
BEGIN
    DECLARE v_table_exists INT DEFAULT 0;
    DECLARE v_pk_exists INT DEFAULT 0;
    DECLARE v_extra VARCHAR(255) DEFAULT '';

    SELECT COUNT(*) INTO v_table_exists
    FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name = p_table;

    IF v_table_exists = 1 THEN
        SELECT COUNT(*) INTO v_pk_exists
        FROM information_schema.table_constraints
        WHERE table_schema = DATABASE()
          AND table_name = p_table
          AND constraint_type = 'PRIMARY KEY';

        IF v_pk_exists = 0 THEN
            SET @sql = CONCAT('ALTER TABLE `',REPLACE(p_table,'`','``'),'` ADD PRIMARY KEY (`',REPLACE(p_column,'`','``'),'`)');
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END IF;

        SELECT COALESCE(MAX(EXTRA),'') INTO v_extra
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = p_table
          AND column_name = p_column;

        IF LOCATE('auto_increment',LOWER(v_extra)) = 0 THEN
            SET @sql = CONCAT('ALTER TABLE `',REPLACE(p_table,'`','``'),'` MODIFY `',REPLACE(p_column,'`','``'),'` INT(11) NOT NULL AUTO_INCREMENT');
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END IF;
    END IF;
END$$
DELIMITER ;

CALL `__uniride_ensure_pk_ai`('admins','admin_id');
CALL `__uniride_ensure_pk_ai`('billing_transactions','transaction_id');
CALL `__uniride_ensure_pk_ai`('bookings','booking_id');
CALL `__uniride_ensure_pk_ai`('buses','bus_id');
CALL `__uniride_ensure_pk_ai`('bus_route_assignments','assignment_id');
CALL `__uniride_ensure_pk_ai`('complaints','complaint_id');
CALL `__uniride_ensure_pk_ai`('faculty','faculty_id');
CALL `__uniride_ensure_pk_ai`('favorite_routes','favorite_id');
CALL `__uniride_ensure_pk_ai`('notifications','notification_id');
CALL `__uniride_ensure_pk_ai`('passengers','passenger_id');
CALL `__uniride_ensure_pk_ai`('routes','route_id');
CALL `__uniride_ensure_pk_ai`('schedules','schedule_id');
CALL `__uniride_ensure_pk_ai`('semesters','semester_id');
CALL `__uniride_ensure_pk_ai`('students','student_id');
CALL `__uniride_ensure_pk_ai`('universities','university_id');
CALL `__uniride_ensure_pk_ai`('university_users','university_user_id');
DROP PROCEDURE `__uniride_ensure_pk_ai`;

-- ---------------------------------------------------------------------------
-- Useful uniqueness rules, added only when the named index is absent.
-- ---------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS `__uniride_add_unique_index`;
DELIMITER $$
CREATE PROCEDURE `__uniride_add_unique_index`(
    IN p_table VARCHAR(64),
    IN p_index VARCHAR(64),
    IN p_columns_sql VARCHAR(500)
)
BEGIN
    DECLARE v_table_exists INT DEFAULT 0;
    DECLARE v_index_exists INT DEFAULT 0;

    SELECT COUNT(*) INTO v_table_exists
    FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name = p_table;

    IF v_table_exists = 1 THEN
        SELECT COUNT(*) INTO v_index_exists
        FROM information_schema.statistics
        WHERE table_schema = DATABASE()
          AND table_name = p_table
          AND index_name = p_index;

        IF v_index_exists = 0 THEN
            SET @sql = CONCAT('ALTER TABLE `',REPLACE(p_table,'`','``'),'` ADD UNIQUE KEY `',REPLACE(p_index,'`','``'),'` (',p_columns_sql,')');
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END IF;
    END IF;
END$$
DELIMITER ;

CALL `__uniride_add_unique_index`('universities','uq_universities_code','`code`');
CALL `__uniride_add_unique_index`('university_users','uq_university_users_email','`email`');
CALL `__uniride_add_unique_index`('passengers','uq_passengers_email','`email`');
CALL `__uniride_add_unique_index`('buses','uq_buses_university_registration','`university_id`,`registration_number`');
CALL `__uniride_add_unique_index`('routes','uq_routes_university_code','`university_id`,`route_code`');
CALL `__uniride_add_unique_index`('bookings','uq_bookings_reference','`booking_reference`');
CALL `__uniride_add_unique_index`('bookings','uq_bookings_qr_token','`qr_token`');
CALL `__uniride_add_unique_index`('favorite_routes','uq_favorite_passenger_route','`passenger_id`,`route_id`');
DROP PROCEDURE `__uniride_add_unique_index`;

-- Existing sp_archive_booking_history() expects this field.
ALTER TABLE `bookings`
    ADD COLUMN IF NOT EXISTS `hidden_from_passenger` TINYINT(1) NOT NULL DEFAULT 0 AFTER `status`;

-- ---------------------------------------------------------------------------
-- Missing support tables already referenced by the existing business logic.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `route_stops` (
    `route_stop_id` INT(11) NOT NULL AUTO_INCREMENT,
    `route_id` INT(11) NOT NULL,
    `stop_name` VARCHAR(200) NOT NULL,
    `stop_order` INT(11) NOT NULL,
    `pickup_offset_minutes` INT(11) DEFAULT NULL,
    `dropoff_offset_minutes` INT(11) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`route_stop_id`),
    UNIQUE KEY `uq_route_stop_order` (`route_id`,`stop_order`),
    KEY `idx_route_stops_route` (`route_id`),
    CONSTRAINT `fk_route_stops_route`
        FOREIGN KEY (`route_id`) REFERENCES `routes` (`route_id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `booking_status_history` (
    `history_id` INT(11) NOT NULL AUTO_INCREMENT,
    `booking_id` INT(11) NOT NULL,
    `old_status` VARCHAR(30) DEFAULT NULL,
    `new_status` VARCHAR(30) NOT NULL,
    `changed_by` VARCHAR(30) NOT NULL DEFAULT 'SYSTEM',
    `changed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`history_id`),
    KEY `idx_booking_status_booking` (`booking_id`),
    KEY `idx_booking_status_changed_at` (`changed_at`),
    CONSTRAINT `fk_booking_status_booking`
        FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `semester_bills` (
    `bill_id` INT(11) NOT NULL AUTO_INCREMENT,
    `passenger_id` INT(11) NOT NULL,
    `semester_id` INT(11) NOT NULL,
    `total_charges` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `total_credits` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `net_balance` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`bill_id`),
    UNIQUE KEY `uq_semester_bill_passenger` (`passenger_id`,`semester_id`),
    KEY `idx_semester_bills_semester` (`semester_id`),
    CONSTRAINT `fk_semester_bills_passenger`
        FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_semester_bills_semester`
        FOREIGN KEY (`semester_id`) REFERENCES `semesters` (`semester_id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ticket_transfers` (
    `transfer_id` INT(11) NOT NULL AUTO_INCREMENT,
    `booking_id` INT(11) NOT NULL,
    `from_passenger_id` INT(11) NOT NULL,
    `to_passenger_id` INT(11) NOT NULL,
    `transfer_type` ENUM('SHARE','SELL') NOT NULL DEFAULT 'SHARE',
    `sale_amount` DECIMAL(10,2) DEFAULT NULL,
    `status` ENUM('PENDING','COMPLETED','REJECTED','CANCELLED') NOT NULL DEFAULT 'PENDING',
    `requested_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `responded_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`transfer_id`),
    KEY `idx_ticket_transfers_booking` (`booking_id`),
    KEY `idx_ticket_transfers_from` (`from_passenger_id`),
    KEY `idx_ticket_transfers_to` (`to_passenger_id`),
    KEY `idx_ticket_transfers_status` (`status`,`requested_at`),
    CONSTRAINT `fk_ticket_transfer_booking`
        FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_ticket_transfer_from_passenger`
        FOREIGN KEY (`from_passenger_id`) REFERENCES `passengers` (`passenger_id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_ticket_transfer_to_passenger`
        FOREIGN KEY (`to_passenger_id`) REFERENCES `passengers` (`passenger_id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = @OLD_FOREIGN_KEY_CHECKS;

SELECT 'UniRide University Admin dashboard migration completed.' AS message,
       DATABASE() AS active_database;
