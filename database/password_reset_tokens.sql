USE `uniride2`;

CREATE TABLE IF NOT EXISTS `password_reset_tokens` (
    `reset_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `account_type` ENUM(
        'PASSENGER',
        'UNIVERSITY_ADMIN',
        'SYSTEM_ADMIN'
    ) NOT NULL,
    `account_id` INT NOT NULL,
    `token_hash` CHAR(64) NOT NULL,
    `expires_at` DATETIME NOT NULL,
    `used_at` DATETIME DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`reset_id`),
    UNIQUE KEY `uq_reset_token_hash` (`token_hash`),
    KEY `idx_reset_account` (`account_type`, `account_id`),
    KEY `idx_reset_expires` (`expires_at`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
