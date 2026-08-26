<?php
declare(strict_types=1);

require_once __DIR__ . '/_university_shell.php';

$tableReady = u_table_exists($pdo, 'announcements');

if ($tableReady && $_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!u_verify_csrf($_POST['csrf_token'] ?? null)) {
        u_flash('error', 'Your session expired. Please try again.');
        u_redirect('announcements.php');
    }

    $action = (string)($_POST['action'] ?? '');

    if ($action === 'create_announcement') {
        $title = trim((string)($_POST['title'] ?? ''));
        $message = trim((string)($_POST['message'] ?? ''));
        $status = strtoupper((string)($_POST['status'] ?? 'DRAFT'));

        if ($title === '' || strlen($title) > 180 || $message === '') {
            u_flash('error', 'Enter a title of up to 180 characters and an announcement message.');
            u_redirect('announcements.php?new=1');
        }
        if (!in_array($status, ['DRAFT', 'PUBLISHED'], true)) {
            $status = 'DRAFT';
        }

        try {
            $pdo->beginTransaction();
            $stmt = $pdo->prepare(
                "INSERT INTO announcements
                    (university_id, created_by, title, message, status, published_at)
                 VALUES (?, ?, ?, ?, ?, CASE WHEN ?='PUBLISHED' THEN NOW() ELSE NULL END)"
            );
            $stmt->execute([$uUniversityId, $uAdminId ?: null, $title, $message, $status, $status]);
            $announcementId = (int)$pdo->lastInsertId();

            if ($status === 'PUBLISHED' && u_table_exists($pdo, 'notifications')) {
                $notify = $pdo->prepare(
                    "INSERT INTO notifications
                        (passenger_id, title, message, notification_type, reference_id)
                     SELECT p.passenger_id, ?, ?, 'ANNOUNCEMENT', ?
                     FROM passengers p
                     WHERE p.university_id=? AND p.status='ACTIVE'
                       AND COALESCE(p.in_app_notifications,1)=1"
                );
                $notify->execute([$title, $message, $announcementId, $uUniversityId]);
            }

            $pdo->commit();
            u_flash(
                'success',
                $status === 'PUBLISHED'
                    ? 'Announcement published to this university’s passengers.'
                    : 'Announcement saved as a draft.'
            );
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            error_log('[UniRide create announcement] ' . $e->getMessage());
            u_flash('error', 'The announcement could not be saved.');
        }
        u_redirect('announcements.php');
    }

    if ($action === 'set_announcement_status') {
        $announcementId = (int)($_POST['announcement_id'] ?? 0);
        $status = strtoupper((string)($_POST['status'] ?? ''));

        if ($announcementId <= 0 || !in_array($status, ['PUBLISHED', 'ARCHIVED'], true)) {
            u_flash('error', 'Invalid announcement request.');
            u_redirect('announcements.php');
        }

        try {
            $pdo->beginTransaction();
            $announcement = u_one(
                $pdo,
                'SELECT announcement_id,title,message,status FROM announcements
                 WHERE announcement_id=? AND university_id=? FOR UPDATE',
                [$announcementId, $uUniversityId]
            );

            if (!$announcement) {
                throw new RuntimeException('Announcement not found for this university.');
            }

            $stmt = $pdo->prepare(
                "UPDATE announcements
                 SET status=?, published_at=CASE
                     WHEN ?='PUBLISHED' THEN COALESCE(published_at,NOW())
                     ELSE published_at END
                 WHERE announcement_id=? AND university_id=?"
            );
            $stmt->execute([$status, $status, $announcementId, $uUniversityId]);

            if (
                $status === 'PUBLISHED'
                && $announcement['status'] !== 'PUBLISHED'
                && u_table_exists($pdo, 'notifications')
            ) {
                $notify = $pdo->prepare(
                    "INSERT INTO notifications
                        (passenger_id,title,message,notification_type,reference_id)
                     SELECT p.passenger_id, ?, ?, 'ANNOUNCEMENT', ?
                     FROM passengers p
                     WHERE p.university_id=? AND p.status='ACTIVE'
                       AND COALESCE(p.in_app_notifications,1)=1
                       AND NOT EXISTS (
                           SELECT 1 FROM notifications n
                           WHERE n.passenger_id=p.passenger_id
                             AND n.notification_type='ANNOUNCEMENT'
                             AND n.reference_id=?
                       )"
                );
                $notify->execute([
                    $announcement['title'],
                    $announcement['message'],
                    $announcementId,
                    $uUniversityId,
                    $announcementId,
                ]);
            }

            $pdo->commit();
            u_flash('success', $status === 'PUBLISHED' ? 'Announcement published.' : 'Announcement archived.');
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            error_log('[UniRide announcement status] ' . $e->getMessage());
            u_flash(
                'error',
                $e instanceof RuntimeException ? $e->getMessage() : 'The announcement could not be updated.'
            );
        }
        u_redirect('announcements.php');
    }
}

$statusFilter = strtoupper((string)($_GET['status'] ?? 'ALL'));
if (!in_array($statusFilter, ['ALL', 'DRAFT', 'PUBLISHED', 'ARCHIVED'], true)) {
    $statusFilter = 'ALL';
}

$rows = [];
if ($tableReady) {
    try {
        $sql = "SELECT a.announcement_id,a.title,a.message,a.status,a.published_at,
                       a.created_at,uu.name AS creator_name
                FROM announcements a
                LEFT JOIN university_users uu
                  ON uu.university_user_id=a.created_by
                 AND uu.university_id=a.university_id
                WHERE a.university_id=?";
        $params = [$uUniversityId];
        if ($statusFilter !== 'ALL') {
            $sql .= ' AND a.status=?';
            $params[] = $statusFilter;
        }
        $sql .= ' ORDER BY a.created_at DESC LIMIT 100';
        $rows = u_all($pdo, $sql, $params);
    } catch (Throwable $e) {
        error_log('[UniRide announcements] ' . $e->getMessage());
    }
}

u_render_start(
    'Announcements',
    'announcements',
    'Service',
    'Publish university-scoped transport updates to active passengers.'
);
if ($tableReady) {
    u_render_actions('<a class="up-button" href="announcements.php?new=1">+ New Announcement</a>');
}
u_render_heading_end();
?>

<?php if (!$tableReady): ?>
    <div class="up-note">
        <strong>Database migration required.</strong>
        Run <code>database/migrations/003_shared_dashboard_tenancy.sql</code> once to enable tenant-owned announcements for every university.
    </div>
<?php else: ?>
    <?php if (isset($_GET['new'])): ?>
        <section class="up-card blue up-card-spaced">
            <div class="section-heading-row"><div><p class="dashboard-kicker">University-wide message</p><h2>New Announcement</h2></div></div>
            <form method="post" class="up-form-grid">
                <input type="hidden" name="csrf_token" value="<?= u_h(u_csrf()) ?>">
                <input type="hidden" name="action" value="create_announcement">
                <label class="up-field wide"><span>Title</span><input name="title" maxlength="180" required></label>
                <label class="up-field wide"><span>Message</span><textarea name="message" required></textarea></label>
                <label class="up-field"><span>Save as</span><select name="status"><option value="DRAFT">Draft</option><option value="PUBLISHED">Publish now</option></select></label>
                <div class="up-form-actions"><button class="up-button" type="submit">Save Announcement</button><a class="up-button-secondary" href="announcements.php">Cancel</a></div>
            </form>
        </section>
    <?php endif; ?>

    <div class="up-tabs">
        <?php foreach (['ALL', 'DRAFT', 'PUBLISHED', 'ARCHIVED'] as $filter): ?>
            <a class="up-tab <?= $filter === $statusFilter ? 'active' : '' ?>" href="?status=<?= u_h($filter) ?>"><?= u_h($filter) ?></a>
        <?php endforeach; ?>
    </div>

    <?php if (!$rows): ?>
        <div class="up-empty"><div><strong>No announcements in this view.</strong><p>Create one for <?= u_h($uUniversity['name']) ?>.</p></div><a class="up-button" href="?new=1">New Announcement</a></div>
    <?php else: ?>
        <div class="up-table-wrap"><table class="up-table"><thead><tr><th>Announcement</th><th>Status</th><th>Created by</th><th>Date</th><th>Action</th></tr></thead><tbody>
        <?php foreach ($rows as $row): ?>
            <tr>
                <td><strong><?= u_h($row['title']) ?></strong><small><?= u_h($row['message']) ?></small></td>
                <td><span class="up-status <?= u_h(u_status_class($row['status'])) ?>"><?= u_h($row['status']) ?></span></td>
                <td><?= u_h($row['creator_name'] ?: 'University Admin') ?></td>
                <td><?= u_h(u_date($row['published_at'] ?: $row['created_at'], 'd M Y · g:i A')) ?></td>
                <td>
                    <?php if ($row['status'] !== 'ARCHIVED'): ?>
                    <form method="post" class="up-inline-form">
                        <input type="hidden" name="csrf_token" value="<?= u_h(u_csrf()) ?>">
                        <input type="hidden" name="action" value="set_announcement_status">
                        <input type="hidden" name="announcement_id" value="<?= (int)$row['announcement_id'] ?>">
                        <input type="hidden" name="status" value="<?= $row['status'] === 'DRAFT' ? 'PUBLISHED' : 'ARCHIVED' ?>">
                        <button class="up-button-secondary" type="submit"><?= $row['status'] === 'DRAFT' ? 'Publish' : 'Archive' ?></button>
                    </form>
                    <?php else: ?>—<?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody></table></div>
    <?php endif; ?>
<?php endif; ?>

<?php u_render_end(); ?>
