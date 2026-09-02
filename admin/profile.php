<?php
declare(strict_types=1);

$PROFILE_PAGE_ASSETS = true;
require_once __DIR__ . '/_admin_context.php';
require_once __DIR__ . '/../includes/profile/bootstrap.php';

profile_handle_request($pdo, 'SYSTEM_ADMIN', $sysAdminId);

sys_page_start(
    'Profile',
    'profile',
    'Manage your platform identity, security preferences and active sessions.'
);
profile_render_page($pdo, 'SYSTEM_ADMIN', $sysAdminId, '..');
sys_page_end();
