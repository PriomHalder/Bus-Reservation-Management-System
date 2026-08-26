<?php
declare(strict_types=1);

require_once __DIR__ . '/profile-service.php';
require_once __DIR__ . '/profile-picture.php';
require_once __DIR__ . '/password-security.php';
require_once __DIR__ . '/profile-navigation.php';

function profile_action_tab(string $action): string
{
    return match ($action) {
        'update_personal' => 'personal',
        'upload_picture','remove_picture' => 'picture',
        'update_notifications' => 'notifications',
        'change_password' => 'security',
        'revoke_session','logout_others' => 'sessions',
        default => 'overview',
    };
}

function profile_handle_request(PDO $pdo, string $role, int $userId, string $redirect = 'profile.php'): void
{
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') return;
    $action = (string)($_POST['action'] ?? '');
    $tab = profile_action_tab($action);
    if (!profile_schema_ready($pdo)) {
        profile_flash('error', 'Profile storage is not installed. Run database/migrations/004_shared_profile_management.sql.');
        header('Location: ' . $redirect . '#overview');
        exit;
    }
    if (!profile_verify_csrf($_POST['csrf_token'] ?? null)) {
        profile_flash('error', 'Your session expired. Refresh the page and try again.');
        header('Location: ' . $redirect . '#' . $tab);
        exit;
    }

    try {
        switch ($action) {
            case 'update_personal':
                profile_update_personal($pdo, $role, $userId, $_POST);
                profile_flash('success', 'Your profile information has been updated.');
                break;
            case 'upload_picture':
                profile_upload_picture($pdo, $role, $userId, $_FILES['profile_picture'] ?? []);
                profile_flash('success', 'Your profile picture has been updated.');
                break;
            case 'remove_picture':
                profile_remove_picture($pdo, $role, $userId);
                profile_flash('success', 'Your profile picture has been removed.');
                break;
            case 'update_notifications':
                profile_update_notifications($pdo, $role, $userId, $_POST);
                profile_flash('success', 'Notification preferences have been saved.');
                break;
            case 'change_password':
                profile_change_password(
                    $pdo, $role, $userId,
                    (string)($_POST['current_password'] ?? ''),
                    (string)($_POST['new_password'] ?? ''),
                    (string)($_POST['confirm_password'] ?? '')
                );
                profile_flash('success', 'Your password has been changed and other sessions were signed out.');
                break;
            case 'revoke_session':
                if (!profile_revoke_session($pdo, $role, $userId, (int)($_POST['session_record_id'] ?? 0))) {
                    throw new RuntimeException('That session is unavailable or is your current session.');
                }
                profile_flash('success', 'The selected session has been signed out.');
                break;
            case 'logout_others':
                $count = profile_revoke_other_sessions($pdo, $role, $userId);
                profile_flash('success', $count > 0 ? "{$count} other session(s) were signed out." : 'There were no other active sessions.');
                break;
            default:
                throw new RuntimeException('The requested profile action is not available.');
        }
    } catch (Throwable $e) {
        error_log('[UniRide profile action] ' . $e->getMessage());
        profile_flash('error', $e instanceof RuntimeException ? $e->getMessage() : 'The profile change could not be completed.');
    }
    header('Location: ' . $redirect . '#' . $tab);
    exit;
}

function profile_date_label(?string $value, string $format = 'd M Y · g:i A'): string
{
    if (!$value) return 'Not available';
    $timestamp = strtotime($value);
    return $timestamp ? date($format, $timestamp) : $value;
}

function profile_mask_ip(?string $ip): string
{
    if (!$ip) return 'Unavailable';
    if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
        $parts = explode('.', $ip); $parts[3] = '×'; return implode('.', $parts);
    }
    if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
        return substr($ip, 0, 12) . '…';
    }
    return 'Unavailable';
}

function profile_passenger_favorite_routes(PDO $pdo, int $passengerId): array
{
    if ($passengerId <= 0 || !profile_table_exists($pdo, 'favorite_routes') || !profile_table_exists($pdo, 'routes')) {
        return [];
    }
    $stmt = $pdo->prepare(
        'SELECT r.route_code,r.route_name
         FROM favorite_routes fr
         INNER JOIN routes r ON r.route_id=fr.route_id
         INNER JOIN passengers p ON p.passenger_id=fr.passenger_id
         WHERE fr.passenger_id=? AND r.university_id=p.university_id
         ORDER BY fr.created_at DESC,r.route_code ASC LIMIT 6'
    );
    $stmt->execute([$passengerId]);
    return $stmt->fetchAll();
}

function profile_panel_start(string $key, bool $active = false): void
{
    echo '<section id="profile-panel-' . profile_h($key) . '" class="profile-panel' . ($active ? ' is-active' : '')
        . '" data-profile-panel="' . profile_h($key) . '" role="tabpanel"' . ($active ? '' : ' hidden') . '>';
}

function profile_render_page(PDO $pdo, string $role, int $userId, string $base = '..'): void
{
    $config = profile_role_config($role);
    $flash = profile_take_flash();
    if ($flash) {
        echo '<div class="profile-alert ' . (($flash['type'] ?? '') === 'success' ? 'is-success' : 'is-error')
            . '" role="status">' . profile_h($flash['message'] ?? '') . '</div>';
    }
    if (!profile_schema_ready($pdo)) {
        echo '<section class="profile-setup-notice"><p class="profile-eyebrow">One-time setup</p><h2>Profile migration required</h2>'
            . '<p>Import <code>database/migrations/004_shared_profile_management.sql</code> once. It is non-destructive and enables the same profile system for every current and future account.</p></section>';
        return;
    }

    $account = profile_load_account($pdo, $role, $userId);
    if (!$account) {
        echo '<div class="profile-alert is-error">The authenticated profile could not be loaded.</div>';
        return;
    }
    $preferences = profile_notification_values($pdo, $role, $userId);
    $sessions = profile_active_sessions($pdo, $role, $userId);
    $activity = profile_recent_activity($pdo, $role, $userId);
    $csrf = profile_csrf_token();
    $picture = $account['profile_picture_path'] ?? null;
    $isPassenger = $role === 'PASSENGER';
    $isUniversityAdmin = $role === 'UNIVERSITY_ADMIN';
    $favoriteRoutes = $isPassenger ? profile_passenger_favorite_routes($pdo, $userId) : [];

    echo '<noscript><style>.profile-tabs{display:none!important}.profile-panel[hidden]{display:block!important}.profile-panel{margin-top:18px}</style></noscript>';
    echo '<div class="profile-workspace">';
    echo '<section class="profile-hero">'
        . profile_avatar_html($base, (string)$account['name'], $picture, 'profile-avatar profile-avatar-hero')
        . '<div class="profile-hero-copy"><p class="profile-eyebrow">' . profile_h($config['label']) . ' account</p>'
        . '<h2>' . profile_h($account['name']) . '</h2><p>' . profile_h($account['email']) . '</p>'
        . '<div class="profile-badges"><span>' . profile_h($account['status']) . '</span><span>'
        . profile_h($account['verification_status']) . '</span>'
        . (!empty($account['university_name']) ? '<span>' . profile_h($account['university_name']) . '</span>' : '')
        . '</div></div><button class="profile-primary" type="button" data-open-profile-tab="personal">Edit profile</button></section>';

    profile_render_navigation();

    profile_panel_start('overview', true);
    echo '<div class="profile-card-grid">';
    echo '<article class="profile-card"><p class="profile-eyebrow">Account details</p><h3>Verified identity</h3><dl class="profile-details">'
        . '<div><dt>Email</dt><dd>' . profile_h($account['email']) . '</dd></div>'
        . '<div><dt>Role</dt><dd>' . profile_h($config['label']) . '</dd></div>'
        . '<div><dt>Status</dt><dd>' . profile_h($account['status']) . '</dd></div>'
        . '<div><dt>Created</dt><dd>' . profile_h(profile_date_label($account['created_at'] ?? null, 'd M Y')) . '</dd></div>'
        . '<div><dt>Last login</dt><dd>' . profile_h(profile_date_label($account['last_login'] ?? null)) . '</dd></div>'
        . '<div><dt>Last profile update</dt><dd>' . profile_h(profile_date_label($account['updated_at'] ?? null)) . '</dd></div>'
        . '</dl></article>';

    if ($isPassenger) {
        echo '<article class="profile-card profile-identity-card"><div><p class="profile-eyebrow">Digital passenger card</p><h3>'
            . profile_h($account['university_code']) . ' · ' . profile_h(ucfirst(strtolower((string)$account['role_detail'])))
            . '</h3><strong>' . profile_h($account['institutional_id'] ?? 'Institutional ID pending') . '</strong><p>'
            . profile_h($account['department'] ?? 'Department unavailable') . '</p><div class="profile-favorite-routes"><span>Favorite routes</span>'
            . ($favoriteRoutes
                ? implode('', array_map(
                    static fn(array $route): string => '<em>' . profile_h((string)$route['route_code']) . ' · ' . profile_h((string)$route['route_name']) . '</em>',
                    $favoriteRoutes
                ))
                : '<em>No routes saved yet</em>')
            . '</div></div><div class="profile-id-mark">'
            . profile_h(profile_initials((string)$account['name'])) . '</div></article>';
    } elseif ($isUniversityAdmin) {
        echo '<article class="profile-card"><p class="profile-eyebrow">Assigned university</p><h3>'
            . profile_h($account['university_name']) . '</h3><p class="profile-card-copy">University code: '
            . profile_h($account['university_code']) . '</p><dl class="profile-details"><div><dt>Admin role</dt><dd>'
            . profile_h($account['role_detail']) . '</dd></div><div><dt>Permissions</dt><dd>University-scoped transport administration</dd></div></dl>'
            . '<p class="profile-boundary">The assigned university is session-derived and cannot be changed from this profile.</p></article>';
    } else {
        echo '<article class="profile-card"><p class="profile-eyebrow">Platform authority</p><h3>System administration</h3>'
            . '<p class="profile-card-copy">Manage platform universities and University Admin accounts through their dedicated workflows.</p>'
            . '<p class="profile-boundary">Profile editing cannot modify platform permissions or grant additional authority.</p></article>';
    }
    echo '</div>';
    echo '<div class="profile-summary-grid"><div><strong>' . count($sessions) . '</strong><span>Active sessions</span></div><div><strong>'
        . count($activity) . '</strong><span>Recent security events</span></div><div><strong>'
        . (int)array_sum(array_map('intval', $preferences)) . '</strong><span>Enabled notification types</span></div></div>';
    echo '</section>';

    profile_panel_start('personal');
    echo '<form method="post" class="profile-card profile-form"><input type="hidden" name="csrf_token" value="' . profile_h($csrf) . '"><input type="hidden" name="action" value="update_personal">'
        . '<div class="profile-section-heading"><div><p class="profile-eyebrow">Editable details</p><h3>Personal information</h3></div><p>Email, role and ownership fields are protected.</p></div><div class="profile-form-grid">';
    profile_input('Full name', 'name', $account['name'] ?? '', 'text', true);
    profile_input('Phone number', 'phone', $account['phone'] ?? '', 'tel');
    profile_input('Date of birth', 'date_of_birth', $account['date_of_birth'] ?? '', 'date');
    echo '<label class="profile-field"><span>Gender</span><select name="gender"><option value="">Not specified</option>';
    foreach (['FEMALE'=>'Female','MALE'=>'Male','NON_BINARY'=>'Non-binary','PREFER_NOT_TO_SAY'=>'Prefer not to say'] as $value => $label) {
        echo '<option value="' . $value . '"' . (($account['gender'] ?? '') === $value ? ' selected' : '') . '>' . $label . '</option>';
    }
    echo '</select></label>';
    echo '<label class="profile-field profile-field-wide"><span>Address</span><textarea name="address" maxlength="500">' . profile_h($account['address'] ?? '') . '</textarea></label>';
    profile_input('Emergency contact name', 'emergency_contact_name', $account['emergency_contact_name'] ?? '');
    profile_input('Emergency contact phone', 'emergency_contact_phone', $account['emergency_contact_phone'] ?? '', 'tel');
    if ($isPassenger) {
        profile_input('Preferred boarding stop', 'preferred_boarding_stop', $account['preferred_boarding_stop'] ?? '');
        profile_input('Preferred destination stop', 'preferred_destination_stop', $account['preferred_destination_stop'] ?? '');
        echo '<label class="profile-field"><span>Travel preference</span><select name="seat_preference">';
        foreach (['NO_PREFERENCE'=>'No preference','SEAT'=>'Seat','STANDING'=>'Standing'] as $value => $label) {
            echo '<option value="' . $value . '"' . (($account['seat_preference'] ?? 'NO_PREFERENCE') === $value ? ' selected' : '') . '>' . $label . '</option>';
        }
        echo '</select></label><div class="profile-field profile-readonly"><span>Academic identity</span><strong>'
            . profile_h(($account['institutional_id'] ?? 'Pending') . ' · ' . ($account['academic_detail'] ?? 'Details unavailable')) . '</strong><small>Verified institutional fields are read-only.</small></div>';
    } elseif ($isUniversityAdmin) {
        profile_input('Job title', 'job_title', $account['job_title'] ?? '');
        profile_input('Department', 'department', $account['department'] ?? '');
        profile_input('Office phone', 'office_phone', $account['office_phone'] ?? '', 'tel');
        profile_input('Office location', 'office_location', $account['office_location'] ?? '');
    }
    echo '</div><div class="profile-form-actions"><button class="profile-secondary" type="button" data-open-profile-tab="overview">Cancel</button><button class="profile-secondary" type="reset">Reset</button><button class="profile-primary" type="submit">Save changes</button></div></form>';
    echo '</section>';

    profile_panel_start('picture');
    echo '<div class="profile-card-grid"><form method="post" enctype="multipart/form-data" class="profile-card profile-picture-form" data-profile-picture-form data-max-bytes="' . PROFILE_PICTURE_MAX_BYTES . '">'
        . '<input type="hidden" name="csrf_token" value="' . profile_h($csrf) . '"><input type="hidden" name="action" value="upload_picture">'
        . '<div class="profile-picture-preview" data-picture-preview>' . profile_avatar_html($base, (string)$account['name'], $picture, 'profile-avatar profile-avatar-preview') . '</div>'
        . '<div><p class="profile-eyebrow">Upload and crop</p><h3>Profile picture</h3><p class="profile-card-copy">JPEG, PNG or WebP. Maximum ' . profile_h(profile_picture_max_label()) . '. The saved image is cropped to a square in supported browsers.</p>'
        . '<label class="profile-file"><span>Choose image</span><input type="file" name="profile_picture" accept="image/jpeg,image/png,image/webp" data-picture-input required></label>'
        . '<div class="profile-crop-controls" data-crop-controls hidden><label><span>Zoom</span><input type="range" min="1" max="3" step="0.05" value="1" data-crop-zoom></label><label><span>Horizontal position</span><input type="range" min="0" max="100" value="50" data-crop-x></label><label><span>Vertical position</span><input type="range" min="0" max="100" value="50" data-crop-y></label></div>'
        . '<canvas width="512" height="512" data-crop-canvas hidden></canvas><div class="profile-form-actions"><button class="profile-primary" type="submit">Upload picture</button></div></div></form>';
    echo '<article class="profile-card"><p class="profile-eyebrow">Current avatar</p><h3>Remove picture</h3><p class="profile-card-copy">Removing the image restores the secure initials-based avatar everywhere in your dashboard.</p>';
    if (profile_safe_picture_path($picture) !== null) {
        echo '<form method="post"><input type="hidden" name="csrf_token" value="' . profile_h($csrf) . '"><input type="hidden" name="action" value="remove_picture"><button class="profile-danger" type="submit">Remove profile picture</button></form>';
    } else echo '<p class="profile-muted">No uploaded profile picture.</p>';
    echo '</article></div></section>';

    profile_panel_start('notifications');
    echo '<form method="post" class="profile-card profile-form"><input type="hidden" name="csrf_token" value="' . profile_h($csrf) . '"><input type="hidden" name="action" value="update_notifications">'
        . '<div class="profile-section-heading"><div><p class="profile-eyebrow">Communication</p><h3>Notification settings</h3></div><p>Critical security notifications remain enabled.</p></div><div class="profile-toggle-list">';
    foreach ($config['notifications'] as $key => $definition) {
        $essential = !empty($definition['essential']);
        echo '<label class="profile-toggle-row"><span><strong>' . profile_h($definition['label']) . ($essential ? ' <em>Required</em>' : '')
            . '</strong><small>' . profile_h($definition['description']) . '</small></span><input type="checkbox" name="notifications['
            . profile_h($key) . ']" value="1"' . (!empty($preferences[$key]) ? ' checked' : '') . ($essential ? ' disabled' : '')
            . ($key === 'master_notifications' ? ' data-notification-master' : ' data-notification-option') . '><i aria-hidden="true"></i>'
            . ($essential ? '<input type="hidden" name="notifications[' . profile_h($key) . ']" value="1">' : '') . '</label>';
    }
    echo '</div><div class="profile-form-actions"><button class="profile-primary" type="submit">Save notification settings</button></div></form></section>';

    profile_panel_start('security');
    echo '<form method="post" class="profile-card profile-form profile-password-form"><input type="hidden" name="csrf_token" value="' . profile_h($csrf) . '"><input type="hidden" name="action" value="change_password">'
        . '<div class="profile-section-heading"><div><p class="profile-eyebrow">Account protection</p><h3>Change password</h3></div><p>Other active sessions are revoked after a successful change.</p></div><div class="profile-form-grid">';
    profile_password_input('Current password', 'current_password');
    profile_password_input('New password', 'new_password', true);
    profile_password_input('Confirm new password', 'confirm_password');
    echo '<div class="profile-password-meter profile-field-wide"><span data-password-strength>Strength: not entered</span><div><i data-password-meter></i></div><small>Use 8–128 characters with uppercase, lowercase, number and special character.</small></div></div>'
        . '<div class="profile-form-actions"><button class="profile-primary" type="submit">Change password</button></div></form></section>';

    profile_panel_start('sessions');
    echo '<div class="profile-card"><div class="profile-section-heading"><div><p class="profile-eyebrow">Devices</p><h3>Active sessions</h3></div><form method="post"><input type="hidden" name="csrf_token" value="' . profile_h($csrf) . '"><input type="hidden" name="action" value="logout_others"><button class="profile-secondary" type="submit">Sign out all other sessions</button></form></div><div class="profile-session-list">';
    if (!$sessions) echo '<p class="profile-muted">No active session records are available.</p>';
    foreach ($sessions as $session) {
        echo '<article class="profile-session"><div class="profile-device-icon" aria-hidden="true"></div><div><strong>' . profile_h(profile_device_label((string)$session['user_agent']))
            . (!empty($session['is_current']) ? ' <em>Current</em>' : '') . '</strong><span>' . profile_h(profile_mask_ip($session['ip_address'] ?? null))
            . ' · Last active ' . profile_h(profile_date_label($session['last_activity_at'] ?? null)) . '</span><small>Signed in ' . profile_h(profile_date_label($session['logged_in_at'] ?? null)) . '</small></div>';
        if (empty($session['is_current'])) {
            echo '<form method="post"><input type="hidden" name="csrf_token" value="' . profile_h($csrf) . '"><input type="hidden" name="action" value="revoke_session"><input type="hidden" name="session_record_id" value="' . (int)$session['session_record_id'] . '"><button class="profile-danger-link" type="submit">Sign out</button></form>';
        }
        echo '</article>';
    }
    echo '</div></div></section>';

    profile_panel_start('activity');
    echo '<div class="profile-card"><div class="profile-section-heading"><div><p class="profile-eyebrow">Audit trail</p><h3>Login and account activity</h3></div><p>Security events never contain passwords or raw session tokens.</p></div><div class="profile-activity-list">';
    if (!$activity) echo '<p class="profile-muted">No recent activity is available.</p>';
    foreach ($activity as $event) {
        echo '<article><i aria-hidden="true"></i><div><strong>' . profile_h(ucwords(strtolower(str_replace('_', ' ', (string)$event['event_type']))))
            . '</strong><span>' . profile_h($event['event_description']) . '</span></div><time>' . profile_h(profile_date_label($event['occurred_at'] ?? null)) . '</time></article>';
    }
    echo '</div></div></section>';
    echo '</div>';
}

function profile_input(string $label, string $name, mixed $value, string $type = 'text', bool $required = false): void
{
    echo '<label class="profile-field"><span>' . profile_h($label) . '</span><input type="' . profile_h($type)
        . '" name="' . profile_h($name) . '" value="' . profile_h($value) . '" maxlength="200"'
        . ($required ? ' required' : '') . '></label>';
}

function profile_password_input(string $label, string $name, bool $strength = false): void
{
    echo '<label class="profile-field profile-password-field"><span>' . profile_h($label) . '</span><span><input type="password" name="'
        . profile_h($name) . '" autocomplete="' . ($name === 'current_password' ? 'current-password' : 'new-password') . '" maxlength="128" required'
        . ($strength ? ' data-new-password' : '') . '><button type="button" data-password-toggle aria-label="Show ' . profile_h(strtolower($label)) . '">Show</button></span></label>';
}
