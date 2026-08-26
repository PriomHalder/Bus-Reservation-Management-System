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
        color: #94a3b8;
        background: rgba(15, 23, 42, 0.6);
        border: 1px solid #1e293b;
        transition: all 0.15s ease;
    }

    .notif-filter-btn.active, .notif-filter-btn:hover {
        background: #0284c7;
        color: #ffffff;
        border-color: #0284c7;
    }

    .notif-alert {
        padding: 12px 16px;
        border-radius: 8px;
        margin-bottom: 20px;
        font-size: 13px;
        font-weight: 600;
        background: rgba(22, 163, 74, 0.15);
        color: #4ade80;
        border: 1px solid rgba(74, 222, 128, 0.3);
    }

    .notif-list {
        display: flex;
        flex-direction: column;
        gap: 12px;
    }

    .notif-card {
        background: rgba(15, 23, 42, 0.75);
        border: 1px solid #1e293b;
        border-radius: 12px;
        padding: 16px 20px;
        display: flex;
        gap: 16px;
        align-items: flex-start;
        position: relative;
        transition: border-color 0.15s ease;
    }

    .notif-card.unread {
        border-left: 4px solid #38bdf8;
        background: rgba(15, 23, 42, 0.9);
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
        background: rgba(2, 132, 199, 0.15);
        color: #38bdf8;
        border: 1px solid rgba(56, 189, 248, 0.2);
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
        color: #f8fafc;
        margin: 0;
    }

    .notif-time {
        font-size: 11px;
        color: #64748b;
        white-space: nowrap;
    }

    .notif-body {
        font-size: 13px;
        color: #94a3b8;
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
        color: #38bdf8;
        font-size: 12px;
        font-weight: 600;
        cursor: pointer;
        padding: 0;
        text-decoration: underline;
    }

    .notif-btn-link.danger {
        color: #f87171;
    }

    .notif-empty {
        background: rgba(15, 23, 42, 0.75);
        border: 1px solid #1e293b;
        border-radius: 12px;
        padding: 48px 20px;
        text-align: center;
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
        <h3 style="color:#f8fafc; margin:0 0 6px; font-size:16px;">No Notifications</h3>
        <p style="color:#64748b; font-size:13px; margin:0;">
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
                            <span style="color:#334155;">•</span>
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