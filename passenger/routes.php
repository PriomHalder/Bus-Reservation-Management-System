<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

pp_render_start(
    'Routes & Schedules',
    'routes',
    'Travel · Phase 2',
    'Browse transport routes and upcoming schedules published by your university.'
);

pp_render_placeholder(
    'Phase 2',
    'Routes & Schedules',
    'Route search, favorite-first ordering, schedule availability and bus-capacity information will live on this screen.'
);

pp_render_end();
