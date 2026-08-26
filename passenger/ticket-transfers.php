<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

pp_render_start(
    'Ticket Transfers',
    'ticket-transfers',
    'Travel · Phase 2',
    'Share or sell an eligible ticket to another passenger from your university.'
);

pp_render_placeholder(
    'Phase 2',
    'Ticket Transfers',
    'Transfer requests, recipient eligibility checks and transfer history will live on this screen.'
);

pp_render_end();
