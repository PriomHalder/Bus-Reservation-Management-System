<?php
declare(strict_types=1);

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/dashboard/nav.php';

requireRole('SYSTEM_ADMIN', '..');
date_default_timezone_set('Asia/Dhaka');

function sys_h(mixed $value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

function sys_one(PDO $pdo, string $sql, array $params = []): array
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetch() ?: [];
}

function sys_all(PDO $pdo, string $sql, array $params = []): array
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll();
}

function sys_scalar(PDO $pdo, string $sql, array $params = []): mixed
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchColumn();
}

function sys_csrf(): string
{
    if (empty($_SESSION['system_admin_csrf'])) {
        $_SESSION['system_admin_csrf'] = bin2hex(random_bytes(32));
    }
    return (string)$_SESSION['system_admin_csrf'];
}

function sys_verify_csrf(?string $token): bool
{
    return is_string($token) && $token !== '' && hash_equals(sys_csrf(), $token);
}

function sys_flash(string $type, string $message): void
{
    $_SESSION['system_admin_flash'] = ['type' => $type, 'message' => $message];
    if ($type === 'success' && isset($GLOBALS['pdo'], $GLOBALS['sysAdminId']) && $GLOBALS['pdo'] instanceof PDO) {
        profile_log_event($GLOBALS['pdo'], 'SYSTEM_ADMIN', (int)$GLOBALS['sysAdminId'], 'ADMIN_ACTION', $message);
    }
}

function sys_take_flash(): ?array
{
    $flash = $_SESSION['system_admin_flash'] ?? null;
    unset($_SESSION['system_admin_flash']);
    return is_array($flash) ? $flash : null;
}

function sys_redirect(string $url): never
{
    header('Location: ' . $url);
    exit;
}

function sys_status_class(string $status): string
{
    return strtoupper($status) === 'ACTIVE' ? 'is-good' : 'is-muted';
}

$sysAdminId = (int)($_SESSION['admin_id'] ?? $_SESSION['user_id'] ?? 0);
try {
    $sysAdmin = $sysAdminId > 0
        ? sys_one($pdo, 'SELECT admin_id,name,email,status FROM admins WHERE admin_id=? LIMIT 1', [$sysAdminId])
        : [];
} catch (Throwable $e) {
    error_log('[UniRide system identity] ' . $e->getMessage());
    http_response_code(503);
    uniride_render_error_page('System administration is temporarily unavailable.', '..');
}

if (!$sysAdmin || strtoupper((string)$sysAdmin['status']) !== 'ACTIVE') {
    http_response_code(403);
    uniride_render_error_page('This System Admin account is currently unavailable.', '..');
}

$sysAdminName = (string)$sysAdmin['name'];
$sysNavCounts = ['universities' => 0, 'administrators' => 0];

try {
    $sysNavCounts['universities'] = (int)sys_scalar(
        $pdo,
        'SELECT COUNT(DISTINCT university_id) FROM universities'
    );
    $sysNavCounts['administrators'] = (int)sys_scalar(
        $pdo,
        'SELECT COUNT(DISTINCT university_user_id) FROM university_users'
    );
} catch (Throwable $e) {
    error_log('[UniRide system context] ' . $e->getMessage());
}

function sys_page_start(string $title, string $active, string $description = ''): void
{
    global $sysAdminName, $sysNavCounts, $PROFILE_PAGE_ASSETS;

    $BASE = '..';
    $ROLE = 'SYSTEM_ADMIN';
    $ROLE_WORD = 'System';
    $PAGE_TITLE = $title;
    $ACTIVE_NAV = $active;
    $NAV_COUNTS = $sysNavCounts;
    $NAV_HIDE = [];
    $EXTRA_STYLESHEETS = ['css/admin-pages.css'];
    $EXTRA_SCRIPTS = [];
    if (!empty($PROFILE_PAGE_ASSETS)) {
        $EXTRA_STYLESHEETS[] = 'css/profile.css';
        $EXTRA_SCRIPTS[] = 'js/profile.js';
    }
    $SHELL_USER_NAME = $sysAdminName;
    $SHELL_USER_SUB = 'Platform administration';
    $flash = sys_take_flash();

    require __DIR__ . '/../includes/dashboard/layout_top.php';

    if ($flash) {
        $class = ($flash['type'] ?? '') === 'success' ? 'success' : 'error';
        echo '<div class="alert ' . sys_h($class) . '" role="status">'
            . sys_h($flash['message'] ?? '') . '</div>';
    }

    echo '<section class="page-head"><div><p class="kicker">Shared platform control</p><h1>'
        . sys_h($title) . '</h1>';
    if ($description !== '') {
        echo '<p class="page-meta">' . sys_h($description) . '</p>';
    }
    echo '</div></section>';
}

function sys_page_end(): void
{
    require __DIR__ . '/../includes/dashboard/layout_bottom.php';
}
