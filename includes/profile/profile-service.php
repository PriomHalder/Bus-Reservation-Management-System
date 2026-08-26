<?php
declare(strict_types=1);

require_once __DIR__ . '/profile-config.php';

function profile_h(mixed $value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

function profile_text_length(string $value): int
{
    return function_exists('mb_strlen') ? mb_strlen($value) : strlen($value);
}

function profile_first_character(string $value): string
{
    $first = function_exists('mb_substr') ? mb_substr($value, 0, 1) : substr($value, 0, 1);
    return function_exists('mb_strtoupper') ? mb_strtoupper($first) : strtoupper($first);
}

function profile_table_exists(PDO $pdo, string $table): bool
{
    static $cache = [];
    if (array_key_exists($table, $cache)) return $cache[$table];
    $stmt = $pdo->prepare(
        'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name=?'
    );
    $stmt->execute([$table]);
    return $cache[$table] = ((int)$stmt->fetchColumn() > 0);
}

function profile_schema_ready(PDO $pdo): bool
{
    foreach (['user_profiles','user_notification_preferences','user_sessions','user_security_events'] as $table) {
        if (!profile_table_exists($pdo, $table)) return false;
    }
    return true;
}

function profile_csrf_token(): string
{
    if (empty($_SESSION['profile_csrf_token'])) {
        $_SESSION['profile_csrf_token'] = bin2hex(random_bytes(32));
    }
    return (string)$_SESSION['profile_csrf_token'];
}

function profile_verify_csrf(?string $token): bool
{
    return is_string($token) && $token !== '' && hash_equals(profile_csrf_token(), $token);
}

function profile_flash(string $type, string $message): void
{
    $_SESSION['profile_flash'] = ['type' => $type, 'message' => $message];
}

function profile_take_flash(): ?array
{
    $flash = $_SESSION['profile_flash'] ?? null;
    unset($_SESSION['profile_flash']);
    return is_array($flash) ? $flash : null;
}

function profile_client_ip(): string
{
    $ip = (string)($_SERVER['REMOTE_ADDR'] ?? '');
    return filter_var($ip, FILTER_VALIDATE_IP) ? substr($ip, 0, 45) : '';
}

function profile_user_agent(): string
{
    return substr(trim((string)($_SERVER['HTTP_USER_AGENT'] ?? 'Unknown device')), 0, 500);
}

function profile_log_event(PDO $pdo, string $role, int $userId, string $type, string $description): void
{
    if ($userId <= 0 || !profile_table_exists($pdo, 'user_security_events')) return;
    try {
        $stmt = $pdo->prepare(
            'INSERT INTO user_security_events
             (user_type,user_id,event_type,event_description,ip_address,user_agent)
             VALUES (?,?,?,?,?,?)'
        );
        $stmt->execute([
            $role, $userId, substr($type, 0, 80), substr($description, 0, 500),
            profile_client_ip(), profile_user_agent(),
        ]);
    } catch (Throwable $e) {
        error_log('[UniRide profile audit] ' . $e->getMessage());
    }
}

function profile_ensure_row(PDO $pdo, string $role, int $userId): void
{
    if (!profile_table_exists($pdo, 'user_profiles')) return;
    $stmt = $pdo->prepare(
        'INSERT IGNORE INTO user_profiles (user_type,user_id) VALUES (?,?)'
    );
    $stmt->execute([$role, $userId]);
}

function profile_sync_session(PDO $pdo, string $role, int $userId): void
{
    if (!profile_table_exists($pdo, 'user_profiles')) return;
    try {
        $stmt = $pdo->prepare('SELECT profile_picture_path FROM user_profiles WHERE user_type=? AND user_id=? LIMIT 1');
        $stmt->execute([$role, $userId]);
        $picture = profile_safe_picture_path($stmt->fetchColumn() ?: null);
        if ($picture !== null) $_SESSION['profile_picture_path'] = $picture;
        else unset($_SESSION['profile_picture_path']);
    } catch (Throwable $e) {
        error_log('[UniRide profile session] ' . $e->getMessage());
    }
}

function profile_load_account(PDO $pdo, string $role, int $userId): array
{
    $role = strtoupper($role);
    if ($userId <= 0) return [];

    if ($role === 'PASSENGER') {
        $stmt = $pdo->prepare(
            "SELECT p.passenger_id AS user_id,p.name,p.email,p.passenger_type AS role_detail,
                    p.phone AS account_phone,p.status,p.created_at,p.university_id,
                    u.name AS university_name,u.code AS university_code,u.status AS university_status
             FROM passengers p JOIN universities u ON u.university_id=p.university_id
             WHERE p.passenger_id=? LIMIT 1"
        );
    } elseif ($role === 'UNIVERSITY_ADMIN') {
        $stmt = $pdo->prepare(
            "SELECT uu.university_user_id AS user_id,uu.name,uu.email,uu.role AS role_detail,
                    NULL AS account_phone,uu.status,uu.created_at,uu.university_id,
                    u.name AS university_name,u.code AS university_code,u.status AS university_status
             FROM university_users uu JOIN universities u ON u.university_id=uu.university_id
             WHERE uu.university_user_id=? LIMIT 1"
        );
    } elseif ($role === 'SYSTEM_ADMIN') {
        $stmt = $pdo->prepare(
            "SELECT a.admin_id AS user_id,a.name,a.email,'SYSTEM_ADMIN' AS role_detail,
                    NULL AS account_phone,a.status,a.created_at,NULL AS university_id,
                    'UniRide Platform' AS university_name,'PLATFORM' AS university_code,
                    'ACTIVE' AS university_status
             FROM admins a WHERE a.admin_id=? LIMIT 1"
        );
    } else {
        return [];
    }

    $stmt->execute([$userId]);
    $account = $stmt->fetch() ?: [];
    if (!$account) return [];

    $profile = [];
    if (profile_table_exists($pdo, 'user_profiles')) {
        profile_ensure_row($pdo, $role, $userId);
        $stmt = $pdo->prepare('SELECT * FROM user_profiles WHERE user_type=? AND user_id=? LIMIT 1');
        $stmt->execute([$role, $userId]);
        $profile = $stmt->fetch() ?: [];
    }

    $account = array_merge($account, $profile);
    if (empty($account['phone'])) $account['phone'] = $account['account_phone'] ?? '';

    if ($role === 'PASSENGER') {
        $type = strtoupper((string)($account['role_detail'] ?? ''));
        if ($type === 'STUDENT') {
            $stmt = $pdo->prepare(
                'SELECT student_identifier AS institutional_id,department,program AS academic_detail,semester_label
                 FROM students WHERE passenger_id=? LIMIT 1'
            );
        } else {
            $stmt = $pdo->prepare(
                "SELECT faculty_identifier AS institutional_id,department,designation AS academic_detail,
                        'Faculty' AS semester_label FROM faculty WHERE passenger_id=? LIMIT 1"
            );
        }
        $stmt->execute([$userId]);
        $account = array_merge($account, $stmt->fetch() ?: []);
        $account['verification_status'] = !empty($account['institutional_id']) ? 'Verified' : 'Pending verification';
    } else {
        $account['verification_status'] = strtoupper((string)$account['status']) === 'ACTIVE' ? 'Verified' : 'Unavailable';
    }

    $account['last_login'] = null;
    if (profile_table_exists($pdo, 'user_sessions')) {
        $stmt = $pdo->prepare('SELECT MAX(logged_in_at) FROM user_sessions WHERE user_type=? AND user_id=?');
        $stmt->execute([$role, $userId]);
        $account['last_login'] = $stmt->fetchColumn() ?: null;
    }
    return $account;
}

function profile_valid_phone(string $value): bool
{
    return $value === '' || (bool)preg_match('/^[+0-9][0-9 ()-]{6,24}$/', $value);
}

function profile_valid_date(string $value): bool
{
    if ($value === '') return true;
    $date = DateTimeImmutable::createFromFormat('!Y-m-d', $value);
    return $date instanceof DateTimeImmutable && $date->format('Y-m-d') === $value && $date <= new DateTimeImmutable('today');
}

function profile_update_personal(PDO $pdo, string $role, int $userId, array $input): void
{
    $config = profile_role_config($role);
    $name = trim((string)($input['name'] ?? ''));
    $phone = trim((string)($input['phone'] ?? ''));
    $address = trim((string)($input['address'] ?? ''));
    $dob = trim((string)($input['date_of_birth'] ?? ''));
    $gender = strtoupper(trim((string)($input['gender'] ?? '')));
    $emergencyName = trim((string)($input['emergency_contact_name'] ?? ''));
    $emergencyPhone = trim((string)($input['emergency_contact_phone'] ?? ''));

    if ($name === '' || profile_text_length($name) > 200) throw new RuntimeException('Enter a valid name containing no more than 200 characters.');
    if (!profile_valid_phone($phone) || !profile_valid_phone($emergencyPhone)) throw new RuntimeException('Enter valid phone numbers using digits, spaces, brackets, hyphens or a leading plus sign.');
    if (profile_text_length($address) > 500 || profile_text_length($emergencyName) > 200) throw new RuntimeException('One or more personal details are too long.');
    if (!profile_valid_date($dob)) throw new RuntimeException('Enter a valid date of birth that is not in the future.');
    if (!in_array($gender, ['', 'FEMALE', 'MALE', 'NON_BINARY', 'PREFER_NOT_TO_SAY'], true)) throw new RuntimeException('Select a valid gender option.');

    $seat = strtoupper((string)($input['seat_preference'] ?? 'NO_PREFERENCE'));
    if (!in_array($seat, ['SEAT','STANDING','NO_PREFERENCE'], true)) $seat = 'NO_PREFERENCE';
    $boarding = trim((string)($input['preferred_boarding_stop'] ?? ''));
    $destination = trim((string)($input['preferred_destination_stop'] ?? ''));
    $jobTitle = trim((string)($input['job_title'] ?? ''));
    $department = trim((string)($input['department'] ?? ''));
    $officePhone = trim((string)($input['office_phone'] ?? ''));
    $officeLocation = trim((string)($input['office_location'] ?? ''));

    if (profile_text_length($boarding) > 200 || profile_text_length($destination) > 200 || profile_text_length($jobTitle) > 150 || profile_text_length($department) > 200 || profile_text_length($officeLocation) > 250) {
        throw new RuntimeException('One or more role-specific details are too long.');
    }
    if (!profile_valid_phone($officePhone)) throw new RuntimeException('Enter a valid office phone number.');

    $pdo->beginTransaction();
    try {
        $table = $config['table'];
        $idColumn = $config['id_column'];
        $stmt = $pdo->prepare("UPDATE {$table} SET name=? WHERE {$idColumn}=?");
        $stmt->execute([$name, $userId]);

        $stmt = $pdo->prepare(
            'INSERT INTO user_profiles
             (user_type,user_id,phone,address,date_of_birth,gender,emergency_contact_name,
              emergency_contact_phone,preferred_boarding_stop,preferred_destination_stop,
              seat_preference,job_title,department,office_phone,office_location)
             VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
             ON DUPLICATE KEY UPDATE phone=VALUES(phone),address=VALUES(address),
              date_of_birth=VALUES(date_of_birth),gender=VALUES(gender),
              emergency_contact_name=VALUES(emergency_contact_name),
              emergency_contact_phone=VALUES(emergency_contact_phone),
              preferred_boarding_stop=VALUES(preferred_boarding_stop),
              preferred_destination_stop=VALUES(preferred_destination_stop),
              seat_preference=VALUES(seat_preference),job_title=VALUES(job_title),
              department=VALUES(department),office_phone=VALUES(office_phone),
              office_location=VALUES(office_location)'
        );
        $stmt->execute([
            $role,$userId,$phone,$address,$dob !== '' ? $dob : null,$gender !== '' ? $gender : null,
            $emergencyName,$emergencyPhone,
            $role === 'PASSENGER' ? $boarding : null,
            $role === 'PASSENGER' ? $destination : null,
            $role === 'PASSENGER' ? $seat : 'NO_PREFERENCE',
            $role === 'UNIVERSITY_ADMIN' ? $jobTitle : null,
            $role === 'UNIVERSITY_ADMIN' ? $department : null,
            $role === 'UNIVERSITY_ADMIN' ? $officePhone : null,
            $role === 'UNIVERSITY_ADMIN' ? $officeLocation : null,
        ]);

        if ($role === 'PASSENGER') {
            $stmt = $pdo->prepare('UPDATE passengers SET phone=? WHERE passenger_id=?');
            $stmt->execute([$phone, $userId]);
        }
        $pdo->commit();
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }

    $_SESSION['name'] = $name;
    profile_log_event($pdo, $role, $userId, 'PROFILE_UPDATED', 'Personal profile information was updated.');
}

function profile_notification_values(PDO $pdo, string $role, int $userId): array
{
    $definitions = profile_role_config($role)['notifications'];
    $values = array_fill_keys(array_keys($definitions), true);
    if (!profile_table_exists($pdo, 'user_notification_preferences')) return $values;
    $stmt = $pdo->prepare('SELECT preference_key,enabled FROM user_notification_preferences WHERE user_type=? AND user_id=?');
    $stmt->execute([$role, $userId]);
    foreach ($stmt->fetchAll() as $row) {
        if (array_key_exists($row['preference_key'], $values)) $values[$row['preference_key']] = (bool)$row['enabled'];
    }
    foreach ($definitions as $key => $definition) {
        if (!empty($definition['essential'])) $values[$key] = true;
    }
    return $values;
}

function profile_update_notifications(PDO $pdo, string $role, int $userId, array $input): void
{
    $definitions = profile_role_config($role)['notifications'];
    $submitted = isset($input['notifications']) && is_array($input['notifications'])
        ? $input['notifications']
        : [];
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            'INSERT INTO user_notification_preferences (user_type,user_id,preference_key,enabled)
             VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE enabled=VALUES(enabled)'
        );
        foreach ($definitions as $key => $definition) {
            $enabled = !empty($definition['essential']) || isset($submitted[$key]);
            $stmt->execute([$role, $userId, $key, $enabled ? 1 : 0]);
        }
        if ($role === 'PASSENGER') {
            $stmt = $pdo->prepare('UPDATE passengers SET email_notifications=?,in_app_notifications=? WHERE passenger_id=?');
            $stmt->execute([
                isset($submitted['email_notifications']) ? 1 : 0,
                isset($submitted['dashboard_notifications']) ? 1 : 0,
                $userId,
            ]);
        }
        $pdo->commit();
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        throw $e;
    }
    profile_log_event($pdo, $role, $userId, 'NOTIFICATIONS_UPDATED', 'Notification preferences were updated.');
}

function profile_recent_activity(PDO $pdo, string $role, int $userId, int $limit = 12): array
{
    if (!profile_table_exists($pdo, 'user_security_events')) return [];
    $limit = max(1, min(30, $limit));
    $stmt = $pdo->prepare(
        "SELECT event_type,event_description,ip_address,user_agent,occurred_at
         FROM user_security_events WHERE user_type=? AND user_id=?
         ORDER BY occurred_at DESC LIMIT {$limit}"
    );
    $stmt->execute([$role, $userId]);
    return $stmt->fetchAll();
}

function profile_initials(string $name): string
{
    $parts = preg_split('/\s+/', trim($name)) ?: [];
    $initials = '';
    foreach (array_slice($parts, 0, 2) as $part) {
        $initials .= profile_first_character($part);
    }
    return $initials !== '' ? $initials : 'UR';
}

function profile_safe_picture_path(?string $path): ?string
{
    $path = ltrim((string)$path, '/');
    return preg_match('#^uploads/profile/[a-f0-9]{32}\.(?:jpg|png|webp)$#', $path) ? $path : null;
}

function profile_avatar_html(string $base, string $name, ?string $picturePath, string $class = 'profile-avatar profile-avatar-small'): string
{
    $safe = profile_safe_picture_path($picturePath);
    $label = profile_h($name . ' profile picture');
    if ($safe !== null) {
        return '<span class="' . profile_h($class) . '"><img src="'
            . profile_h(rtrim($base, '/') . '/' . $safe) . '" alt="' . $label . '"></span>';
    }
    return '<span class="' . profile_h($class) . '" role="img" aria-label="' . $label . '"><span>'
        . profile_h(profile_initials($name)) . '</span></span>';
}
