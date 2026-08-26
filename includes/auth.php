<?php
declare(strict_types=1);

require_once __DIR__ . '/profile/session-management.php';
require_once __DIR__ . '/theme.php';

function h(mixed $value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

function csrfToken(): string
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }

    return (string)$_SESSION['csrf_token'];
}

function verifyCsrf(string $submitted): bool
{
    return hash_equals(csrfToken(), $submitted);
}

/**
 * Bare "is anyone signed in" gate, with no role check.
 *
 * $base is the path back to the app root, exactly as in requireRole(): '.'
 * at the root, '..' from a role directory. Without it a page in a
 * subdirectory would redirect to passenger/signin.php, which does not
 * exist. The default keeps the original root-level behaviour.
 *
 * Prefer requireRole() for anything under passenger/, university/, admin/
 * or tools/ — an area that is worth gating is almost always worth gating to
 * a specific role.
 */
function requireLogin(string $base = '.'): void
{
    if (empty($_SESSION['authenticated']) || empty($_SESSION['user_type'])) {
        header('Location: ' . $base . '/signin.php');
        exit;
    }
}

/*
|--------------------------------------------------------------------------
| Phase 1 dashboard authorisation
|--------------------------------------------------------------------------
| The three dashboards live in subdirectories, so they cannot reuse the
| relative redirect in requireLogin(). These helpers take the app root as
| an argument instead of guessing at it.
*/

/** Canonical dashboard path for a role, relative to the app root. */
function dashboardPathFor(?string $userType): string
{
    require_once __DIR__ . '/dashboard/nav.php';
    return (string)dashboard_role((string)$userType)['dashboard'];
}

/**
 * Gate a page to one or more roles.
 *
 * Not signed in            -> redirected to the sign-in page.
 * Signed in as wrong role  -> 403, rendered as a plain page so no schema
 *                             or session detail leaks.
 *
 * $base is the path back to the app root ('.' at the root, '..' one level
 * down) so this works identically from any directory depth.
 */
function requireRole(string|array $allowed, string $base = '.'): void
{
    $allowed = array_map(
        static fn($role): string => strtoupper((string)$role),
        is_array($allowed) ? $allowed : [$allowed]
    );

    if (empty($_SESSION['authenticated']) || empty($_SESSION['user_type'])) {
        header('Location: ' . $base . '/signin.php');
        exit;
    }

    $userType = strtoupper((string)$_SESSION['user_type']);

    if (in_array($userType, $allowed, true)) {
        if (isset($GLOBALS['pdo']) && $GLOBALS['pdo'] instanceof PDO) {
            profile_enforce_session($GLOBALS['pdo'], $base);
        }
        return;
    }

    // Authenticated, but not for this area.
    http_response_code(403);
    header('Content-Type: text/html; charset=utf-8');

    $ownDashboard = $base . '/' . dashboardPathFor($userType);

    echo '<!doctype html><html lang="en"><head><meta charset="utf-8">'
        . '<meta name="viewport" content="width=device-width, initial-scale=1">'
        . '<title>Not available — UniRide</title>'
        . uniride_theme_head_html($base)
        . '<link rel="stylesheet" href="' . h($base) . '/css/style.css">'
        . '<link rel="stylesheet" href="' . h($base) . '/css/uniride-ui.css"></head>'
        . '<body class="access-denied-page"><main class="container" style="padding:120px 0;max-width:560px">'
        . '<p class="kicker">403 — Forbidden</p>'
        . '<h1 style="font-family:Georgia,serif;font-weight:500;letter-spacing:-.04em;'
        . 'font-size:44px;margin:0 0 14px">This area is not available '
        . 'to your account.</h1>'
        . '<p style="color:#777">Your account does not have permission to view '
        . 'this part of UniRide.</p>'
        . '<p style="margin-top:26px"><a class="button button-dark" href="'
        . h($ownDashboard) . '">Go to your dashboard</a></p>'
        . '</main></body></html>';

    exit;
}

/**
 * Session value that identifies the signed-in passenger. Ownership is read
 * from the session only — never from the query string or request body.
 */
function sessionPassengerId(): int
{
    return (int)($_SESSION['passenger_id'] ?? 0);
}

/** Session-scoped university, used to isolate every university admin query. */
function sessionUniversityId(): int
{
    return (int)($_SESSION['university_id'] ?? 0);
}
