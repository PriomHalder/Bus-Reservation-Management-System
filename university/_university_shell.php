<?php
declare(strict_types=1);
require_once __DIR__ . '/_university_context.php';
require_once __DIR__ . '/../includes/dashboard/nav.php';
require_once __DIR__ . '/../includes/theme.php';

function u_render_start(string $title,string $active,string $kicker='Transport administration',string $description=''): void
{
    global $uUniversity,$uAdminName,$uSemester,$uNavCounts,$PROFILE_PAGE_ASSETS;
    $flash=u_take_flash();
    $semesterName=$uSemester['semester_name']??'No active semester';
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= u_h($title) ?> — <?= u_h($uUniversity['code']) ?> UniRide</title>
<?= uniride_theme_head_html('..') ?>
<link rel="icon" type="image/svg+xml" href="../img/logo.svg">
<link rel="stylesheet" href="../css/style.css">
<link rel="stylesheet" href="../css/dashboard.css">
<link rel="stylesheet" href="../css/university-pages.css">
<link rel="stylesheet" href="../css/university-theme.css">
<link rel="stylesheet" href="../css/uniride-ui.css">
<?php if (!empty($PROFILE_PAGE_ASSETS)): ?><link rel="stylesheet" href="../css/profile.css"><script src="../js/profile.js" defer></script><?php endif; ?>
<script src="../js/dashboard.js" defer></script>
</head>
<body class="uni-admin-body university-page-body">
<header class="uni-topbar">
<div class="uni-topbar-left">
<button class="sidebar-toggle" type="button" data-sidebar-toggle aria-controls="uniSidebar" aria-expanded="false"><span class="sr-only">Toggle navigation</span><span></span><span></span></button>
<a class="uni-brand" href="../index.php"><img src="../img/logo.svg" alt=""><strong>UniRide</strong><em>University</em></a>
</div>
<div class="uni-account"><?= profile_avatar_html('..', $uAdminName, $_SESSION['profile_picture_path'] ?? null) ?><div class="uni-account-copy"><strong><?= u_h($uAdminName) ?></strong><span><?= u_h($uUniversity['code']) ?> · Uni Admin</span></div><a class="signout-button" href="../logout.php">Sign out</a></div>
</header>
<div class="dashboard-shell">
<aside class="uni-sidebar" id="uniSidebar" data-dashboard-sidebar><nav aria-label="University administration">
<?= dashboard_render_navigation(
    'UNIVERSITY_ADMIN',
    $active,
    $uNavCounts,
    [],
    '..',
    [
        'heading' => 'side-heading',
        'link' => 'side-link',
        'active' => 'is-active',
        'count' => 'side-count',
        'child' => 'side-link-child',
    ]
) ?>
<div class="side-divider"></div><a class="side-link" href="../logout.php"><span>Logout</span></a>
</nav></aside>
<button class="sidebar-scrim" type="button" data-sidebar-scrim aria-label="Close navigation"></button>
<main class="uni-main">
<?php if($flash): ?><div class="dashboard-alert <?= ($flash['type']??'')==='success'?'is-success':'is-error' ?>" role="status"><?= u_h($flash['message']??'') ?></div><?php endif; ?>
<section class="university-page-heading"><div><p class="dashboard-kicker"><?= u_h($uUniversity['code']) ?> · <?= u_h($kicker) ?></p><h1><?= u_h($title) ?></h1><?php if($description!==''): ?><p><?= u_h($description) ?></p><?php endif; ?><div class="university-page-meta"><span><?= u_h($uUniversity['name']) ?></span><span>·</span><span>Admin: <?= u_h($uAdminName) ?></span><span>·</span><span><?= u_h($semesterName) ?></span><span>·</span><span><?= u_h(date('d M Y')) ?></span></div></div>
<?php
}

function u_render_actions(string $html): void { echo '<div class="university-page-actions">'.$html.'</div>'; }
function u_render_heading_end(): void { echo '</section>'; }
function u_render_end(): void
{
    global $uUniversity;
?>
<footer class="university-page-footer"><span>UniRide · <?= u_h($uUniversity['name']) ?> transport administration</span><span>Tenant <?= (int)$uUniversity['university_id'] ?> · session isolated</span></footer>
</main></div></body></html>
<?php }
