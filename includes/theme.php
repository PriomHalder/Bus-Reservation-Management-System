<?php
declare(strict_types=1);

/**
 * Shared, pre-render theme bootstrap for every UniRide page family.
 *
 * The inline bootstrap is intentionally tiny: it applies the stored or
 * operating-system preference before stylesheets paint, while theme.js owns
 * the interactive control and cross-page persistence.
 */
function uniride_theme_head_html(string $base = '.'): string
{
    $script = rtrim($base, '/') . '/js/theme.js';
    $script = htmlspecialchars($script, ENT_QUOTES, 'UTF-8');

    return <<<'HTML'
<script>
(function(){
    var key='uniride-color-theme',theme=null;
    try{theme=window.localStorage.getItem(key);}catch(error){}
    if(theme!=='light'&&theme!=='dark'){
        var match=document.cookie.match(new RegExp('(?:^|; )'+key+'=(light|dark)(?:;|$)'));
        theme=match?match[1]:null;
    }
    if(theme!=='light'&&theme!=='dark'){
        theme=window.matchMedia&&window.matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';
    }
    document.documentElement.setAttribute('data-theme',theme);
    document.documentElement.style.colorScheme=theme;
})();
</script>
HTML
        . '<script src="' . $script . '" defer></script>';
}

/** Resolve the app-relative asset base for an error raised before a shell. */
function uniride_theme_request_base(): string
{
    $appRoot = str_replace('\\', '/', realpath(dirname(__DIR__)) ?: dirname(__DIR__));
    $script = (string)($_SERVER['SCRIPT_FILENAME'] ?? '');
    $scriptDirectory = str_replace('\\', '/', realpath(dirname($script)) ?: dirname($script));

    if ($script === '' || !str_starts_with($scriptDirectory, $appRoot)) {
        return '.';
    }

    $relative = trim(substr($scriptDirectory, strlen($appRoot)), '/');
    if ($relative === '') {
        return '.';
    }

    return implode('/', array_fill(0, count(array_filter(explode('/', $relative))), '..'));
}

/** Render early authorization/service failures with the shared theme system. */
function uniride_render_error_page(string $message, ?string $base = null): never
{
    $status = http_response_code();
    if ($status < 400) {
        $status = 500;
        http_response_code($status);
    }

    $base = $base ?? uniride_theme_request_base();
    $safeBase = htmlspecialchars(rtrim($base, '/'), ENT_QUOTES, 'UTF-8');
    $safeMessage = htmlspecialchars($message, ENT_QUOTES, 'UTF-8');
    $title = $status === 403 ? 'Access unavailable' : 'Service unavailable';

    echo '<!doctype html><html lang="en"><head><meta charset="utf-8">'
        . '<meta name="viewport" content="width=device-width, initial-scale=1">'
        . '<title>' . $title . ' — UniRide</title>'
        . uniride_theme_head_html($base)
        . '<link rel="icon" href="' . $safeBase . '/img/logo.svg" type="image/svg+xml">'
        . '<link rel="stylesheet" href="' . $safeBase . '/css/style.css">'
        . '<link rel="stylesheet" href="' . $safeBase . '/css/uniride-ui.css"></head>'
        . '<body class="access-denied-page"><main class="container">'
        . '<p class="kicker">' . $status . ' — ' . $title . '</p>'
        . '<h1>' . $safeMessage . '</h1>'
        . '<p>Return to UniRide or try again after confirming your account and service status.</p>'
        . '<p><a class="button button-dark" href="' . $safeBase . '/index.php">Return to UniRide</a></p>'
        . '</main></body></html>';
    exit;
}
