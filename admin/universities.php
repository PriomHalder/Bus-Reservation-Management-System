<?php
declare(strict_types=1);

require_once __DIR__ . '/_admin_context.php';
require_once __DIR__ . '/../includes/profile/profile-picture.php';

function sys_university_expected_domain(string $code): string
{
    $label = strtolower(str_replace('_', '-', trim($code)));
    return $label === '' ? '' : $label . '.ac.bd';
}

function sys_university_domain_is_valid(string $code, string $domain): bool
{
    $expected = sys_university_expected_domain($code);
    return $expected !== ''
        && (bool)preg_match('/^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.ac\.bd$/D', $domain)
        && hash_equals($expected, $domain);
}

function sys_university_admin_email_is_gmail(string $email): bool
{
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        return false;
    }

    $separator = strrpos($email, '@');
    return $separator !== false
        && $separator > 0
        && substr($email, $separator + 1) === 'gmail.com';
}

function sys_university_form_draft(array $source): array
{
    return [
        'name' => trim((string)($source['name'] ?? '')),
        'code' => strtoupper(trim((string)($source['code'] ?? ''))),
        'academic_domain' => strtolower(trim((string)($source['academic_domain'] ?? ''))),
        'contact_email' => strtolower(trim((string)($source['contact_email'] ?? ''))),
        'address' => trim((string)($source['address'] ?? '')),
        'status' => strtoupper((string)($source['status'] ?? 'ACTIVE')),
        'admin_name' => trim((string)($source['admin_name'] ?? '')),
        'admin_email' => strtolower(trim((string)($source['admin_email'] ?? ''))),
    ];
}

function sys_university_form_error(string $message, array $draft): never
{
    $_SESSION['system_admin_university_draft'] = $draft;
    sys_flash('error', $message);
    sys_redirect('universities.php?new=1');
}

function sys_take_university_form_draft(): array
{
    $draft = $_SESSION['system_admin_university_draft'] ?? [];
    unset($_SESSION['system_admin_university_draft']);
    return is_array($draft) ? $draft : [];
}

function sys_university_table_exists(PDO $pdo, string $table): bool
{
    static $cache = [];

    if (!preg_match('/^[a-zA-Z0-9_]+$/D', $table)) {
        return false;
    }
    if (array_key_exists($table, $cache)) {
        return $cache[$table];
    }

    $stmt = $pdo->prepare(
        'SELECT COUNT(*) FROM information_schema.tables '
        . 'WHERE table_schema=DATABASE() AND table_name=?'
    );
    $stmt->execute([$table]);
    return $cache[$table] = ((int)$stmt->fetchColumn() > 0);
}

function sys_university_column_exists(PDO $pdo, string $table, string $column): bool
{
    static $cache = [];
    $key = $table . '.' . $column;

    if (
        !preg_match('/^[a-zA-Z0-9_]+$/D', $table)
        || !preg_match('/^[a-zA-Z0-9_]+$/D', $column)
    ) {
        return false;
    }
    if (array_key_exists($key, $cache)) {
        return $cache[$key];
    }

    $stmt = $pdo->prepare(
        'SELECT COUNT(*) FROM information_schema.columns '
        . 'WHERE table_schema=DATABASE() AND table_name=? AND column_name=?'
    );
    $stmt->execute([$table, $column]);
    return $cache[$key] = ((int)$stmt->fetchColumn() > 0);
}

function sys_university_fetch_ids(PDO $pdo, string $sql, array $params = []): array
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return array_values(array_unique(array_map('intval', $stmt->fetchAll(PDO::FETCH_COLUMN))));
}

function sys_university_delete_where(
    PDO $pdo,
    string $table,
    string $where,
    array $params = []
): void {
    if (!sys_university_table_exists($pdo, $table)) {
        return;
    }

    $stmt = $pdo->prepare('DELETE FROM `' . $table . '` WHERE ' . $where);
    $stmt->execute($params);
}

function sys_university_delete_ids(
    PDO $pdo,
    string $table,
    string $column,
    array $ids
): void {
    $ids = array_values(array_filter(array_unique(array_map('intval', $ids))));
    if (
        $ids === []
        || !sys_university_table_exists($pdo, $table)
        || !sys_university_column_exists($pdo, $table, $column)
    ) {
        return;
    }

    $placeholders = implode(',', array_fill(0, count($ids), '?'));
    $stmt = $pdo->prepare(
        'DELETE FROM `' . $table . '` WHERE `' . $column . '` IN (' . $placeholders . ')'
    );
    $stmt->execute($ids);
}

function sys_university_identity_picture_paths(
    PDO $pdo,
    string $role,
    array $ids
): array {
    $ids = array_values(array_filter(array_unique(array_map('intval', $ids))));
    if ($ids === [] || !sys_university_table_exists($pdo, 'user_profiles')) {
        return [];
    }

    $placeholders = implode(',', array_fill(0, count($ids), '?'));
    $stmt = $pdo->prepare(
        'SELECT profile_picture_path FROM user_profiles '
        . 'WHERE user_type=? AND user_id IN (' . $placeholders . ') '
        . 'AND profile_picture_path IS NOT NULL'
    );
    $stmt->execute(array_merge([$role], $ids));
    return array_values(array_filter(array_map('strval', $stmt->fetchAll(PDO::FETCH_COLUMN))));
}

function sys_university_delete_identity_rows(
    PDO $pdo,
    string $role,
    array $ids
): void {
    $ids = array_values(array_filter(array_unique(array_map('intval', $ids))));
    if ($ids === []) {
        return;
    }

    $placeholders = implode(',', array_fill(0, count($ids), '?'));
    foreach (['user_notification_preferences', 'user_sessions', 'user_security_events', 'user_profiles'] as $table) {
        if (!sys_university_table_exists($pdo, $table)) {
            continue;
        }
        $stmt = $pdo->prepare(
            'DELETE FROM `' . $table . '` WHERE user_type=? '
            . 'AND user_id IN (' . $placeholders . ')'
        );
        $stmt->execute(array_merge([$role], $ids));
    }

    if (sys_university_table_exists($pdo, 'password_reset_tokens')) {
        $stmt = $pdo->prepare(
            'DELETE FROM password_reset_tokens WHERE account_type=? '
            . 'AND account_id IN (' . $placeholders . ')'
        );
        $stmt->execute(array_merge([$role], $ids));
    }
}

function sys_university_remove_picture_files(array $paths): void
{
    $root = realpath(dirname(__DIR__));
    $directory = realpath(dirname(__DIR__) . '/uploads/profile');
    if (!$root || !$directory) {
        return;
    }

    $prefix = rtrim($directory, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
    foreach (array_unique($paths) as $path) {
        $safe = profile_safe_picture_path((string)$path);
        if ($safe === null) {
            continue;
        }
        $candidate = realpath(
            $root . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $safe)
        );
        if ($candidate && str_starts_with($candidate, $prefix) && is_file($candidate)) {
            @unlink($candidate);
        }
    }
}

/**
 * Permanently remove one university and all records owned through its
 * administrators, passengers, routes, buses and schedules.
 *
 * @return array{name:string,code:string,picture_paths:array}
 */
function sys_permanently_delete_university(
    PDO $pdo,
    int $universityId,
    string $confirmation
): array {
    if ($universityId <= 0 || trim($confirmation) === '') {
        throw new RuntimeException('Type the university code or full name to confirm permanent deletion.');
    }

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            'SELECT university_id,name,code FROM universities '
            . 'WHERE university_id=? LIMIT 1 FOR UPDATE'
        );
        $stmt->execute([$universityId]);
        $university = $stmt->fetch();
        if (!$university) {
            throw new RuntimeException('The selected university no longer exists.');
        }

        $confirmation = trim($confirmation);
        if (
            strcasecmp($confirmation, (string)$university['code']) !== 0
            && strcasecmp($confirmation, (string)$university['name']) !== 0
        ) {
            throw new RuntimeException('The confirmation did not match the university code or full name.');
        }

        $adminIds = sys_university_fetch_ids(
            $pdo,
            'SELECT university_user_id FROM university_users WHERE university_id=?',
            [$universityId]
        );
        $passengerIds = sys_university_fetch_ids(
            $pdo,
            'SELECT passenger_id FROM passengers WHERE university_id=?',
            [$universityId]
        );
        $routeIds = sys_university_fetch_ids(
            $pdo,
            'SELECT route_id FROM routes WHERE university_id=?',
            [$universityId]
        );
        $busIds = sys_university_fetch_ids(
            $pdo,
            'SELECT bus_id FROM buses WHERE university_id=?',
            [$universityId]
        );

        $scheduleIds = [];
        if ($routeIds !== []) {
            $placeholders = implode(',', array_fill(0, count($routeIds), '?'));
            $scheduleIds = array_merge($scheduleIds, sys_university_fetch_ids(
                $pdo,
                'SELECT schedule_id FROM schedules WHERE route_id IN (' . $placeholders . ')',
                $routeIds
            ));
        }
        if ($busIds !== []) {
            $placeholders = implode(',', array_fill(0, count($busIds), '?'));
            $scheduleIds = array_merge($scheduleIds, sys_university_fetch_ids(
                $pdo,
                'SELECT schedule_id FROM schedules WHERE bus_id IN (' . $placeholders . ')',
                $busIds
            ));
        }
        $scheduleIds = array_values(array_unique($scheduleIds));

        $bookingIds = [];
        if ($passengerIds !== []) {
            $placeholders = implode(',', array_fill(0, count($passengerIds), '?'));
            $bookingIds = array_merge($bookingIds, sys_university_fetch_ids(
                $pdo,
                'SELECT booking_id FROM bookings WHERE passenger_id IN (' . $placeholders . ')',
                $passengerIds
            ));
        }
        if ($scheduleIds !== []) {
            $placeholders = implode(',', array_fill(0, count($scheduleIds), '?'));
            $bookingIds = array_merge($bookingIds, sys_university_fetch_ids(
                $pdo,
                'SELECT booking_id FROM bookings WHERE schedule_id IN (' . $placeholders . ')',
                $scheduleIds
            ));
        }
        $bookingIds = array_values(array_unique($bookingIds));

        $semesterIds = [];
        if (sys_university_column_exists($pdo, 'semesters', 'university_id')) {
            $semesterIds = sys_university_fetch_ids(
                $pdo,
                'SELECT semester_id FROM semesters WHERE university_id=?',
                [$universityId]
            );
        }

        $picturePaths = array_merge(
            sys_university_identity_picture_paths($pdo, 'UNIVERSITY_ADMIN', $adminIds),
            sys_university_identity_picture_paths($pdo, 'PASSENGER', $passengerIds)
        );

        sys_university_delete_where($pdo, 'announcements', 'university_id=?', [$universityId]);

        sys_university_delete_ids($pdo, 'ticket_transfers', 'booking_id', $bookingIds);
        sys_university_delete_ids($pdo, 'ticket_transfers', 'from_passenger_id', $passengerIds);
        sys_university_delete_ids($pdo, 'ticket_transfers', 'to_passenger_id', $passengerIds);
        sys_university_delete_ids($pdo, 'booking_status_history', 'booking_id', $bookingIds);

        sys_university_delete_ids($pdo, 'billing_transactions', 'booking_id', $bookingIds);
        sys_university_delete_ids($pdo, 'billing_transactions', 'passenger_id', $passengerIds);
        sys_university_delete_ids($pdo, 'billing_transactions', 'semester_id', $semesterIds);
        sys_university_delete_ids($pdo, 'semester_bills', 'passenger_id', $passengerIds);
        sys_university_delete_ids($pdo, 'semester_bills', 'semester_id', $semesterIds);
        if (sys_university_column_exists($pdo, 'semester_bills', 'university_id')) {
            sys_university_delete_where($pdo, 'semester_bills', 'university_id=?', [$universityId]);
        }

        sys_university_delete_ids($pdo, 'notifications', 'passenger_id', $passengerIds);
        sys_university_delete_where($pdo, 'complaints', 'university_id=?', [$universityId]);
        sys_university_delete_ids($pdo, 'complaints', 'passenger_id', $passengerIds);
        sys_university_delete_ids($pdo, 'favorite_routes', 'passenger_id', $passengerIds);
        sys_university_delete_ids($pdo, 'favorite_routes', 'route_id', $routeIds);
        sys_university_delete_ids($pdo, 'students', 'passenger_id', $passengerIds);
        sys_university_delete_ids($pdo, 'faculty', 'passenger_id', $passengerIds);

        sys_university_delete_ids($pdo, 'bookings', 'booking_id', $bookingIds);
        sys_university_delete_ids($pdo, 'route_stops', 'route_id', $routeIds);
        sys_university_delete_ids($pdo, 'bus_route_assignments', 'route_id', $routeIds);
        sys_university_delete_ids($pdo, 'bus_route_assignments', 'bus_id', $busIds);
        sys_university_delete_ids($pdo, 'schedules', 'schedule_id', $scheduleIds);

        sys_university_delete_ids($pdo, 'semesters', 'semester_id', $semesterIds);
        sys_university_delete_ids($pdo, 'routes', 'route_id', $routeIds);
        sys_university_delete_ids($pdo, 'buses', 'bus_id', $busIds);

        sys_university_delete_identity_rows($pdo, 'PASSENGER', $passengerIds);
        sys_university_delete_identity_rows($pdo, 'UNIVERSITY_ADMIN', $adminIds);
        sys_university_delete_ids($pdo, 'passengers', 'passenger_id', $passengerIds);
        sys_university_delete_ids($pdo, 'university_users', 'university_user_id', $adminIds);

        $stmt = $pdo->prepare('DELETE FROM universities WHERE university_id=?');
        $stmt->execute([$universityId]);
        if ($stmt->rowCount() !== 1) {
            throw new RuntimeException('The university could not be deleted.');
        }

        $pdo->commit();
        return [
            'name' => (string)$university['name'],
            'code' => (string)$university['code'],
            'picture_paths' => $picturePaths,
        ];
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!sys_verify_csrf($_POST['csrf_token'] ?? null)) {
        sys_flash('error', 'Your session expired. Please try again.');
        sys_redirect('universities.php');
    }

    $action = (string)($_POST['action'] ?? '');

    if ($action === 'create_university') {
        $draft = sys_university_form_draft($_POST);
        $name = trim((string)($_POST['name'] ?? ''));
        $code = strtoupper(trim((string)($_POST['code'] ?? '')));
        $domain = strtolower(trim((string)($_POST['academic_domain'] ?? '')));
        $address = trim((string)($_POST['address'] ?? ''));
        $contactEmail = strtolower(trim((string)($_POST['contact_email'] ?? '')));
        $status = strtoupper((string)($_POST['status'] ?? 'ACTIVE'));
        $adminName = trim((string)($_POST['admin_name'] ?? ''));
        $adminEmail = strtolower(trim((string)($_POST['admin_email'] ?? '')));
        $adminPassword = (string)($_POST['admin_password'] ?? '');

        if ($name === '' || strlen($name) > 200) {
            sys_university_form_error('Enter a valid university name.', $draft);
        }
        if (!preg_match('/^[A-Z0-9](?:[A-Z0-9_-]{0,18}[A-Z0-9])$/D', $code)) {
            sys_university_form_error(
                'Use a unique 2–20 character university code that begins and ends with a letter or number.',
                $draft
            );
        }
        if (!sys_university_domain_is_valid($code, $domain)) {
            sys_university_form_error(
                'Academic domain must match the university code: ' . sys_university_expected_domain($code) . '.',
                $draft
            );
        }
        if ($contactEmail !== '' && !filter_var($contactEmail, FILTER_VALIDATE_EMAIL)) {
            sys_university_form_error('Enter a valid university contact email.', $draft);
        }
        if (!in_array($status, ['ACTIVE', 'INACTIVE'], true)) {
            $status = 'ACTIVE';
        }
        if ($adminName === '') {
            sys_university_form_error('Enter the first University Admin’s name.', $draft);
        }
        if (!sys_university_admin_email_is_gmail($adminEmail)) {
            sys_university_form_error(
                'The first University Admin email must be a valid @gmail.com address.',
                $draft
            );
        }
        if (strlen($adminPassword) < 8) {
            sys_university_form_error(
                'The first University Admin password must contain at least 8 characters.',
                $draft
            );
        }

        try {
            $pdo->beginTransaction();

            if ((int)sys_scalar($pdo, 'SELECT COUNT(*) FROM universities WHERE code=? OR name=?', [$code, $name]) > 0) {
                throw new RuntimeException('A university with this name or code already exists.');
            }
            if ((int)sys_scalar($pdo, 'SELECT COUNT(*) FROM university_users WHERE LOWER(email)=LOWER(?)', [$adminEmail]) > 0) {
                throw new RuntimeException('A University Admin with this email already exists.');
            }

            $stmt = $pdo->prepare(
                'INSERT INTO universities
                    (name, code, academic_domain, address, contact_email, status)
                 VALUES (?, ?, ?, ?, ?, ?)'
            );
            $stmt->execute([
                $name,
                $code,
                $domain !== '' ? $domain : null,
                $address !== '' ? $address : null,
                $contactEmail !== '' ? $contactEmail : null,
                $status,
            ]);

            $universityId = (int)$pdo->lastInsertId();
            if ($universityId <= 0) {
                throw new RuntimeException('University IDs are not configured for automatic generation. Import the integrity migration first.');
            }

            $stmt = $pdo->prepare(
                "INSERT INTO university_users
                    (university_id, name, email, password_hash, role, status)
                 VALUES (?, ?, ?, ?, 'ADMIN', 'ACTIVE')"
            );
            $stmt->execute([
                $universityId,
                $adminName,
                $adminEmail,
                password_hash($adminPassword, PASSWORD_DEFAULT),
            ]);

            $pdo->commit();
            unset($_SESSION['system_admin_university_draft']);
            sys_flash(
                'success',
                $name . ' was created with its first University Admin. The complete shared dashboard and all role features are available immediately.'
            );
            sys_redirect('universities.php');
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            error_log('[UniRide create university] ' . $e->getMessage());
            $message = $e instanceof RuntimeException
                ? $e->getMessage()
                : 'The university could not be created. Check duplicate values and database migrations.';
            sys_university_form_error($message, $draft);
        }
    }

    if ($action === 'set_status') {
        $universityId = (int)($_POST['university_id'] ?? 0);
        $status = strtoupper((string)($_POST['status'] ?? ''));

        if ($universityId <= 0 || !in_array($status, ['ACTIVE', 'INACTIVE'], true)) {
            sys_flash('error', 'Invalid university status request.');
            sys_redirect('universities.php');
        }

        try {
            $stmt = $pdo->prepare('UPDATE universities SET status=? WHERE university_id=?');
            $stmt->execute([$status, $universityId]);
            sys_flash('success', 'University status updated.');
        } catch (Throwable $e) {
            error_log('[UniRide university status] ' . $e->getMessage());
            sys_flash('error', 'The university status could not be updated.');
        }
        sys_redirect('universities.php');
    }

    if ($action === 'delete_university') {
        $universityId = (int)($_POST['university_id'] ?? 0);
        $confirmation = trim((string)($_POST['delete_confirmation'] ?? ''));

        try {
            $deleted = sys_permanently_delete_university($pdo, $universityId, $confirmation);
            sys_university_remove_picture_files($deleted['picture_paths']);
            profile_log_event(
                $pdo,
                'SYSTEM_ADMIN',
                $sysAdminId,
                'UNIVERSITY_DELETED',
                'Permanently deleted university ' . $deleted['code'] . ' (' . $deleted['name'] . ').'
            );
            $_SESSION['system_admin_flash'] = [
                'type' => 'success',
                'message' => $deleted['name'] . ' was permanently deleted with its university-owned records.',
            ];
        } catch (Throwable $e) {
            error_log('[UniRide delete university] ' . $e->getMessage());
            sys_flash(
                'error',
                $e instanceof RuntimeException
                    ? $e->getMessage()
                    : 'The university could not be deleted. No records were removed.'
            );
        }
        sys_redirect('universities.php');
    }
}

$universities = [];
$pageError = '';
$universityDraft = sys_take_university_form_draft();

try {
    $universities = sys_all(
        $pdo,
        "SELECT
            u.university_id, u.name, u.code, u.academic_domain, u.contact_email,
            u.status, u.created_at,
            COUNT(DISTINCT uu.university_user_id) AS admin_count,
            COUNT(DISTINCT p.passenger_id) AS passenger_count,
            COUNT(DISTINCT b.bus_id) AS bus_count,
            COUNT(DISTINCT r.route_id) AS route_count
         FROM universities u
         LEFT JOIN university_users uu ON uu.university_id=u.university_id
         LEFT JOIN passengers p ON p.university_id=u.university_id
         LEFT JOIN buses b ON b.university_id=u.university_id
         LEFT JOIN routes r ON r.university_id=u.university_id
         GROUP BY u.university_id, u.name, u.code, u.academic_domain,
                  u.contact_email, u.status, u.created_at
         ORDER BY u.name"
    );
} catch (Throwable $e) {
    error_log('[UniRide universities list] ' . $e->getMessage());
    $pageError = 'University information is temporarily unavailable.';
}

sys_page_start(
    'Universities',
    'universities',
    'Create a university once; the shared UniAdmin dashboard and every subtask apply automatically.'
);
?>
<?php if ($pageError): ?>
    <div class="alert error"><?= sys_h($pageError) ?></div>
<?php endif; ?>

<div class="admin-page-actions">
    <a class="button button-dark button-small" href="universities.php?new=1">Add university</a>
    <a class="button button-light button-small" href="administrators.php">Manage administrators</a>
</div>

<?php if (isset($_GET['new'])): ?>
<section class="admin-card admin-card-accent">
    <div class="admin-card-heading">
        <div><p class="kicker">Automatic onboarding</p><h2>New university and first administrator</h2></div>
        <a href="universities.php">Cancel</a>
    </div>
    <p class="admin-help">No dashboard files are copied. The new administrator signs into the same shared UniAdmin application, scoped automatically by the new university ID.</p>
    <form method="post" class="admin-form-grid">
        <input type="hidden" name="csrf_token" value="<?= sys_h(sys_csrf()) ?>">
        <input type="hidden" name="action" value="create_university">
        <label><span>University name</span><input name="name" maxlength="200" value="<?= sys_h($universityDraft['name'] ?? '') ?>" required></label>
        <label><span>Code</span><input name="code" maxlength="20" placeholder="SEU" value="<?= sys_h($universityDraft['code'] ?? '') ?>" data-university-code required></label>
        <label><span>Academic domain</span><input name="academic_domain" placeholder="seu.ac.bd" value="<?= sys_h($universityDraft['academic_domain'] ?? '') ?>" pattern="[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.ac\.bd" title="Use the university code followed by .ac.bd, for example seu.ac.bd" data-academic-domain required></label>
        <label><span>Contact email</span><input type="email" name="contact_email" value="<?= sys_h($universityDraft['contact_email'] ?? '') ?>"></label>
        <label class="wide"><span>Address</span><textarea name="address" rows="3"><?= sys_h($universityDraft['address'] ?? '') ?></textarea></label>
        <label><span>University status</span><select name="status"><option value="ACTIVE" <?= ($universityDraft['status'] ?? 'ACTIVE') === 'ACTIVE' ? 'selected' : '' ?>>Active</option><option value="INACTIVE" <?= ($universityDraft['status'] ?? '') === 'INACTIVE' ? 'selected' : '' ?>>Inactive</option></select></label>
        <div class="admin-form-divider wide"><strong>First University Admin</strong><span>This account receives the shared dashboard automatically.</span></div>
        <label><span>Administrator name</span><input name="admin_name" maxlength="200" value="<?= sys_h($universityDraft['admin_name'] ?? '') ?>" required></label>
        <label><span>Administrator email</span><input type="email" name="admin_email" maxlength="200" placeholder="transport.admin@gmail.com" value="<?= sys_h($universityDraft['admin_email'] ?? '') ?>" pattern="[^@\s]+@[gG][mM][aA][iI][lL]\.[cC][oO][mM]" title="Use a valid Gmail address ending in @gmail.com" required></label>
        <label><span>Temporary password</span><input type="password" name="admin_password" minlength="8" autocomplete="new-password" required></label>
        <div class="admin-form-actions wide"><button class="button button-dark" type="submit">Create university</button></div>
    </form>
</section>
<?php endif; ?>

<section class="admin-card">
    <div class="admin-card-heading"><div><p class="kicker">Database-driven tenants</p><h2>All universities</h2></div><span><?= number_format(count($universities)) ?> total</span></div>
    <?php if (!$universities): ?>
        <div class="admin-empty"><strong>No universities found.</strong><p>Add the first university to activate its shared dashboard.</p></div>
    <?php else: ?>
        <div class="admin-table-wrap"><table class="admin-table"><thead><tr><th>University</th><th>Domain</th><th>Admins</th><th>Passengers</th><th>Buses</th><th>Routes</th><th>Status</th><th>Actions</th></tr></thead><tbody>
        <?php foreach ($universities as $university): ?>
            <tr>
                <td><strong><?= sys_h($university['name']) ?></strong><small><?= sys_h($university['code']) ?> · ID <?= (int)$university['university_id'] ?></small></td>
                <td><?= sys_h($university['academic_domain'] ?: '—') ?></td>
                <td><?= number_format((int)$university['admin_count']) ?></td>
                <td><?= number_format((int)$university['passenger_count']) ?></td>
                <td><?= number_format((int)$university['bus_count']) ?></td>
                <td><?= number_format((int)$university['route_count']) ?></td>
                <td><span class="status-pill <?= sys_h(sys_status_class($university['status'])) ?>"><?= sys_h($university['status']) ?></span></td>
                <td><div class="admin-row-actions"><form method="post" class="inline-form"><input type="hidden" name="csrf_token" value="<?= sys_h(sys_csrf()) ?>"><input type="hidden" name="action" value="set_status"><input type="hidden" name="university_id" value="<?= (int)$university['university_id'] ?>"><input type="hidden" name="status" value="<?= $university['status'] === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE' ?>"><button type="submit"><?= $university['status'] === 'ACTIVE' ? 'Deactivate' : 'Activate' ?></button></form><form method="post" class="inline-form" data-delete-university data-university-code="<?= sys_h($university['code']) ?>" data-university-name="<?= sys_h($university['name']) ?>"><input type="hidden" name="csrf_token" value="<?= sys_h(sys_csrf()) ?>"><input type="hidden" name="action" value="delete_university"><input type="hidden" name="university_id" value="<?= (int)$university['university_id'] ?>"><input type="hidden" name="delete_confirmation" value=""><button class="admin-delete-button" type="submit">Delete</button></form></div></td>
            </tr>
        <?php endforeach; ?>
        </tbody></table></div>
    <?php endif; ?>
</section>

<script src="../js/admin-universities.js"></script>

<?php sys_page_end(); ?>
