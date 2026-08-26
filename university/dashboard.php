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

if (($_SESSION['user_type'] ?? '') !== 'UNIVERSITY_ADMIN') {
    header('Location: ../dashboard.php');
    exit;
}

$universityId = (int)($_SESSION['university_id'] ?? 0);
$adminId = (int)($_SESSION['university_user_id'] ?? $_SESSION['user_id'] ?? 0);
$adminName = (string)($_SESSION['name'] ?? 'University Admin');

if ($universityId <= 0 || $adminId <= 0) {
    http_response_code(403);
    uniride_render_error_page('University access is unavailable for this account.', '..');
}
profile_enforce_session($pdo, '..');

date_default_timezone_set('Asia/Dhaka');

function uh(mixed $value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

function tableExists(PDO $pdo, string $table): bool
{
    static $cache = [];
    if (array_key_exists($table, $cache)) {
        return $cache[$table];
    }

    $stmt = $pdo->prepare(
        "SELECT COUNT(*) FROM information_schema.tables
         WHERE table_schema = DATABASE() AND table_name = ?"
    );
    $stmt->execute([$table]);
    return $cache[$table] = ((int)$stmt->fetchColumn() > 0);
}

function fetchOne(PDO $pdo, string $sql, array $params = []): array
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetch() ?: [];
}

function fetchAllRows(PDO $pdo, string $sql, array $params = []): array
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll();
}

function scalar(PDO $pdo, string $sql, array $params = []): mixed
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchColumn();
}

function validDate(?string $date): ?string
{
    if (!$date || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
        return null;
    }
    $obj = DateTimeImmutable::createFromFormat('!Y-m-d', $date);
    return ($obj && $obj->format('Y-m-d') === $date) ? $date : null;
}

function timeLabel(?string $time): string
{
    if (!$time) return '—';
    $ts = strtotime($time);
    return $ts ? date('g:i A', $ts) : $time;
}

function dateTimeLabel(?string $value): string
{
    if (!$value) return '—';
    $ts = strtotime($value);
    return $ts ? date('d M · g:i A', $ts) : $value;
}

function seatLabel(array $row): string
{
    if (($row['slot_type'] ?? '') === 'STANDING') {
        $slot = (int)($row['standing_slot'] ?? 0);
        return $slot > 0 ? 'Standing ' . str_pad((string)$slot, 2, '0', STR_PAD_LEFT) : 'Standing';
    }

    $seat = (int)($row['seat_number'] ?? 0);
    if ($seat < 1) return 'Seat';
    $letter = chr(64 + (int)ceil($seat / 4));
    $column = (($seat - 1) % 4) + 1;
    return $letter . $column;
}

function friendlyBusType(string $type): string
{
    return match ($type) {
        'STUDENT_ONLY' => 'Student only',
        'FACULTY_ONLY' => 'Faculty only',
        'STANDARD' => 'Standard',
        default => ucwords(strtolower(str_replace('_', ' ', $type))),
    };
}

function statusClass(string $status): string
{
    return match ($status) {
        'ACTIVE', 'CONFIRMED', 'COMPLETED', 'RESOLVED' => 'is-good',
        'SCHEDULED', 'BOOKED', 'IN_PROGRESS', 'TRANSFER_PENDING', 'PENDING' => 'is-neutral',
        'MAINTENANCE', 'OPEN' => 'is-warn',
        'INACTIVE', 'CANCELLED', 'CLOSED', 'REJECTED' => 'is-muted',
        default => 'is-neutral',
    };
}

function percentValue(int|float $used, int|float $capacity): int
{
    return $capacity > 0 ? (int)round(($used / $capacity) * 100) : 0;
}

function actionLink(string $path, string $label, string $class = 'text-action', array $query = []): string
{
    if (!is_file(__DIR__ . '/' . $path)) {
        return '<span class="' . uh($class) . ' is-disabled" aria-disabled="true">' . uh($label) . '</span>';
    }
    $href = $path . ($query ? '?' . http_build_query($query) : '');
    return '<a class="' . uh($class) . '" href="' . uh($href) . '">' . uh($label) . '</a>';
}

try {
    $identity = fetchOne(
        $pdo,
        "SELECT uu.name,uu.status AS admin_status,u.status AS university_status
         FROM university_users uu
         INNER JOIN universities u ON u.university_id=uu.university_id
         WHERE uu.university_user_id=? AND uu.university_id=? LIMIT 1",
        [$adminId, $universityId]
    );
    if (
        !$identity
        || strtoupper((string)$identity['admin_status']) !== 'ACTIVE'
        || strtoupper((string)$identity['university_status']) !== 'ACTIVE'
    ) {
        http_response_code(403);
        uniride_render_error_page('This University Admin account is currently unavailable.', '..');
    }
    $adminName = (string)$identity['name'];
} catch (Throwable $e) {
    error_log('[UniRide Uni Admin identity] ' . $e->getMessage());
    http_response_code(503);
    uniride_render_error_page('University administration is temporarily unavailable.', '..');
}

$today = new DateTimeImmutable('today');
$tomorrow = $today->modify('+1 day');
$selectedDate = validDate($_GET['date'] ?? null) ?: $today->format('Y-m-d');
$selectedDateObject = new DateTimeImmutable($selectedDate);
$isToday = $selectedDate === $today->format('Y-m-d');
$isTomorrow = $selectedDate === $tomorrow->format('Y-m-d');
$dateContext = $isToday ? 'Today' : ($isTomorrow ? 'Tomorrow' : $selectedDateObject->format('d M Y'));

if (empty($_SESSION['university_dashboard_csrf'])) {
    $_SESSION['university_dashboard_csrf'] = bin2hex(random_bytes(32));
}
$csrfToken = (string)$_SESSION['university_dashboard_csrf'];

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'update_complaint') {
    $submitted = (string)($_POST['csrf_token'] ?? '');
    $complaintId = (int)($_POST['complaint_id'] ?? 0);
    $newStatus = strtoupper(trim((string)($_POST['status'] ?? '')));
    $response = trim((string)($_POST['university_response'] ?? ''));
    $allowed = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];

    if (!hash_equals($csrfToken, $submitted) || $complaintId <= 0 || !in_array($newStatus, $allowed, true)) {
        $_SESSION['uni_dashboard_flash'] = ['type' => 'error', 'message' => 'The complaint update could not be validated.'];
    } else {
        try {
            $stmt = $pdo->prepare(
                "UPDATE complaints
                 SET status = ?,
                     university_response = CASE WHEN ? <> '' THEN ? ELSE university_response END,
                     updated_at = NOW()
                 WHERE complaint_id = ? AND university_id = ?"
            );
            $stmt->execute([$newStatus, $response, $response, $complaintId, $universityId]);
            $_SESSION['uni_dashboard_flash'] = [
                'type' => 'success',
                'message' => $stmt->rowCount() ? 'Complaint updated successfully.' : 'No complaint record was changed.',
            ];
        } catch (Throwable $e) {
            error_log('[UniRide Uni Admin complaint update] ' . $e->getMessage());
            $_SESSION['uni_dashboard_flash'] = ['type' => 'error', 'message' => 'The complaint could not be updated right now.'];
        }
    }

    $redirect = 'dashboard.php' . (!$isToday ? '?date=' . rawurlencode($selectedDate) : '');
    header('Location: ' . $redirect . '#complaints');
    exit;
}

$flash = $_SESSION['uni_dashboard_flash'] ?? null;
unset($_SESSION['uni_dashboard_flash']);

$university = $semester = [];
$passengerStats = ['total_passengers'=>0,'students'=>0,'faculty'=>0];
$fleetStats = ['total_buses'=>0,'active_buses'=>0,'seat_capacity'=>0,'standing_capacity'=>0];
$routeStats = ['active_routes'=>0,'average_fare'=>0];
$departureStats = ['departures'=>0,'next_departure'=>null];
$bookingStats = ['bookings'=>0,'trips_with_bookings'=>0];
$capacityStats = ['seat_capacity'=>0,'standing_capacity'=>0];
$loadStats = ['booked_seats'=>0,'booked_standing'=>0];
$complaintStats = ['open_total'=>0,'awaiting_response'=>0,'in_progress'=>0];
$departures = $recentBookings = $complaints = $fleet = $routeUtilisation = [];
$routeStopGroups = $recentTransfers = $needsAttention = [];
$transferStats = ['pending'=>0,'selected_date'=>0,'completed'=>0];
$billingStats = ['passengers_billed'=>0,'total_charges'=>0,'total_credits'=>0,'net_balance'=>0,'transactions'=>0];
$panelAvailability = ['route_stops'=>false,'ticket_transfers'=>false,'semester_bills'=>false];
$dashboardError = '';

try {
    $university = fetchOne($pdo,
        "SELECT university_id,name,code,academic_domain,address,contact_email,status
         FROM universities WHERE university_id=? LIMIT 1",
        [$universityId]
    );
    if (!$university) {
        http_response_code(403);
        uniride_render_error_page('Your university is not available.', '..');
    }
    if (strtoupper((string)$university['status']) !== 'ACTIVE') {
        http_response_code(403);
        uniride_render_error_page('This university is currently inactive.', '..');
    }

    $semester = fetchOne($pdo,
        "SELECT semester_id,semester_name,start_date,end_date,is_active
         FROM semesters WHERE is_active=1 ORDER BY start_date DESC LIMIT 1"
    );

    $passengerStats = array_merge($passengerStats, fetchOne($pdo,
        "SELECT
            COUNT(DISTINCT passenger_id) total_passengers,
            COUNT(DISTINCT CASE WHEN passenger_type='STUDENT' THEN passenger_id END) students,
            COUNT(DISTINCT CASE WHEN passenger_type='FACULTY' THEN passenger_id END) faculty
         FROM passengers WHERE university_id=?",
        [$universityId]
    ));

    $fleetStats = array_merge($fleetStats, fetchOne($pdo,
        "SELECT
            COUNT(DISTINCT bus_id) total_buses,
            COUNT(DISTINCT CASE WHEN status='ACTIVE' THEN bus_id END) active_buses,
            COALESCE(SUM(CASE WHEN status='ACTIVE' THEN seat_capacity ELSE 0 END),0) seat_capacity,
            COALESCE(SUM(CASE WHEN status='ACTIVE' THEN standing_capacity ELSE 0 END),0) standing_capacity
         FROM buses WHERE university_id=?",
        [$universityId]
    ));

    $routeStats = array_merge($routeStats, fetchOne($pdo,
        "SELECT COUNT(DISTINCT route_id) active_routes, COALESCE(AVG(fare),0) average_fare
         FROM routes WHERE university_id=? AND status='ACTIVE'",
        [$universityId]
    ));

    $departureStats = array_merge($departureStats, fetchOne($pdo,
        "SELECT COUNT(DISTINCT s.schedule_id) departures,
                MIN(CASE WHEN s.status='SCHEDULED' THEN s.departure_time END) next_departure
         FROM schedules s JOIN routes r ON r.route_id=s.route_id
         WHERE r.university_id=? AND s.schedule_date=? AND s.status<>'CANCELLED'",
        [$universityId,$selectedDate]
    ));

    $bookingStats = array_merge($bookingStats, fetchOne($pdo,
        "SELECT
            COUNT(DISTINCT CASE WHEN bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING') THEN bk.booking_id END) bookings,
            COUNT(DISTINCT CASE WHEN bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING') THEN s.schedule_id END) trips_with_bookings
         FROM schedules s
         JOIN routes r ON r.route_id=s.route_id
         LEFT JOIN bookings bk ON bk.schedule_id=s.schedule_id
         WHERE r.university_id=? AND s.schedule_date=?",
        [$universityId,$selectedDate]
    ));

    $capacityStats = array_merge($capacityStats, fetchOne($pdo,
        "SELECT COALESCE(SUM(b.seat_capacity),0) seat_capacity,
                COALESCE(SUM(b.standing_capacity),0) standing_capacity
         FROM schedules s JOIN routes r ON r.route_id=s.route_id JOIN buses b ON b.bus_id=s.bus_id
         WHERE r.university_id=? AND s.schedule_date=? AND s.status<>'CANCELLED'",
        [$universityId,$selectedDate]
    ));

    $loadStats = array_merge($loadStats, fetchOne($pdo,
        "SELECT
            COUNT(DISTINCT CASE WHEN bk.slot_type='SEAT' AND bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING') THEN bk.booking_id END) booked_seats,
            COUNT(DISTINCT CASE WHEN bk.slot_type='STANDING' AND bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING') THEN bk.booking_id END) booked_standing
         FROM bookings bk JOIN schedules s ON s.schedule_id=bk.schedule_id JOIN routes r ON r.route_id=s.route_id
         WHERE r.university_id=? AND s.schedule_date=?",
        [$universityId,$selectedDate]
    ));

    $complaintStats = array_merge($complaintStats, fetchOne($pdo,
        "SELECT
            COUNT(DISTINCT CASE WHEN status IN ('OPEN','IN_PROGRESS') THEN complaint_id END) open_total,
            COUNT(DISTINCT CASE WHEN status='OPEN' AND (university_response IS NULL OR TRIM(university_response)='') THEN complaint_id END) awaiting_response,
            COUNT(DISTINCT CASE WHEN status='IN_PROGRESS' THEN complaint_id END) in_progress
         FROM complaints WHERE university_id=?",
        [$universityId]
    ));

    $departures = fetchAllRows($pdo,
        "SELECT s.schedule_id,s.schedule_date,s.departure_time,s.arrival_time,s.status,
                r.route_code,r.route_name,b.bus_id,b.registration_number,b.bus_type,b.seat_capacity,b.standing_capacity,
                COUNT(DISTINCT CASE WHEN bk.slot_type='SEAT' AND bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING') THEN bk.booking_id END) booked_seats,
                COUNT(DISTINCT CASE WHEN bk.slot_type='STANDING' AND bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING') THEN bk.booking_id END) booked_standing,
                COUNT(DISTINCT CASE WHEN bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING') THEN bk.booking_id END) total_load
         FROM schedules s JOIN routes r ON r.route_id=s.route_id JOIN buses b ON b.bus_id=s.bus_id
         LEFT JOIN bookings bk ON bk.schedule_id=s.schedule_id
         WHERE r.university_id=? AND s.schedule_date=?
         GROUP BY s.schedule_id,s.schedule_date,s.departure_time,s.arrival_time,s.status,
                  r.route_code,r.route_name,b.bus_id,b.registration_number,b.bus_type,b.seat_capacity,b.standing_capacity
         ORDER BY s.departure_time",
        [$universityId,$selectedDate]
    );

    $recentBookings = fetchAllRows($pdo,
        "SELECT bk.booking_id,bk.booking_reference,bk.slot_type,bk.seat_number,bk.standing_slot,
                bk.fare_charged,bk.status,bk.booking_date,p.name passenger_name,p.passenger_type,
                r.route_code,r.route_name,s.schedule_date,s.departure_time
         FROM bookings bk
         JOIN schedules s ON s.schedule_id=bk.schedule_id
         JOIN routes r ON r.route_id=s.route_id
         JOIN (SELECT passenger_id,MIN(name) name,MIN(passenger_type) passenger_type FROM passengers GROUP BY passenger_id) p
           ON p.passenger_id=bk.passenger_id
         WHERE r.university_id=?
         ORDER BY bk.booking_date DESC,bk.booking_id DESC LIMIT 8",
        [$universityId]
    );

    $complaints = fetchAllRows($pdo,
        "SELECT c.complaint_id,c.subject,c.description,c.status,c.university_response,c.submitted_at,c.updated_at,p.name passenger_name
         FROM complaints c
         JOIN (SELECT passenger_id,MIN(name) name FROM passengers GROUP BY passenger_id) p ON p.passenger_id=c.passenger_id
         WHERE c.university_id=? AND c.status IN ('OPEN','IN_PROGRESS')
         ORDER BY CASE c.status WHEN 'OPEN' THEN 0 ELSE 1 END,c.submitted_at ASC LIMIT 6",
        [$universityId]
    );

    $fleet = fetchAllRows($pdo,
        "SELECT b.bus_id,b.registration_number,b.bus_type,b.seat_capacity,b.standing_capacity,b.status,
                COALESCE(ds.trip_count,0) trip_count,COALESCE(ds.active_load,0) active_load,ns.next_departure
         FROM buses b
         LEFT JOIN (
             SELECT s.bus_id,COUNT(DISTINCT s.schedule_id) trip_count,
                    COUNT(DISTINCT CASE WHEN bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING') THEN bk.booking_id END) active_load
             FROM schedules s LEFT JOIN bookings bk ON bk.schedule_id=s.schedule_id
             WHERE s.schedule_date=? GROUP BY s.bus_id
         ) ds ON ds.bus_id=b.bus_id
         LEFT JOIN (
             SELECT bus_id,MIN(CONCAT(schedule_date,' ',departure_time)) next_departure
             FROM schedules WHERE status='SCHEDULED' AND CONCAT(schedule_date,' ',departure_time)>=NOW()
             GROUP BY bus_id
         ) ns ON ns.bus_id=b.bus_id
         WHERE b.university_id=?
         ORDER BY CASE b.status WHEN 'ACTIVE' THEN 0 WHEN 'MAINTENANCE' THEN 1 ELSE 2 END,b.registration_number",
        [$selectedDate,$universityId]
    );

    $periodStart = $semester['start_date'] ?? '1900-01-01';
    $periodEnd = $semester['end_date'] ?? '2999-12-31';
    $routeUtilisation = fetchAllRows($pdo,
        "SELECT r.route_id,r.route_code,r.route_name,r.fare,r.status,
                COALESCE(ss.trip_count,0) trip_count,COALESCE(ss.seat_capacity_offered,0) seat_capacity_offered,
                COALESCE(bs.booking_count,0) booking_count,COALESCE(bs.seated_booking_count,0) seated_booking_count
         FROM routes r
         LEFT JOIN (
             SELECT s.route_id,COUNT(DISTINCT s.schedule_id) trip_count,COALESCE(SUM(b.seat_capacity),0) seat_capacity_offered
             FROM schedules s JOIN buses b ON b.bus_id=s.bus_id
             WHERE s.schedule_date BETWEEN ? AND ? AND s.status<>'CANCELLED' GROUP BY s.route_id
         ) ss ON ss.route_id=r.route_id
         LEFT JOIN (
             SELECT s.route_id,
                    COUNT(DISTINCT CASE WHEN bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING','COMPLETED') THEN bk.booking_id END) booking_count,
                    COUNT(DISTINCT CASE WHEN bk.slot_type='SEAT' AND bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING','COMPLETED') THEN bk.booking_id END) seated_booking_count
             FROM schedules s LEFT JOIN bookings bk ON bk.schedule_id=s.schedule_id
             WHERE s.schedule_date BETWEEN ? AND ? GROUP BY s.route_id
         ) bs ON bs.route_id=r.route_id
         WHERE r.university_id=? ORDER BY booking_count DESC,r.route_code",
        [$periodStart,$periodEnd,$periodStart,$periodEnd,$universityId]
    );

    if ((int)$complaintStats['awaiting_response'] > 0) {
        $n=(int)$complaintStats['awaiting_response'];
        $needsAttention[] = "$n complaint" . ($n===1?'':'s') . ' awaiting a university response.';
    }

    $panelAvailability['route_stops'] = tableExists($pdo,'route_stops');
    if ($panelAvailability['route_stops']) {
        $missingStops = (int)scalar($pdo,
            "SELECT COUNT(*) FROM routes r
             WHERE r.university_id=? AND r.status='ACTIVE'
               AND NOT EXISTS (SELECT 1 FROM route_stops rs WHERE rs.route_id=r.route_id)",
            [$universityId]
        );
        if ($missingStops > 0) {
            $needsAttention[] = "$missingStops active route" . ($missingStops===1?'':'s') . ' missing a configured stop sequence.';
        }

        $routeStops = fetchAllRows($pdo,
            "SELECT r.route_id,r.route_code,r.route_name,rs.stop_name,rs.stop_order
             FROM routes r LEFT JOIN route_stops rs ON rs.route_id=r.route_id
             WHERE r.university_id=? AND r.status='ACTIVE'
             ORDER BY r.route_code,rs.stop_order LIMIT 80",
            [$universityId]
        );
        foreach ($routeStops as $row) {
            $rid=(int)$row['route_id'];
            $routeStopGroups[$rid] ??= ['route_code'=>$row['route_code'],'route_name'=>$row['route_name'],'stops'=>[]];
            if ($row['stop_name'] !== null) {
                $routeStopGroups[$rid]['stops'][]=['name'=>$row['stop_name'],'order'=>(int)$row['stop_order']];
            }
        }
    }

    $high=0;
    foreach ($departures as $d) {
        if ((int)$d['seat_capacity'] > 0 && percentValue((int)$d['booked_seats'],(int)$d['seat_capacity']) >= 90) $high++;
    }
    if ($high > 0) $needsAttention[] = "$high trip" . ($high===1?'':'s') . ' at or above 90% seated occupancy on the selected date.';

    $noFuture=(int)scalar($pdo,
        "SELECT COUNT(*) FROM routes r
         WHERE r.university_id=? AND r.status='ACTIVE'
           AND NOT EXISTS (SELECT 1 FROM schedules s WHERE s.route_id=r.route_id AND s.schedule_date>=? AND s.status='SCHEDULED')",
        [$universityId,$selectedDate]
    );
    if ($noFuture > 0) $needsAttention[] = "$noFuture active route" . ($noFuture===1?'':'s') . ' with no upcoming scheduled trip.';

    $badBus=(int)scalar($pdo,
        "SELECT COUNT(DISTINCT b.bus_id)
         FROM buses b JOIN schedules s ON s.bus_id=b.bus_id JOIN routes r ON r.route_id=s.route_id
         WHERE b.university_id=? AND r.university_id=? AND b.status<>'ACTIVE' AND s.status='SCHEDULED' AND s.schedule_date>=?",
        [$universityId,$universityId,$selectedDate]
    );
    if ($badBus > 0) $needsAttention[] = "$badBus unavailable bus" . ($badBus===1?'':'es') . ' still referenced by a future schedule.';

    $panelAvailability['ticket_transfers'] = tableExists($pdo,'ticket_transfers');
    if ($panelAvailability['ticket_transfers']) {
        $transferStats = array_merge($transferStats,fetchOne($pdo,
            "SELECT
                COUNT(DISTINCT CASE WHEN tt.status='PENDING' THEN tt.transfer_id END) pending,
                COUNT(DISTINCT CASE WHEN DATE(tt.requested_at)=? THEN tt.transfer_id END) selected_date,
                COUNT(DISTINCT CASE WHEN tt.status='COMPLETED' THEN tt.transfer_id END) completed
             FROM ticket_transfers tt JOIN bookings bk ON bk.booking_id=tt.booking_id
             JOIN schedules s ON s.schedule_id=bk.schedule_id JOIN routes r ON r.route_id=s.route_id
             WHERE r.university_id=?",
            [$selectedDate,$universityId]
        ));
        $recentTransfers=fetchAllRows($pdo,
            "SELECT tt.transfer_id,tt.transfer_type,tt.sale_amount,tt.status,tt.requested_at,tt.responded_at,
                    bk.booking_reference,r.route_code,r.route_name,fp.name from_name,tp.name to_name
             FROM ticket_transfers tt JOIN bookings bk ON bk.booking_id=tt.booking_id
             JOIN schedules s ON s.schedule_id=bk.schedule_id JOIN routes r ON r.route_id=s.route_id
             JOIN (SELECT passenger_id,MIN(name) name FROM passengers GROUP BY passenger_id) fp ON fp.passenger_id=tt.from_passenger_id
             JOIN (SELECT passenger_id,MIN(name) name FROM passengers GROUP BY passenger_id) tp ON tp.passenger_id=tt.to_passenger_id
             WHERE r.university_id=? ORDER BY tt.requested_at DESC,tt.transfer_id DESC LIMIT 5",
            [$universityId]
        );
    }

    $panelAvailability['semester_bills'] = tableExists($pdo,'semester_bills');
    if ($panelAvailability['semester_bills'] && $semester) {
        $billingStats=array_merge($billingStats,fetchOne($pdo,
            "SELECT COUNT(DISTINCT sb.passenger_id) passengers_billed,
                    COALESCE(SUM(sb.total_charges),0) total_charges,
                    COALESCE(SUM(sb.total_credits),0) total_credits,
                    COALESCE(SUM(sb.net_balance),0) net_balance
             FROM semester_bills sb
             JOIN (SELECT DISTINCT passenger_id,university_id FROM passengers) p ON p.passenger_id=sb.passenger_id
             WHERE p.university_id=? AND sb.semester_id=?",
            [$universityId,(int)$semester['semester_id']]
        ));
        $billingStats['transactions']=(int)scalar($pdo,
            "SELECT COUNT(DISTINCT bt.transaction_id)
             FROM billing_transactions bt
             JOIN (SELECT DISTINCT passenger_id,university_id FROM passengers) p ON p.passenger_id=bt.passenger_id
             WHERE p.university_id=? AND bt.semester_id=?",
            [$universityId,(int)$semester['semester_id']]
        );
    }
} catch (Throwable $e) {
    error_log('[UniRide University Admin dashboard] ' . $e->getMessage());
    $dashboardError = 'Some dashboard information is temporarily unavailable.';
}

$seatOccupancy = percentValue((int)$loadStats['booked_seats'],(int)$capacityStats['seat_capacity']);
$standingUsage = percentValue((int)$loadStats['booked_standing'],(int)$capacityStats['standing_capacity']);
$universityName=$university['name']??'University';
$universityCode=$university['code']??'UNI';
$semesterName=$semester['semester_name']??'No active semester';
$passengerCount=(int)$passengerStats['total_passengers'];
$busCount=(int)$fleetStats['total_buses'];
$routeCount=(int)$routeStats['active_routes'];
$openComplaintCount=(int)$complaintStats['open_total'];
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= uh($universityCode) ?> Transport — UniRide</title>
    <?= uniride_theme_head_html('..') ?>
    <link rel="icon" type="image/svg+xml" href="../img/logo.svg">
    <link rel="stylesheet" href="../css/style.css">
    <link rel="stylesheet" href="../css/dashboard.css">
    <link rel="stylesheet" href="../css/university-theme.css">
    <link rel="stylesheet" href="../css/uniride-ui.css">
    <script src="../js/dashboard.js" defer></script>
</head>
<body class="uni-admin-body">
<header class="uni-topbar">
    <div class="uni-topbar-left">
        <button class="sidebar-toggle" type="button" data-sidebar-toggle aria-controls="uniSidebar" aria-expanded="false">
            <span class="sr-only">Toggle navigation</span><span></span><span></span>
        </button>
        <a class="uni-brand" href="../index.php"><img src="../img/logo.svg" alt=""><strong>UniRide</strong><em>University</em></a>
    </div>
    <div class="uni-account">
        <?= profile_avatar_html('..', $adminName, $_SESSION['profile_picture_path'] ?? null) ?>
        <div class="uni-account-copy"><strong><?= uh($adminName) ?></strong><span><?= uh($universityCode) ?> · Uni Admin</span></div>
        <a class="signout-button" href="../logout.php">Sign out</a>
    </div>
</header>

<div class="dashboard-shell">
<aside class="uni-sidebar" id="uniSidebar" data-dashboard-sidebar>
<nav aria-label="University administration">
    <?= dashboard_render_navigation(
        'UNIVERSITY_ADMIN',
        'overview',
        [
            'passengers' => $passengerCount,
            'students' => (int)$passengerStats['students'],
            'faculty' => (int)$passengerStats['faculty'],
            'buses' => $busCount,
            'routes' => $routeCount,
            'complaints' => $openComplaintCount,
        ],
        [],
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
<button class="sidebar-scrim" type="button" data-sidebar-scrim aria-label="Close navigation"></button>

<main class="uni-main">
<?php if ($dashboardError): ?><div class="dashboard-alert is-error" role="alert"><?= uh($dashboardError) ?></div><?php endif; ?>
<?php if ($flash): ?><div class="dashboard-alert <?= ($flash['type']??'')==='success'?'is-success':'is-error' ?>" role="status"><?= uh($flash['message']??'') ?></div><?php endif; ?>

<section class="dashboard-title-row">
    <div>
        <p class="dashboard-kicker"><?= uh($universityCode) ?> transport operations</p>
        <h1><?= uh($universityName) ?> <span>transport</span></h1>
        <p class="dashboard-meta"><?= uh($universityCode) ?><span>·</span>Admin: <?= uh($adminName) ?><span>·</span><?= uh($semesterName) ?><span>·</span><?= uh(date('d M Y')) ?></p>
    </div>
    <div class="quick-actions">
        <?= actionLink('schedules.php','+ Create Schedule','primary-action',['new'=>1]) ?>
        <?= actionLink('buses.php','+ Add Bus','secondary-action',['new'=>1]) ?>
        <?= actionLink('routes.php','+ Add Route','secondary-action',['new'=>1]) ?>
        <?= actionLink('complaints.php','View Complaints','secondary-action') ?>
    </div>
</section>

<section class="metric-grid" aria-label="Transport statistics">
<?php
$metrics=[
 ['Registered passengers',$passengerCount,number_format((int)$passengerStats['students']).' students · '.number_format((int)$passengerStats['faculty']).' faculty'],
 ['Fleet in service',(int)$fleetStats['active_buses'],'of '.number_format((int)$fleetStats['total_buses']).' buses · '.number_format((int)$fleetStats['seat_capacity']).' seats · '.number_format((int)$fleetStats['standing_capacity']).' standing'],
 ['Active routes',(int)$routeStats['active_routes'],'avg fare ৳'.number_format(uniride_ticket_fare(),0)],
 ['Departures '.strtolower($dateContext),(int)$departureStats['departures'],$departureStats['next_departure']?'first departure '.timeLabel($departureStats['next_departure']):'Nothing scheduled for this date'],
 ['Bookings '.strtolower($dateContext),(int)$bookingStats['bookings'],'across '.number_format((int)$bookingStats['trips_with_bookings']).' trips'],
 ['Seat occupancy',$seatOccupancy.'%',number_format((int)$loadStats['booked_seats']).' / '.number_format((int)$capacityStats['seat_capacity']).' seats booked'],
 ['Standing usage',$standingUsage.'%',(int)$capacityStats['standing_capacity']>0?number_format((int)$loadStats['booked_standing']).' / '.number_format((int)$capacityStats['standing_capacity']).' slots used':'No standing capacity offered'],
 ['Open complaints',$openComplaintCount,number_format((int)$complaintStats['awaiting_response']).' awaiting response · '.number_format((int)$complaintStats['in_progress']).' in progress'],
];
foreach($metrics as [$label,$value,$detail]): ?>
<article class="metric-card"><p><?= uh($label) ?></p><strong><?= uh((string)$value) ?></strong><span><?= uh($detail) ?></span></article>
<?php endforeach; ?>
</section>

<section class="attention-panel">
    <div class="section-heading-row"><div><p class="dashboard-kicker">Operational check</p><h2>Needs attention</h2></div></div>
    <?php if (!$needsAttention): ?>
        <div class="attention-clear"><span class="attention-check">✓</span><div><strong>Everything looks good.</strong><p>No urgent transport issues need attention right now.</p></div></div>
    <?php else: ?>
        <div class="attention-list"><?php foreach($needsAttention as $item): ?><div class="attention-item"><span class="attention-dot"></span><p><?= uh($item) ?></p></div><?php endforeach; ?></div>
    <?php endif; ?>
</section>

<section class="dashboard-section">
<div class="section-heading-row departures-heading">
    <div><p class="dashboard-kicker">Daily operations</p><h2>Departures · <?= uh($dateContext) ?></h2><p>Live load per trip, measured against each bus's own capacity.</p></div>
    <div class="date-controls">
        <a class="date-chip <?= $isToday?'is-active':'' ?>" href="dashboard.php">Today</a>
        <a class="date-chip <?= $isTomorrow?'is-active':'' ?>" href="dashboard.php?date=<?= uh($tomorrow->format('Y-m-d')) ?>">Tomorrow</a>
        <button class="date-chip <?= (!$isToday&&!$isTomorrow)?'is-active':'' ?>" type="button" data-custom-date-toggle aria-expanded="<?= (!$isToday&&!$isTomorrow)?'true':'false' ?>">Custom</button>
        <form class="custom-date-form <?= (!$isToday&&!$isTomorrow)?'is-visible':'' ?>" method="get" data-custom-date-form><input type="date" name="date" value="<?= uh($selectedDate) ?>" required><button type="submit">Apply</button></form>
    </div>
</div>
<?php if(!$departures): ?>
<div class="compact-empty"><div><strong>No departures on <?= uh($selectedDateObject->format('d M Y')) ?>.</strong><p>Create a schedule or choose another date.</p></div><?= actionLink('schedules.php','Create a schedule','empty-action',['new'=>1,'date'=>$selectedDate]) ?></div>
<?php else: ?>
<div class="table-wrap"><table class="ops-table departure-table"><thead><tr><th>Route</th><th>Bus</th><th>Departure</th><th>Arrival</th><th>Seats</th><th>Standing</th><th>Load</th><th>Occupancy</th><th>Status</th><th>Actions</th></tr></thead><tbody>
<?php foreach($departures as $d): $bs=(int)$d['booked_seats'];$sc=(int)$d['seat_capacity'];$bst=(int)$d['booked_standing'];$stc=(int)$d['standing_capacity'];$load=(int)$d['total_load'];$totalCap=$sc+$stc;$occ=percentValue($bs,$sc); ?>
<tr>
<td><strong><?= uh($d['route_code']) ?></strong><small><?= uh($d['route_name']) ?></small></td>
<td><strong><?= uh($d['registration_number']) ?></strong><small><?= uh(friendlyBusType($d['bus_type'])) ?></small></td>
<td><?= uh(timeLabel($d['departure_time'])) ?></td><td><?= uh(timeLabel($d['arrival_time'])) ?></td>
<td><strong><?= $bs ?></strong> / <?= $sc ?></td><td><strong><?= $bst ?></strong> / <?= $stc ?></td><td><strong><?= $load ?></strong> / <?= $totalCap ?></td>
<td><div class="occupancy-cell"><div class="occupancy-track" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="<?= $occ ?>"><span style="width:<?= min(100,$occ) ?>%"></span></div><strong><?= $occ ?>%</strong></div></td>
<td><span class="status-pill <?= uh(statusClass($d['status'])) ?>"><?= uh($d['status']) ?></span></td>
<td class="table-actions"><?= actionLink('schedules.php','View','text-action',['schedule_id'=>(int)$d['schedule_id']]) ?> <?= actionLink('bookings.php','Bookings','text-action',['schedule_id'=>(int)$d['schedule_id']]) ?></td>
</tr><?php endforeach; ?></tbody></table></div>
<?php endif; ?>
</section>

<section class="split-section">
<article class="dashboard-section"><div class="section-heading-row"><div><p class="dashboard-kicker">Latest activity</p><h2>Recent bookings</h2></div><?= actionLink('bookings.php','View all') ?></div>
<?php if(!$recentBookings): ?><div class="compact-empty compact-empty-small"><div><strong>No recent bookings.</strong><p>Bookings for your university will appear here.</p></div></div>
<?php else: ?><div class="compact-list"><?php foreach($recentBookings as $b): ?><div class="booking-row"><div class="booking-main"><strong><?= uh($b['booking_reference']) ?></strong><span><?= uh($b['passenger_name']) ?> · <?= uh(ucfirst(strtolower($b['passenger_type']))) ?></span></div><div class="booking-route"><strong><?= uh($b['route_code']) ?></strong><span><?= uh(date('d M',strtotime($b['schedule_date']))) ?> · <?= uh(timeLabel($b['departure_time'])) ?></span></div><div class="booking-slot"><strong><?= uh(seatLabel($b)) ?></strong><span>৳<?= number_format((float)$b['fare_charged'],0) ?></span></div><span class="status-pill <?= uh(statusClass($b['status'])) ?>"><?= uh($b['status']) ?></span></div><?php endforeach; ?></div><?php endif; ?>
</article>

<article class="dashboard-section" id="complaints"><div class="section-heading-row"><div><p class="dashboard-kicker">Service</p><h2>Complaints requiring attention</h2></div><?= actionLink('complaints.php','View all') ?></div>
<?php if(!$complaints): ?><div class="compact-empty compact-empty-small"><div><strong>Nothing awaiting action.</strong><p>Every complaint is resolved or closed.</p></div></div>
<?php else: ?><div class="complaint-list"><?php foreach($complaints as $c): ?><details class="complaint-item"><summary><div><strong><?= uh($c['passenger_name']) ?></strong><span><?= uh($c['subject']) ?></span></div><div class="complaint-summary-meta"><span><?= uh(dateTimeLabel($c['submitted_at'])) ?></span><span class="status-pill <?= uh(statusClass($c['status'])) ?>"><?= uh($c['status']) ?></span></div></summary><div class="complaint-detail"><p><?= nl2br(uh($c['description'])) ?></p><form method="post" class="complaint-form"><input type="hidden" name="action" value="update_complaint"><input type="hidden" name="csrf_token" value="<?= uh($csrfToken) ?>"><input type="hidden" name="complaint_id" value="<?= (int)$c['complaint_id'] ?>"><label><span>Status</span><select name="status"><?php foreach(['OPEN','IN_PROGRESS','RESOLVED','CLOSED'] as $s): ?><option value="<?= uh($s) ?>" <?= $s===$c['status']?'selected':'' ?>><?= uh($s) ?></option><?php endforeach; ?></select></label><label class="complaint-response-field"><span>University response</span><textarea name="university_response" rows="3" placeholder="Add a short response for the passenger..."><?= uh($c['university_response']??'') ?></textarea></label><button class="small-dark-button" type="submit">Save update</button></form></div></details><?php endforeach; ?></div><?php endif; ?>
</article>
</section>

<section class="split-section">
<article class="dashboard-section"><div class="section-heading-row"><div><p class="dashboard-kicker">Fleet</p><h2>Fleet status</h2></div><?= actionLink('buses.php','Manage') ?></div>
<?php if(!$fleet): ?><div class="compact-empty compact-empty-small"><div><strong>No buses registered.</strong><p>Your fleet will appear here.</p></div></div>
<?php else: ?><div class="table-wrap"><table class="ops-table"><thead><tr><th>Registration</th><th>Type</th><th>Capacity</th><th><?= uh($dateContext) ?> trips</th><th>Next departure</th><th>Load</th><th>Status</th></tr></thead><tbody><?php foreach($fleet as $b): ?><tr><td><strong><?= uh($b['registration_number']) ?></strong></td><td><?= uh(friendlyBusType($b['bus_type'])) ?></td><td><?= (int)$b['seat_capacity'] ?> seats<small>+ <?= (int)$b['standing_capacity'] ?> standing</small></td><td><?= (int)$b['trip_count'] ?></td><td><?= uh(dateTimeLabel($b['next_departure'])) ?></td><td><?= (int)$b['active_load'] ?></td><td><span class="status-pill <?= uh(statusClass($b['status'])) ?>"><?= uh($b['status']) ?></span></td></tr><?php endforeach; ?></tbody></table></div><?php endif; ?>
</article>

<article class="dashboard-section"><div class="section-heading-row"><div><p class="dashboard-kicker">Demand</p><h2>Route utilisation</h2><p><?= uh($semesterName) ?> · all recorded trips</p></div><?= actionLink('routes.php','Manage') ?></div>
<?php if(!$routeUtilisation): ?><div class="compact-empty compact-empty-small"><div><strong>No routes available.</strong><p>Active route performance will appear here.</p></div></div>
<?php else: ?><div class="route-util-list"><?php foreach($routeUtilisation as $r): $ro=percentValue((int)$r['seated_booking_count'],(int)$r['seat_capacity_offered']); ?><div class="route-util-row"><div class="route-util-title"><strong><?= uh($r['route_code']) ?></strong><span><?= uh($r['route_name']) ?></span></div><div class="route-util-bar"><span style="width:<?= min(100,$ro) ?>%"></span></div><div class="route-util-meta"><span><?= (int)$r['trip_count'] ?> trips</span><span><?= (int)$r['booking_count'] ?> bookings</span><span><?= $ro ?>% avg seat use</span><span>৳<?= number_format(uniride_ticket_fare(),0) ?></span></div></div><?php endforeach; ?></div><?php endif; ?>
</article>
</section>

<section class="dashboard-section"><div class="section-heading-row"><div><p class="dashboard-kicker">Route setup</p><h2>Route stops</h2><p>The published stop sequence for active routes.</p></div><?= actionLink('route-stops.php','Manage route stops') ?></div>
<?php if(!$panelAvailability['route_stops']): ?><div class="compact-empty compact-empty-small"><div><strong>Route stops are not configured yet.</strong><p>This feature will become available after database setup is completed.</p></div></div>
<?php elseif(!$routeStopGroups): ?><div class="compact-empty compact-empty-small"><div><strong>No route stops configured.</strong><p>Add stop sequences to help passengers understand each route.</p></div></div>
<?php else: ?><div class="stop-grid"><?php foreach(array_slice($routeStopGroups,0,6,true) as $r): ?><article class="stop-card"><div><strong><?= uh($r['route_code']) ?></strong><span><?= uh($r['route_name']) ?></span></div><?php if(!$r['stops']): ?><p class="stop-empty">No stops configured.</p><?php else: ?><ol><?php foreach($r['stops'] as $s): ?><li><span><?= (int)$s['order'] ?></span><?= uh($s['name']) ?></li><?php endforeach; ?></ol><?php endif; ?></article><?php endforeach; ?></div><?php endif; ?>
</section>

<section class="split-section">
<article class="dashboard-section"><div class="section-heading-row"><div><p class="dashboard-kicker">Passenger exchange</p><h2>Ticket transfers</h2></div><?= actionLink('transfers.php','View transfers') ?></div>
<?php if(!$panelAvailability['ticket_transfers']): ?><div class="compact-empty compact-empty-small"><div><strong>Ticket transfers are not configured yet.</strong><p>This panel will activate after database setup is completed.</p></div></div>
<?php else: ?><div class="mini-metrics"><div><strong><?= (int)$transferStats['pending'] ?></strong><span>Pending</span></div><div><strong><?= (int)$transferStats['selected_date'] ?></strong><span><?= uh($dateContext) ?></span></div><div><strong><?= (int)$transferStats['completed'] ?></strong><span>Completed</span></div></div><?php if($recentTransfers): ?><div class="transfer-list"><?php foreach($recentTransfers as $t): ?><div class="transfer-row"><div><strong><?= uh($t['booking_reference']) ?></strong><span><?= uh($t['from_name']) ?> → <?= uh($t['to_name']) ?></span></div><div><strong><?= uh($t['route_code']) ?></strong><span><?= uh($t['transfer_type']) ?></span></div><span class="status-pill <?= uh(statusClass($t['status'])) ?>"><?= uh($t['status']) ?></span></div><?php endforeach; ?></div><?php else: ?><p class="panel-inline-empty">No ticket transfers recorded yet.</p><?php endif; ?><?php endif; ?>
</article>

<article class="dashboard-section"><div class="section-heading-row"><div><p class="dashboard-kicker">Finance</p><h2>Semester billing</h2><p><?= uh($semesterName) ?></p></div><?= actionLink('semester-fares.php','Manage semester & fares') ?></div>
<?php if(!$panelAvailability['semester_bills']): ?><div class="compact-empty compact-empty-small"><div><strong>Semester billing is not configured yet.</strong><p>This panel will activate after database setup is completed.</p></div></div>
<?php else: ?><div class="billing-summary"><div><span>Passengers billed</span><strong><?= (int)$billingStats['passengers_billed'] ?></strong></div><div><span>Transport charges</span><strong>৳<?= number_format((float)$billingStats['total_charges'],0) ?></strong></div><div><span>Credits</span><strong>৳<?= number_format((float)$billingStats['total_credits'],0) ?></strong></div><div><span>Net balance</span><strong>৳<?= number_format((float)$billingStats['net_balance'],0) ?></strong></div><div><span>Transactions</span><strong><?= (int)$billingStats['transactions'] ?></strong></div></div><?php endif; ?>
</article>
</section>
</main>
</div>
</body>
</html>
