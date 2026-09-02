<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

$message = '';
$messageType = '';

// Handle Notification Actions (Mark Read, Mark All Read, Delete)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    if ($action === 'mark_read') {
        $notifId = (int)($_POST['notification_id'] ?? 0);
        if ($notifId > 0) {
            try {
                $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE notification_id = ? AND passenger_id = ?");
                $stmt->execute([$notifId, $ppPassengerId]);
                $message = 'Notification marked as read.';
                $messageType = 'success';
            } catch (PDOException $e) {
                error_log('[notifications.php] ' . $e->getMessage());
            }
        }
    } elseif ($action === 'mark_all_read') {
        try {
            $stmt = $pdo->prepare("UPDATE notifications SET is_read = 1 WHERE passenger_id = ? AND is_read = 0");
            $stmt->execute([$ppPassengerId]);
            $message = 'All notifications marked as read.';
            $messageType = 'success';
        } catch (PDOException $e) {
            error_log('[notifications.php] ' . $e->getMessage());
        }
    } elseif ($action === 'delete') {
        $notifId = (int)($_POST['notification_id'] ?? 0);
        if ($notifId > 0) {
            try {
                $stmt = $pdo->prepare("DELETE FROM notifications WHERE notification_id = ? AND passenger_id = ?");
                $stmt->execute([$notifId, $ppPassengerId]);
                $message = 'Notification removed.';
                $messageType = 'success';
            } catch (PDOException $e) {
                error_log('[notifications.php] ' . $e->getMessage());
            }
        }
    }
}

// Filter mode
$filter = $_GET['filter'] ?? 'all';

// Fetch Notifications for logged-in passenger
$notifications = [];
$unreadCount = 0;

try {
    // Unread count query
    $stmtCount = $pdo->prepare("SELECT COUNT(*) FROM notifications WHERE passenger_id = ? AND is_read = 0");
    $stmtCount->execute([$ppPassengerId]);
    $unreadCount = (int)$stmtCount->fetchColumn();

    // Query list
    $sql = "SELECT notification_id, title, message, notification_type, is_read, created_at 
            FROM notifications 
            WHERE passenger_id = ?";
    
    if ($filter === 'unread') {
        $sql .= " AND is_read = 0";
    }
    
    $sql .= " ORDER BY created_at DESC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([$ppPassengerId]);
    $notifications = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    error_log('[notifications.php] ' . $e->getMessage());
}

pp_render_start(
    'Notifications',
    'notifications',
    'Account',
    'Stay updated on bookings, schedule changes, transfers and complaint responses.'
);
?>

<style>
    .notif-bar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-top: 20px;
        margin-bottom: 24px;
        flex-wrap: wrap;
        gap: 16px;
    }

    .notif-filters {
        display: flex;
        gap: 8px;
    }

    .notif-filter-btn {
        padding: 8px 16px;
        border-radius: 8px;
        font-size: 13px;
        font-weight: 600;
        text-decoration: none;
        color: var(--ui-text, #46505a);
        background: var(--ui-surface, #ffffff);
        border: 1px solid var(--ui-line-strong, #d2dce7);
        transition: all 0.15s ease;
    }

    .notif-filter-btn.active, .notif-filter-btn:hover {
        background: var(--ui-navy, #123f7c);
        color: #ffffff;
        border-color: var(--ui-navy, #123f7c);
    }

    .notif-alert {
        padding: 12px 16px;
        border-radius: 8px;
        margin-bottom: 20px;
        font-size: 13px;
        font-weight: 600;
        background: var(--ui-success-bg, #eef8f1);
        color: var(--ui-success, #176536);
        border: 1px solid #b9ddc5;
    }

    .notif-list {
        display: flex;
        flex-direction: column;
        gap: 12px;
    }

    .notif-card {
        background: var(--ui-surface, #ffffff);
        border: 1px solid var(--ui-line, #e1e7ee);
        border-radius: 12px;
        padding: 16px 20px;
        display: flex;
        gap: 16px;
        align-items: flex-start;
        position: relative;
        color: var(--ui-text, #46505a);
        box-shadow: var(--ui-shadow, 0 10px 30px rgba(11, 47, 97, 0.055));
        transition: border-color 0.15s ease, box-shadow 0.15s ease;
    }

    .notif-card.unread {
        border-left: 4px solid var(--ui-navy, #123f7c);
        background: var(--ui-navy-pale, #f8fbff);
    }

    .notif-card:hover {
        border-color: var(--ui-line-strong, #d2dce7);
        box-shadow: var(--ui-shadow-hover, 0 16px 38px rgba(11, 47, 97, 0.10));
    }

    .notif-icon {
        width: 40px;
        height: 40px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 18px;
        flex-shrink: 0;
        background: var(--ui-navy-soft, #eef4fb);
        color: var(--ui-navy, #123f7c);
        border: 1px solid #cbdced;
    }

    .notif-content {
        flex: 1;
    }

    .notif-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 4px;
    }

    .notif-title {
        font-size: 15px;
        font-weight: 700;
        color: var(--ui-ink, #17191c);
        margin: 0;
    }

    .notif-time {
        font-size: 11px;
        color: var(--ui-muted, #707780);
        white-space: nowrap;
    }

    .notif-body {
        font-size: 13px;
        color: var(--ui-text, #46505a);
        margin: 0 0 10px;
        line-height: 1.5;
    }

    .notif-actions {
        display: flex;
        gap: 10px;
    }

    .notif-btn-link {
        background: none;
        border: none;
        color: var(--ui-navy, #123f7c);
        font-size: 12px;
        font-weight: 600;
        cursor: pointer;
        padding: 0;
        text-decoration: underline;
    }

    .notif-btn-link.danger {
        color: var(--ui-danger, #a5241a);
    }

    .notif-btn-link:hover {
        color: var(--ui-navy-dark, #0b2f61);
    }

    .notif-btn-link.danger:hover {
        color: #7f1d1d;
    }

    .notif-empty {
        background: var(--ui-surface, #ffffff);
        border: 1px solid var(--ui-line, #e1e7ee);
        border-radius: 12px;
        padding: 48px 20px;
        text-align: center;
        color: var(--ui-text, #46505a);
        box-shadow: var(--ui-shadow, 0 10px 30px rgba(11, 47, 97, 0.055));
    }

    html[data-theme="dark"] .notif-filter-btn {
        color: #a9cfff;
        background: #132238;
        border-color: var(--ui-line-strong, #3a4d64);
    }

    html[data-theme="dark"] .notif-filter-btn.active,
    html[data-theme="dark"] .notif-filter-btn:hover {
        color: #ffffff;
        background: #245a9c;
        border-color: #3779c6;
    }

    html[data-theme="dark"] .notif-alert {
        background: var(--ui-success-bg, #102c21);
        color: var(--ui-success, #7bd8a0);
        border-color: #28583c;
    }

    html[data-theme="dark"] .notif-card,
    html[data-theme="dark"] .notif-empty {
        background: var(--ui-surface, #111d2c);
        border-color: var(--ui-line, #27374b);
        color: var(--ui-text, #c2ccd8);
        box-shadow: var(--ui-shadow, 0 12px 32px rgba(0, 0, 0, 0.24));
    }

    html[data-theme="dark"] .notif-card.unread {
        background: #14243a;
        border-left-color: #5b9be5;
    }

    html[data-theme="dark"] .notif-icon {
        background: #172a43;
        color: #8bbcff;
        border-color: #334a65;
    }

    html[data-theme="dark"] .notif-title {
        color: var(--ui-ink, #f2f6fb) !important;
    }

    html[data-theme="dark"] .notif-body {
        color: var(--ui-text, #c2ccd8);
    }

    html[data-theme="dark"] .notif-time {
        color: var(--ui-muted, #9ba9ba) !important;
    }

    html[data-theme="dark"] .notif-btn-link {
        color: #8bbcff;
    }

    html[data-theme="dark"] .notif-btn-link.danger {
        color: var(--ui-danger, #ff9e98);
    }

    html[data-theme="dark"] .notif-btn-link:hover {
        color: #c3dcff;
    }

    html[data-theme="dark"] .notif-btn-link.danger:hover {
        color: #ffc0bc;
    }
</style>

<?php if ($message): ?>
    <div class="notif-alert">
        <?= pp_h($message) ?>
    </div>
<?php endif; ?>

<!-- Notification Header Controls -->
<div class="notif-bar">
    <div class="notif-filters">
        <a href="notifications.php?filter=all" class="notif-filter-btn <?= $filter !== 'unread' ? 'active' : '' ?>">
            All Notifications
        </a>
        <a href="notifications.php?filter=unread" class="notif-filter-btn <?= $filter === 'unread' ? 'active' : '' ?>">
            Unread <?= $unreadCount > 0 ? '(' . $unreadCount . ')' : '' ?>
        </a>
    </div>

    <?php if ($unreadCount > 0): ?>
        <form method="POST" action="">
            <input type="hidden" name="action" value="mark_all_read">
            <button type="submit" class="pp-secondary-button" style="font-size:12px; padding:6px 14px;">
                ✓ Mark All as Read
            </button>
        </form>
    <?php endif; ?>
</div>

<!-- Notification List -->
<?php if (empty($notifications)): ?>
    <div class="notif-empty">
        <div style="font-size:36px; margin-bottom:12px;">🔔</div>
        <h3 style="color:var(--ui-ink, #17191c); margin:0 0 6px; font-size:16px;">No Notifications</h3>
        <p style="color:var(--ui-muted, #707780); font-size:13px; margin:0;">
            <?= $filter === 'unread' ? 'You have no unread notifications.' : 'You are all caught up! Updates regarding your bookings and transport alerts will appear here.' ?>
        </p>
    </div>
<?php else: ?>
    <div class="notif-list">
        <?php foreach ($notifications as $n): 
            $isUnread = ((int)$n['is_read'] === 0);
            $type = strtoupper($n['notification_type'] ?? 'GENERAL');

            $icon = '🔔';
            if (str_contains($type, 'BOOKING')) $icon = '🎫';
            elseif (str_contains($type, 'SCHEDULE')) $icon = '🚌';
            elseif (str_contains($type, 'TRANSFER')) $icon = '🔄';
            elseif (str_contains($type, 'COMPLAINT')) $icon = '💬';
        ?>
            <div class="notif-card <?= $isUnread ? 'unread' : '' ?>">
                <div class="notif-icon">
                    <?= $icon ?>
                </div>

                <div class="notif-content">
                    <div class="notif-header">
                        <h4 class="notif-title"><?= pp_h($n['title']) ?></h4>
                        <span class="notif-time"><?= pp_h($n['created_at']) ?></span>
                    </div>

                    <p class="notif-body"><?= pp_h($n['message']) ?></p>

                    <div class="notif-actions">
                        <?php if ($isUnread): ?>
                            <form method="POST" action="" style="display:inline;">
                                <input type="hidden" name="action" value="mark_read">
                                <input type="hidden" name="notification_id" value="<?= $n['notification_id'] ?>">
                                <button type="submit" class="notif-btn-link">Mark as Read</button>
                            </form>
                            <span style="color:var(--ui-muted, #707780);">•</span>
                        <?php endif; ?>

                        <form method="POST" action="" style="display:inline;">
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="notification_id" value="<?= $n['notification_id'] ?>">
                            <button type="submit" class="notif-btn-link danger" onclick="return confirm('Dismiss this notification?')">Dismiss</button>
                        </form>
                    </div>
                </div>
            </div>
        <?php endforeach; ?>
    </div>
<?php endif; ?>

<?php
pp_render_end();
