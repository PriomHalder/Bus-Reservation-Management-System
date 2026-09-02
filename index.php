<?php
declare(strict_types=1);

session_start();

require_once __DIR__ . '/includes/theme.php';

$stats = [
    'universities' => 0,
    'routes' => 0,
    'students' => 0,
    'faculty' => 0,
];
$universities = [];
$dbError = '';

try {
    require_once __DIR__ . '/config/database.php';

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

    $universities = $pdo->query(
        "SELECT university_id, name, code
         FROM universities
         WHERE status='ACTIVE'
         ORDER BY name"
    )->fetchAll();
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
    <?= uniride_theme_head_html('.') ?>
    <meta name="description" content="UniRide university bus ticket booking platform.">

    <link rel="icon" href="img/logo.svg" type="image/svg+xml">
    <link rel="stylesheet" href="css/style.css">

    <style>
        /* ================================================================
           UniRide public homepage — current navy / white theme
           Scoped to body.home-current-theme so no dashboard is affected.
           ================================================================ */
        body.home-current-theme {
            --ur-blue: #184987;
            --ur-blue-dark: #10376a;
            --ur-blue-soft: #eef4fb;
            --ur-blue-pale: #f8fbff;
            --ur-ink: #17191c;
            --ur-muted: #707780;
            --ur-line: #e3e8ee;
            --ur-white: #ffffff;
            margin: 0;
            background: var(--ur-white);
            color: var(--ur-ink);
        }

        .home-current-theme .topbar {
            background: rgba(255,255,255,.96);
            border-bottom: 1px solid var(--ur-line);
            backdrop-filter: blur(16px);
        }

        .home-current-theme .brand {
            color: var(--ur-ink);
        }

        .home-current-theme .brand img {
            width: 25px;
            height: 25px;
        }

        .home-current-theme .brand span {
            font-weight: 850;
            letter-spacing: -.035em;
        }

        .home-current-theme .main-nav a,
        .home-current-theme .link-btn {
            color: #555d66;
            transition: color .15s ease, background .15s ease;
        }

        .home-current-theme .main-nav a:hover,
        .home-current-theme .link-btn:hover {
            color: var(--ur-blue);
        }

        .home-current-theme .button-light {
            border-color: #dce3eb;
            background: #fff;
            color: var(--ur-blue);
        }

        .home-current-theme .button-light:hover {
            border-color: #c5d4e4;
            background: var(--ur-blue-pale);
        }

        .home-current-theme .button-dark {
            border-color: var(--ur-blue);
            background: var(--ur-blue);
            color: #fff;
        }

        .home-current-theme .button-dark:hover {
            border-color: var(--ur-blue-dark);
            background: var(--ur-blue-dark);
        }

        .home-current-theme .hero {
            min-height: 720px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding-top: 116px;
            padding-bottom: 86px;
            text-align: center;
        }

        .home-current-theme .hero .kicker {
            margin-bottom: 18px;
            color: var(--ur-blue);
            font-size: 12px;
            font-weight: 900;
            letter-spacing: .11em;
        }

        .home-current-theme .hero h1 {
            max-width: 920px;
            margin-inline: auto;
            color: var(--ur-ink);
            font-size: clamp(72px, 7.1vw, 112px);
            line-height: .88;
            letter-spacing: -.065em;
        }

        .home-current-theme .hero h1 em {
            color: var(--ur-blue);
            font-weight: inherit;
        }

        .home-current-theme .hero-text {
            max-width: 780px;
            margin-top: 38px;
            color: var(--ur-muted);
            font-size: 17px;
            line-height: 1.6;
        }

        .home-current-theme .stats {
            width: min(880px, 100%);
            margin-top: 70px;
            padding-top: 34px;
            border-top: 1px solid var(--ur-line);
        }

        .home-current-theme .stats > div {
            position: relative;
        }

        .home-current-theme .stats strong {
            color: var(--ur-blue);
            font-family: Georgia, "Times New Roman", serif;
            font-size: 32px;
            font-weight: 500;
        }

        .home-current-theme .stats span {
            color: #7a8189;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: .08em;
            text-transform: uppercase;
        }

        .home-current-theme .empty-card {
            width: min(880px, 100%);
            margin-top: 20px;
            border-color: #d8e2ed;
            background: var(--ur-blue-pale);
        }

        .home-current-theme .section {
            padding-top: 88px;
            padding-bottom: 88px;
        }

        .home-current-theme .section-head {
            margin-bottom: 28px;
        }

        .home-current-theme .title-with-count h2 {
            color: var(--ur-ink);
        }

        .home-current-theme .title-with-count span,
        .home-current-theme .section-head p,
        .home-current-theme .universities .kicker {
            color: var(--ur-blue);
        }

        .home-current-theme .feature-card {
            border-color: var(--ur-line);
            background: #fff;
            box-shadow: 0 8px 28px rgba(16,55,106,.035);
            transition: transform .16s ease, border-color .16s ease, box-shadow .16s ease;
        }

        .home-current-theme .feature-card:hover {
            transform: translateY(-2px);
            border-color: #cfdbe8;
            box-shadow: 0 12px 34px rgba(16,55,106,.07);
        }

        .home-current-theme .feature-art {
            background: #f4f7fa;
        }

        .home-current-theme .feature-art.qr,
        .home-current-theme .feature-art.notification,
        .home-current-theme .feature-art.bill strong {
            color: var(--ur-blue);
        }

        .home-current-theme .feature-art.seats i.selected {
            background: var(--ur-blue);
            border-color: var(--ur-blue);
        }

        .home-current-theme .feature-art.transfer b {
            border-color: #cedae7;
            background: #fff;
            color: var(--ur-blue);
        }

        .home-current-theme .feature-copy small {
            color: var(--ur-blue);
        }

        .home-current-theme .feature-copy h3 {
            color: var(--ur-ink);
        }

        .home-current-theme .feature-copy p {
            color: var(--ur-muted);
        }

        .home-current-theme .universities {
            padding-top: 46px;
        }

        .home-current-theme .university-row {
            border-top-color: var(--ur-line);
            border-bottom-color: var(--ur-line);
        }

        .home-current-theme .university-row span {
            color: var(--ur-ink);
        }

        .home-current-theme footer {
            border-top: 1px solid var(--ur-line);
            background: #fbfdff;
        }

        .home-current-theme footer p {
            color: #899099;
        }

        .home-current-theme .menu-btn span {
            background: var(--ur-blue);
        }

        @media (max-width: 900px) {
            .home-current-theme .hero {
                min-height: auto;
                padding-top: 140px;
                padding-bottom: 70px;
            }

            .home-current-theme .hero h1 {
                font-size: clamp(58px, 12vw, 86px);
            }

            .home-current-theme .stats {
                margin-top: 52px;
            }
        }

        @media (max-width: 640px) {
            .home-current-theme .hero {
                align-items: flex-start;
                text-align: left;
            }

            .home-current-theme .hero h1,
            .home-current-theme .hero-text {
                margin-inline: 0;
            }

            .home-current-theme .hero h1 {
                font-size: clamp(52px, 15vw, 74px);
            }

            .home-current-theme .hero-text {
                font-size: 15px;
            }

            .home-current-theme .stats {
                width: 100%;
            }

            .home-current-theme .stats strong {
                font-size: 28px;
            }
        }
    </style>
    <link rel="stylesheet" href="css/uniride-ui.css">

    <script src="js/app.js" defer></script>
</head>
<body class="home-current-theme">

<header class="topbar">
    <div class="container nav">
        <a class="brand" href="index.php">
            <img src="img/logo.svg" alt="">
            <span>UniRide</span>
        </a>

        <nav class="main-nav" id="mainNav">
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
            A unified university transport platform for schedules, ticket booking,
            seat management, notifications, complaints, transfers and semester billing.
        </p>

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

        <?php if ($dbError): ?>
            <div class="empty-card">
                <strong>Database unavailable</strong>
                <p><?= htmlspecialchars($dbError, ENT_QUOTES, 'UTF-8') ?></p>
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
            <?php if ($universities): ?>
                <?php foreach ($universities as $university): ?>
                    <span>
                        <?= htmlspecialchars((string)$university['name'], ENT_QUOTES, 'UTF-8') ?>
                    </span>
                <?php endforeach; ?>
            <?php else: ?>
                <span>No active university is available yet.</span>
            <?php endif; ?>
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
