<?php
declare(strict_types=1);

if (!defined('PROFILE_PICTURE_MAX_BYTES')) {
    define('PROFILE_PICTURE_MAX_BYTES', 2 * 1024 * 1024);
}

/** Central role and notification configuration for every profile page. */
function profile_role_config(string $role): array
{
    $role = strtoupper($role);
    $common = [
        'master_notifications' => ['label' => 'All optional notifications', 'description' => 'Master control for non-security messages.', 'essential' => false],
        'dashboard_notifications' => ['label' => 'Dashboard notifications', 'description' => 'Show relevant updates inside UniRide.', 'essential' => false],
        'email_notifications' => ['label' => 'Email notifications', 'description' => 'Send permitted updates to the verified account email.', 'essential' => false],
        'security_alerts' => ['label' => 'Security alerts', 'description' => 'Critical protection and account-access warnings.', 'essential' => true],
        'password_changes' => ['label' => 'Password-change alerts', 'description' => 'Always notify when the account password changes.', 'essential' => true],
        'suspicious_logins' => ['label' => 'Suspicious-login alerts', 'description' => 'Warn about unusual or newly observed sign-ins.', 'essential' => true],
        'profile_updates' => ['label' => 'Profile updates', 'description' => 'Confirm changes to personal and contact information.', 'essential' => false],
        'service_announcements' => ['label' => 'Service announcements', 'description' => 'Important information about UniRide services.', 'essential' => false],
        'platform_maintenance' => ['label' => 'Platform maintenance', 'description' => 'Planned downtime and availability notices.', 'essential' => false],
    ];

    $roles = [
        'PASSENGER' => [
            'label' => 'Passenger', 'table' => 'passengers', 'id_column' => 'passenger_id',
            'password_column' => 'password_hash', 'dashboard' => 'passenger/dashboard.php',
            'notifications' => [
                'booking_updates' => ['label' => 'Booking updates', 'description' => 'Booking confirmations, changes and cancellations.'],
                'schedule_changes' => ['label' => 'Schedule changes', 'description' => 'Departure, route and cancellation alerts.'],
                'ticket_transfers' => ['label' => 'Ticket transfers', 'description' => 'Transfer requests and completion updates.'],
                'semester_billing' => ['label' => 'Semester billing', 'description' => 'Transport charges, credits and billing updates.'],
                'complaint_responses' => ['label' => 'Complaint responses', 'description' => 'Updates from your university transport team.'],
            ],
        ],
        'UNIVERSITY_ADMIN' => [
            'label' => 'University Admin', 'table' => 'university_users', 'id_column' => 'university_user_id',
            'password_column' => 'password_hash', 'dashboard' => 'university/dashboard.php',
            'notifications' => [
                'passenger_registrations' => ['label' => 'Passenger registrations', 'description' => 'New student and faculty passenger records.'],
                'booking_activity' => ['label' => 'Booking activity', 'description' => 'University booking and demand updates.'],
                'capacity_warnings' => ['label' => 'Capacity warnings', 'description' => 'Trips approaching or exceeding capacity.'],
                'complaints' => ['label' => 'Complaints', 'description' => 'New and escalated passenger complaints.'],
                'schedule_changes' => ['label' => 'Schedule changes', 'description' => 'Operational trip and timetable changes.'],
                'fleet_route_changes' => ['label' => 'Bus and route changes', 'description' => 'Fleet, route and stop configuration updates.'],
                'announcement_activity' => ['label' => 'Announcement activity', 'description' => 'Publishing and delivery status.'],
                'verification_events' => ['label' => 'Verification events', 'description' => 'Student and faculty verification activity.'],
                'transport_events' => ['label' => 'Important transport events', 'description' => 'High-priority university transport notices.'],
            ],
        ],
        'SYSTEM_ADMIN' => [
            'label' => 'System Admin', 'table' => 'admins', 'id_column' => 'admin_id',
            'password_column' => 'password', 'dashboard' => 'admin/dashboard.php',
            'notifications' => [
                'university_created' => ['label' => 'New universities', 'description' => 'University onboarding events.'],
                'university_status' => ['label' => 'University status changes', 'description' => 'Activation and deactivation events.'],
                'admin_accounts' => ['label' => 'University Admin accounts', 'description' => 'New or updated administrator accounts.'],
                'account_suspensions' => ['label' => 'Account suspensions', 'description' => 'Important account enforcement events.'],
                'failed_logins' => ['label' => 'Repeated failed logins', 'description' => 'Possible brute-force or credential attacks.'],
                'platform_activity' => ['label' => 'Suspicious platform activity', 'description' => 'High-risk system administration events.'],
                'database_warnings' => ['label' => 'Database warnings', 'description' => 'Important integrity and availability notices.'],
            ],
        ],
    ];

    $config = $roles[$role] ?? $roles['PASSENGER'];
    $config['role'] = $role;
    $config['notifications'] = array_merge($common, $config['notifications']);
    foreach ($config['notifications'] as $key => $definition) {
        $config['notifications'][$key]['essential'] = (bool)($definition['essential'] ?? false);
    }
    return $config;
}

function profile_identity(): array
{
    $role = strtoupper((string)($_SESSION['user_type'] ?? ''));
    $id = match ($role) {
        'PASSENGER' => (int)($_SESSION['passenger_id'] ?? $_SESSION['user_id'] ?? 0),
        'UNIVERSITY_ADMIN' => (int)($_SESSION['university_user_id'] ?? $_SESSION['user_id'] ?? 0),
        'SYSTEM_ADMIN' => (int)($_SESSION['admin_id'] ?? $_SESSION['user_id'] ?? 0),
        default => 0,
    };
    return ['role' => $role, 'user_id' => $id];
}
