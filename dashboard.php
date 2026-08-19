<?php
declare(strict_types=1);

session_start();

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/includes/auth.php';

requireLogin();

$type = (string)$_SESSION['user_type'];
$name = (string)($_SESSION['name'] ?? 'User');
$email = (string)($_SESSION['email'] ?? '');

$title = 'Dashboard';
$subtitle = '';
$metrics = [];
$rows = [];

try {
    if ($type === 'PASSENGER') {
        $passengerId = (int)$_SESSION['passenger_id'];
        $universityId = (int)$_SESSION['university_id'];
        $passengerType = (string)$_SESSION['passenger_type'];

        $stmt = $pdo->prepare(
            "SELECT u.code, u.name
             FROM universities u
             WHERE u.university_id = ?
             LIMIT 1"
        );
        $stmt->execute([$universityId]);
        $university = $stmt->fetch();

        $title = ($university['code'] ?? '') . ' Passenger';
        $subtitle = $passengerType . ' · ' . ($university['name'] ?? '');

        $queries = [
            'Active bookings' =>
                "SELECT COUNT(*) FROM bookings
                 WHERE passenger_id=?
                   AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')",

            'Favorite routes' =>
                "SELECT COUNT(*) FROM favorite_routes WHERE passenger_id=?",

            'Unread updates' =>
                "SELECT COUNT(*) FROM notifications
                 WHERE passenger_id=? AND is_read=0",

            'Open complaints' =>
                "SELECT COUNT(*) FROM complaints
                 WHERE passenger_id=?
                   AND status IN ('OPEN','IN_PROGRESS')",
        ];

        foreach ($queries as $label => $sql) {
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$passengerId]);
            $metrics[] = [$label, (int)$stmt->fetchColumn()];
        }

        $stmt = $pdo->prepare(
            "SELECT
                r.route_code,
                r.route_name,
                s.schedule_date,
                s.departure_time,
                s.arrival_time,
                r.fare,
                b.registration_number,
                b.bus_type
             FROM schedules s
             JOIN routes r ON r.route_id=s.route_id
             JOIN buses b ON b.bus_id=s.bus_id
             WHERE r.university_id=?
               AND s.status='SCHEDULED'
             ORDER BY s.schedule_date, s.departure_time
             LIMIT 10"
        );
        $stmt->execute([$universityId]);
        $rows = $stmt->fetchAll();
    } elseif ($type === 'UNIVERSITY_ADMIN') {
        $universityId = (int)$_SESSION['university_id'];

        $stmt = $pdo->prepare(
            "SELECT code, name
             FROM universities
             WHERE university_id=?
             LIMIT 1"
        );
        $stmt->execute([$universityId]);
        $university = $stmt->fetch();

        $title = ($university['code'] ?? '') . ' Transport Admin';
        $subtitle = $university['name'] ?? 'University';

        $queries = [
            'Passengers' =>
                "SELECT COUNT(*) FROM passengers WHERE university_id=?",
            'Active buses' =>
                "SELECT COUNT(*) FROM buses
                 WHERE university_id=? AND status='ACTIVE'",
            'Active routes' =>
                "SELECT COUNT(*) FROM routes
                 WHERE university_id=? AND status='ACTIVE'",
            'Open complaints' =>
                "SELECT COUNT(*) FROM complaints
                 WHERE university_id=?
                   AND status IN ('OPEN','IN_PROGRESS')",
        ];

        foreach ($queries as $label => $sql) {
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$universityId]);
            $metrics[] = [$label, (int)$stmt->fetchColumn()];
        }

        $stmt = $pdo->prepare(
            "SELECT
                r.route_code,
                r.route_name,
                s.schedule_date,
                s.departure_time,
                s.arrival_time,
                b.registration_number,
                b.bus_type,
                s.status
             FROM schedules s
             JOIN routes r ON r.route_id=s.route_id
             JOIN buses b ON b.bus_id=s.bus_id
             WHERE r.university_id=?
             ORDER BY s.schedule_date, s.departure_time
             LIMIT 10"
        );
        $stmt->execute([$universityId]);
        $rows = $stmt->fetchAll();
    } else {
        $title = 'System Administration';
        $subtitle = 'UniRide platform overview';

        $metrics = [
            ['Universities', (int)$pdo->query(
                "SELECT COUNT(*) FROM universities WHERE status='ACTIVE'"
            )->fetchColumn()],
            ['Passengers', (int)$pdo->query(
                "SELECT COUNT(*) FROM passengers"
            )->fetchColumn()],
            ['Active buses', (int)$pdo->query(
                "SELECT COUNT(*) FROM buses WHERE status='ACTIVE'"
            )->fetchColumn()],
            ['Bookings', (int)$pdo->query(
                "SELECT COUNT(*) FROM bookings"
            )->fetchColumn()],
        ];

        $rows = $pdo->query(
            "SELECT
                u.code,
                u.name,
                u.status,
                (SELECT COUNT(*) FROM passengers p
                 WHERE p.university_id=u.university_id) AS passengers,
                (SELECT COUNT(*) FROM routes r
                 WHERE r.university_id=u.university_id) AS routes,
                (SELECT COUNT(*) FROM buses b
                 WHERE b.university_id=u.university_id) AS buses
             FROM universities u
             ORDER BY u.university_id"
        )->fetchAll();
    }
} catch (Throwable $e) {
    error_log('[UniRide dashboard] ' . $e->getMessage());
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= h($title) ?> — UniRide</title>

    <link rel="icon" href="img/logo.svg" type="image/svg+xml">
    <link rel="stylesheet" href="css/style.css">
</head>
<body>

<header class="topbar">
    <div class="container nav">
        <a class="brand" href="index.php">
            <img src="img/logo.svg" alt="">
            <span>UniRide</span>
        </a>

        <nav class="main-nav">
            <a href="dashboard.php">Dashboard</a>
            <a href="index.php#routes">Routes</a>
        </nav>

        <div class="nav-actions">
            <span class="user-name"><?= h($name) ?></span>
            <a href="logout.php" class="button button-light button-small">Sign out</a>
        </div>
    </div>
</header>

<main class="dashboard container">
    <section class="dashboard-head">
        <p class="kicker"><?= h($type) ?></p>
        <h1><?= h($title) ?></h1>
        <p><?= h($subtitle) ?> · <?= h($email) ?></p>
    </section>

    <section class="metric-grid">
        <?php foreach ($metrics as [$label, $value]): ?>
            <article class="metric-card">
                <strong><?= number_format($value) ?></strong>
                <span><?= h($label) ?></span>
            </article>
        <?php endforeach; ?>
    </section>

    <section class="table-panel">
        <div class="section-head">
            <div>
                <div class="title-with-count">
                    <h2><?= $type === 'SYSTEM_ADMIN' ? 'Universities' : 'Schedules' ?></h2>
                </div>
                <p>Current information from the database.</p>
            </div>
        </div>

        <div class="table-scroll">
            <?php if ($type === 'SYSTEM_ADMIN'): ?>
                <table>
                    <thead>
                    <tr>
                        <th>Code</th>
                        <th>University</th>
                        <th>Passengers</th>
                        <th>Routes</th>
                        <th>Buses</th>
                        <th>Status</th>
                    </tr>
                    </thead>
                    <tbody>
                    <?php foreach ($rows as $row): ?>
                        <tr>
                            <td><strong><?= h($row['code']) ?></strong></td>
                            <td><?= h($row['name']) ?></td>
                            <td><?= number_format((int)$row['passengers']) ?></td>
                            <td><?= number_format((int)$row['routes']) ?></td>
                            <td><?= number_format((int)$row['buses']) ?></td>
                            <td><span class="status"><?= h($row['status']) ?></span></td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            <?php else: ?>
                <table>
                    <thead>
                    <tr>
                        <th>Route</th>
                        <th>Date</th>
                        <th>Departure</th>
                        <th>Arrival</th>
                        <th>Bus</th>
                        <th>Type</th>
                        <th><?= $type === 'PASSENGER' ? 'Fare' : 'Status' ?></th>
                    </tr>
                    </thead>
                    <tbody>
                    <?php if (!$rows): ?>
                        <tr>
                            <td colspan="7">No schedules found.</td>
                        </tr>
                    <?php endif; ?>

                    <?php foreach ($rows as $row): ?>
                        <tr>
                            <td>
                                <strong><?= h($row['route_code']) ?></strong><br>
                                <small><?= h($row['route_name']) ?></small>
                            </td>
                            <td><?= h($row['schedule_date']) ?></td>
                            <td><?= h(date('g:i A', strtotime($row['departure_time']))) ?></td>
                            <td><?= h(date('g:i A', strtotime($row['arrival_time']))) ?></td>
                            <td><?= h($row['registration_number']) ?></td>
                            <td><?= h($row['bus_type']) ?></td>
                            <td>
                                <?php if ($type === 'PASSENGER'): ?>
                                    ৳<?= number_format((float)$row['fare'], 0) ?>
                                <?php else: ?>
                                    <span class="status"><?= h($row['status']) ?></span>
                                <?php endif; ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            <?php endif; ?>
        </div>
    </section>
</main>

</body>
</html>
