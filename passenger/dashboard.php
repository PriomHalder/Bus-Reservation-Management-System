<?php
declare(strict_types=1);

session_start();

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/dashboard/nav.php';
require_once __DIR__ . '/../includes/booking-service.php';
require_once __DIR__ . '/../includes/profile/session-management.php';
require_once __DIR__ . '/../includes/theme.php';

if (empty($_SESSION['authenticated'])) {
    header('Location: ../signin.php');
    exit;
}

if (($_SESSION['user_type'] ?? '') !== 'PASSENGER') {
    header('Location: ../dashboard.php');
    exit;
}

date_default_timezone_set('Asia/Dhaka');

function pd_h(mixed $value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

function pd_one(PDO $pdo, string $sql, array $params = []): array
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetch() ?: [];
}

function pd_all(PDO $pdo, string $sql, array $params = []): array
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll();
}

function pd_scalar(PDO $pdo, string $sql, array $params = []): mixed
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchColumn();
}

function pd_table_exists(PDO $pdo, string $table): bool
{
    $stmt = $pdo->prepare(
        "SELECT COUNT(*)
         FROM information_schema.tables
         WHERE table_schema = DATABASE()
           AND table_name = ?"
    );
    $stmt->execute([$table]);
    return (int)$stmt->fetchColumn() > 0;
}

function pd_status_class(string $status): string
{
    return match (strtoupper($status)) {
        'BOOKED', 'CONFIRMED', 'ACTIVE', 'RESOLVED', 'COMPLETED' => 'is-good',
        'TRANSFER_PENDING', 'OPEN', 'IN_PROGRESS', 'PENDING' => 'is-warn',
        'CANCELLED', 'CLOSED', 'REJECTED', 'SUSPENDED' => 'is-muted',
        default => 'is-muted',
    };
}

function pd_seat_label(array $booking): string
{
    if (($booking['slot_type'] ?? '') === 'STANDING') {
        $slot = (int)($booking['standing_slot'] ?? 0);
        return $slot > 0 ? 'Standing ' . $slot : 'Standing';
    }

    $seat = (int)($booking['seat_number'] ?? 0);
    if ($seat <= 0) {
        return 'Seat';
    }

    $row = intdiv($seat - 1, 4);
    $column = (($seat - 1) % 4) + 1;
    return chr(65 + $row) . $column;
}

function pd_time(string|null $time): string
{
    if (!$time) {
        return '—';
    }

    $ts = strtotime($time);
    return $ts ? date('g:i A', $ts) : $time;
}

function pd_page(array $candidates, string $fallback): string
{
    foreach ($candidates as $candidate) {
        if (is_file(__DIR__ . '/' . $candidate)) {
            return $candidate;
        }
    }

    return $fallback;
}

$passengerId = (int)($_SESSION['passenger_id'] ?? $_SESSION['user_id'] ?? 0);
$sessionUniversityId = (int)($_SESSION['university_id'] ?? 0);

if ($passengerId <= 0) {
    session_destroy();
    header('Location: ../signin.php');
    exit;
}
profile_enforce_session($pdo, '..');

$profile = [];
$subtype = [];
$semester = [];
$activeBookings = [];
$favoriteRoutes = [];
$availableSchedules = [];
$notifications = [];
$complaints = [];
$dashboardError = '';

$stats = [
    'active_bookings' => 0,
    'favorites' => 0,
    'unread_notifications' => 0,
    'open_complaints' => 0,
    'booking_history' => 0,
    'transfers' => 0,
    'semester_balance' => 0.0,
];

try {
    $profile = pd_one(
        $pdo,
        "SELECT
            p.passenger_id,
            p.university_id,
            p.name,
            p.email,
            p.passenger_type,
            p.phone,
            p.status,
            u.code AS university_code,
            u.name AS university_name,
            u.contact_email AS university_contact,
            u.status AS university_status
         FROM passengers p
         INNER JOIN universities u
            ON u.university_id = p.university_id
         WHERE p.passenger_id = ?
         LIMIT 1",
        [$passengerId]
    );

    if (!$profile) {
        http_response_code(403);
        uniride_render_error_page('Passenger account not found.', '..');
    }

    if (
        $sessionUniversityId > 0 &&
        (int)$profile['university_id'] !== $sessionUniversityId
    ) {
        http_response_code(403);
        uniride_render_error_page('Passenger session does not match the account university.', '..');
    }

    if (
        strtoupper((string)$profile['status']) !== 'ACTIVE'
        || strtoupper((string)$profile['university_status']) !== 'ACTIVE'
    ) {
        http_response_code(403);
        uniride_render_error_page('This passenger account is currently unavailable.', '..');
    }

    if ($profile['passenger_type'] === 'STUDENT') {
        $subtype = pd_one(
            $pdo,
            "SELECT
                student_identifier AS identifier,
                department,
                program AS role_detail,
                semester_label
             FROM students
             WHERE passenger_id = ?
             LIMIT 1",
            [$passengerId]
        );
    } else {
        $subtype = pd_one(
            $pdo,
            "SELECT
                faculty_identifier AS identifier,
                department,
                designation AS role_detail,
                NULL AS semester_label
             FROM faculty
             WHERE passenger_id = ?
             LIMIT 1",
            [$passengerId]
        );
    }

    $semester = pd_one(
        $pdo,
        "SELECT semester_id, semester_name, start_date, end_date
         FROM semesters
         WHERE is_active = 1
         ORDER BY start_date DESC
         LIMIT 1"
    );

    $stats['active_bookings'] = (int)pd_scalar(
        $pdo,
        "SELECT COUNT(DISTINCT b.booking_id)
         FROM bookings b
         INNER JOIN schedules s
            ON s.schedule_id = b.schedule_id
         INNER JOIN routes r
            ON r.route_id = s.route_id
         WHERE b.passenger_id = ?
           AND r.university_id = ?
           AND b.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')
           AND s.status <> 'CANCELLED'
           AND s.schedule_date >= CURDATE()",
        [$passengerId, (int)$profile['university_id']]
    );

    $stats['favorites'] = (int)pd_scalar(
        $pdo,
        "SELECT COUNT(DISTINCT fr.favorite_id)
         FROM favorite_routes fr
         INNER JOIN routes r
            ON r.route_id = fr.route_id
         WHERE fr.passenger_id = ?
           AND r.university_id = ?",
        [$passengerId, (int)$profile['university_id']]
    );

    $stats['unread_notifications'] = (int)pd_scalar(
        $pdo,
        "SELECT COUNT(*)
         FROM notifications
         WHERE passenger_id = ?
           AND is_read = 0",
        [$passengerId]
    );

    $stats['open_complaints'] = (int)pd_scalar(
        $pdo,
        "SELECT COUNT(*)
         FROM complaints
         WHERE passenger_id = ?
           AND university_id = ?
           AND status IN ('OPEN','IN_PROGRESS')",
        [$passengerId, (int)$profile['university_id']]
    );

    $stats['booking_history'] = (int)pd_scalar(
        $pdo,
        "SELECT COUNT(*)
         FROM bookings
         WHERE passenger_id = ?",
        [$passengerId]
    );

    if (pd_table_exists($pdo, 'ticket_transfers')) {
        $stats['transfers'] = (int)pd_scalar(
            $pdo,
            "SELECT COUNT(*)
             FROM ticket_transfers
             WHERE from_passenger_id = ?
                OR to_passenger_id = ?",
            [$passengerId, $passengerId]
        );
    }

    if ($semester) {
        if (pd_table_exists($pdo, 'semester_bills')) {
            $bill = pd_one(
                $pdo,
                "SELECT net_balance
                 FROM semester_bills
                 WHERE passenger_id = ?
                   AND semester_id = ?
                 LIMIT 1",
                [$passengerId, (int)$semester['semester_id']]
            );
            $stats['semester_balance'] = (float)($bill['net_balance'] ?? 0);
        } else {
            $stats['semester_balance'] = (float)pd_scalar(
                $pdo,
                "SELECT COALESCE(SUM(amount), 0)
                 FROM billing_transactions
                 WHERE passenger_id = ?
                   AND semester_id = ?",
                [$passengerId, (int)$semester['semester_id']]
            );
        }
    }

    $activeBookings = pd_all(
        $pdo,
        "SELECT
            b.booking_id,
            b.booking_reference,
            b.slot_type,
            b.seat_number,
            b.standing_slot,
            b.fare_charged,
            b.status,
            b.qr_token,
            s.schedule_date,
            s.departure_time,
            s.arrival_time,
            r.route_code,
            r.route_name,
            r.start_location,
            r.end_location,
            bus.registration_number,
            bus.bus_type
         FROM bookings b
         INNER JOIN schedules s
            ON s.schedule_id = b.schedule_id
         INNER JOIN routes r
            ON r.route_id = s.route_id
         INNER JOIN buses bus
            ON bus.bus_id = s.bus_id
         WHERE b.passenger_id = ?
           AND r.university_id = ?
           AND b.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')
           AND s.status <> 'CANCELLED'
           AND s.schedule_date >= CURDATE()
         ORDER BY s.schedule_date, s.departure_time
         LIMIT 3",
        [$passengerId, (int)$profile['university_id']]
    );

    $favoriteRoutes = pd_all(
        $pdo,
        "SELECT
            r.route_id,
            r.route_code,
            r.route_name,
            r.start_location,
            r.end_location,
            r.fare,
            MIN(CASE
                WHEN s.status = 'SCHEDULED'
                 AND s.schedule_date >= CURDATE()
                THEN CONCAT(s.schedule_date, ' ', s.departure_time)
                ELSE NULL
            END) AS next_departure
         FROM favorite_routes fr
         INNER JOIN routes r
            ON r.route_id = fr.route_id
         LEFT JOIN schedules s
            ON s.route_id = r.route_id
         WHERE fr.passenger_id = ?
           AND r.university_id = ?
           AND r.status = 'ACTIVE'
         GROUP BY
            r.route_id,
            r.route_code,
            r.route_name,
            r.start_location,
            r.end_location,
            r.fare,
            fr.created_at
         ORDER BY fr.created_at DESC
         LIMIT 4",
        [$passengerId, (int)$profile['university_id']]
    );

    $availableSchedules = pd_all(
        $pdo,
        "SELECT
            s.schedule_id,
            s.schedule_date,
            s.departure_time,
            s.arrival_time,
            r.route_code,
            r.route_name,
            r.start_location,
            r.end_location,
            r.fare,
            bus.registration_number,
            bus.bus_type,
            bus.seat_capacity,
            bus.standing_capacity,
            COALESCE(SUM(CASE
                WHEN bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')
                 AND bk.slot_type = 'SEAT'
                THEN 1 ELSE 0 END), 0) AS booked_seats,
            COALESCE(SUM(CASE
                WHEN bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')
                 AND bk.slot_type = 'STANDING'
                THEN 1 ELSE 0 END), 0) AS booked_standing
         FROM schedules s
         INNER JOIN routes r
            ON r.route_id = s.route_id
         INNER JOIN buses bus
            ON bus.bus_id = s.bus_id
         LEFT JOIN bookings bk
            ON bk.schedule_id = s.schedule_id
         WHERE r.university_id = ?
           AND r.status = 'ACTIVE'
           AND s.status = 'SCHEDULED'
           AND s.schedule_date >= CURDATE()
           AND (
                bus.bus_type = 'STANDARD'
                OR (? = 'STUDENT' AND bus.bus_type = 'STUDENT_ONLY')
                OR (? = 'FACULTY' AND bus.bus_type = 'FACULTY_ONLY')
           )
         GROUP BY
            s.schedule_id,
            s.schedule_date,
            s.departure_time,
            s.arrival_time,
            r.route_code,
            r.route_name,
            r.start_location,
            r.end_location,
            r.fare,
            bus.registration_number,
            bus.bus_type,
            bus.seat_capacity,
            bus.standing_capacity
         ORDER BY s.schedule_date, s.departure_time
         LIMIT 6",
        [
            (int)$profile['university_id'],
            (string)$profile['passenger_type'],
            (string)$profile['passenger_type'],
        ]
    );

    $notifications = pd_all(
        $pdo,
        "SELECT
            notification_id,
            title,
            message,
            notification_type,
            is_read,
            created_at
         FROM notifications
         WHERE passenger_id = ?
         ORDER BY is_read ASC, created_at DESC
         LIMIT 5",
        [$passengerId]
    );

    $complaints = pd_all(
        $pdo,
        "SELECT
            complaint_id,
            subject,
            status,
            university_response,
            submitted_at,
            updated_at
         FROM complaints
         WHERE passenger_id = ?
           AND university_id = ?
         ORDER BY updated_at DESC, complaint_id DESC
         LIMIT 4",
        [$passengerId, (int)$profile['university_id']]
    );
} catch (Throwable $e) {
    error_log('[UniRide Passenger dashboard] ' . $e->getMessage());
    $dashboardError = 'Some dashboard information is temporarily unavailable.';
}

$name = (string)($profile['name'] ?? $_SESSION['name'] ?? 'Passenger');
$firstName = trim(explode(' ', $name)[0] ?? $name);
$universityCode = (string)($profile['university_code'] ?? 'University');
$universityName = (string)($profile['university_name'] ?? 'University');
$passengerType = ucfirst(strtolower((string)($profile['passenger_type'] ?? 'Passenger')));
$semesterName = (string)($semester['semester_name'] ?? ($subtype['semester_label'] ?? 'Current semester'));
$roleDetail = (string)($subtype['role_detail'] ?? '');
$department = (string)($subtype['department'] ?? '');
$identifier = (string)($subtype['identifier'] ?? '');

$bookPage = pd_page(['book-ticket.php', 'book.php'], '#available-rides');
$bookingsPage = pd_page(['my-bookings.php', 'bookings.php'], '#my-trip');
$routesPage = pd_page(['routes.php', 'routes-schedules.php', 'schedules.php'], '#available-rides');
$favoritesPage = pd_page(['favorite-routes.php', 'favorites.php'], '#favorites');
$transfersPage = pd_page(['ticket-transfers.php', 'transfers.php'], '#account-summary');
$complaintsPage = pd_page(['complaints.php'], '#complaints');
$billingPage = pd_page(['semester-billing.php', 'billing.php'], '#billing');
$notificationsPage = pd_page(['notifications.php'], '#notifications');
$profilePage = pd_page(['profile.php'], '#profile-summary');
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="UniRide passenger dashboard">
    <title>Passenger Dashboard — UniRide</title>
    <?= uniride_theme_head_html('..') ?>
    <link rel="icon" type="image/svg+xml" href="../img/logo.svg">

    <style>
        :root {
            --pr-blue: #123f7c;
            --pr-blue-dark: #0b2f61;
            --pr-blue-soft: #eef4fb;
            --pr-blue-pale: #f7faff;
            --pr-ink: #17191c;
            --pr-muted: #747980;
            --pr-line: #e5e8ec;
            --pr-soft: #f6f7f8;
            --pr-white: #ffffff;
            --pr-good: #176536;
            --pr-good-bg: #eff8f1;
            --pr-warn: #8a5a00;
            --pr-warn-bg: #fff8e8;
            --pr-radius: 14px;
            --pr-sidebar: 228px;
            --pr-serif: Georgia, "Times New Roman", serif;
            --pr-ui: Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }

        * {
            box-sizing: border-box;
        }

        html {
            scroll-behavior: smooth;
        }

        body.passenger-dashboard {
            min-height: 100vh;
            margin: 0;
            overflow-x: hidden;
            background: var(--pr-white);
            color: var(--pr-ink);
            font-family: var(--pr-ui);
            font-size: 13px;
            line-height: 1.45;
            -webkit-font-smoothing: antialiased;
        }

        body.passenger-dashboard.sidebar-open {
            overflow: hidden;
        }

        .passenger-dashboard a {
            color: inherit;
            text-decoration: none;
        }

        .passenger-dashboard button,
        .passenger-dashboard input {
            font: inherit;
        }

        .sr-only {
            position: absolute;
            width: 1px;
            height: 1px;
            padding: 0;
            margin: -1px;
            overflow: hidden;
            clip: rect(0, 0, 0, 0);
            white-space: nowrap;
            border: 0;
        }

        .passenger-topbar {
            position: sticky;
            top: 0;
            z-index: 60;
            min-height: 62px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 24px;
            padding: 0 24px;
            border-bottom: 1px solid var(--pr-line);
            background: rgba(255, 255, 255, 0.96);
            backdrop-filter: blur(16px);
        }

        .passenger-topbar-left,
        .passenger-account,
        .passenger-brand {
            display: flex;
            align-items: center;
        }

        .passenger-topbar-left {
            gap: 12px;
        }

        .passenger-brand {
            gap: 9px;
            letter-spacing: -0.03em;
        }

        .passenger-brand img {
            width: 25px;
            height: 25px;
        }

        .passenger-brand strong {
            color: var(--pr-blue);
            font-size: 14px;
            font-weight: 850;
        }

        .passenger-brand em {
            margin-left: 1px;
            color: var(--pr-muted);
            font-family: var(--pr-serif);
            font-size: 12px;
            font-style: italic;
            font-weight: 400;
        }

        .passenger-account {
            gap: 14px;
        }

        .passenger-account-copy {
            display: grid;
            justify-items: end;
            gap: 1px;
        }

        .passenger-account-copy strong {
            font-size: 11px;
        }

        .passenger-account-copy span {
            color: var(--pr-muted);
            font-size: 9px;
        }

        .signout-button {
            min-height: 34px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 13px;
            border: 1px solid var(--pr-line);
            border-radius: 9px;
            background: var(--pr-white);
            color: var(--pr-blue);
            font-size: 10px;
            font-weight: 850;
            transition: border-color 140ms ease, background 140ms ease;
        }

        .signout-button:hover {
            border-color: #cbd7e6;
            background: var(--pr-blue-pale);
        }

        .passenger-shell {
            width: 100%;
            display: grid;
            grid-template-columns: var(--pr-sidebar) minmax(0, 1fr);
        }

        .passenger-sidebar {
            position: sticky;
            top: 62px;
            height: calc(100vh - 62px);
            overflow-y: auto;
            padding: 24px 20px 30px;
            border-right: 1px solid var(--pr-line);
            background: #fcfdff;
        }

        .passenger-sidebar nav {
            display: grid;
            gap: 2px;
        }

        .side-heading {
            margin: 19px 8px 6px;
            color: #9298a0;
            font-size: 8px;
            font-weight: 900;
            letter-spacing: 0.1em;
            text-transform: uppercase;
        }

        .side-link {
            min-height: 36px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            padding: 0 10px;
            border-radius: 9px;
            color: #626870;
            font-size: 10px;
            font-weight: 600;
            transition: background 140ms ease, color 140ms ease;
        }

        .side-link:hover {
            background: var(--pr-blue-soft);
            color: var(--pr-blue);
        }

        .side-link.is-active {
            background: var(--pr-blue);
            color: #fff;
            font-weight: 850;
        }

        .side-count {
            min-width: 22px;
            padding: 2px 6px;
            border-radius: 999px;
            background: #edf0f3;
            color: #68707a;
            text-align: center;
            font-size: 8px;
            font-weight: 850;
        }

        .side-link.is-active .side-count {
            background: rgba(255, 255, 255, 0.17);
            color: #fff;
        }

        .side-divider {
            height: 1px;
            margin: 20px 0 8px;
            background: var(--pr-line);
        }

        .sidebar-toggle {
            display: none;
            width: 36px;
            height: 36px;
            padding: 8px;
            border: 1px solid var(--pr-line);
            border-radius: 9px;
            background: #fff;
        }

        .sidebar-toggle > span:not(.sr-only) {
            display: block;
            width: 17px;
            height: 1px;
            margin: 4px auto;
            background: var(--pr-blue);
        }

        .sidebar-scrim {
            display: none;
        }

        .passenger-main {
            min-width: 0;
            padding: 42px clamp(24px, 4vw, 58px) 90px;
        }

        .dashboard-alert {
            margin-bottom: 20px;
            padding: 12px 14px;
            border: 1px solid #f2c9c4;
            border-radius: 10px;
            background: #fff3f1;
            color: #9d271d;
            font-size: 10px;
        }

        .hero-row {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 32px;
            margin-bottom: 30px;
        }

        .kicker {
            margin: 0 0 7px;
            color: var(--pr-blue);
            font-size: 8px;
            font-weight: 900;
            letter-spacing: 0.11em;
            text-transform: uppercase;
        }

        .hero-row h1 {
            margin: 0;
            font-family: var(--pr-serif);
            font-size: clamp(38px, 4.4vw, 60px);
            line-height: 0.98;
            font-weight: 500;
            letter-spacing: -0.055em;
        }

        .hero-row h1 em {
            color: var(--pr-blue);
            font-style: italic;
            font-weight: 500;
        }

        .hero-meta {
            margin: 11px 0 0;
            display: flex;
            flex-wrap: wrap;
            gap: 7px;
            color: var(--pr-muted);
            font-size: 9px;
        }

        .hero-meta strong {
            color: var(--pr-ink);
        }

        .hero-actions {
            max-width: 410px;
            display: flex;
            justify-content: flex-end;
            flex-wrap: wrap;
            gap: 8px;
        }

        .action-primary,
        .action-secondary {
            min-height: 36px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 13px;
            border-radius: 9px;
            font-size: 9px;
            font-weight: 850;
        }

        .action-primary {
            border: 1px solid var(--pr-blue);
            background: var(--pr-blue);
            color: #fff;
        }

        .action-primary:hover {
            background: var(--pr-blue-dark);
        }

        .action-secondary {
            border: 1px solid var(--pr-line);
            background: #fff;
            color: var(--pr-blue);
        }

        .action-secondary:hover {
            border-color: #cdd9e7;
            background: var(--pr-blue-pale);
        }

        .metric-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 11px;
            margin-bottom: 26px;
        }

        .metric-card {
            min-width: 0;
            min-height: 128px;
            padding: 17px;
            border: 1px solid var(--pr-line);
            border-radius: var(--pr-radius);
            background: #fff;
        }

        .metric-card.featured {
            border-color: #cfdae8;
            background: var(--pr-blue-pale);
        }

        .metric-card p {
            margin: 0 0 14px;
            color: var(--pr-muted);
            font-size: 8px;
            font-weight: 900;
            letter-spacing: 0.09em;
            text-transform: uppercase;
        }

        .metric-card strong {
            display: block;
            color: var(--pr-ink);
            font-family: var(--pr-serif);
            font-size: 30px;
            line-height: 1;
            font-weight: 500;
            letter-spacing: -0.04em;
        }

        .metric-card.featured strong {
            color: var(--pr-blue);
        }

        .metric-card span {
            display: block;
            margin-top: 10px;
            color: var(--pr-muted);
            font-size: 9px;
        }

        .section {
            min-width: 0;
            margin-top: 27px;
        }

        .section-heading {
            min-height: 48px;
            display: flex;
            align-items: flex-end;
            justify-content: space-between;
            gap: 18px;
            margin-bottom: 12px;
        }

        .section-heading h2 {
            margin: 0;
            font-family: var(--pr-serif);
            font-size: 23px;
            line-height: 1;
            font-weight: 500;
            letter-spacing: -0.035em;
        }

        .section-heading p:not(.kicker) {
            margin: 6px 0 0;
            color: var(--pr-muted);
            font-size: 9px;
        }

        .text-action {
            flex: 0 0 auto;
            color: var(--pr-blue);
            font-size: 8px;
            font-weight: 850;
        }

        .trip-card {
            display: grid;
            grid-template-columns: minmax(0, 1.4fr) minmax(160px, 0.7fr) auto;
            gap: 22px;
            align-items: center;
            padding: 19px;
            border: 1px solid #d7e0eb;
            border-radius: 15px;
            background: linear-gradient(135deg, #f7faff 0%, #ffffff 66%);
        }

        .trip-route {
            min-width: 0;
        }

        .trip-route-code {
            color: var(--pr-blue);
            font-size: 8px;
            font-weight: 900;
            letter-spacing: 0.07em;
            text-transform: uppercase;
        }

        .trip-route h3 {
            margin: 6px 0 0;
            font-family: var(--pr-serif);
            font-size: 25px;
            font-weight: 500;
            letter-spacing: -0.035em;
        }

        .route-flow {
            margin-top: 13px;
            display: grid;
            grid-template-columns: auto minmax(40px, 1fr) auto;
            align-items: center;
            gap: 8px;
            color: #5f6670;
            font-size: 9px;
        }

        .route-flow i {
            height: 1px;
            background: #c8d4e3;
        }

        .trip-time {
            display: grid;
            gap: 5px;
        }

        .trip-time strong {
            font-family: var(--pr-serif);
            font-size: 21px;
            font-weight: 500;
        }

        .trip-time span {
            color: var(--pr-muted);
            font-size: 9px;
        }

        .trip-ticket {
            display: grid;
            justify-items: end;
            gap: 6px;
        }

        .trip-ticket strong {
            color: var(--pr-blue);
            font-size: 10px;
        }

        .trip-ticket small {
            color: var(--pr-muted);
            font-size: 8px;
        }

        .status-pill {
            display: inline-flex;
            align-items: center;
            min-height: 22px;
            padding: 0 7px;
            border: 1px solid #e2e5e8;
            border-radius: 999px;
            background: #f3f4f5;
            color: #777c82;
            font-size: 7px;
            font-weight: 850;
            letter-spacing: 0.03em;
        }

        .status-pill.is-good {
            border-color: #cce6d3;
            background: var(--pr-good-bg);
            color: var(--pr-good);
        }

        .status-pill.is-warn {
            border-color: #ead9af;
            background: var(--pr-warn-bg);
            color: var(--pr-warn);
        }

        .status-pill.is-muted {
            color: #888d92;
        }

        .empty-state {
            min-height: 106px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 20px;
            padding: 18px;
            border: 1px dashed #ced7e2;
            border-radius: 13px;
            background: #fbfdff;
        }

        .empty-state strong,
        .empty-state p {
            margin: 0;
        }

        .empty-state strong {
            font-size: 10px;
        }

        .empty-state p {
            margin-top: 3px;
            color: var(--pr-muted);
            font-size: 9px;
        }

        .ride-grid,
        .favorite-grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 11px;
        }

        .ride-card,
        .favorite-card {
            min-width: 0;
            padding: 16px;
            border: 1px solid var(--pr-line);
            border-radius: 13px;
            background: #fff;
        }

        .ride-card-top,
        .favorite-card-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
        }

        .route-badge {
            display: inline-flex;
            align-items: center;
            min-height: 22px;
            padding: 0 7px;
            border: 1px solid #d7e0eb;
            border-radius: 999px;
            color: var(--pr-blue);
            font-size: 7px;
            font-weight: 900;
        }

        .fare {
            color: var(--pr-muted);
            font-size: 8px;
        }

        .ride-card h3,
        .favorite-card h3 {
            margin: 14px 0 0;
            font-family: var(--pr-serif);
            font-size: 18px;
            font-weight: 500;
            letter-spacing: -0.025em;
        }

        .mini-route {
            margin-top: 10px;
            display: grid;
            grid-template-columns: auto minmax(28px, 1fr) auto;
            align-items: center;
            gap: 7px;
            color: var(--pr-muted);
            font-size: 8px;
        }

        .mini-route i {
            height: 1px;
            background: #d5dde7;
        }

        .ride-card-footer,
        .favorite-card-footer {
            margin-top: 14px;
            padding-top: 11px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            border-top: 1px solid var(--pr-line);
            color: var(--pr-muted);
            font-size: 8px;
        }

        .ride-card-footer strong {
            color: var(--pr-ink);
            font-size: 9px;
        }

        .capacity-wrap {
            margin-top: 12px;
        }

        .capacity-meta {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            color: var(--pr-muted);
            font-size: 8px;
        }

        .capacity-track {
            height: 5px;
            margin-top: 6px;
            overflow: hidden;
            border-radius: 999px;
            background: #edf1f5;
        }

        .capacity-track span {
            display: block;
            height: 100%;
            border-radius: inherit;
            background: var(--pr-blue);
        }

        .split-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 15px;
            align-items: start;
        }

        .panel {
            min-width: 0;
            padding: 17px;
            border: 1px solid var(--pr-line);
            border-radius: 13px;
            background: #fff;
        }

        .panel-heading {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 16px;
            margin-bottom: 12px;
        }

        .panel-heading h3 {
            margin: 0;
            font-family: var(--pr-serif);
            font-size: 19px;
            font-weight: 500;
            letter-spacing: -0.025em;
        }

        .panel-heading p {
            margin: 4px 0 0;
            color: var(--pr-muted);
            font-size: 8px;
        }

        .notification-list,
        .complaint-list {
            display: grid;
        }

        .notification-row,
        .complaint-row {
            display: grid;
            grid-template-columns: minmax(0, 1fr) auto;
            gap: 12px;
            align-items: center;
            min-height: 58px;
            padding: 10px 0;
            border-top: 1px solid var(--pr-line);
        }

        .notification-row:first-child,
        .complaint-row:first-child {
            border-top: 0;
        }

        .notification-row.unread {
            position: relative;
            padding-left: 12px;
        }

        .notification-row.unread::before {
            content: "";
            position: absolute;
            left: 0;
            top: 17px;
            width: 5px;
            height: 5px;
            border-radius: 50%;
            background: var(--pr-blue);
        }

        .notification-row strong,
        .complaint-row strong {
            display: block;
            font-size: 9px;
        }

        .notification-row p,
        .complaint-row p {
            margin: 2px 0 0;
            overflow: hidden;
            color: var(--pr-muted);
            font-size: 8px;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .notification-row time,
        .complaint-row time {
            color: #969ba1;
            font-size: 7px;
            white-space: nowrap;
        }

        .billing-card {
            display: grid;
            grid-template-columns: minmax(0, 1fr) auto;
            gap: 18px;
            align-items: center;
            padding: 18px;
            border: 1px solid #d9e3ee;
            border-radius: 13px;
            background: var(--pr-blue-pale);
        }

        .billing-card strong {
            display: block;
            color: var(--pr-blue);
            font-family: var(--pr-serif);
            font-size: 30px;
            font-weight: 500;
        }

        .billing-card span {
            color: var(--pr-muted);
            font-size: 8px;
        }

        .profile-card {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 9px;
        }

        .profile-item {
            min-height: 66px;
            padding: 11px;
            border: 1px solid var(--pr-line);
            border-radius: 10px;
            background: #fff;
        }

        .profile-item span {
            display: block;
            color: var(--pr-muted);
            font-size: 7px;
            font-weight: 850;
            letter-spacing: 0.07em;
            text-transform: uppercase;
        }

        .profile-item strong {
            display: block;
            margin-top: 7px;
            overflow: hidden;
            font-size: 9px;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .footer-note {
            margin-top: 34px;
            padding-top: 18px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            border-top: 1px solid var(--pr-line);
            color: #93989e;
            font-size: 8px;
        }

        .passenger-dashboard :focus-visible {
            outline: 2px solid var(--pr-blue);
            outline-offset: 2px;
        }

        @media (max-width: 1180px) {
            .metric-grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }

            .ride-grid,
            .favorite-grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
        }

        @media (max-width: 920px) {
            .passenger-topbar {
                padding-inline: 14px;
            }

            .sidebar-toggle {
                display: inline-block;
            }

            .passenger-shell {
                display: block;
            }

            .passenger-sidebar {
                position: fixed;
                top: 62px;
                left: 0;
                z-index: 55;
                width: min(290px, 84vw);
                height: calc(100vh - 62px);
                transform: translateX(-102%);
                transition: transform 180ms ease;
                box-shadow: 20px 0 45px rgba(18, 63, 124, 0.09);
            }

            .passenger-sidebar.is-open {
                transform: translateX(0);
            }

            .sidebar-scrim {
                position: fixed;
                inset: 62px 0 0;
                z-index: 50;
                border: 0;
                background: rgba(20, 30, 44, 0.18);
            }

            .sidebar-scrim.is-visible {
                display: block;
            }

            .passenger-main {
                padding: 32px 18px 70px;
            }

            .hero-row {
                display: grid;
            }

            .hero-actions {
                max-width: none;
                justify-content: flex-start;
            }

            .trip-card {
                grid-template-columns: 1fr 1fr;
            }

            .trip-ticket {
                grid-column: span 2;
                justify-items: start;
                padding-top: 12px;
                border-top: 1px solid var(--pr-line);
            }

            .split-grid {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 640px) {
            .passenger-brand em,
            .passenger-account-copy {
                display: none;
            }

            .passenger-main {
                padding-inline: 14px;
            }

            .hero-row h1 {
                font-size: 40px;
            }

            .metric-grid,
            .ride-grid,
            .favorite-grid,
            .profile-card {
                grid-template-columns: 1fr;
            }

            .section-heading {
                align-items: flex-start;
                flex-direction: column;
            }

            .trip-card {
                grid-template-columns: 1fr;
            }

            .trip-ticket {
                grid-column: auto;
            }

            .empty-state {
                align-items: flex-start;
                flex-direction: column;
            }

            .footer-note {
                align-items: flex-start;
                flex-direction: column;
            }
        }
    </style>
    <link rel="stylesheet" href="../css/uniride-ui.css">
    <script src="../js/dashboard.js" defer></script>
</head>
<body class="passenger-dashboard">

<header class="passenger-topbar">
    <div class="passenger-topbar-left">
        <button
            class="sidebar-toggle"
            type="button"
            data-sidebar-toggle
            aria-controls="passengerSidebar"
            aria-expanded="false"
        >
            <span class="sr-only">Toggle navigation</span>
            <span></span>
            <span></span>
        </button>

        <a class="passenger-brand" href="../index.php">
            <img src="../img/logo.svg" alt="">
            <strong>UniRide</strong>
            <em>Passenger</em>
        </a>
    </div>

    <div class="passenger-account">
        <?= profile_avatar_html('..', $name, $_SESSION['profile_picture_path'] ?? null) ?>
        <div class="passenger-account-copy">
            <strong><?= pd_h($name) ?></strong>
            <span><?= pd_h($universityCode) ?> · <?= pd_h($passengerType) ?></span>
        </div>
        <a class="signout-button" href="../logout.php">Sign out</a>
    </div>
</header>

<div class="passenger-shell">
    <aside class="passenger-sidebar" id="passengerSidebar" data-dashboard-sidebar>
        <nav aria-label="Passenger navigation">
            <?= dashboard_render_navigation(
                'PASSENGER',
                'overview',
                [
                    'my-bookings' => $stats['active_bookings'],
                    'favorite-routes' => $stats['favorites'],
                    'complaints' => ['value' => $stats['open_complaints'], 'alert' => true],
                    'notifications' => ['value' => $stats['unread_notifications'], 'alert' => true],
                ],
                strtoupper((string)($profile['passenger_type'] ?? '')) === 'STUDENT'
                    ? []
                    : ['ticket-transfers'],
                '..',
                [
                    'heading' => 'side-heading',
                    'link' => 'side-link',
                    'active' => 'is-active',
                    'count' => 'side-count',
                    'child' => 'side-link-child',
                ]
            ) ?>

            <div class="side-divider"></div>
            <a class="side-link" href="../logout.php"><span>Logout</span></a>
        </nav>
    </aside>

    <button
        class="sidebar-scrim"
        type="button"
        data-sidebar-scrim
        aria-label="Close navigation"
    ></button>

    <main class="passenger-main">
        <?php if ($dashboardError): ?>
            <div class="dashboard-alert" role="alert"><?= pd_h($dashboardError) ?></div>
        <?php endif; ?>

        <section class="hero-row" id="profile-summary">
            <div>
                <p class="kicker">Passenger overview</p>
                <h1>Welcome back, <em><?= pd_h($firstName) ?></em></h1>
                <p class="hero-meta">
                    <strong><?= pd_h($universityName) ?></strong>
                    <span>·</span>
                    <?= pd_h($passengerType) ?>
                    <?php if ($semesterName): ?>
                        <span>·</span>
                        <?= pd_h($semesterName) ?>
                    <?php endif; ?>
                    <?php if ($roleDetail): ?>
                        <span>·</span>
                        <?= pd_h($roleDetail) ?>
                    <?php endif; ?>
                    <span>·</span>
                    <?= pd_h(date('d M Y')) ?>
                </p>
            </div>

            <div class="hero-actions">
                <a class="action-primary" href="<?= pd_h($bookPage) ?>">Book a Ticket</a>
                <a class="action-secondary" href="<?= pd_h($bookingsPage) ?>">My Bookings</a>
                <a class="action-secondary" href="<?= pd_h($routesPage) ?>">Browse Schedules</a>
            </div>
        </section>

        <section class="metric-grid" aria-label="Passenger statistics">
            <article class="metric-card featured">
                <p>Active booking</p>
                <strong><?= number_format($stats['active_bookings']) ?></strong>
                <span><?= $stats['active_bookings'] ? 'Upcoming ticket ready' : 'No upcoming booking' ?></span>
            </article>

            <article class="metric-card">
                <p>Favorite routes</p>
                <strong><?= number_format($stats['favorites']) ?></strong>
                <span><?= $stats['favorites'] ? 'Saved for quick access' : 'None saved yet' ?></span>
            </article>

            <article class="metric-card">
                <p>Unread notifications</p>
                <strong><?= number_format($stats['unread_notifications']) ?></strong>
                <span><?= $stats['unread_notifications'] ? 'Updates waiting for you' : 'You are all caught up' ?></span>
            </article>

            <article class="metric-card">
                <p>Semester transport bill</p>
                <strong>৳<?= number_format($stats['semester_balance'], 0) ?></strong>
                <span><?= pd_h($semesterName) ?></span>
            </article>
        </section>

        <section class="section" id="my-trip">
            <div class="section-heading">
                <div>
                    <p class="kicker">Your journey</p>
                    <h2>Upcoming trip</h2>
                    <p>Your nearest active booking from the database.</p>
                </div>
                <a class="text-action" href="<?= pd_h($bookingsPage) ?>">View all bookings</a>
            </div>

            <?php if (!$activeBookings): ?>
                <div class="empty-state">
                    <div>
                        <strong>No upcoming booking.</strong>
                        <p>Choose an available schedule when you are ready to travel.</p>
                    </div>
                    <a class="action-primary" href="<?= pd_h($bookPage) ?>">Find a Ride</a>
                </div>
            <?php else: ?>
                <?php $trip = $activeBookings[0]; ?>
                <article class="trip-card">
                    <div class="trip-route">
                        <span class="trip-route-code"><?= pd_h($trip['route_code']) ?> · <?= pd_h($trip['booking_reference']) ?></span>
                        <h3><?= pd_h($trip['route_name']) ?></h3>
                        <div class="route-flow">
                            <span><?= pd_h($trip['start_location']) ?></span>
                            <i></i>
                            <span><?= pd_h($trip['end_location']) ?></span>
                        </div>
                    </div>

                    <div class="trip-time">
                        <strong><?= pd_h(pd_time($trip['departure_time'])) ?></strong>
                        <span>
                            <?= pd_h(date('D, d M Y', strtotime($trip['schedule_date']))) ?>
                            · arrives <?= pd_h(pd_time($trip['arrival_time'])) ?>
                        </span>
                        <span><?= pd_h($trip['registration_number']) ?> · <?= pd_h(str_replace('_', ' ', $trip['bus_type'])) ?></span>
                    </div>

                    <div class="trip-ticket">
                        <span class="status-pill <?= pd_h(pd_status_class($trip['status'])) ?>"><?= pd_h($trip['status']) ?></span>
                        <strong><?= pd_h(pd_seat_label($trip)) ?></strong>
                        <small>Fare ৳<?= number_format((float)$trip['fare_charged'], 0) ?></small>
                    </div>
                </article>
            <?php endif; ?>
        </section>

        <section class="section" id="available-rides">
            <div class="section-heading">
                <div>
                    <p class="kicker">Travel</p>
                    <h2>Available rides</h2>
                    <p>Upcoming schedules for your university and passenger type.</p>
                </div>
                <a class="text-action" href="<?= pd_h($routesPage) ?>">Routes &amp; schedules</a>
            </div>

            <?php if (!$availableSchedules): ?>
                <div class="empty-state">
                    <div>
                        <strong>No upcoming schedules are currently available.</strong>
                        <p>Your university transport admin can publish new schedules.</p>
                    </div>
                </div>
            <?php else: ?>
                <div class="ride-grid">
                    <?php foreach ($availableSchedules as $ride): ?>
                        <?php
                            $seatCapacity = max(0, (int)$ride['seat_capacity']);
                            $bookedSeats = max(0, (int)$ride['booked_seats']);
                            $availableSeats = max(0, $seatCapacity - $bookedSeats);
                            $seatPercent = $seatCapacity > 0
                                ? min(100, (int)round(($bookedSeats / $seatCapacity) * 100))
                                : 0;
                        ?>
                        <article class="ride-card">
                            <div class="ride-card-top">
                                <span class="route-badge"><?= pd_h($ride['route_code']) ?></span>
                                <span class="fare">৳<?= number_format(uniride_ticket_fare(), 0) ?></span>
                            </div>
                            <h3><?= pd_h($ride['route_name']) ?></h3>
                            <div class="mini-route">
                                <span><?= pd_h($ride['start_location']) ?></span>
                                <i></i>
                                <span><?= pd_h($ride['end_location']) ?></span>
                            </div>
                            <div class="capacity-wrap">
                                <div class="capacity-meta">
                                    <span><?= $availableSeats ?> seats available</span>
                                    <span><?= $seatPercent ?>% occupied</span>
                                </div>
                                <div class="capacity-track"><span style="width: <?= $seatPercent ?>%"></span></div>
                            </div>
                            <div class="ride-card-footer">
                                <div>
                                    <strong><?= pd_h(pd_time($ride['departure_time'])) ?></strong>
                                    <span> · <?= pd_h(date('d M', strtotime($ride['schedule_date']))) ?></span>
                                </div>
                                <span><?= pd_h($ride['registration_number']) ?></span>
                            </div>
                        </article>
                    <?php endforeach; ?>
                </div>
            <?php endif; ?>
        </section>

        <section class="section" id="favorites">
            <div class="section-heading">
                <div>
                    <p class="kicker">Saved routes</p>
                    <h2>Favorite routes</h2>
                    <p>Your frequently used routes stay close at hand.</p>
                </div>
                <a class="text-action" href="<?= pd_h($favoritesPage) ?>">Manage favorites</a>
            </div>

            <?php if (!$favoriteRoutes): ?>
                <div class="empty-state">
                    <div>
                        <strong>No favorite routes yet.</strong>
                        <p>Save a route and it will appear here for faster booking.</p>
                    </div>
                    <a class="action-secondary" href="<?= pd_h($routesPage) ?>">Browse Routes</a>
                </div>
            <?php else: ?>
                <div class="favorite-grid">
                    <?php foreach ($favoriteRoutes as $route): ?>
                        <article class="favorite-card">
                            <div class="favorite-card-top">
                                <span class="route-badge"><?= pd_h($route['route_code']) ?></span>
                                <span class="fare">৳<?= number_format(uniride_ticket_fare(), 0) ?></span>
                            </div>
                            <h3><?= pd_h($route['route_name']) ?></h3>
                            <div class="mini-route">
                                <span><?= pd_h($route['start_location']) ?></span>
                                <i></i>
                                <span><?= pd_h($route['end_location']) ?></span>
                            </div>
                            <div class="favorite-card-footer">
                                <?php if ($route['next_departure']): ?>
                                    <span>Next <?= pd_h(date('d M · g:i A', strtotime($route['next_departure']))) ?></span>
                                <?php else: ?>
                                    <span>No upcoming departure</span>
                                <?php endif; ?>
                            </div>
                        </article>
                    <?php endforeach; ?>
                </div>
            <?php endif; ?>
        </section>

        <section class="section split-grid">
            <article class="panel" id="notifications">
                <div class="panel-heading">
                    <div>
                        <p class="kicker">Updates</p>
                        <h3>Notifications</h3>
                        <p><?= number_format($stats['unread_notifications']) ?> unread</p>
                    </div>
                    <a class="text-action" href="<?= pd_h($notificationsPage) ?>">View all</a>
                </div>

                <?php if (!$notifications): ?>
                    <div class="empty-state">
                        <div>
                            <strong>No notifications yet.</strong>
                            <p>Booking and transport updates will appear here.</p>
                        </div>
                    </div>
                <?php else: ?>
                    <div class="notification-list">
                        <?php foreach ($notifications as $notification): ?>
                            <div class="notification-row <?= !(int)$notification['is_read'] ? 'unread' : '' ?>">
                                <div>
                                    <strong><?= pd_h($notification['title']) ?></strong>
                                    <p><?= pd_h($notification['message']) ?></p>
                                </div>
                                <time><?= pd_h(date('d M', strtotime($notification['created_at']))) ?></time>
                            </div>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
            </article>

            <article class="panel" id="complaints">
                <div class="panel-heading">
                    <div>
                        <p class="kicker">Support</p>
                        <h3>Complaints</h3>
                        <p><?= number_format($stats['open_complaints']) ?> open or in progress</p>
                    </div>
                    <a class="text-action" href="<?= pd_h($complaintsPage) ?>">Open complaints</a>
                </div>

                <?php if (!$complaints): ?>
                    <div class="empty-state">
                        <div>
                            <strong>No complaints submitted.</strong>
                            <p>You can contact your university transport team when needed.</p>
                        </div>
                    </div>
                <?php else: ?>
                    <div class="complaint-list">
                        <?php foreach ($complaints as $complaint): ?>
                            <div class="complaint-row">
                                <div>
                                    <strong><?= pd_h($complaint['subject']) ?></strong>
                                    <p><?= pd_h($complaint['university_response'] ?: 'Awaiting or tracking university response') ?></p>
                                </div>
                                <div>
                                    <span class="status-pill <?= pd_h(pd_status_class($complaint['status'])) ?>"><?= pd_h($complaint['status']) ?></span>
                                    <time><?= pd_h(date('d M', strtotime($complaint['updated_at']))) ?></time>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
            </article>
        </section>

        <section class="section split-grid">
            <article class="panel" id="billing">
                <div class="panel-heading">
                    <div>
                        <p class="kicker">Semester account</p>
                        <h3>Transport billing</h3>
                        <p>Charges come from database booking transactions.</p>
                    </div>
                    <a class="text-action" href="<?= pd_h($billingPage) ?>">View bill</a>
                </div>
                <div class="billing-card">
                    <div>
                        <span><?= pd_h($semesterName) ?> balance</span>
                        <strong>৳<?= number_format($stats['semester_balance'], 0) ?></strong>
                    </div>
                    <span><?= number_format($stats['booking_history']) ?> total booking records</span>
                </div>
            </article>

            <article class="panel" id="account-summary">
                <div class="panel-heading">
                    <div>
                        <p class="kicker">Account</p>
                        <h3>Passenger profile</h3>
                        <p>Your university transport identity.</p>
                    </div>
                    <a class="text-action" href="<?= pd_h($profilePage) ?>">Edit profile</a>
                </div>

                <div class="profile-card">
                    <div class="profile-item">
                        <span>Academic email</span>
                        <strong><?= pd_h($profile['email'] ?? '') ?></strong>
                    </div>
                    <div class="profile-item">
                        <span>Passenger type</span>
                        <strong><?= pd_h($passengerType) ?></strong>
                    </div>
                    <div class="profile-item">
                        <span><?= $profile['passenger_type'] === 'STUDENT' ? 'Student ID' : 'Faculty ID' ?></span>
                        <strong><?= pd_h($identifier ?: '—') ?></strong>
                    </div>
                    <div class="profile-item">
                        <span>Department</span>
                        <strong><?= pd_h($department ?: '—') ?></strong>
                    </div>
                </div>
            </article>
        </section>

        <div class="footer-note">
            <span>UniRide · <?= pd_h($universityName) ?> passenger portal</span>
            <span>Database-backed dashboard · <?= pd_h(date('Y')) ?></span>
        </div>
    </main>
</div>

</body>
</html>
