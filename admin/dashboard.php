<?php
declare(strict_types=1);

session_start();

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/dashboard/nav.php';
require_once __DIR__ . '/../includes/profile/session-management.php';
require_once __DIR__ . '/../includes/theme.php';

if (empty($_SESSION['authenticated'])) {
    header('Location: ../signin.php');
    exit;
}

if (($_SESSION['user_type'] ?? '') !== 'SYSTEM_ADMIN') {
    header('Location: ../dashboard.php');
    exit;
}

date_default_timezone_set('Asia/Dhaka');

function sa_h(mixed $value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

function sa_one(PDO $pdo, string $sql, array $params = []): array
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetch() ?: [];
}

function sa_all(PDO $pdo, string $sql, array $params = []): array
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll();
}

function sa_scalar(PDO $pdo, string $sql, array $params = []): mixed
{
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchColumn();
}

function sa_file_link(string $path, string $label, string $class = 'system-action'): string
{
    $filePath = (string)(parse_url($path, PHP_URL_PATH) ?: $path);
    $fullPath = __DIR__ . '/' . $filePath;

    if (!is_file($fullPath)) {
        return '<span class="' . sa_h($class) . ' is-disabled" aria-disabled="true">'
            . sa_h($label)
            . '</span>';
    }

    return '<a class="' . sa_h($class) . '" href="' . sa_h($path) . '">'
        . sa_h($label)
        . '</a>';
}

function sa_status_class(string $status): string
{
    return strtoupper($status) === 'ACTIVE'
        ? 'is-good'
        : 'is-muted';
}

$adminId = (int)($_SESSION['admin_id'] ?? $_SESSION['user_id'] ?? 0);
try {
    $adminIdentity = $adminId > 0
        ? sa_one($pdo, 'SELECT admin_id,name,email,status FROM admins WHERE admin_id=? LIMIT 1', [$adminId])
        : [];
} catch (Throwable $e) {
    error_log('[UniRide system identity] ' . $e->getMessage());
    http_response_code(503);
    uniride_render_error_page('System administration is temporarily unavailable.', '..');
}

if (!$adminIdentity || strtoupper((string)$adminIdentity['status']) !== 'ACTIVE') {
    http_response_code(403);
    uniride_render_error_page('This System Admin account is currently unavailable.', '..');
}
profile_enforce_session($pdo, '..');

$adminName = (string)$adminIdentity['name'];

$stats = [
    'universities' => 0,
    'active_universities' => 0,
    'passengers' => 0,
    'students' => 0,
    'faculty' => 0,
    'university_admins' => 0,
    'buses' => 0,
    'routes' => 0,
    'bookings' => 0,
];

$activeSemester = [];
$universities = [];
$universityAdmins = [];
$recentUniversities = [];
$dashboardError = '';

try {
    $stats['universities'] = (int)sa_scalar(
        $pdo,
        "SELECT COUNT(DISTINCT university_id)
         FROM universities"
    );

    $stats['active_universities'] = (int)sa_scalar(
        $pdo,
        "SELECT COUNT(DISTINCT university_id)
         FROM universities
         WHERE status = 'ACTIVE'"
    );

    $passengerStats = sa_one(
        $pdo,
        "SELECT
            COUNT(DISTINCT passenger_id) AS passengers,
            COUNT(DISTINCT CASE
                WHEN passenger_type = 'STUDENT' THEN passenger_id
            END) AS students,
            COUNT(DISTINCT CASE
                WHEN passenger_type = 'FACULTY' THEN passenger_id
            END) AS faculty
         FROM passengers"
    );

    $stats['passengers'] = (int)($passengerStats['passengers'] ?? 0);
    $stats['students'] = (int)($passengerStats['students'] ?? 0);
    $stats['faculty'] = (int)($passengerStats['faculty'] ?? 0);

    $stats['university_admins'] = (int)sa_scalar(
        $pdo,
        "SELECT COUNT(DISTINCT university_user_id)
         FROM university_users
         WHERE status = 'ACTIVE'"
    );

    $stats['buses'] = (int)sa_scalar(
        $pdo,
        "SELECT COUNT(DISTINCT bus_id)
         FROM buses"
    );

    $stats['routes'] = (int)sa_scalar(
        $pdo,
        "SELECT COUNT(DISTINCT route_id)
         FROM routes
         WHERE status = 'ACTIVE'"
    );

    $stats['bookings'] = (int)sa_scalar(
        $pdo,
        "SELECT COUNT(DISTINCT booking_id)
         FROM bookings"
    );

    $activeSemester = sa_one(
        $pdo,
        "SELECT
            semester_id,
            semester_name,
            start_date,
            end_date,
            is_active
         FROM semesters
         WHERE is_active = 1
         ORDER BY start_date DESC
         LIMIT 1"
    );

    $universities = sa_all(
        $pdo,
        "SELECT
            u.university_id,
            u.code,
            u.name,
            u.contact_email,
            u.status,
            u.created_at,
            COALESCE(p.passenger_count, 0) AS passenger_count,
            COALESCE(b.bus_count, 0) AS bus_count,
            COALESCE(r.route_count, 0) AS route_count,
            COALESCE(bk.booking_count, 0) AS booking_count,
            COALESCE(ua.admin_count, 0) AS admin_count
         FROM universities u
         LEFT JOIN (
             SELECT
                university_id,
                COUNT(DISTINCT passenger_id) AS passenger_count
             FROM passengers
             GROUP BY university_id
         ) p
             ON p.university_id = u.university_id
         LEFT JOIN (
             SELECT
                university_id,
                COUNT(DISTINCT bus_id) AS bus_count
             FROM buses
             GROUP BY university_id
         ) b
             ON b.university_id = u.university_id
         LEFT JOIN (
             SELECT
                university_id,
                COUNT(DISTINCT route_id) AS route_count
             FROM routes
             WHERE status = 'ACTIVE'
             GROUP BY university_id
         ) r
             ON r.university_id = u.university_id
         LEFT JOIN (
             SELECT
                r2.university_id,
                COUNT(DISTINCT bk2.booking_id) AS booking_count
             FROM routes r2
             INNER JOIN schedules s2
                 ON s2.route_id = r2.route_id
             LEFT JOIN bookings bk2
                 ON bk2.schedule_id = s2.schedule_id
             GROUP BY r2.university_id
         ) bk
             ON bk.university_id = u.university_id
         LEFT JOIN (
             SELECT
                university_id,
                COUNT(DISTINCT university_user_id) AS admin_count
             FROM university_users
             WHERE status = 'ACTIVE'
             GROUP BY university_id
         ) ua
             ON ua.university_id = u.university_id
         ORDER BY
            CASE u.status
                WHEN 'ACTIVE' THEN 0
                ELSE 1
            END,
            u.name"
    );

    $universityAdmins = sa_all(
        $pdo,
        "SELECT
            uu.university_user_id,
            uu.name,
            uu.email,
            uu.role,
            uu.status,
            uu.created_at,
            u.code AS university_code,
            u.name AS university_name
         FROM university_users uu
         INNER JOIN universities u
             ON u.university_id = uu.university_id
         ORDER BY
            CASE uu.status
                WHEN 'ACTIVE' THEN 0
                ELSE 1
            END,
            uu.created_at DESC
         LIMIT 8"
    );

    $recentUniversities = sa_all(
        $pdo,
        "SELECT
            university_id,
            code,
            name,
            contact_email,
            status,
            created_at
         FROM universities
         ORDER BY created_at DESC, university_id DESC
         LIMIT 5"
    );
} catch (Throwable $e) {
    error_log('[UniRide System Admin dashboard] ' . $e->getMessage());
    $dashboardError = 'Some platform information is temporarily unavailable.';
}

$semesterName = $activeSemester['semester_name'] ?? 'No active semester';
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta
        name="description"
        content="UniRide system administration platform overview."
    >
    <title>System Administration — UniRide</title>
    <?= uniride_theme_head_html('..') ?>

    <link rel="icon" type="image/svg+xml" href="../img/logo.svg">
    <link rel="stylesheet" href="../css/style.css">
    <link rel="stylesheet" href="../css/dashboard.css">
    <link rel="stylesheet" href="../css/uniride-ui.css">
    <script src="../js/dashboard.js" defer></script>
</head>
<body class="system-admin-body">

<header class="system-topbar">
    <div class="system-topbar-left">
        <button
            class="sidebar-toggle system-sidebar-toggle"
            type="button"
            data-sidebar-toggle
            aria-controls="systemSidebar"
            aria-expanded="false"
        >
            <span class="sr-only">Toggle navigation</span>
            <span></span>
            <span></span>
        </button>

        <a class="system-brand" href="../index.php">
            <img src="../img/logo.svg" alt="">
            <strong>UniRide</strong>
            <em>Platform</em>
        </a>
    </div>

    <div class="system-account">
        <?= profile_avatar_html('..', $adminName, $_SESSION['profile_picture_path'] ?? null) ?>
        <div class="system-account-copy">
            <strong><?= sa_h($adminName) ?></strong>
            <span>System administrator</span>
        </div>

        <a class="system-signout" href="../logout.php">Sign out</a>
    </div>
</header>

<div class="system-shell">
    <aside class="system-sidebar" id="systemSidebar" data-dashboard-sidebar>
        <nav aria-label="System administration">
            <?= dashboard_render_navigation(
                'SYSTEM_ADMIN',
                'overview',
                [
                    'universities' => $stats['universities'],
                    'administrators' => $stats['university_admins'],
                ],
                [],
                '..',
                [
                    'heading' => 'system-side-heading',
                    'link' => 'system-side-link',
                    'active' => 'is-active',
                    'count' => 'system-side-count',
                    'child' => '',
                ]
            ) ?>

            <div class="system-side-divider"></div>

            <a class="system-side-link" href="../logout.php">
                <span>Logout</span>
            </a>
        </nav>
    </aside>

    <button
        class="system-sidebar-scrim"
        type="button"
        data-sidebar-scrim
        aria-label="Close navigation"
    ></button>

    <main class="system-main">
        <?php if ($dashboardError): ?>
            <div class="system-alert is-error" role="alert">
                <?= sa_h($dashboardError) ?>
            </div>
        <?php endif; ?>

        <section class="system-title-row">
            <div>
                <p class="system-kicker">System administration</p>

                <h1>
                    UniRide
                    <span>platform</span>
                </h1>

                <p class="system-meta">
                    <?= sa_h($adminName) ?>
                    <span>·</span>
                    <?= sa_h($semesterName) ?>
                    <span>·</span>
                    <?= number_format($stats['active_universities']) ?> active universities
                    <span>·</span>
                    <?= sa_h(date('d M Y')) ?>
                </p>
            </div>

            <div class="system-quick-actions">
                <?= sa_file_link(
                    'universities.php?new=1',
                    '+ Add University',
                    'system-action system-action-dark'
                ) ?>

                <?= sa_file_link(
                    'universities.php',
                    'Manage Universities'
                ) ?>

                <?= sa_file_link(
                    'administrators.php?new=1',
                    'Create Uni Admin'
                ) ?>

                <?= sa_file_link(
                    'statistics.php',
                    'Platform Statistics'
                ) ?>
            </div>
        </section>

        <section class="system-metric-grid" aria-label="Platform statistics">
            <article class="system-metric-card system-metric-featured">
                <p>Universities</p>
                <strong><?= number_format($stats['universities']) ?></strong>
                <span>
                    <?= number_format($stats['active_universities']) ?> active
                </span>
            </article>

            <article class="system-metric-card">
                <p>Registered passengers</p>
                <strong><?= number_format($stats['passengers']) ?></strong>
                <span>
                    <?= number_format($stats['students']) ?> students
                    ·
                    <?= number_format($stats['faculty']) ?> faculty
                </span>
            </article>

            <article class="system-metric-card">
                <p>University admins</p>
                <strong><?= number_format($stats['university_admins']) ?></strong>
                <span>Active transport administrators</span>
            </article>

            <article class="system-metric-card">
                <p>Fleet</p>
                <strong><?= number_format($stats['buses']) ?></strong>
                <span>Buses registered platform-wide</span>
            </article>

            <article class="system-metric-card">
                <p>Active routes</p>
                <strong><?= number_format($stats['routes']) ?></strong>
                <span>Across all participating universities</span>
            </article>

            <article class="system-metric-card">
                <p>Total bookings</p>
                <strong><?= number_format($stats['bookings']) ?></strong>
                <span>Recorded across the UniRide platform</span>
            </article>

            <article class="system-metric-card">
                <p>Students</p>
                <strong><?= number_format($stats['students']) ?></strong>
                <span>Passenger subtype</span>
            </article>

            <article class="system-metric-card">
                <p>Faculty</p>
                <strong><?= number_format($stats['faculty']) ?></strong>
                <span>Passenger subtype</span>
            </article>
        </section>

        <section class="system-section">
            <div class="system-section-heading">
                <div>
                    <p class="system-kicker">Network overview</p>
                    <h2>Participating universities</h2>
                    <p>
                        Platform-level totals only. Daily transport operations remain
                        the responsibility of each University Admin.
                    </p>
                </div>

                <?= sa_file_link(
                    'universities.php',
                    'Manage universities',
                    'system-text-action'
                ) ?>
            </div>

            <?php if (!$universities): ?>
                <div class="system-empty">
                    <strong>No universities are registered.</strong>
                    <p>Approved universities will appear here.</p>
                </div>
            <?php else: ?>
                <div class="system-table-wrap">
                    <table class="system-table">
                        <thead>
                            <tr>
                                <th>University</th>
                                <th>Passengers</th>
                                <th>Buses</th>
                                <th>Routes</th>
                                <th>Bookings</th>
                                <th>Uni Admins</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($universities as $university): ?>
                            <tr>
                                <td>
                                    <strong><?= sa_h($university['code']) ?></strong>
                                    <span><?= sa_h($university['name']) ?></span>
                                </td>
                                <td><?= number_format((int)$university['passenger_count']) ?></td>
                                <td><?= number_format((int)$university['bus_count']) ?></td>
                                <td><?= number_format((int)$university['route_count']) ?></td>
                                <td><?= number_format((int)$university['booking_count']) ?></td>
                                <td><?= number_format((int)$university['admin_count']) ?></td>
                                <td>
                                    <span class="system-status <?= sa_h(sa_status_class($university['status'])) ?>">
                                        <?= sa_h($university['status']) ?>
                                    </span>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </section>

        <section class="system-split">
            <article class="system-section">
                <div class="system-section-heading">
                    <div>
                        <p class="system-kicker">Administration</p>
                        <h2>University administrators</h2>
                    </div>

                    <?= sa_file_link(
                        'administrators.php',
                        'Manage admins',
                        'system-text-action'
                    ) ?>
                </div>

                <?php if (!$universityAdmins): ?>
                    <div class="system-empty system-empty-small">
                        <strong>No University Admin accounts found.</strong>
                    </div>
                <?php else: ?>
                    <div class="system-list">
                        <?php foreach ($universityAdmins as $user): ?>
                            <div class="system-list-row">
                                <div>
                                    <strong><?= sa_h($user['name']) ?></strong>
                                    <span><?= sa_h($user['email']) ?></span>
                                </div>

                                <div>
                                    <strong><?= sa_h($user['university_code']) ?></strong>
                                    <span><?= sa_h($user['role']) ?></span>
                                </div>

                                <span class="system-status <?= sa_h(sa_status_class($user['status'])) ?>">
                                    <?= sa_h($user['status']) ?>
                                </span>
                            </div>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
            </article>

            <article class="system-section">
                <div class="system-section-heading">
                    <div>
                        <p class="system-kicker">Platform activity</p>
                        <h2>Recently added universities</h2>
                    </div>
                </div>

                <?php if (!$recentUniversities): ?>
                    <div class="system-empty system-empty-small">
                        <strong>No recent university records.</strong>
                    </div>
                <?php else: ?>
                    <div class="system-list">
                        <?php foreach ($recentUniversities as $university): ?>
                            <div class="system-list-row system-list-row-recent">
                                <div>
                                    <strong><?= sa_h($university['code']) ?></strong>
                                    <span><?= sa_h($university['name']) ?></span>
                                </div>

                                <div>
                                    <strong>
                                        <?= sa_h(
                                            date(
                                                'd M Y',
                                                strtotime($university['created_at'])
                                            )
                                        ) ?>
                                    </strong>
                                    <span><?= sa_h($university['contact_email'] ?? '') ?></span>
                                </div>

                                <span class="system-status <?= sa_h(sa_status_class($university['status'])) ?>">
                                    <?= sa_h($university['status']) ?>
                                </span>
                            </div>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
            </article>
        </section>

        <section class="system-boundary-note">
            <div>
                <p class="system-kicker">Role boundary</p>
                <h2>Platform administration, not daily transport operations.</h2>
            </div>

            <p>
                System Admin manages participating universities, University Admin
                accounts, and platform-wide visibility. Bus scheduling, passenger
                complaints, route stops, seat occupancy, and daily booking operations
                stay inside each university's own dashboard.
            </p>
        </section>
    </main>
</div>

</body>
</html>
