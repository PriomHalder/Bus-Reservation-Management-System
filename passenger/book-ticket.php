<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

pp_render_start(
    'Book a Ticket',
    'book-ticket',
    'Travel · Phase 2',
    'Choose a university bus schedule and continue to seat or standing-slot selection.'
);

pp_render_placeholder(
    'Phase 2',
    'Book a Ticket',
    'Seat map, standing slots and fare confirmation for the 10-row, 4-across bus layout.'
);

pp_render_end();
