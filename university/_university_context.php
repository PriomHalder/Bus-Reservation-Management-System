<?php
declare(strict_types=1);

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/booking-service.php';
require_once __DIR__ . '/../includes/profile/session-management.php';

if (empty($_SESSION['authenticated'])) {
    header('Location: ../signin.php');
    exit;
}

if (($_SESSION['user_type'] ?? '') !== 'UNIVERSITY_ADMIN') {
    header('Location: ../dashboard.php');
    exit;
}

date_default_timezone_set('Asia/Dhaka');

$uUniversityId = (int)($_SESSION['university_id'] ?? 0);
$uAdminId = (int)($_SESSION['university_user_id'] ?? $_SESSION['user_id'] ?? 0);
$uAdminName = (string)($_SESSION['name'] ?? 'University Admin');

if ($uUniversityId <= 0) {
    http_response_code(403);
    uniride_render_error_page('University access is unavailable for this account.', '..');
}

function u_h(mixed $value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

function u_one(PDO $pdo, string $sql, array $params = []): array
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetch() ?: [];
}

function u_all(PDO $pdo, string $sql, array $params = []): array
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll();
}

function u_scalar(PDO $pdo, string $sql, array $params = []): mixed
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchColumn();
}

function u_table_exists(PDO $pdo, string $table): bool
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

function u_column_exists(PDO $pdo, string $table, string $column): bool
{
    static $cache = [];
    $key = $table . '.' . $column;
    if (array_key_exists($key, $cache)) {
        return $cache[$key];
    }
    $stmt = $pdo->prepare(
        "SELECT COUNT(*) FROM information_schema.columns
         WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?"
    );
    $stmt->execute([$table, $column]);
    return $cache[$key] = ((int)$stmt->fetchColumn() > 0);
}

function u_csrf(): string
{
    if (empty($_SESSION['university_admin_csrf'])) {
        $_SESSION['university_admin_csrf'] = bin2hex(random_bytes(32));
    }
    return (string)$_SESSION['university_admin_csrf'];
}

function u_verify_csrf(?string $token): bool
{
    return is_string($token) && $token !== '' && hash_equals(u_csrf(), $token);
}

function u_flash(string $type, string $message): void
{
    $_SESSION['university_flash'] = ['type' => $type, 'message' => $message];
    if ($type === 'success' && isset($GLOBALS['pdo'], $GLOBALS['uAdminId']) && $GLOBALS['pdo'] instanceof PDO) {
        profile_log_event($GLOBALS['pdo'], 'UNIVERSITY_ADMIN', (int)$GLOBALS['uAdminId'], 'ADMIN_ACTION', $message);
    }
}

function u_take_flash(): ?array
{
    $flash = $_SESSION['university_flash'] ?? null;
    unset($_SESSION['university_flash']);
    return is_array($flash) ? $flash : null;
}

function u_redirect(string $url): never
{
    header('Location: ' . $url);
    exit;
}

function u_valid_date(?string $date): ?string
{
    if (!$date || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
        return null;
    }
    $obj = DateTimeImmutable::createFromFormat('!Y-m-d', $date);
    return ($obj && $obj->format('Y-m-d') === $date) ? $date : null;
}

function u_time(?string $time): string
{
    if (!$time) return '—';
    $ts = strtotime($time);
    return $ts ? date('g:i A', $ts) : $time;
}

function u_date(?string $value, string $format = 'd M Y'): string
{
    if (!$value) return '—';
    $ts = strtotime($value);
    return $ts ? date($format, $ts) : $value;
}

function u_percent(int|float $used, int|float $capacity): int
{
    return $capacity > 0 ? (int)round(($used / $capacity) * 100) : 0;
}

function u_status_class(string $status): string
{
    return match (strtoupper($status)) {
        'ACTIVE','CONFIRMED','COMPLETED','RESOLVED','PUBLISHED' => 'is-good',
        'OPEN','MAINTENANCE' => 'is-warn',
        'SCHEDULED','IN_PROGRESS','BOOKED','TRANSFER_PENDING','PENDING' => 'is-neutral',
        'INACTIVE','SUSPENDED','CANCELLED','CLOSED','REJECTED','ARCHIVED' => 'is-muted',
        default => 'is-neutral',
    };
}

function u_bus_type(string $type): string
{
    return match ($type) {
        'STUDENT_ONLY' => 'Student only',
        'FACULTY_ONLY' => 'Faculty only',
        'STANDARD' => 'Standard',
        default => ucwords(strtolower(str_replace('_', ' ', $type))),
    };
}

function u_seat_label(array $row): string
{
    if (($row['slot_type'] ?? '') === 'STANDING') {
        $slot = (int)($row['standing_slot'] ?? 0);
        return $slot > 0 ? 'Standing ' . $slot : 'Standing';
    }
    $seat = (int)($row['seat_number'] ?? 0);
    if ($seat < 1) return 'Seat';
    $letter = chr(64 + (int)ceil($seat / 4));
    $column = (($seat - 1) % 4) + 1;
    return $letter . $column;
}

try {
    $uAdmin = u_one(
        $pdo,
        "SELECT university_user_id,university_id,name,email,role,status
         FROM university_users
         WHERE university_user_id=? AND university_id=? LIMIT 1",
        [$uAdminId, $uUniversityId]
    );
} catch (Throwable $e) {
    error_log('[UniRide university identity] ' . $e->getMessage());
    http_response_code(503);
    uniride_render_error_page('University administration is temporarily unavailable.', '..');
}

if (!$uAdmin || strtoupper((string)$uAdmin['status']) !== 'ACTIVE') {
    http_response_code(403);
    uniride_render_error_page('This University Admin account is currently unavailable.', '..');
}

// Display current database values instead of stale session copies. The
// session identifies the account; the database remains authoritative.
$uAdminName = (string)$uAdmin['name'];
profile_enforce_session($pdo, '..');

$uUniversity = u_one(
    $pdo,
    "SELECT university_id,name,code,academic_domain,address,contact_email,logo_path,status,created_at
     FROM universities WHERE university_id=? LIMIT 1",
    [$uUniversityId]
);

if (!$uUniversity) {
    http_response_code(403);
    uniride_render_error_page('Your university is not available.', '..');
}

if (strtoupper((string)$uUniversity['status']) !== 'ACTIVE') {
    http_response_code(403);
    uniride_render_error_page('This university is currently inactive.', '..');
}

if (u_table_exists($pdo, 'semesters') && u_column_exists($pdo, 'semesters', 'university_id')) {
    $uSemester = u_one(
        $pdo,
        "SELECT semester_id,semester_name,start_date,end_date,is_active
         FROM semesters WHERE university_id=? AND is_active=1
         ORDER BY start_date DESC LIMIT 1",
        [$uUniversityId]
    );
} else {
    $uSemester = u_table_exists($pdo, 'semesters')
        ? u_one($pdo, "SELECT semester_id,semester_name,start_date,end_date,is_active FROM semesters WHERE is_active=1 ORDER BY start_date DESC LIMIT 1")
        : [];
}

$uNavCounts = ['passengers'=>0,'students'=>0,'faculty'=>0,'buses'=>0,'routes'=>0];
try {
    $pc = u_one($pdo,
        "SELECT COUNT(DISTINCT passenger_id) passengers,
                COUNT(DISTINCT CASE WHEN passenger_type='STUDENT' THEN passenger_id END) students,
                COUNT(DISTINCT CASE WHEN passenger_type='FACULTY' THEN passenger_id END) faculty
         FROM passengers WHERE university_id=?",
        [$uUniversityId]
    );
    $uNavCounts['passengers']=(int)($pc['passengers']??0);
    $uNavCounts['students']=(int)($pc['students']??0);
    $uNavCounts['faculty']=(int)($pc['faculty']??0);
    $uNavCounts['buses']=(int)u_scalar($pdo,"SELECT COUNT(DISTINCT bus_id) FROM buses WHERE university_id=?",[$uUniversityId]);
    $uNavCounts['routes']=(int)u_scalar($pdo,"SELECT COUNT(DISTINCT route_id) FROM routes WHERE university_id=?",[$uUniversityId]);
} catch (Throwable $e) {
    error_log('[UniRide university context] ' . $e->getMessage());
}
