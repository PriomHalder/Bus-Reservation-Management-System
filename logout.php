<?php
declare(strict_types=1);

session_start();

try {
    $UNI_DB_OPTIONAL = true;
    require_once __DIR__ . '/config/database.php';
    if ($pdo instanceof PDO) {
        require_once __DIR__ . '/includes/profile/session-management.php';
        profile_revoke_current_session($pdo);
    }
} catch (Throwable $e) {
    error_log('[UniRide logout audit] ' . $e->getMessage());
}

$_SESSION = [];

if (ini_get('session.use_cookies')) {
    $params = session_get_cookie_params();

    setcookie(
        session_name(),
        '',
        time() - 42000,
        $params['path'],
        $params['domain'],
        (bool)$params['secure'],
        (bool)$params['httponly']
    );
}

session_destroy();

header('Location: signin.php');
exit;
