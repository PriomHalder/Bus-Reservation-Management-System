<?php
declare(strict_types=1);

require_once __DIR__ . '/profile-service.php';

function profile_session_hash(): string
{
    return hash('sha256', session_id());
}

function profile_register_login(PDO $pdo, string $role, int $userId, bool $audit = true): void
{
    if ($userId <= 0 || !profile_table_exists($pdo, 'user_sessions')) return;
    $hash = profile_session_hash();
    $userAgent = profile_user_agent();
    $ipAddress = profile_client_ip();
    $newDeviceOrNetwork = false;
    if ($audit) {
        $stmt = $pdo->prepare('SELECT COUNT(*) FROM user_sessions WHERE user_type=? AND user_id=?');
        $stmt->execute([$role, $userId]);
        $hasHistory = (int)$stmt->fetchColumn() > 0;
        if ($hasHistory) {
            $stmt = $pdo->prepare(
                'SELECT COUNT(*) FROM user_sessions
                 WHERE user_type=? AND user_id=? AND user_agent=? AND ip_address=?'
            );
            $stmt->execute([$role, $userId, $userAgent, $ipAddress]);
            $newDeviceOrNetwork = (int)$stmt->fetchColumn() === 0;
        }
    }
    $stmt = $pdo->prepare(
        'INSERT INTO user_sessions
         (user_type,user_id,session_token_hash,user_agent,ip_address,logged_in_at,last_activity_at,revoked_at)
         VALUES (?,?,?,?,?,NOW(),NOW(),NULL)
         ON DUPLICATE KEY UPDATE user_type=VALUES(user_type),user_id=VALUES(user_id),
         user_agent=VALUES(user_agent),ip_address=VALUES(ip_address),last_activity_at=NOW(),revoked_at=NULL'
    );
    $stmt->execute([$role, $userId, $hash, $userAgent, $ipAddress]);
    $_SESSION['profile_session_hash'] = $hash;
    $_SESSION['profile_session_touched'] = time();
    if ($audit) {
        profile_log_event($pdo, $role, $userId, 'LOGIN_SUCCESS', 'A successful sign-in was recorded.');
        if ($newDeviceOrNetwork) {
            profile_log_event($pdo, $role, $userId, 'SUSPICIOUS_LOGIN', 'A sign-in from a new device or network was detected.');
            if ($role === 'PASSENGER' && profile_table_exists($pdo, 'notifications')) {
                try {
                    $stmt = $pdo->prepare(
                        "INSERT INTO notifications (passenger_id,title,message,notification_type)
                         VALUES (?,'New sign-in detected','A sign-in from a new device or network was recorded. Review your active sessions if this was not you.','SECURITY')"
                    );
                    $stmt->execute([$userId]);
                } catch (Throwable $e) {
                    error_log('[UniRide security notification] ' . $e->getMessage());
                }
            }
        }
    }
}

function profile_enforce_session(PDO $pdo, string $base = '.'): void
{
    if (!profile_table_exists($pdo, 'user_sessions') || empty($_SESSION['authenticated'])) return;
    $identity = profile_identity();
    if ($identity['user_id'] <= 0 || $identity['role'] === '') return;
    $hash = profile_session_hash();
    $stmt = $pdo->prepare(
        'SELECT revoked_at FROM user_sessions WHERE user_type=? AND user_id=? AND session_token_hash=? LIMIT 1'
    );
    $stmt->execute([$identity['role'], $identity['user_id'], $hash]);
    $row = $stmt->fetch();
    if (!$row) {
        profile_register_login($pdo, $identity['role'], $identity['user_id'], false);
        profile_sync_session($pdo, $identity['role'], $identity['user_id']);
        return;
    }
    if (!empty($row['revoked_at'])) {
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $params = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000, $params['path'], $params['domain'], (bool)$params['secure'], (bool)$params['httponly']);
        }
        session_destroy();
        header('Location: ' . rtrim($base, '/') . '/signin.php?session=revoked');
        exit;
    }
    if ((int)($_SESSION['profile_session_touched'] ?? 0) < time() - 60) {
        $stmt = $pdo->prepare('UPDATE user_sessions SET last_activity_at=NOW() WHERE session_token_hash=? AND revoked_at IS NULL');
        $stmt->execute([$hash]);
        $_SESSION['profile_session_touched'] = time();
    }
    if (!array_key_exists('profile_picture_path', $_SESSION)) {
        profile_sync_session($pdo, $identity['role'], $identity['user_id']);
    }
}

function profile_revoke_current_session(PDO $pdo): void
{
    if (!profile_table_exists($pdo, 'user_sessions') || session_id() === '') return;
    $stmt = $pdo->prepare('UPDATE user_sessions SET revoked_at=COALESCE(revoked_at,NOW()) WHERE session_token_hash=?');
    $stmt->execute([profile_session_hash()]);
}

function profile_active_sessions(PDO $pdo, string $role, int $userId): array
{
    if (!profile_table_exists($pdo, 'user_sessions')) return [];
    $stmt = $pdo->prepare(
        'SELECT session_record_id,session_token_hash,user_agent,ip_address,logged_in_at,last_activity_at
         FROM user_sessions WHERE user_type=? AND user_id=? AND revoked_at IS NULL
         ORDER BY last_activity_at DESC LIMIT 20'
    );
    $stmt->execute([$role, $userId]);
    $current = profile_session_hash();
    $rows = $stmt->fetchAll();
    foreach ($rows as &$row) $row['is_current'] = hash_equals($current, (string)$row['session_token_hash']);
    unset($row);
    return $rows;
}

function profile_revoke_session(PDO $pdo, string $role, int $userId, int $sessionRecordId): bool
{
    if ($sessionRecordId <= 0) return false;
    $stmt = $pdo->prepare(
        'UPDATE user_sessions SET revoked_at=NOW()
         WHERE session_record_id=? AND user_type=? AND user_id=?
         AND session_token_hash<>? AND revoked_at IS NULL'
    );
    $stmt->execute([$sessionRecordId, $role, $userId, profile_session_hash()]);
    if ($stmt->rowCount() > 0) {
        profile_log_event($pdo, $role, $userId, 'SESSION_REVOKED', 'Another active session was signed out.');
        return true;
    }
    return false;
}

function profile_revoke_other_sessions(PDO $pdo, string $role, int $userId): int
{
    $stmt = $pdo->prepare(
        'UPDATE user_sessions SET revoked_at=NOW()
         WHERE user_type=? AND user_id=? AND session_token_hash<>? AND revoked_at IS NULL'
    );
    $stmt->execute([$role, $userId, profile_session_hash()]);
    $count = $stmt->rowCount();
    profile_log_event($pdo, $role, $userId, 'OTHER_SESSIONS_REVOKED', 'All other active sessions were signed out.');
    return $count;
}

function profile_revoke_all_sessions_for_user(PDO $pdo, string $role, int $userId): int
{
    if (!profile_table_exists($pdo, 'user_sessions')) return 0;
    $stmt = $pdo->prepare(
        'UPDATE user_sessions SET revoked_at=NOW() WHERE user_type=? AND user_id=? AND revoked_at IS NULL'
    );
    $stmt->execute([$role, $userId]);
    return $stmt->rowCount();
}

function profile_rotate_current_session(PDO $pdo, string $role, int $userId): void
{
    $oldHash = profile_session_hash();
    $stmt = $pdo->prepare('UPDATE user_sessions SET revoked_at=NOW() WHERE session_token_hash=?');
    $stmt->execute([$oldHash]);
    session_regenerate_id(true);
    profile_register_login($pdo, $role, $userId, false);
}

function profile_device_label(string $agent): string
{
    $browser = str_contains($agent, 'Edg/') ? 'Edge' : (str_contains($agent, 'Chrome/') ? 'Chrome' : (str_contains($agent, 'Firefox/') ? 'Firefox' : (str_contains($agent, 'Safari/') ? 'Safari' : 'Browser')));
    $device = preg_match('/Android|iPhone|Mobile/i', $agent) ? 'Mobile' : (preg_match('/iPad|Tablet/i', $agent) ? 'Tablet' : 'Computer');
    return $browser . ' on ' . $device;
}
