<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

pp_render_start(
    'Favorite Routes',
    'favorite-routes',
    'Travel · Phase 2',
    'Keep the routes you use most often ready for quick access.'
);

pp_render_placeholder(
    'Phase 2',
    'Favorite Routes',
    'Saved-route management and favorite-first schedule browsing will live on this screen.'
);

pp_render_end();
