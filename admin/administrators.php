<?php
declare(strict_types=1);

require_once __DIR__ . '/_admin_context.php';
require_once __DIR__ . '/../includes/profile/profile-picture.php';

function sys_administrator_email_is_gmail(string $email): bool
{
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        return false;
    }

    $separator = strrpos($email, '@');
    return $separator !== false
        && $separator > 0
        && substr($email, $separator + 1) === 'gmail.com';
}

/**
 * Permanently remove one University Admin account without touching its
 * university or university-owned operational records.
 *
 * @return array{name:string,email:string,picture_path:?string}
 */
function sys_permanently_delete_university_admin(
    PDO $pdo,
    int $adminId,
    string $confirmation
): array {
    if ($adminId <= 0 || trim($confirmation) === '') {
        throw new RuntimeException('Type the administrator email address to confirm permanent deletion.');
    }

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            'SELECT university_user_id,name,email FROM university_users '
            . 'WHERE university_user_id=? LIMIT 1 FOR UPDATE'
        );
        $stmt->execute([$adminId]);
        $administrator = $stmt->fetch();
        if (!$administrator) {
            throw new RuntimeException('The selected University Administrator no longer exists.');
        }

        if (strcasecmp(trim($confirmation), (string)$administrator['email']) !== 0) {
            throw new RuntimeException('The confirmation did not match the administrator email address.');
        }

        $picturePath = null;
        if (profile_table_exists($pdo, 'user_profiles')) {
            $stmt = $pdo->prepare(
                "SELECT profile_picture_path FROM user_profiles
                 WHERE user_type='UNIVERSITY_ADMIN' AND user_id=? LIMIT 1"
            );
            $stmt->execute([$adminId]);
            $picturePath = profile_safe_picture_path($stmt->fetchColumn() ?: null);
        }

        if (profile_table_exists($pdo, 'announcements')) {
            $stmt = $pdo->prepare('UPDATE announcements SET created_by=NULL WHERE created_by=?');
            $stmt->execute([$adminId]);
        }

        foreach (['user_notification_preferences', 'user_sessions', 'user_security_events', 'user_profiles'] as $table) {
            if (!profile_table_exists($pdo, $table)) {
                continue;
            }
            $stmt = $pdo->prepare(
                'DELETE FROM `' . $table . "` WHERE user_type='UNIVERSITY_ADMIN' AND user_id=?"
            );
            $stmt->execute([$adminId]);
        }

        if (profile_table_exists($pdo, 'password_reset_tokens')) {
            $stmt = $pdo->prepare(
                "DELETE FROM password_reset_tokens
                 WHERE account_type='UNIVERSITY_ADMIN' AND account_id=?"
            );
            $stmt->execute([$adminId]);
        }

        $stmt = $pdo->prepare('DELETE FROM university_users WHERE university_user_id=?');
        $stmt->execute([$adminId]);
        if ($stmt->rowCount() !== 1) {
            throw new RuntimeException('The University Administrator could not be deleted.');
        }

        $pdo->commit();
        return [
            'name' => (string)$administrator['name'],
            'email' => (string)$administrator['email'],
            'picture_path' => $picturePath,
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
        sys_redirect('administrators.php');
    }

    $action = (string)($_POST['action'] ?? '');

    if ($action === 'create_admin') {
        $universityId = (int)($_POST['university_id'] ?? 0);
        $name = trim((string)($_POST['name'] ?? ''));
        $email = strtolower(trim((string)($_POST['email'] ?? '')));
        $password = (string)($_POST['password'] ?? '');
        $role = strtoupper((string)($_POST['role'] ?? 'ADMIN'));

        if ($universityId <= 0 || $name === '') {
            sys_flash('error', 'Select a university and enter a valid administrator name.');
            sys_redirect('administrators.php?new=1');
        }
        if (!sys_administrator_email_is_gmail($email)) {
            sys_flash('error', 'The University Admin email must be a valid @gmail.com address.');
            sys_redirect('administrators.php?new=1');
        }
        if (strlen($password) < 8 || !in_array($role, ['ADMIN', 'MODERATOR'], true)) {
            sys_flash('error', 'Use a valid role and a password containing at least 8 characters.');
            sys_redirect('administrators.php?new=1');
        }

        try {
            $university = sys_one(
                $pdo,
                'SELECT university_id, name FROM universities WHERE university_id=? LIMIT 1',
                [$universityId]
            );
            if (!$university) {
                throw new RuntimeException('The selected university does not exist.');
            }
            if ((int)sys_scalar($pdo, 'SELECT COUNT(*) FROM university_users WHERE LOWER(email)=LOWER(?)', [$email]) > 0) {
                throw new RuntimeException('A University Admin with this email already exists.');
            }

            $stmt = $pdo->prepare(
                'INSERT INTO university_users
                    (university_id, name, email, password_hash, role, status)
                 VALUES (?, ?, ?, ?, ?, \'ACTIVE\')'
            );
            $stmt->execute([
                $universityId,
                $name,
                $email,
                password_hash($password, PASSWORD_DEFAULT),
                $role,
            ]);
            sys_flash('success', $name . ' can now use the shared dashboard for ' . $university['name'] . '.');
        } catch (Throwable $e) {
            error_log('[UniRide create university admin] ' . $e->getMessage());
            sys_flash(
                'error',
                $e instanceof RuntimeException ? $e->getMessage() : 'The administrator could not be created.'
            );
        }
        sys_redirect('administrators.php');
    }

    if ($action === 'set_status') {
        $adminId = (int)($_POST['university_user_id'] ?? 0);
        $status = strtoupper((string)($_POST['status'] ?? ''));

        if ($adminId <= 0 || !in_array($status, ['ACTIVE', 'INACTIVE'], true)) {
            sys_flash('error', 'Invalid administrator status request.');
            sys_redirect('administrators.php');
        }

        try {
            $stmt = $pdo->prepare('UPDATE university_users SET status=? WHERE university_user_id=?');
            $stmt->execute([$status, $adminId]);
            sys_flash('success', 'Administrator status updated.');
        } catch (Throwable $e) {
            error_log('[UniRide university admin status] ' . $e->getMessage());
            sys_flash('error', 'The administrator status could not be updated.');
        }
        sys_redirect('administrators.php');
    }

    if ($action === 'delete_admin') {
        $adminId = (int)($_POST['university_user_id'] ?? 0);
        $confirmation = trim((string)($_POST['delete_confirmation'] ?? ''));

        try {
            $deleted = sys_permanently_delete_university_admin($pdo, $adminId, $confirmation);
            profile_delete_picture_file($deleted['picture_path']);
            profile_log_event(
                $pdo,
                'SYSTEM_ADMIN',
                $sysAdminId,
                'UNIVERSITY_ADMIN_DELETED',
                'Permanently deleted University Administrator ' . $deleted['email'] . '.'
            );
            $_SESSION['system_admin_flash'] = [
                'type' => 'success',
                'message' => $deleted['name'] . ' was permanently deleted. The associated university was not changed.',
            ];
        } catch (Throwable $e) {
            error_log('[UniRide delete university admin] ' . $e->getMessage());
            sys_flash(
                'error',
                $e instanceof RuntimeException
                    ? $e->getMessage()
                    : 'The University Administrator could not be deleted. No account records were removed.'
            );
        }
        sys_redirect('administrators.php');
    }
}

$universities = [];
$administrators = [];
$pageError = '';

try {
    $universities = sys_all(
        $pdo,
        'SELECT university_id, name, code, status FROM universities ORDER BY name'
    );
    $administrators = sys_all(
        $pdo,
        "SELECT uu.university_user_id, uu.name, uu.email, uu.role, uu.status,
                uu.created_at, u.university_id, u.name AS university_name, u.code
         FROM university_users uu
         INNER JOIN universities u ON u.university_id=uu.university_id
         ORDER BY u.name, uu.name"
    );
} catch (Throwable $e) {
    error_log('[UniRide university administrators] ' . $e->getMessage());
    $pageError = 'Administrator information is temporarily unavailable.';
}

sys_page_start(
    'University Administrators',
    'administrators',
    'Every administrator uses the same role dashboard; university ownership comes from the database relationship.'
);
?>
<?php if ($pageError): ?><div class="alert error"><?= sys_h($pageError) ?></div><?php endif; ?>

<div class="admin-page-actions">
    <a class="button button-dark button-small" href="administrators.php?new=1">Add administrator</a>
    <a class="button button-light button-small" href="universities.php">Manage universities</a>
</div>

<?php if (isset($_GET['new'])): ?>
<section class="admin-card admin-card-accent">
    <div class="admin-card-heading"><div><p class="kicker">Shared role assignment</p><h2>New University Admin</h2></div><a href="administrators.php">Cancel</a></div>
    <form method="post" class="admin-form-grid">
        <input type="hidden" name="csrf_token" value="<?= sys_h(sys_csrf()) ?>">
        <input type="hidden" name="action" value="create_admin">
        <label><span>University</span><select name="university_id" required><option value="">Choose university</option><?php foreach ($universities as $university): ?><option value="<?= (int)$university['university_id'] ?>"><?= sys_h($university['name'] . ' (' . $university['code'] . ')') ?></option><?php endforeach; ?></select></label>
        <label><span>Role</span><select name="role"><option value="ADMIN">Admin</option><option value="MODERATOR">Moderator</option></select></label>
        <label><span>Name</span><input name="name" maxlength="200" required></label>
        <label><span>Email</span><input type="email" name="email" maxlength="200" placeholder="transport.admin@gmail.com" pattern="[^@\s]+@[gG][mM][aA][iI][lL]\.[cC][oO][mM]" title="Use a valid Gmail address ending in @gmail.com" required></label>
        <label><span>Temporary password</span><input type="password" name="password" minlength="8" autocomplete="new-password" required></label>
        <div class="admin-form-actions wide"><button class="button button-dark" type="submit">Create administrator</button></div>
    </form>
</section>
<?php endif; ?>

<section class="admin-card">
    <div class="admin-card-heading"><div><p class="kicker">One shared UniAdmin application</p><h2>All administrators</h2></div><span><?= number_format(count($administrators)) ?> total</span></div>
    <?php if (!$administrators): ?>
        <div class="admin-empty"><strong>No University Administrators found.</strong></div>
    <?php else: ?>
        <div class="admin-table-wrap"><table class="admin-table"><thead><tr><th>Administrator</th><th>University</th><th>Role</th><th>Status</th><th>Created</th><th>Actions</th></tr></thead><tbody>
        <?php foreach ($administrators as $administrator): ?>
            <tr>
                <td><strong><?= sys_h($administrator['name']) ?></strong><small><?= sys_h($administrator['email']) ?></small></td>
                <td><strong><?= sys_h($administrator['university_name']) ?></strong><small><?= sys_h($administrator['code']) ?> · ID <?= (int)$administrator['university_id'] ?></small></td>
                <td><?= sys_h($administrator['role']) ?></td>
                <td><span class="status-pill <?= sys_h(sys_status_class($administrator['status'])) ?>"><?= sys_h($administrator['status']) ?></span></td>
                <td><?= sys_h(date('d M Y', strtotime((string)$administrator['created_at']))) ?></td>
                <td><div class="admin-row-actions"><form method="post" class="inline-form"><input type="hidden" name="csrf_token" value="<?= sys_h(sys_csrf()) ?>"><input type="hidden" name="action" value="set_status"><input type="hidden" name="university_user_id" value="<?= (int)$administrator['university_user_id'] ?>"><input type="hidden" name="status" value="<?= $administrator['status'] === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE' ?>"><button type="submit"><?= $administrator['status'] === 'ACTIVE' ? 'Deactivate' : 'Activate' ?></button></form><form method="post" class="inline-form" data-delete-administrator data-administrator-name="<?= sys_h($administrator['name']) ?>" data-administrator-email="<?= sys_h($administrator['email']) ?>"><input type="hidden" name="csrf_token" value="<?= sys_h(sys_csrf()) ?>"><input type="hidden" name="action" value="delete_admin"><input type="hidden" name="university_user_id" value="<?= (int)$administrator['university_user_id'] ?>"><input type="hidden" name="delete_confirmation" value=""><button class="admin-delete-button" type="submit">Delete</button></form></div></td>
            </tr>
        <?php endforeach; ?>
        </tbody></table></div>
    <?php endif; ?>
</section>

<script src="../js/admin-administrators.js"></script>

<?php sys_page_end(); ?>
