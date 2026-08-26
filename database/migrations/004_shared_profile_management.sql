-- UniRide shared profile management
-- Non-destructive and safe to run more than once on an existing uniride2 DB.

CREATE TABLE IF NOT EXISTS user_profiles (
    profile_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_type ENUM('PASSENGER','UNIVERSITY_ADMIN','SYSTEM_ADMIN') NOT NULL,
    user_id INT NOT NULL,
    phone VARCHAR(30) NULL,
    address VARCHAR(500) NULL,
    date_of_birth DATE NULL,
    gender VARCHAR(30) NULL,
    emergency_contact_name VARCHAR(200) NULL,
    emergency_contact_phone VARCHAR(30) NULL,
    profile_picture_path VARCHAR(500) NULL,
    preferred_boarding_stop VARCHAR(200) NULL,
    preferred_destination_stop VARCHAR(200) NULL,
    seat_preference ENUM('SEAT','STANDING','NO_PREFERENCE') NOT NULL DEFAULT 'NO_PREFERENCE',
    job_title VARCHAR(150) NULL,
    department VARCHAR(200) NULL,
    office_phone VARCHAR(30) NULL,
    office_location VARCHAR(250) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (profile_id),
    UNIQUE KEY uq_user_profiles_identity (user_type, user_id),
    KEY idx_user_profiles_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_notification_preferences (
    preference_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_type ENUM('PASSENGER','UNIVERSITY_ADMIN','SYSTEM_ADMIN') NOT NULL,
    user_id INT NOT NULL,
    preference_key VARCHAR(80) NOT NULL,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (preference_id),
    UNIQUE KEY uq_notification_preference (user_type, user_id, preference_key),
    KEY idx_notification_identity (user_type, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_sessions (
    session_record_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_type ENUM('PASSENGER','UNIVERSITY_ADMIN','SYSTEM_ADMIN') NOT NULL,
    user_id INT NOT NULL,
    session_token_hash CHAR(64) NOT NULL,
    user_agent VARCHAR(500) NULL,
    ip_address VARCHAR(45) NULL,
    logged_in_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (session_record_id),
    UNIQUE KEY uq_session_token_hash (session_token_hash),
    KEY idx_session_identity_active (user_type, user_id, revoked_at),
    KEY idx_session_activity (last_activity_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_security_events (
    security_event_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_type ENUM('PASSENGER','UNIVERSITY_ADMIN','SYSTEM_ADMIN') NOT NULL,
    user_id INT NOT NULL,
    event_type VARCHAR(80) NOT NULL,
    event_description VARCHAR(500) NOT NULL,
    ip_address VARCHAR(45) NULL,
    user_agent VARCHAR(500) NULL,
    occurred_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (security_event_id),
    KEY idx_security_identity_time (user_type, user_id, occurred_at),
    KEY idx_security_event_time (event_type, occurred_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Existing accounts receive a profile row without changing their account data.
INSERT IGNORE INTO user_profiles (user_type, user_id, phone)
SELECT 'PASSENGER', passenger_id, phone FROM passengers;

INSERT IGNORE INTO user_profiles (user_type, user_id)
SELECT 'UNIVERSITY_ADMIN', university_user_id FROM university_users;

INSERT IGNORE INTO user_profiles (user_type, user_id)
SELECT 'SYSTEM_ADMIN', admin_id FROM admins;

-- Common notification defaults for existing accounts. The application also
-- supplies these defaults lazily for every account created in the future.
INSERT IGNORE INTO user_notification_preferences (user_type, user_id, preference_key, enabled)
SELECT identities.user_type, identities.user_id, preferences.preference_key, 1
FROM (
    SELECT 'PASSENGER' user_type, passenger_id user_id FROM passengers
    UNION ALL SELECT 'UNIVERSITY_ADMIN', university_user_id FROM university_users
    UNION ALL SELECT 'SYSTEM_ADMIN', admin_id FROM admins
) identities
CROSS JOIN (
    SELECT 'master_notifications' preference_key
    UNION ALL SELECT 'dashboard_notifications'
    UNION ALL SELECT 'email_notifications'
    UNION ALL SELECT 'security_alerts'
    UNION ALL SELECT 'password_changes'
    UNION ALL SELECT 'suspicious_logins'
    UNION ALL SELECT 'profile_updates'
    UNION ALL SELECT 'service_announcements'
    UNION ALL SELECT 'platform_maintenance'
) preferences
WHERE identities.user_type <> 'PASSENGER'
   OR preferences.preference_key NOT IN ('dashboard_notifications','email_notifications');

-- Preserve the Passenger switches already used by the current application.
INSERT IGNORE INTO user_notification_preferences (user_type, user_id, preference_key, enabled)
SELECT 'PASSENGER', passenger_id, 'dashboard_notifications', in_app_notifications FROM passengers;

INSERT IGNORE INTO user_notification_preferences (user_type, user_id, preference_key, enabled)
SELECT 'PASSENGER', passenger_id, 'email_notifications', email_notifications FROM passengers;

-- Seed the role-aware categories for current accounts. INSERT IGNORE keeps the
-- migration repeatable and never overwrites choices saved after installation.
INSERT IGNORE INTO user_notification_preferences (user_type, user_id, preference_key, enabled)
SELECT 'PASSENGER', p.passenger_id, preferences.preference_key, 1
FROM passengers p
CROSS JOIN (
    SELECT 'booking_updates' preference_key
    UNION ALL SELECT 'schedule_changes'
    UNION ALL SELECT 'ticket_transfers'
    UNION ALL SELECT 'semester_billing'
    UNION ALL SELECT 'complaint_responses'
) preferences;

INSERT IGNORE INTO user_notification_preferences (user_type, user_id, preference_key, enabled)
SELECT 'UNIVERSITY_ADMIN', uu.university_user_id, preferences.preference_key, 1
FROM university_users uu
CROSS JOIN (
    SELECT 'passenger_registrations' preference_key
    UNION ALL SELECT 'booking_activity'
    UNION ALL SELECT 'capacity_warnings'
    UNION ALL SELECT 'complaints'
    UNION ALL SELECT 'schedule_changes'
    UNION ALL SELECT 'fleet_route_changes'
    UNION ALL SELECT 'announcement_activity'
    UNION ALL SELECT 'verification_events'
    UNION ALL SELECT 'transport_events'
) preferences;

INSERT IGNORE INTO user_notification_preferences (user_type, user_id, preference_key, enabled)
SELECT 'SYSTEM_ADMIN', a.admin_id, preferences.preference_key, 1
FROM admins a
CROSS JOIN (
    SELECT 'university_created' preference_key
    UNION ALL SELECT 'university_status'
    UNION ALL SELECT 'admin_accounts'
    UNION ALL SELECT 'account_suspensions'
    UNION ALL SELECT 'failed_logins'
    UNION ALL SELECT 'platform_activity'
    UNION ALL SELECT 'database_warnings'
) preferences;
