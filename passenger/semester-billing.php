<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

pp_render_start(
    'Semester Billing',
    'semester-billing',
    'Account · Phase 2',
    'Review transport charges and adjustments for your active academic semester.'
);

pp_render_placeholder(
    'Phase 2',
    'Semester Billing',
    'Booking charges, cancellation credits, transfer adjustments and semester totals will live on this screen.'
);

pp_render_end();
