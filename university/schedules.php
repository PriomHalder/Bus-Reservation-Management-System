<?php
declare(strict_types=1);
require_once __DIR__ . '/_university_shell.php';

$date = u_valid_date($_GET['date'] ?? null) ?: date('Y-m-d');

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'add_schedule') {
    if (!u_verify_csrf($_POST['csrf_token'] ?? null)) {
        u_flash('error', 'Your session expired. Please try again.');
        u_redirect('schedules.php?new=1');
    }

    $routeId = (int)($_POST['route_id'] ?? 0);
    $busId = (int)($_POST['bus_id'] ?? 0);
    $scheduleDate = u_valid_date($_POST['schedule_date'] ?? null);
    $departure = (string)($_POST['departure_time'] ?? '');
    $arrival = (string)($_POST['arrival_time'] ?? '');

    $routeOwned = (int)u_scalar($pdo, "SELECT COUNT(*) FROM routes WHERE route_id=? AND university_id=? AND status='ACTIVE'", [$routeId, $uUniversityId]);
    $busOwned = (int)u_scalar($pdo, "SELECT COUNT(*) FROM buses WHERE bus_id=? AND university_id=? AND status='ACTIVE'", [$busId, $uUniversityId]);

    if (!$routeOwned || !$busOwned || !$scheduleDate || $departure === '' || $arrival === '') {
        u_flash('error', 'Choose an active route and bus belonging to your university, then complete date and time.');
        u_redirect('schedules.php?new=1');
    }

    // Check to prevent duplicate schedules on the same date & departure time
    $isDuplicate = (int)u_scalar($pdo, "SELECT COUNT(*) FROM schedules WHERE route_id = ? AND bus_id = ? AND schedule_date = ? AND departure_time = ?", [$routeId, $busId, $scheduleDate, $departure]);
    if ($isDuplicate > 0) {
        u_flash('error', 'A schedule for this bus, route, and departure time already exists on this date.');
        u_redirect('schedules.php?new=1');
    }

    try {
        $stmt = $pdo->prepare("INSERT INTO schedules(route_id, bus_id, schedule_date, departure_time, arrival_time, status) VALUES (?, ?, ?, ?, ?, 'SCHEDULED')");
        $stmt->execute([$routeId, $busId, $scheduleDate, $departure, $arrival]);
        u_flash('success', 'Schedule created for ' . $uUniversity['name'] . '.');
        u_redirect('schedules.php?date=' . rawurlencode($scheduleDate));
    } catch (Throwable $e) {
        error_log('[UniRide add schedule] ' . $e->getMessage());
        u_flash('error', 'The schedule could not be created.');
        u_redirect('schedules.php?new=1');
    }
}

$routes = u_all($pdo, "SELECT route_id, route_code, route_name FROM routes WHERE university_id=? AND status='ACTIVE' ORDER BY route_code", [$uUniversityId]);
$buses = u_all($pdo, "SELECT bus_id, registration_number, bus_type FROM buses WHERE university_id=? AND status='ACTIVE' ORDER BY registration_number", [$uUniversityId]);

$rows = u_all($pdo, "SELECT s.schedule_id, s.departure_time, s.arrival_time, s.status, r.route_code, r.route_name, b.registration_number, b.bus_type, b.seat_capacity, b.standing_capacity, COUNT(DISTINCT CASE WHEN bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING') THEN bk.booking_id END) bookings FROM schedules s JOIN routes r ON r.route_id=s.route_id JOIN buses b ON b.bus_id=s.bus_id LEFT JOIN bookings bk ON bk.schedule_id=s.schedule_id WHERE r.university_id=? AND b.university_id=? AND s.schedule_date=? GROUP BY s.schedule_id, s.departure_time, s.arrival_time, s.status, r.route_code, r.route_name, b.registration_number, b.bus_type, b.seat_capacity, b.standing_capacity ORDER BY s.departure_time", [$uUniversityId, $uUniversityId, $date]);

u_render_start('Schedules', 'schedules', 'Operations', 'Create and review date-specific trips using only this university’s routes and buses.');
u_render_actions('<a class="up-button" href="schedules.php?new=1&date=' . u_h($date) . '">+ Create Schedule</a>');
u_render_heading_end();
?>

<?php if (isset($_GET['new'])): ?>
    <section class="up-card blue" style="margin-bottom:16px">
        <div class="section-heading-row">
            <div>
                <p class="dashboard-kicker">New trip</p>
                <h2>Create Schedule</h2>
            </div>
        </div>
        <form method="post" class="up-form-grid">
            <input type="hidden" name="csrf_token" value="<?= u_h(u_csrf()) ?>">
            <input type="hidden" name="action" value="add_schedule">
            <label class="up-field">
                <span>Route</span>
                <select name="route_id" required>
                    <option value="">Choose route</option>
                    <?php foreach ($routes as $r): ?>
                        <option value="<?= (int)$r['route_id'] ?>"><?= u_h($r['route_code'] . ' · ' . $r['route_name']) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label class="up-field">
                <span>Bus</span>
                <select name="bus_id" required>
                    <option value="">Choose bus</option>
                    <?php foreach ($buses as $b): ?>
                        <option value="<?= (int)$b['bus_id'] ?>"><?= u_h($b['registration_number'] . ' · ' . u_bus_type($b['bus_type'])) ?></option>
                    <?php endforeach; ?>
                </select>
            </label>
            <label class="up-field">
                <span>Date</span>
                <input type="date" name="schedule_date" value="<?= u_h($date) ?>" required>
            </label>
            <label class="up-field">
                <span>Departure</span>
                <input type="time" name="departure_time" required>
            </label>
            <label class="up-field">
                <span>Arrival</span>
                <input type="time" name="arrival_time" required>
            </label>
            <div class="up-form-actions">
                <button class="up-button" type="submit">Save Schedule</button>
                <a class="up-button-secondary" href="schedules.php?date=<?= u_h($date) ?>">Cancel</a>
            </div>
        </form>
    </section>
<?php endif; ?>

<form method="get" class="up-filter up-filter-date">
    <input type="date" name="date" value="<?= u_h($date) ?>">
    <button class="up-button-secondary" type="submit">View Date</button>
</form>

<?php if (!$rows): ?>
    <div class="up-empty">
        <div>
            <strong>No schedules on <?= u_h(u_date($date)) ?>.</strong>
            <p>Create a trip using this university’s routes and buses.</p>
        </div>
        <a class="up-button" href="?new=1&date=<?= u_h($date) ?>">Create Schedule</a>
    </div>
<?php else: ?>
    <div class="up-table-wrap">
        <table class="up-table">
            <thead>
                <tr>
                    <th>Route</th>
                    <th>Bus</th>
                    <th>Departure</th>
                    <th>Arrival</th>
                    <th>Bookings</th>
                    <th>Capacity</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($rows as $r): ?>
                    <tr>
                        <td><strong><?= u_h($r['route_code']) ?></strong><small><?= u_h($r['route_name']) ?></small></td>
                        <td><strong><?= u_h($r['registration_number']) ?></strong><small><?= u_h(u_bus_type($r['bus_type'])) ?></small></td>
                        <td><?= u_h(u_time($r['departure_time'])) ?></td>
                        <td><?= u_h(u_time($r['arrival_time'])) ?></td>
                        <td><?= (int)$r['bookings'] ?></td>
                        <td><?= (int)$r['seat_capacity'] ?> seats · <?= (int)$r['standing_capacity'] ?> standing</td>
                        <td><span class="up-status <?= u_h(u_status_class($r['status'])) ?>"><?= u_h($r['status']) ?></span></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
<?php endif; ?>

<?php u_render_end(); ?>