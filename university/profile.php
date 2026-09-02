<?php
declare(strict_types=1);

$PROFILE_PAGE_ASSETS = true;
require_once __DIR__ . '/_university_shell.php';
require_once __DIR__ . '/../includes/profile/bootstrap.php';

profile_handle_request($pdo, 'UNIVERSITY_ADMIN', $uAdminId);

u_render_start(
    'Profile',
    'profile',
    'Account & security',
    'Manage your administrator identity, operational alerts and active sessions.'
);
u_render_heading_end();
profile_render_page($pdo, 'UNIVERSITY_ADMIN', $uAdminId, '..');
u_render_end();
