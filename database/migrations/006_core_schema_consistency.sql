-- =====================================================================
-- UniRide — migration 006: core schema consistency
-- =====================================================================
-- Target database : uniride2
-- Run in          : phpMyAdmin -> uniride2 -> SQL tab
--
-- This non-destructive migration repairs only the database objects used by
-- password recovery, route stops, announcements and semester billing.
-- Existing rows are preserved. It intentionally contains no ticket-transfer
-- DDL or data changes.
--
-- Run after importing uniride2.sql and migration 000. It is safe to run more
-- than once on the MariaDB version bundled with XAMPP.
-- =====================================================================

USE `uniride2`;

SET NAMES utf8mb4;


-- =====================================================================
-- 1. Password-reset tokens
-- =====================================================================

CREATE TABLE IF NOT EXISTS `password_reset_tokens` (
    `reset_id`     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account_type` ENUM('PASSENGER','UNIVERSITY_ADMIN','SYSTEM_ADMIN') NOT NULL,
    `account_id`   INT             NOT NULL,
    `token_hash`   CHAR(64)        NOT NULL,
    `expires_at`   DATETIME        NOT NULL,
    `used_at`      DATETIME            NULL,
    `created_at`   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`reset_id`),
    UNIQUE KEY `uq_reset_token_hash` (`token_hash`),
    KEY `idx_reset_account` (`account_type`, `account_id`),
    KEY `idx_reset_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =====================================================================
-- 2. Route stops
-- =====================================================================

CREATE TABLE IF NOT EXISTS `route_stops` (
    `stop_id`      INT          NOT NULL AUTO_INCREMENT,
    `route_id`     INT          NOT NULL,
    `stop_name`    VARCHAR(200) NOT NULL,
    `stop_order`   INT          NOT NULL COMMENT '1 = origin, ascending along the route',
    `arrival_time` TIME             NULL,
    `landmark`     VARCHAR(200)     NULL,
    `status`       ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`stop_id`),
    UNIQUE KEY `uq_route_stop_order` (`route_id`, `stop_order`),
    KEY `idx_stop_route_status` (`route_id`, `status`),

    CONSTRAINT `fk_stop_route`
        FOREIGN KEY (`route_id`) REFERENCES `routes` (`route_id`)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =====================================================================
-- 3. University announcements
-- =====================================================================

CREATE TABLE IF NOT EXISTS `announcements` (
    `announcement_id` INT          NOT NULL AUTO_INCREMENT,
    `university_id`   INT          NOT NULL,
    `created_by`      INT              NULL,
    `title`           VARCHAR(180) NOT NULL,
    `message`         TEXT         NOT NULL,
    `status`          ENUM('DRAFT','PUBLISHED','ARCHIVED')
                                  NOT NULL DEFAULT 'DRAFT',
    `published_at`    DATETIME         NULL,
    `created_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                  ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`announcement_id`),
    KEY `idx_announcement_tenant_status`
        (`university_id`, `status`, `published_at`),
    KEY `idx_announcement_creator` (`created_by`),

    CONSTRAINT `fk_announcement_university`
        FOREIGN KEY (`university_id`) REFERENCES `universities` (`university_id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_announcement_creator`
        FOREIGN KEY (`created_by`) REFERENCES `university_users` (`university_user_id`)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- =====================================================================
-- 4. Semester-bill university ownership
-- =====================================================================
-- uniride2.sql already creates semester_bills, so CREATE TABLE IF NOT EXISTS
-- cannot upgrade it. Add the missing tenant and status columns before the
-- trigger references university_id, then backfill every existing bill from
-- its authenticated passenger relationship.

CREATE TABLE IF NOT EXISTS `semester_bills` (
    `bill_id`       INT           NOT NULL AUTO_INCREMENT,
    `passenger_id`  INT           NOT NULL,
    `semester_id`   INT           NOT NULL,
    `university_id` INT               NULL,
    `total_charges` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `total_credits` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `net_balance`   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `status`        ENUM('OPEN','PAID','WAIVED','VOID') NOT NULL DEFAULT 'OPEN',
    `created_at`    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
                                 ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (`bill_id`),
    UNIQUE KEY `uq_bill_passenger_semester` (`passenger_id`, `semester_id`),
    KEY `idx_bill_semester` (`semester_id`),
    KEY `idx_bill_university` (`university_id`, `semester_id`),

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

ALTER TABLE `semester_bills`
    ADD COLUMN IF NOT EXISTS `university_id` INT NULL AFTER `semester_id`,
    ADD COLUMN IF NOT EXISTS `status` ENUM('OPEN','PAID','WAIVED','VOID')
        NOT NULL DEFAULT 'OPEN' AFTER `net_balance`;

UPDATE `semester_bills` `sb`
JOIN `passengers` `p` ON `p`.`passenger_id` = `sb`.`passenger_id`
SET `sb`.`university_id` = `p`.`university_id`
WHERE `sb`.`university_id` IS NULL
   OR `sb`.`university_id` <> `p`.`university_id`;

-- Accept either the original dump's uk_passenger_semester name or the newer
-- uq_bill_passenger_semester name. Add a unique key only when no equivalent
-- unique definition exists.
SET @ur_has_bill_unique := (
    SELECT COUNT(*)
    FROM (
        SELECT `index_name`
        FROM `information_schema`.`statistics`
        WHERE `table_schema` = DATABASE()
          AND `table_name` = 'semester_bills'
          AND `non_unique` = 0
        GROUP BY `index_name`
        HAVING GROUP_CONCAT(`column_name` ORDER BY `seq_in_index` SEPARATOR ',')
               = 'passenger_id,semester_id'
    ) `bill_unique_indexes`
);
SET @ur_bill_unique_sql := IF(
    @ur_has_bill_unique = 0,
    'ALTER TABLE `semester_bills` ADD UNIQUE KEY `uq_bill_passenger_semester` (`passenger_id`,`semester_id`)',
    'SELECT 1'
);
PREPARE ur_bill_unique_stmt FROM @ur_bill_unique_sql;
EXECUTE ur_bill_unique_stmt;
DEALLOCATE PREPARE ur_bill_unique_stmt;

SET @ur_has_bill_tenant_index := (
    SELECT COUNT(*)
    FROM `information_schema`.`statistics`
    WHERE `table_schema` = DATABASE()
      AND `table_name` = 'semester_bills'
      AND `index_name` = 'idx_bill_university'
);
SET @ur_bill_tenant_index_sql := IF(
    @ur_has_bill_tenant_index = 0,
    'ALTER TABLE `semester_bills` ADD KEY `idx_bill_university` (`university_id`,`semester_id`)',
    'SELECT 1'
);
PREPARE ur_bill_tenant_index_stmt FROM @ur_bill_tenant_index_sql;
EXECUTE ur_bill_tenant_index_stmt;
DEALLOCATE PREPARE ur_bill_tenant_index_stmt;

SET @ur_has_bill_tenant_fk := (
    SELECT COUNT(*)
    FROM `information_schema`.`key_column_usage`
    WHERE `table_schema` = DATABASE()
      AND `table_name` = 'semester_bills'
      AND `column_name` = 'university_id'
      AND `referenced_table_name` = 'universities'
      AND `referenced_column_name` = 'university_id'
);
SET @ur_bill_tenant_fk_sql := IF(
    @ur_has_bill_tenant_fk = 0,
    'ALTER TABLE `semester_bills` ADD CONSTRAINT `fk_bill_university` FOREIGN KEY (`university_id`) REFERENCES `universities` (`university_id`) ON DELETE SET NULL ON UPDATE CASCADE',
    'SELECT 1'
);
PREPARE ur_bill_tenant_fk_stmt FROM @ur_bill_tenant_fk_sql;
EXECUTE ur_bill_tenant_fk_stmt;
DEALLOCATE PREPARE ur_bill_tenant_fk_stmt;

DROP TRIGGER IF EXISTS `trg_semester_bills_set_university`;
CREATE TRIGGER `trg_semester_bills_set_university`
BEFORE INSERT ON `semester_bills`
FOR EACH ROW
    SET NEW.`university_id` = (
        SELECT `p`.`university_id`
        FROM `passengers` `p`
        WHERE `p`.`passenger_id` = NEW.`passenger_id`
    );

DROP TRIGGER IF EXISTS `trg_semester_bills_sync_university_update`;
CREATE TRIGGER `trg_semester_bills_sync_university_update`
BEFORE UPDATE ON `semester_bills`
FOR EACH ROW
    SET NEW.`university_id` = (
        SELECT `p`.`university_id`
        FROM `passengers` `p`
        WHERE `p`.`passenger_id` = NEW.`passenger_id`
    );

SELECT
    'Core schema consistency migration completed. Ticket transfers were not changed.'
    AS `status`;
