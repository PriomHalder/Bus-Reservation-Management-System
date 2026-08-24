<?php
declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| UniRide Passenger Subpage Shell
|--------------------------------------------------------------------------
| Self-contained Passenger-only shell.
| CSS + mobile navigation JS are embedded here so Passenger subpages cannot
| lose styling because of a missing external stylesheet.
*/

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/dashboard/nav.php';
require_once __DIR__ . '/../includes/profile/session-management.php';
require_once __DIR__ . '/../includes/theme.php';

if (empty($_SESSION['authenticated'])) {
    header('Location: ../signin.php');
    exit;
}

if (($_SESSION['user_type'] ?? '') !== 'PASSENGER') {
    header('Location: ../dashboard.php');
    exit;
}

function pp_h(mixed $value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

function pp_scalar(PDO $pdo, string $sql, array $params = []): int
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    return (int)$stmt->fetchColumn();
}

function pp_profile(PDO $pdo, int $passengerId): array
{
    $stmt = $pdo->prepare(
        "SELECT
            p.passenger_id,
            p.university_id,
            p.name,
            p.email,
            p.passenger_type,
            p.status,
            u.code AS university_code,
            u.name AS university_name,
            u.status AS university_status
         FROM passengers p
         INNER JOIN universities u
            ON u.university_id = p.university_id
         WHERE p.passenger_id = ?
         LIMIT 1"
    );
    $stmt->execute([$passengerId]);

    return $stmt->fetch() ?: [];
}

function pp_active_class(string $key, string $active): string
{
    return $key === $active ? ' is-active' : '';
}

$ppPassengerId = (int)($_SESSION['passenger_id'] ?? $_SESSION['user_id'] ?? 0);

if ($ppPassengerId <= 0) {
    session_destroy();
    header('Location: ../signin.php');
    exit;
}

$ppProfile = pp_profile($pdo, $ppPassengerId);

if (!$ppProfile) {
    http_response_code(403);
    uniride_render_error_page('Passenger account not found.', '..');
}

if (
    strtoupper((string)$ppProfile['status']) !== 'ACTIVE'
    || strtoupper((string)$ppProfile['university_status']) !== 'ACTIVE'
) {
    http_response_code(403);
    uniride_render_error_page('This passenger account is currently unavailable.', '..');
}

$ppUniversityId = (int)$ppProfile['university_id'];
profile_enforce_session($pdo, '..');

if (
    basename((string)($_SERVER['SCRIPT_NAME'] ?? '')) === 'ticket-transfers.php'
    && strtoupper((string)$ppProfile['passenger_type']) !== 'STUDENT'
) {
    header('Location: dashboard.php');
    exit;
}

if (
    !empty($_SESSION['university_id'])
    && (int)$_SESSION['university_id'] !== $ppUniversityId
) {
    http_response_code(403);
    uniride_render_error_page('Passenger session does not match this university.', '..');
}

$ppCounts = [
    'bookings' => 0,
    'favorites' => 0,
    'notifications' => 0,
    'complaints' => 0,
];

try {
    $ppCounts['bookings'] = pp_scalar(
        $pdo,
        "SELECT COUNT(DISTINCT b.booking_id)
         FROM bookings b
         INNER JOIN schedules s ON s.schedule_id = b.schedule_id
         INNER JOIN routes r ON r.route_id = s.route_id
         WHERE b.passenger_id = ?
           AND r.university_id = ?
           AND b.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')
           AND s.status <> 'CANCELLED'
           AND s.schedule_date >= CURDATE()",
        [$ppPassengerId, $ppUniversityId]
    );

    $ppCounts['favorites'] = pp_scalar(
        $pdo,
        "SELECT COUNT(DISTINCT fr.favorite_id)
         FROM favorite_routes fr
         INNER JOIN routes r ON r.route_id = fr.route_id
         WHERE fr.passenger_id = ?
           AND r.university_id = ?",
        [$ppPassengerId, $ppUniversityId]
    );

    $ppCounts['notifications'] = pp_scalar(
        $pdo,
        "SELECT COUNT(*)
         FROM notifications
         WHERE passenger_id = ?
           AND is_read = 0",
        [$ppPassengerId]
    );

    $ppCounts['complaints'] = pp_scalar(
        $pdo,
        "SELECT COUNT(*)
         FROM complaints
         WHERE passenger_id = ?
           AND university_id = ?
           AND status IN ('OPEN','IN_PROGRESS')",
        [$ppPassengerId, $ppUniversityId]
    );
} catch (Throwable $e) {
    error_log('[UniRide Passenger subpage shell] ' . $e->getMessage());
}

function pp_render_start(
    string $pageTitle,
    string $activeNav,
    string $eyebrow,
    string $description
): void {
    global $ppProfile, $ppCounts, $PROFILE_PAGE_ASSETS;

    $passengerType = ucfirst(
        strtolower((string)($ppProfile['passenger_type'] ?? 'Passenger'))
    );
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= pp_h($pageTitle) ?> — UniRide</title>
    <?= uniride_theme_head_html('..') ?>
    <link rel="icon" type="image/svg+xml" href="../img/logo.svg">

    <style>
        :root {
            --pp-blue: #184987;
            --pp-blue-dark: #10376a;
            --pp-blue-soft: #edf4fb;
            --pp-blue-pale: #f8fbff;
            --pp-white: #ffffff;
            --pp-ink: #17191c;
            --pp-muted: #737a82;
            --pp-muted-2: #9aa1a9;
            --pp-line: #e3e8ee;
            --pp-line-blue: #d2deeb;
            --pp-soft: #f5f7f9;
            --pp-sidebar: 280px;
            --pp-serif: Georgia, "Times New Roman", serif;
            --pp-ui: Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }

        * {
            box-sizing: border-box;
        }

        html {
            scroll-behavior: smooth;
        }

        body.pp-body {
            min-height: 100vh;
            margin: 0;
            overflow-x: hidden;
            background: #fff;
            color: var(--pp-ink);
            font-family: var(--pp-ui);
            font-size: 13px;
            line-height: 1.5;
            -webkit-font-smoothing: antialiased;
        }

        body.pp-body.sidebar-open {
            overflow: hidden;
        }

        .pp-body a {
            color: inherit;
            text-decoration: none;
        }

        .pp-body button {
            font: inherit;
        }

        .pp-sr-only {
            position: absolute;
            width: 1px;
            height: 1px;
            padding: 0;
            margin: -1px;
            overflow: hidden;
            clip: rect(0,0,0,0);
            white-space: nowrap;
            border: 0;
        }

        /* Top bar */

        .pp-topbar {
            position: sticky;
            top: 0;
            z-index: 60;
            min-height: 62px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 24px;
            padding: 0 24px;
            border-bottom: 1px solid var(--pp-line);
            background: rgba(255,255,255,.97);
            backdrop-filter: blur(16px);
        }

        .pp-topbar-left,
        .pp-brand,
        .pp-account {
            display: flex;
            align-items: center;
        }

        .pp-topbar-left {
            gap: 12px;
        }

        .pp-brand {
            gap: 9px;
            letter-spacing: -.03em;
        }

        .pp-brand img {
            width: 25px;
            height: 25px;
        }

        .pp-brand strong {
            color: var(--pp-blue);
            font-size: 14px;
            font-weight: 850;
        }

        .pp-brand em {
            margin-left: 1px;
            color: var(--pp-muted);
            font-family: var(--pp-serif);
            font-size: 12px;
            font-style: italic;
            font-weight: 400;
        }

        .pp-account {
            gap: 14px;
        }

        .pp-account-copy {
            display: grid;
            justify-items: end;
            gap: 1px;
        }

        .pp-account-copy strong {
            font-size: 11px;
        }

        .pp-account-copy span {
            color: var(--pp-muted);
            font-size: 9px;
        }

        .pp-signout {
            min-height: 34px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 13px;
            border: 1px solid var(--pp-line);
            border-radius: 9px;
            background: #fff;
            color: var(--pp-blue);
            font-size: 10px;
            font-weight: 850;
        }

        .pp-signout:hover {
            border-color: #c7d5e5;
            background: var(--pp-blue-pale);
        }

        /* Shell */

        .pp-shell {
            width: 100%;
            display: grid;
            grid-template-columns: var(--pp-sidebar) minmax(0,1fr);
        }

        .pp-sidebar {
            position: sticky;
            top: 62px;
            height: calc(100vh - 62px);
            overflow-y: auto;
            padding: 20px;
            border-right: 1px solid var(--pp-line);
            background: #fbfdff;
        }

        .pp-sidebar nav {
            display: grid;
            gap: 2px;
        }

        .pp-side-heading {
            margin: 22px 10px 8px;
            color: #949ca5;
            font-size: 8px;
            font-weight: 900;
            letter-spacing: .11em;
            text-transform: uppercase;
        }

        .pp-side-link {
            min-height: 43px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            padding: 0 13px;
            border-radius: 10px;
            color: #25282c;
            font-size: 10px;
            font-weight: 650;
            transition:
                color .14s ease,
                background .14s ease;
        }

        .pp-side-link:hover {
            background: var(--pp-blue-soft);
            color: var(--pp-blue);
        }

        .pp-side-link.is-active {
            background: var(--pp-blue);
            color: #fff;
            font-weight: 850;
        }

        .pp-side-count {
            min-width: 24px;
            padding: 3px 7px;
            border-radius: 999px;
            background: #edf0f3;
            color: #6d747c;
            text-align: center;
            font-size: 8px;
            font-weight: 850;
        }

        .pp-side-link.is-active .pp-side-count {
            background: rgba(255,255,255,.16);
            color: #fff;
        }

        .pp-side-divider {
            height: 1px;
            margin: 21px 0 8px;
            background: var(--pp-line);
        }

        .pp-sidebar-toggle {
            display: none;
            width: 36px;
            height: 36px;
            padding: 8px;
            border: 1px solid var(--pp-line);
            border-radius: 9px;
            background: #fff;
        }

        .pp-sidebar-toggle > span:not(.pp-sr-only) {
            display: block;
            width: 17px;
            height: 1px;
            margin: 4px auto;
            background: var(--pp-blue);
        }

        .pp-sidebar-scrim {
            display: none;
        }

        /* Main */

        .pp-main {
            min-width: 0;
            padding: 38px clamp(26px,4vw,64px) 72px;
        }

        .pp-breadcrumb {
            display: flex;
            align-items: center;
            gap: 7px;
            margin-bottom: 27px;
            color: var(--pp-muted-2);
            font-size: 9px;
        }

        .pp-breadcrumb a {
            color: var(--pp-blue);
        }

        .pp-breadcrumb strong {
            color: #5b6168;
            font-weight: 700;
        }

        .pp-page-heading {
            display: flex;
            align-items: flex-end;
            justify-content: space-between;
            gap: 28px;
            padding-bottom: 24px;
            border-bottom: 1px solid var(--pp-line);
        }

        .pp-kicker {
            margin: 0 0 8px;
            color: var(--pp-blue);
            font-size: 8px;
            font-weight: 900;
            letter-spacing: .11em;
            text-transform: uppercase;
        }

        .pp-page-heading h1 {
            margin: 0;
            font-family: var(--pp-serif);
            font-size: clamp(38px,4vw,56px);
            line-height: .98;
            font-weight: 500;
            letter-spacing: -.05em;
        }

        .pp-description {
            max-width: 700px;
            margin: 13px 0 0;
            color: var(--pp-muted);
            font-size: 10px;
            line-height: 1.7;
        }

        .pp-back-link {
            flex: 0 0 auto;
            min-height: 36px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 13px;
            border: 1px solid var(--pp-line-blue);
            border-radius: 9px;
            background: #fff;
            color: var(--pp-blue);
            font-size: 9px;
            font-weight: 850;
        }

        .pp-back-link:hover {
            background: var(--pp-blue-pale);
        }

        /* Phase card */

        .pp-content-card {
            position: relative;
            min-height: 360px;
            margin-top: 28px;
            display: grid;
            grid-template-columns: 68px minmax(0,1fr);
            align-content: start;
            gap: 24px;
            padding: 28px;
            overflow: hidden;
            border: 1px solid var(--pp-line-blue);
            border-radius: 15px;
            background:
                linear-gradient(135deg,#f7faff 0%,#fff 56%,#fff 100%);
        }

        .pp-content-card::after {
            content: "";
            position: absolute;
            top: -120px;
            right: -90px;
            width: 280px;
            height: 280px;
            border: 1px solid rgba(24,73,135,.07);
            border-radius: 50%;
            pointer-events: none;
        }

        .pp-phase-badge {
            position: absolute;
            top: 22px;
            right: 22px;
            min-height: 27px;
            display: inline-flex;
            align-items: center;
            padding: 0 9px;
            border: 1px solid #d4e0ed;
            border-radius: 999px;
            background: #fff;
            color: var(--pp-blue);
            font-size: 8px;
            font-weight: 900;
            letter-spacing: .04em;
            text-transform: uppercase;
        }

        .pp-placeholder-icon {
            width: 64px;
            height: 64px;
            display: grid;
            place-items: center;
            margin-top: 2px;
            border: 1px solid #cfdae7;
            border-radius: 16px;
            background: #fff;
        }

        .pp-placeholder-icon span {
            position: relative;
            width: 25px;
            height: 18px;
            border: 2px solid var(--pp-blue);
            border-radius: 5px;
        }

        .pp-placeholder-icon span::before,
        .pp-placeholder-icon span::after {
            content: "";
            position: absolute;
            bottom: -7px;
            width: 4px;
            height: 4px;
            border-radius: 50%;
            background: var(--pp-blue);
        }

        .pp-placeholder-icon span::before {
            left: 3px;
        }

        .pp-placeholder-icon span::after {
            right: 3px;
        }

        .pp-content-copy {
            max-width: 720px;
            padding-top: 3px;
        }

        .pp-content-copy h2 {
            margin: 0;
            font-family: var(--pp-serif);
            font-size: 25px;
            font-weight: 500;
            letter-spacing: -.035em;
        }

        .pp-content-copy p {
            margin: 10px 0 0;
            color: var(--pp-muted);
            font-size: 10px;
            line-height: 1.75;
        }

        .pp-content-footer {
            grid-column: 1 / -1;
            align-self: end;
            min-height: 90px;
            margin-top: 86px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 24px;
            padding: 18px;
            border: 1px solid var(--pp-line);
            border-radius: 12px;
            background: rgba(255,255,255,.9);
        }

        .pp-content-footer > div {
            max-width: 710px;
            display: grid;
            gap: 4px;
        }

        .pp-content-footer strong {
            font-size: 9px;
        }

        .pp-content-footer span {
            color: var(--pp-muted);
            font-size: 9px;
            line-height: 1.55;
        }

        .pp-primary-button {
            flex: 0 0 auto;
            min-height: 37px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0 14px;
            border: 1px solid var(--pp-blue);
            border-radius: 9px;
            background: var(--pp-blue);
            color: #fff;
            font-size: 9px;
            font-weight: 850;
        }

        .pp-primary-button:hover {
            background: var(--pp-blue-dark);
        }

        .pp-footer {
            margin-top: 34px;
            padding-top: 18px;
            display: flex;
            justify-content: space-between;
            gap: 18px;
            border-top: 1px solid var(--pp-line);
            color: var(--pp-muted-2);
            font-size: 8px;
        }

        .pp-body :focus-visible {
            outline: 2px solid var(--pp-blue);
            outline-offset: 2px;
        }

        @media (max-width: 920px) {
            .pp-topbar {
                padding-inline: 14px;
            }

            .pp-sidebar-toggle {
                display: inline-block;
            }

            .pp-shell {
                display: block;
            }

            .pp-sidebar {
                position: fixed;
                top: 62px;
                left: 0;
                z-index: 55;
                width: min(290px,84vw);
                height: calc(100vh - 62px);
                transform: translateX(-102%);
                transition: transform .18s ease;
                box-shadow: 20px 0 45px rgba(23,72,135,.10);
            }

            .pp-sidebar.is-open {
                transform: translateX(0);
            }

            .pp-sidebar-scrim {
                position: fixed;
                inset: 62px 0 0;
                z-index: 50;
                border: 0;
                background: rgba(20,30,44,.18);
            }

            .pp-sidebar-scrim.is-visible {
                display: block;
            }

            .pp-main {
                padding: 30px 18px 60px;
            }

            .pp-page-heading {
                align-items: flex-start;
                flex-direction: column;
            }
        }

        @media (max-width: 640px) {
            .pp-brand em,
            .pp-account-copy {
                display: none;
            }

            .pp-main {
                padding-inline: 14px;
            }

            .pp-page-heading h1 {
                font-size: 39px;
            }

            .pp-content-card {
                min-height: auto;
                grid-template-columns: 1fr;
                padding: 20px;
            }

            .pp-phase-badge {
                position: static;
                width: fit-content;
                grid-row: 1;
            }

            .pp-placeholder-icon {
                grid-row: 2;
            }

            .pp-content-copy {
                grid-row: 3;
            }

            .pp-content-footer {
                grid-column: auto;
                grid-row: 4;
                margin-top: 30px;
                align-items: flex-start;
                flex-direction: column;
            }

            .pp-footer {
                align-items: flex-start;
                flex-direction: column;
            }
        }
    </style>
    <link rel="stylesheet" href="../css/uniride-ui.css">
    <?php if (!empty($PROFILE_PAGE_ASSETS)): ?>
        <link rel="stylesheet" href="../css/profile.css">
        <script src="../js/profile.js" defer></script>
    <?php endif; ?>
    <script src="../js/dashboard.js" defer></script>
</head>
<body class="pp-body">

<header class="pp-topbar">
    <div class="pp-topbar-left">
        <button
            class="pp-sidebar-toggle"
            type="button"
            data-sidebar-toggle
            aria-controls="ppSidebar"
            aria-expanded="false"
        >
            <span class="pp-sr-only">Toggle navigation</span>
            <span></span>
            <span></span>
        </button>

        <a class="pp-brand" href="../index.php">
            <img src="../img/logo.svg" alt="">
            <strong>UniRide</strong>
            <em>Passenger</em>
        </a>
    </div>

    <div class="pp-account">
        <?= profile_avatar_html('..', (string)$ppProfile['name'], $_SESSION['profile_picture_path'] ?? null) ?>
        <div class="pp-account-copy">
            <strong><?= pp_h($ppProfile['name']) ?></strong>
            <span>
                <?= pp_h($ppProfile['university_code']) ?>
                ·
                <?= pp_h($passengerType) ?>
            </span>
        </div>

        <a class="pp-signout" href="../logout.php">Sign out</a>
    </div>
</header>

<div class="pp-shell">
    <aside class="pp-sidebar" id="ppSidebar" data-dashboard-sidebar>
        <nav aria-label="Passenger navigation">
            <?= dashboard_render_navigation(
                'PASSENGER',
                $activeNav,
                [
                    'my-bookings' => $ppCounts['bookings'],
                    'favorite-routes' => $ppCounts['favorites'],
                    'complaints' => ['value' => $ppCounts['complaints'], 'alert' => true],
                    'notifications' => ['value' => $ppCounts['notifications'], 'alert' => true],
                ],
                strtoupper((string)($ppProfile['passenger_type'] ?? '')) === 'STUDENT'
                    ? []
                    : ['ticket-transfers'],
                '..',
                [
                    'heading' => 'pp-side-heading',
                    'link' => 'pp-side-link',
                    'active' => 'is-active',
                    'count' => 'pp-side-count',
                    'child' => '',
                ]
            ) ?>

            <div class="pp-side-divider"></div>

            <a class="pp-side-link" href="../logout.php">
                <span>Logout</span>
            </a>
        </nav>
    </aside>

    <button
        class="pp-sidebar-scrim"
        type="button"
        data-sidebar-scrim
        aria-label="Close navigation"
    ></button>

    <main class="pp-main">
        <div class="pp-breadcrumb">
            <a href="dashboard.php">Passenger</a>
            <span>/</span>
            <strong><?= pp_h($pageTitle) ?></strong>
        </div>

        <section class="pp-page-heading">
            <div>
                <p class="pp-kicker"><?= pp_h($eyebrow) ?></p>
                <h1><?= pp_h($pageTitle) ?></h1>
                <p class="pp-description"><?= pp_h($description) ?></p>
            </div>

            <a class="pp-back-link" href="dashboard.php">
                Back to dashboard
            </a>
        </section>
<?php
}

function pp_render_placeholder(
    string $phase,
    string $title,
    string $body
): void {
?>
        <section class="pp-content-card">
            <div class="pp-phase-badge"><?= pp_h($phase) ?></div>

            <div class="pp-placeholder-icon" aria-hidden="true">
                <span></span>
            </div>

            <div class="pp-content-copy">
                <h2><?= pp_h($title) ?></h2>
                <p><?= pp_h($body) ?></p>
            </div>

            <div class="pp-content-footer">
                <div>
                    <strong>Dashboard integration is already active.</strong>
                    <span>
                        This screen remains reserved for its full workflow
                        implementation in the next development phase.
                    </span>
                </div>

                <a class="pp-primary-button" href="dashboard.php">
                    Back to dashboard
                </a>
            </div>
        </section>
<?php
}

function pp_render_end(): void {
    global $ppProfile;
?>
        <footer class="pp-footer">
            <span>
                UniRide · <?= pp_h($ppProfile['university_name']) ?>
            </span>
            <span>Passenger portal</span>
        </footer>
    </main>
</div>

</body>
</html>
<?php
}
