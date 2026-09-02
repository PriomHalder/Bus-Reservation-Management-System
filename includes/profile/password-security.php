<?php
declare(strict_types=1);

require_once __DIR__ . '/session-management.php';

function profile_password_is_strong(string $password): bool
{
    return strlen($password) >= 8
        && strlen($password) <= 128
        && preg_match('/[a-z]/', $password)
        && preg_match('/[A-Z]/', $password)
        && preg_match('/[0-9]/', $password)
        && preg_match('/[^A-Za-z0-9]/', $password);
}

function profile_password_failures(PDO $pdo, string $role, int $userId): int
{
    if (!profile_table_exists($pdo, 'user_security_events')) return 0;
    $stmt = $pdo->prepare(
        "SELECT COUNT(*) FROM user_security_events
         WHERE user_type=? AND user_id=? AND event_type='PASSWORD_CHANGE_FAILED'
         AND occurred_at >= DATE_SUB(NOW(), INTERVAL 15 MINUTE)"
    );
    $stmt->execute([$role, $userId]);
    return (int)$stmt->fetchColumn();
}

function profile_change_password(PDO $pdo, string $role, int $userId, string $current, string $new, string $confirm): void
{
    if (profile_password_failures($pdo, $role, $userId) >= 5) {
        throw new RuntimeException('Too many unsuccessful attempts. Wait 15 minutes before trying again.');
    }
    if ($new !== $confirm) throw new RuntimeException('The new-password confirmation does not match.');
    if (!profile_password_is_strong($new)) {
        throw new RuntimeException('Use 8–128 characters with uppercase, lowercase, a number and a special character.');
    }
    $config = profile_role_config($role);
    $table = $config['table'];
    $idColumn = $config['id_column'];
    $passwordColumn = $config['password_column'];
    $stmt = $pdo->prepare("SELECT {$passwordColumn} FROM {$table} WHERE {$idColumn}=? LIMIT 1");
    $stmt->execute([$userId]);
    $hash = (string)$stmt->fetchColumn();
    if ($hash === '' || !password_verify($current, $hash)) {
        profile_log_event($pdo, $role, $userId, 'PASSWORD_CHANGE_FAILED', 'An incorrect current password was supplied.');
        throw new RuntimeException('The current password is incorrect.');
    }
    if (password_verify($new, $hash)) throw new RuntimeException('The new password must be different from the current password.');

    $newHash = password_hash($new, PASSWORD_DEFAULT);
    if (!is_string($newHash) || $newHash === '') throw new RuntimeException('A secure password hash could not be generated.');
    $stmt = $pdo->prepare("UPDATE {$table} SET {$passwordColumn}=? WHERE {$idColumn}=?");
    $stmt->execute([$newHash, $userId]);

    profile_revoke_other_sessions($pdo, $role, $userId);
    profile_rotate_current_session($pdo, $role, $userId);
    profile_log_event($pdo, $role, $userId, 'PASSWORD_CHANGED', 'The account password was changed securely.');

    if ($role === 'PASSENGER' && profile_table_exists($pdo, 'notifications')) {
        $stmt = $pdo->prepare(
            "INSERT INTO notifications (passenger_id,title,message,notification_type)
             VALUES (?,'Password changed','Your UniRide password was changed. If this was not you, contact support immediately.','SECURITY')"
        );
        $stmt->execute([$userId]);
    }
}
