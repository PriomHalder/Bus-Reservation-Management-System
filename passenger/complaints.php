<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

pp_render_start(
    'Complaints',
    'complaints',
    'Account · Phase 2',
    'Contact your university transport team and track the status of submitted complaints.'
);

pp_render_placeholder(
    'Phase 2',
    'Complaints',
    'Complaint submission, university responses and status history will live on this screen.'
);

pp_render_end();
