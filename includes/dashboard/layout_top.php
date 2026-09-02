<?php
declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| UniRide — Dashboard shell (top half)
|--------------------------------------------------------------------------
| Shared furniture for all three roles: document head, top bar, sidebar,
| and the opening of the main column. Close it with layout_bottom.php.
|
| The including page is expected to have set:
|   $BASE         path back to the app root ('..' from a role directory)
|   $ROLE         PASSENGER | UNIVERSITY_ADMIN | SYSTEM_ADMIN
|   $PAGE_TITLE   browser title
|   $ACTIVE_NAV   nav key to highlight
|
| Optional:
|   $ROLE_WORD       italic qualifier beside the wordmark
|   $NAV_COUNTS      badge counts keyed by nav key
|   $NAV_HIDE        nav keys to omit for this account
|   $EXTRA_STYLESHEETS app-root-relative stylesheets for this page family
|   $SHELL_USER_NAME / $SHELL_USER_SUB   top-right identity
*/

$BASE       = $BASE       ?? '.';
$ROLE       = $ROLE       ?? '';
$PAGE_TITLE = $PAGE_TITLE ?? 'Dashboard';
$ACTIVE_NAV = $ACTIVE_NAV ?? '';
$ROLE_WORD  = $ROLE_WORD  ?? '';
$NAV_COUNTS = $NAV_COUNTS ?? [];
$NAV_HIDE   = $NAV_HIDE   ?? [];
$EXTRA_STYLESHEETS = $EXTRA_STYLESHEETS ?? [];
$EXTRA_SCRIPTS = $EXTRA_SCRIPTS ?? [];

$SHELL_USER_NAME = $SHELL_USER_NAME ?? (string)($_SESSION['name'] ?? 'User');
$SHELL_USER_SUB  = $SHELL_USER_SUB  ?? (string)($_SESSION['email'] ?? '');
$SHELL_ROLE_CLASS = strtolower(str_replace('_', '-', $ROLE));

require_once __DIR__ . '/nav.php';
require_once dirname(__DIR__) . '/profile/profile-service.php';
require_once dirname(__DIR__) . '/theme.php';
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= h($PAGE_TITLE) ?> — UniRide</title>
    <?= uniride_theme_head_html($BASE) ?>

    <link rel="icon" href="<?= h($BASE) ?>/img/logo.svg" type="image/svg+xml">
    <link rel="stylesheet" href="<?= h($BASE) ?>/css/style.css">
    <link rel="stylesheet" href="<?= h($BASE) ?>/css/dashboard.css">
    <link rel="stylesheet" href="<?= h($BASE) ?>/css/dashboard-shell.css">
    <?php foreach ($EXTRA_STYLESHEETS as $stylesheet): ?>
        <link rel="stylesheet" href="<?= h(rtrim($BASE, '/') . '/' . ltrim((string)$stylesheet, '/')) ?>">
    <?php endforeach; ?>
    <link rel="stylesheet" href="<?= h($BASE) ?>/css/uniride-ui.css">
    <?php foreach ($EXTRA_SCRIPTS as $script): ?>
        <script src="<?= h(rtrim($BASE, '/') . '/' . ltrim((string)$script, '/')) ?>" defer></script>
    <?php endforeach; ?>
    <script src="<?= h($BASE) ?>/js/dashboard.js" defer></script>
</head>
<body class="dashboard-generic-body role-<?= h($SHELL_ROLE_CLASS) ?>">

<div class="shell">

    <header class="shell-top">
        <div class="shell-top-row">
            <button
                class="shell-burger"
                type="button"
                data-sidebar-toggle
                aria-controls="dashboardSidebar"
                aria-expanded="false"
                aria-label="Toggle navigation"
            >
                <span></span><span></span><span></span>
            </button>

            <a class="shell-brand" href="<?= h($BASE) ?>/index.php">
                <img src="<?= h($BASE) ?>/img/logo.svg" alt="">
                <span>UniRide</span>
                <?php if ($ROLE_WORD !== ''): ?>
                    <em><?= h($ROLE_WORD) ?></em>
                <?php endif; ?>
            </a>

            <div class="shell-top-spacer"></div>

            <div class="shell-user">
                <?= profile_avatar_html($BASE, $SHELL_USER_NAME, $_SESSION['profile_picture_path'] ?? null) ?>
                <span class="shell-user-name"><?= h($SHELL_USER_NAME) ?></span>

                <?php if ($SHELL_USER_SUB !== ''): ?>
                    <span class="shell-user-sub">·</span>
                    <span class="shell-user-sub"><?= h($SHELL_USER_SUB) ?></span>
                <?php endif; ?>

                <a class="button button-light button-small"
                   href="<?= h($BASE) ?>/logout.php">Sign out</a>
            </div>
        </div>
    </header>

    <div class="shell-body">

        <aside class="shell-side" id="dashboardSidebar" data-dashboard-sidebar>
            <?= dashboard_render_navigation(
                $ROLE,
                $ACTIVE_NAV,
                $NAV_COUNTS,
                $NAV_HIDE,
                $BASE,
                [
                    'group' => 'side-group',
                    'group_nav' => 'side-nav',
                    'heading' => 'side-group-label',
                    'link' => '',
                    'active' => 'active',
                    'count' => 'side-count',
                    'child' => '',
                    'children' => 'side-sub side-nav',
                ]
            ) ?>

            <div class="side-foot">
                <nav class="side-nav">
                    <a href="<?= h($BASE) ?>/logout.php"><span>Logout</span></a>
                </nav>
            </div>
        </aside>

        <button
            class="shell-sidebar-scrim"
            type="button"
            data-sidebar-scrim
            aria-label="Close navigation"
        ></button>

        <main class="shell-main">
