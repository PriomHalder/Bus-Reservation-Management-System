<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

pp_render_start(
    'Notifications',
    'notifications',
    'Account · Phase 2',
    'Stay updated on bookings, schedule changes, transfers and complaint responses.'
);

pp_render_placeholder(
    'Phase 2',
    'Notifications',
    'Unread/read notification management and passenger transport alerts will live on this screen.'
);

pp_render_end();
