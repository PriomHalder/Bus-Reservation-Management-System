<?php
declare(strict_types=1);

session_start();

$routes = [];
$stats = [
    'universities' => 0,
    'routes' => 0,
    'students' => 0,
    'faculty' => 0,
];
$dbError = '';

try {
    require_once __DIR__ . '/config/database.php';

    $routes = $pdo->query(
        "SELECT
            r.route_id,
            r.route_code,
            r.route_name,
            r.start_location,
            r.end_location,
            r.fare,
            u.code AS university_code,
            u.name AS university_name
         FROM routes r
         JOIN universities u
           ON u.university_id = r.university_id
         WHERE r.status = 'ACTIVE'
           AND u.status = 'ACTIVE'
         ORDER BY u.university_id, r.route_id"
    )->fetchAll();

    $stats['universities'] = (int)$pdo->query(
        "SELECT COUNT(*) FROM universities WHERE status='ACTIVE'"
    )->fetchColumn();

    $stats['routes'] = (int)$pdo->query(
        "SELECT COUNT(*) FROM routes WHERE status='ACTIVE'"
    )->fetchColumn();

    $stats['students'] = (int)$pdo->query(
        "SELECT COUNT(*) FROM passengers
         WHERE passenger_type='STUDENT' AND status='ACTIVE'"
    )->fetchColumn();

    $stats['faculty'] = (int)$pdo->query(
        "SELECT COUNT(*) FROM passengers
         WHERE passenger_type='FACULTY' AND status='ACTIVE'"
    )->fetchColumn();
} catch (Throwable $e) {
    error_log('[UniRide index] ' . $e->getMessage());
    $dbError = 'Could not load database content.';
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>UniRide — University Bus Ticketing</title>
    <meta name="description" content="UniRide university bus ticket booking platform.">

    <link rel="icon" href="img/logo.svg" type="image/svg+xml">
    <link rel="stylesheet" href="css/style.css">
    <script src="js/app.js" defer></script>
</head>
<body>

<header class="topbar">
    <div class="container nav">
        <a class="brand" href="index.php">
            <img src="img/logo.svg" alt="">
            <span>UniRide</span>
        </a>

        <nav class="main-nav" id="mainNav">
            <a href="#routes">Routes</a>
            <a href="#features">Features</a>
            <a href="#universities">Universities</a>
        </nav>

        <div class="nav-actions">
            <?php if (!empty($_SESSION['authenticated'])): ?>
                <a href="dashboard.php" class="link-btn">Dashboard</a>
                <a href="logout.php" class="button button-dark button-small">Sign out</a>
            <?php else: ?>
                <a href="signin.php" class="button button-light button-small">Login</a>
            <?php endif; ?>
        </div>

        <button class="menu-btn" type="button" aria-label="Open menu" data-menu-button>
            <span></span><span></span>
        </button>
    </div>
</header>

<main>
    <section class="hero container">
        <p class="kicker">Multi-university bus ticketing</p>

        <h1>
            Find a ride<br>
            <em>that fits your day.</em>
        </h1>

        <p class="hero-text">
            Search university bus routes, check schedules, book seats,
            manage tickets, and keep semester transport charges in one place.
        </p>

        <div class="search-area">
            <label class="search-box">
                <span aria-hidden="true">⌕</span>
                <input
                    type="search"
                    id="routeSearch"
                    placeholder="Search route, area, or university"
                    autocomplete="off"
                >
            </label>

            <div class="filters">
                <button type="button" class="filter active" data-filter="all">All</button>
                <button type="button" class="filter" data-filter="bracu">BRACU</button>
                <button type="button" class="filter" data-filter="nsu">NSU</button>
                <button type="button" class="filter" data-filter="aiub">AIUB</button>
            </div>
        </div>

        <div class="stats">
            <div>
                <strong><?= number_format($stats['universities']) ?></strong>
                <span>Universities</span>
            </div>
            <div>
                <strong><?= number_format($stats['routes']) ?></strong>
                <span>Active routes</span>
            </div>
            <div>
                <strong><?= number_format($stats['students']) ?></strong>
                <span>Students</span>
            </div>
            <div>
                <strong><?= number_format($stats['faculty']) ?></strong>
                <span>Faculty</span>
            </div>
        </div>
    </section>

    <section class="section container" id="routes">
        <div class="section-head">
            <div>
                <div class="title-with-count">
                    <h2>Routes</h2>
                    <span><?= count($routes) ?></span>
                </div>
                <p>Route information is loaded directly from the <strong>uniride2</strong> database.</p>
            </div>
        </div>

        <?php if ($dbError): ?>
            <div class="empty-card">
                <strong>Database unavailable</strong>
                <p><?= htmlspecialchars($dbError, ENT_QUOTES, 'UTF-8') ?></p>
            </div>
        <?php elseif (!$routes): ?>
            <div class="empty-card">
                <strong>No active routes found</strong>
                <p>Add route records through your database or admin panel.</p>
            </div>
        <?php else: ?>
            <div class="route-grid">
                <?php foreach ($routes as $i => $route): ?>
                    <?php
                    $searchText = strtolower(
                        $route['route_code'] . ' ' .
                        $route['route_name'] . ' ' .
                        $route['start_location'] . ' ' .
                        $route['end_location'] . ' ' .
                        $route['university_code'] . ' ' .
                        $route['university_name']
                    );
                    ?>
                    <article
                        class="route-card <?= $i === 1 ? 'dark-card' : '' ?>"
                        data-route-card
                        data-university="<?= htmlspecialchars(strtolower($route['university_code']), ENT_QUOTES, 'UTF-8') ?>"
                        data-search="<?= htmlspecialchars($searchText, ENT_QUOTES, 'UTF-8') ?>"
                    >
                        <div class="card-top">
                            <span class="badge"><?= htmlspecialchars($route['university_code'], ENT_QUOTES, 'UTF-8') ?></span>
                            <span class="fare">৳<?= number_format((float)$route['fare'], 0) ?></span>
                        </div>

                        <div class="route-graphic">
                            <span class="route-point"></span>
                            <span class="route-line"></span>
                            <span class="bus-icon">▣</span>
                            <span class="route-line"></span>
                            <span class="route-point filled"></span>
                        </div>

                        <p class="route-code"><?= htmlspecialchars($route['route_code'], ENT_QUOTES, 'UTF-8') ?></p>
                        <h3><?= htmlspecialchars($route['route_name'], ENT_QUOTES, 'UTF-8') ?></h3>

                        <div class="route-path">
                            <span><?= htmlspecialchars($route['start_location'], ENT_QUOTES, 'UTF-8') ?></span>
                            <b>→</b>
                            <span><?= htmlspecialchars($route['end_location'], ENT_QUOTES, 'UTF-8') ?></span>
                        </div>

                        <div class="card-footer">
                            <span><?= htmlspecialchars($route['university_name'], ENT_QUOTES, 'UTF-8') ?></span>
                            <a href="signin.php">View / Book ↗</a>
                        </div>
                    </article>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </section>

    <section class="section container" id="features">
        <div class="section-head">
            <div>
                <div class="title-with-count">
                    <h2>Features</h2>
                    <span>06</span>
                </div>
                <p>The core database-course functionality of UniRide.</p>
            </div>
        </div>

        <div class="feature-grid">
            <article class="feature-card feature-wide">
                <div class="feature-art seats">
                    <i></i><i class="selected"></i><span></span><i></i><i class="booked"></i>
                </div>
                <div class="feature-copy">
                    <small>01 · Seat booking</small>
                    <h3>Choose from available bus seats.</h3>
                    <p>Bookings stay linked to passengers, buses, routes, schedules and billing.</p>
                </div>
            </article>

            <article class="feature-card">
                <div class="feature-art qr">QR</div>
                <div class="feature-copy">
                    <small>02 · Ticket</small>
                    <h3>QR-ready booking records.</h3>
                </div>
            </article>

            <article class="feature-card">
                <div class="feature-art lines"><i></i><i></i><i></i></div>
                <div class="feature-copy">
                    <small>03 · Schedule</small>
                    <h3>Routes, dates and timing.</h3>
                </div>
            </article>

            <article class="feature-card">
                <div class="feature-art transfer"><b>A</b><span>→</span><b>B</b></div>
                <div class="feature-copy">
                    <small>04 · Transfer</small>
                    <h3>Transfer eligible tickets.</h3>
                </div>
            </article>

            <article class="feature-card">
                <div class="feature-art notification">3</div>
                <div class="feature-copy">
                    <small>05 · Updates</small>
                    <h3>Complaints and notifications.</h3>
                </div>
            </article>

            <article class="feature-card">
                <div class="feature-art bill"><strong>৳</strong><span>Semester</span></div>
                <div class="feature-copy">
                    <small>06 · Billing</small>
                    <h3>Semester transport charges.</h3>
                </div>
            </article>
        </div>
    </section>

    <section class="section container universities" id="universities">
        <p class="kicker">Participating universities</p>
        <div class="university-row">
            <span>BRAC University</span>
            <span>North South University</span>
            <span>AIUB</span>
        </div>
    </section>
</main>

<footer>
    <div class="container footer-row">
        <a class="brand" href="index.php">
            <img src="img/logo.svg" alt="">
            <span>UniRide</span>
        </a>
        <p>University Bus Ticketing System</p>
    </div>
</footer>

</body>
</html>
