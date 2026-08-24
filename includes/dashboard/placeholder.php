<?php
declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| UniRide — Phase 1 placeholder page
|--------------------------------------------------------------------------
| Every sidebar link resolves to a real, role-guarded page even though the
| full CRUD feature arrives in a later phase. That keeps the navigation
| honest: no 404s, no dead anchors, and no link that silently does nothing.
|
| A stub page is two lines — it declares its role and includes this file.
| The title and description come from placeholder_section() in nav.php, so
| a sidebar entry and its page are described in one place.
|
| The including stub must define:
|   $ROLE   PASSENGER | UNIVERSITY_ADMIN | SYSTEM_ADMIN
*/

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}

require_once __DIR__ . '/../auth.php';
require_once __DIR__ . '/nav.php';

$BASE = '..';
$ROLE = strtoupper((string)($ROLE ?? ''));

requireRole($ROLE, $BASE);

// Identify the page from the script that included this file, so a stub
// needs no configuration beyond its role.
$script  = basename((string)($_SERVER['SCRIPT_NAME'] ?? ''));
$section = placeholder_section($ROLE, $script);

if ($section === null) {
    // A link exists in the sidebar that this registry does not describe.
    // Fall back rather than fail, and leave a trace for the developer.
    error_log('[UniRide] No placeholder_section() entry for ' . $ROLE . '/' . $script);

    $section = [
        'title' => 'Coming soon',
        'blurb' => 'This area is part of a later phase of the project.',
        'nav'   => '',
    ];
}

$ROLE_WORD = match ($ROLE) {
    'UNIVERSITY_ADMIN' => 'University',
    'SYSTEM_ADMIN'     => 'Platform',
    default            => 'Passenger',
};

$PAGE_TITLE = $section['title'];
$ACTIVE_NAV = $section['nav'];

/*
 * Ticket transfers are a student behaviour: sp_request_ticket_transfer only
 * moves a ticket between two passengers of the same type, and it is
 * students who share or sell a seat. A faculty passenger therefore does not
 * get the sidebar link, and reaching the page directly redirects them home
 * rather than showing an area that can never apply to them.
 */
$NAV_HIDE = [];

if ($ROLE === 'PASSENGER'
    && strtoupper((string)($_SESSION['passenger_type'] ?? 'STUDENT')) !== 'STUDENT') {
    $NAV_HIDE[] = 'ticket-transfers';

    if ($script === 'ticket-transfers.php') {
        header('Location: ' . $BASE . '/passenger/dashboard.php');
        exit;
    }
}

$dashboardHref = $BASE . '/' . dashboardPathFor($ROLE);

require __DIR__ . '/layout_top.php';
?>

<section class="page-head">
    <h1><?= h($section['title']) ?></h1>
    <p class="page-meta"><span>Phase 2</span></p>
</section>

<section class="panel">
    <div class="surface surface-pad">
        <div class="stub">
            <p class="stub-blurb"><?= h($section['blurb']) ?></p>

            <p class="stub-note">
                The dashboard for your role is complete and reads live data
                from the database. This page is reserved for the full
                create, read, update and delete screens, which are the next
                stage of the project.
            </p>

            <div class="trip-actions">
                <a class="button button-dark button-small"
                   href="<?= h($dashboardHref) ?>">Back to dashboard</a>
            </div>
        </div>
    </div>
</section>

<?php require __DIR__ . '/layout_bottom.php'; ?>
