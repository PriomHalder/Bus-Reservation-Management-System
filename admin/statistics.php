<?php
declare(strict_types=1);

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}

require_once __DIR__ . '/../includes/auth.php';

requireRole('SYSTEM_ADMIN', '..');
header('Location: dashboard.php', true, 302);
exit;
