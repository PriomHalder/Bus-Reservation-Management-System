<?php
declare(strict_types=1);

$PROFILE_PAGE_ASSETS = true;
require_once __DIR__ . '/_page_shell.php';
require_once __DIR__ . '/../includes/profile/bootstrap.php';

profile_handle_request($pdo, 'PASSENGER', $ppPassengerId);

pp_render_start(
    'Profile',
    'profile',
    'Account & security',
    'Manage your identity, preferences, password and active sessions.'
);

profile_render_page($pdo, 'PASSENGER', $ppPassengerId, '..');
pp_render_end();
