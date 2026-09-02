-- =====================================================================
-- UniRide — migration 003: shared dashboard tenancy features
-- =====================================================================
-- Run after:
--   000_repair_existing_keys.sql
--   001_add_missing_dashboard_tables.sql
--
-- A feature table must identify its university. This allows one shared
-- University Admin page to serve every existing and future university
-- without copying dashboard files or mixing tenant data.
-- =====================================================================

USE `uniride2`;

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `announcements` (
    `announcement_id`   INT          NOT NULL AUTO_INCREMENT,
    `university_id`     INT          NOT NULL,
    `created_by`        INT              NULL,
    `title`             VARCHAR(180) NOT NULL,
    `message`           TEXT         NOT NULL,
    `status`            ENUM('DRAFT','PUBLISHED','ARCHIVED')
                                      NOT NULL DEFAULT 'DRAFT',
    `published_at`      DATETIME          NULL,
    `created_at`        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
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

