-- =====================================================================
-- UniRide — migration 007: fixed bus-to-route assignments and shifts
-- =====================================================================
-- Target database : uniride2
-- Run in          : phpMyAdmin -> uniride2 -> SQL tab
-- Run after       : migration 006
--
-- This migration preserves all existing assignment, schedule and booking
-- rows. Where an old bus has several assignment rows, the earliest remains
-- active and the others become read-only history. Legacy schedules keep
-- their original dates and times; only future writes must use the fixed
-- Noon and Evening policy.
-- =====================================================================

USE `uniride2`;

SET NAMES utf8mb4;


-- =====================================================================
-- 1. One active route assignment per bus
-- =====================================================================

ALTER TABLE `bus_route_assignments`
    ADD COLUMN IF NOT EXISTS `is_active` TINYINT(1) NOT NULL DEFAULT 1
        AFTER `route_id`,
    ADD COLUMN IF NOT EXISTS `active_bus_key` INT NULL
        COMMENT 'Mirrors bus_id only for the active assignment'
        AFTER `is_active`;

-- Preserve every old relationship. If a bus appears more than once, retain
-- its earliest assignment as the active, canonical relationship.
UPDATE `bus_route_assignments` `a`
JOIN (
    SELECT `bus_id`, MIN(`assignment_id`) AS `keep_assignment_id`
    FROM `bus_route_assignments`
    WHERE `is_active` = 1
    GROUP BY `bus_id`
    HAVING COUNT(*) > 1
) `duplicates` ON `duplicates`.`bus_id` = `a`.`bus_id`
SET `a`.`is_active` = IF(
    `a`.`assignment_id` = `duplicates`.`keep_assignment_id`,
    1,
    0
)
WHERE `a`.`is_active` = 1;

-- Recover a missing assignment only when the existing schedule history shows
-- exactly one route for that bus. Ambiguous histories are left for a
-- University Admin to resolve by assigning an unassigned bus in the UI.
INSERT INTO `bus_route_assignments`
    (`bus_id`, `route_id`, `is_active`, `active_bus_key`)
SELECT `candidate`.`bus_id`, `candidate`.`route_id`, 1, `candidate`.`bus_id`
FROM (
    SELECT `s`.`bus_id`, MIN(`s`.`route_id`) AS `route_id`
    FROM `schedules` `s`
    INNER JOIN `buses` `b` ON `b`.`bus_id` = `s`.`bus_id`
    INNER JOIN `routes` `r` ON `r`.`route_id` = `s`.`route_id`
    WHERE `b`.`university_id` = `r`.`university_id`
    GROUP BY `s`.`bus_id`
    HAVING COUNT(DISTINCT `s`.`route_id`) = 1
) `candidate`
LEFT JOIN `bus_route_assignments` `active_assignment`
  ON `active_assignment`.`bus_id` = `candidate`.`bus_id`
 AND `active_assignment`.`is_active` = 1
LEFT JOIN `bus_route_assignments` `same_assignment`
  ON `same_assignment`.`bus_id` = `candidate`.`bus_id`
 AND `same_assignment`.`route_id` = `candidate`.`route_id`
WHERE `active_assignment`.`assignment_id` IS NULL
  AND `same_assignment`.`assignment_id` IS NULL;

UPDATE `bus_route_assignments`
SET `active_bus_key` = IF(`is_active` = 1, `bus_id`, NULL)
WHERE NOT (`active_bus_key` <=> IF(`is_active` = 1, `bus_id`, NULL));

SET @ur_has_one_active_route := (
    SELECT COUNT(*)
    FROM `information_schema`.`statistics`
    WHERE `table_schema` = DATABASE()
      AND `table_name` = 'bus_route_assignments'
      AND `index_name` = 'uq_active_assignment_bus'
);
SET @ur_one_active_route_sql := IF(
    @ur_has_one_active_route = 0,
    'ALTER TABLE `bus_route_assignments` ADD UNIQUE KEY `uq_active_assignment_bus` (`active_bus_key`)',
    'SELECT 1'
);
PREPARE ur_one_active_route_stmt FROM @ur_one_active_route_sql;
EXECUTE ur_one_active_route_stmt;
DEALLOCATE PREPARE ur_one_active_route_stmt;

DROP TRIGGER IF EXISTS `trg_bus_route_assign_ins_check`;
DELIMITER $$
CREATE TRIGGER `trg_bus_route_assign_ins_check`
BEFORE INSERT ON `bus_route_assignments`
FOR EACH ROW
BEGIN
    DECLARE v_bus_uni INT DEFAULT NULL;
    DECLARE v_route_uni INT DEFAULT NULL;
    DECLARE v_active_count INT DEFAULT 0;

    SET v_bus_uni = (
        SELECT `university_id` FROM `buses` WHERE `bus_id` = NEW.`bus_id`
    );
    SET v_route_uni = (
        SELECT `university_id` FROM `routes` WHERE `route_id` = NEW.`route_id`
    );

    IF v_bus_uni IS NULL OR v_route_uni IS NULL OR v_bus_uni <> v_route_uni THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Bus and route must belong to the same university.';
    END IF;

    IF NEW.`is_active` <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'New bus-to-route assignments must be active.';
    END IF;

    IF NEW.`is_active` = 1 THEN
        SELECT COUNT(*) INTO v_active_count
        FROM `bus_route_assignments`
        WHERE `bus_id` = NEW.`bus_id` AND `is_active` = 1;

        IF v_active_count > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'This bus already has an active route assignment.';
        END IF;
    END IF;

    SET NEW.`active_bus_key` = IF(NEW.`is_active` = 1, NEW.`bus_id`, NULL);
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_bus_route_assign_upd_check`;
DELIMITER $$
CREATE TRIGGER `trg_bus_route_assign_upd_check`
BEFORE UPDATE ON `bus_route_assignments`
FOR EACH ROW
BEGIN
    DECLARE v_active_count INT DEFAULT 0;

    IF NEW.`bus_id` <> OLD.`bus_id`
       OR NEW.`route_id` <> OLD.`route_id`
       OR NEW.`is_active` <> OLD.`is_active` THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A bus-to-route assignment is permanent and cannot be changed.';
    END IF;

    IF NEW.`is_active` = 1 THEN
        SELECT COUNT(*) INTO v_active_count
        FROM `bus_route_assignments`
        WHERE `bus_id` = NEW.`bus_id`
          AND `is_active` = 1
          AND `assignment_id` <> OLD.`assignment_id`;

        IF v_active_count > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'This bus already has an active route assignment.';
        END IF;
    END IF;

    SET NEW.`active_bus_key` = IF(NEW.`is_active` = 1, NEW.`bus_id`, NULL);
END$$
DELIMITER ;


-- =====================================================================
-- 2. Two fixed schedule shifts
-- =====================================================================

ALTER TABLE `schedules`
    ADD COLUMN IF NOT EXISTS `shift_name` ENUM('NOON','EVENING') NULL
        AFTER `schedule_date`;

-- Backfill only unambiguous rows that already use a fixed departure and the
-- bus's active route. Arbitrary legacy schedule times remain NULL and are
-- preserved for historical bookings.
UPDATE `schedules` `s`
JOIN `bus_route_assignments` `a`
  ON `a`.`bus_id` = `s`.`bus_id`
 AND `a`.`route_id` = `s`.`route_id`
 AND `a`.`is_active` = 1
JOIN (
    SELECT `bus_id`, `schedule_date`, `departure_time`, MIN(`schedule_id`) AS `keep_schedule_id`
    FROM `schedules`
    WHERE `departure_time` IN ('14:00:00','17:10:00')
    GROUP BY `bus_id`, `schedule_date`, `departure_time`
) `fixed_rows`
  ON `fixed_rows`.`bus_id` = `s`.`bus_id`
 AND `fixed_rows`.`schedule_date` = `s`.`schedule_date`
 AND `fixed_rows`.`departure_time` = `s`.`departure_time`
 AND `fixed_rows`.`keep_schedule_id` = `s`.`schedule_id`
LEFT JOIN (
    SELECT `bus_id`, `schedule_date`, `shift_name`
    FROM `schedules`
    WHERE `shift_name` IS NOT NULL
    GROUP BY `bus_id`, `schedule_date`, `shift_name`
) `existing_shift`
  ON `existing_shift`.`bus_id` = `s`.`bus_id`
 AND `existing_shift`.`schedule_date` = `s`.`schedule_date`
 AND `existing_shift`.`shift_name` = CASE `s`.`departure_time`
    WHEN '14:00:00' THEN 'NOON'
    WHEN '17:10:00' THEN 'EVENING'
    ELSE NULL
 END
SET `s`.`shift_name` = CASE `s`.`departure_time`
    WHEN '14:00:00' THEN 'NOON'
    WHEN '17:10:00' THEN 'EVENING'
    ELSE NULL
END
WHERE `s`.`shift_name` IS NULL
  AND `existing_shift`.`bus_id` IS NULL;

-- If a partially applied older attempt produced duplicate shift metadata,
-- keep the earliest row canonical without deleting any schedule.
UPDATE `schedules` `s`
JOIN (
    SELECT `bus_id`, `schedule_date`, `shift_name`, MIN(`schedule_id`) AS `keep_schedule_id`
    FROM `schedules`
    WHERE `shift_name` IS NOT NULL
    GROUP BY `bus_id`, `schedule_date`, `shift_name`
    HAVING COUNT(*) > 1
) `duplicates`
  ON `duplicates`.`bus_id` = `s`.`bus_id`
 AND `duplicates`.`schedule_date` = `s`.`schedule_date`
 AND `duplicates`.`shift_name` = `s`.`shift_name`
SET `s`.`shift_name` = NULL
WHERE `s`.`schedule_id` <> `duplicates`.`keep_schedule_id`;

SET @ur_has_fixed_shift_unique := (
    SELECT COUNT(*)
    FROM `information_schema`.`statistics`
    WHERE `table_schema` = DATABASE()
      AND `table_name` = 'schedules'
      AND `index_name` = 'uq_bus_date_shift'
);
SET @ur_fixed_shift_unique_sql := IF(
    @ur_has_fixed_shift_unique = 0,
    'ALTER TABLE `schedules` ADD UNIQUE KEY `uq_bus_date_shift` (`bus_id`,`schedule_date`,`shift_name`)',
    'SELECT 1'
);
PREPARE ur_fixed_shift_unique_stmt FROM @ur_fixed_shift_unique_sql;
EXECUTE ur_fixed_shift_unique_stmt;
DEALLOCATE PREPARE ur_fixed_shift_unique_stmt;

SET @ur_has_shift_order_index := (
    SELECT COUNT(*)
    FROM `information_schema`.`statistics`
    WHERE `table_schema` = DATABASE()
      AND `table_name` = 'schedules'
      AND `index_name` = 'idx_route_date_shift'
);
SET @ur_shift_order_index_sql := IF(
    @ur_has_shift_order_index = 0,
    'ALTER TABLE `schedules` ADD KEY `idx_route_date_shift` (`route_id`,`schedule_date`,`shift_name`)',
    'SELECT 1'
);
PREPARE ur_shift_order_index_stmt FROM @ur_shift_order_index_sql;
EXECUTE ur_shift_order_index_stmt;
DEALLOCATE PREPARE ur_shift_order_index_stmt;

DROP TRIGGER IF EXISTS `trg_schedule_fixed_shift_insert`;
DELIMITER $$
CREATE TRIGGER `trg_schedule_fixed_shift_insert`
BEFORE INSERT ON `schedules`
FOR EACH ROW
BEGIN
    DECLARE v_assignment_count INT DEFAULT 0;
    DECLARE v_conflict_count INT DEFAULT 0;

    IF NEW.`shift_name` IS NULL
       OR NEW.`shift_name` NOT IN ('NOON','EVENING')
       OR (NEW.`shift_name` = 'NOON' AND NEW.`departure_time` <> '14:00:00')
       OR (NEW.`shift_name` = 'EVENING' AND NEW.`departure_time` <> '17:10:00') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Schedules must use Noon at 14:00 or Evening at 17:10.';
    END IF;

    SELECT COUNT(*) INTO v_assignment_count
    FROM `bus_route_assignments`
    WHERE `bus_id` = NEW.`bus_id`
      AND `route_id` = NEW.`route_id`
      AND `is_active` = 1;

    IF v_assignment_count <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Schedule bus and route must match one active assignment.';
    END IF;

    IF NEW.`arrival_time` <= NEW.`departure_time` THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Schedule arrival must be after departure.';
    END IF;

    IF NEW.`status` <> 'CANCELLED' THEN
        SELECT COUNT(*) INTO v_conflict_count
        FROM `schedules`
        WHERE `bus_id` = NEW.`bus_id`
          AND `schedule_date` = NEW.`schedule_date`
          AND `status` <> 'CANCELLED'
          AND `departure_time` < NEW.`arrival_time`
          AND `arrival_time` > NEW.`departure_time`;

        IF v_conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'This bus already has an overlapping schedule.';
        END IF;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS `trg_schedule_fixed_shift_update`;
DELIMITER $$
CREATE TRIGGER `trg_schedule_fixed_shift_update`
BEFORE UPDATE ON `schedules`
FOR EACH ROW
BEGIN
    DECLARE v_assignment_count INT DEFAULT 0;
    DECLARE v_conflict_count INT DEFAULT 0;
    DECLARE v_schedule_changed TINYINT DEFAULT 0;

    SET v_schedule_changed =
        NOT (NEW.`bus_id` <=> OLD.`bus_id`)
        OR NOT (NEW.`route_id` <=> OLD.`route_id`)
        OR NOT (NEW.`schedule_date` <=> OLD.`schedule_date`)
        OR NOT (NEW.`departure_time` <=> OLD.`departure_time`)
        OR NOT (NEW.`shift_name` <=> OLD.`shift_name`);

    IF NEW.`shift_name` IS NOT NULL OR v_schedule_changed = 1 THEN
        IF NEW.`shift_name` IS NULL
           OR NEW.`shift_name` NOT IN ('NOON','EVENING')
           OR (NEW.`shift_name` = 'NOON' AND NEW.`departure_time` <> '14:00:00')
           OR (NEW.`shift_name` = 'EVENING' AND NEW.`departure_time` <> '17:10:00') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Schedules must use Noon at 14:00 or Evening at 17:10.';
        END IF;

        SELECT COUNT(*) INTO v_assignment_count
        FROM `bus_route_assignments`
        WHERE `bus_id` = NEW.`bus_id`
          AND `route_id` = NEW.`route_id`
          AND `is_active` = 1;

        IF v_assignment_count <> 1 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Schedule bus and route must match one active assignment.';
        END IF;

        IF NEW.`arrival_time` <= NEW.`departure_time` THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Schedule arrival must be after departure.';
        END IF;

        IF NEW.`status` <> 'CANCELLED' THEN
            SELECT COUNT(*) INTO v_conflict_count
            FROM `schedules`
            WHERE `bus_id` = NEW.`bus_id`
              AND `schedule_date` = NEW.`schedule_date`
              AND `schedule_id` <> OLD.`schedule_id`
              AND `status` <> 'CANCELLED'
              AND `departure_time` < NEW.`arrival_time`
              AND `arrival_time` > NEW.`departure_time`;

            IF v_conflict_count > 0 THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'This bus already has an overlapping schedule.';
            END IF;
        END IF;
    END IF;
END$$
DELIMITER ;

SELECT
    'Fixed bus-to-route assignments and Noon/Evening shifts are enabled.'
    AS `status`;
