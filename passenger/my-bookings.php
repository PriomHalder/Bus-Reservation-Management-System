<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

pp_render_start(
    'My Bookings',
    'my-bookings',
    'Travel · Phase 2',
    'Review your active ticket, upcoming journeys and preserved booking history.'
);

pp_render_placeholder(
    'Phase 2',
    'My Bookings',
    'Active bookings, QR ticket access, cancellation controls and booking history will live on this screen.'
);

pp_render_end();
