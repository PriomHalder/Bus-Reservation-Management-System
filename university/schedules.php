<?php
declare(strict_types=1);

require_once __DIR__ . '/_university_shell.php';
require_once __DIR__ . '/../includes/schedule-policy.php';

$date = u_valid_date($_GET['date'] ?? ($_POST['schedule_date'] ?? null)) ?: date('Y-m-d');
$editScheduleId = max(0, (int)($_GET['edit'] ?? 0));
$shifts = uniride_schedule_shifts();
$fixedShiftReady = u_column_exists($pdo, 'schedules', 'shift_name')
    && u_column_exists($pdo, 'bus_route_assignments', 'is_active')
    && u_column_exists($pdo, 'bus_route_assignments', 'active_bus_key');

/** Reuse a route's most recent valid travel duration; default to one hour. */
function u_schedule_duration_minutes(PDO $pdo, int $routeId, int $busId): int
{
    $queries = [
        [
            "SELECT TIMESTAMPDIFF(MINUTE,departure_time,arrival_time)
             FROM schedules
             WHERE route_id=? AND bus_id=? AND arrival_time>departure_time
             ORDER BY schedule_date DESC,schedule_id DESC LIMIT 1",
            [$routeId, $busId],
        ],
        [
            "SELECT TIMESTAMPDIFF(MINUTE,departure_time,arrival_time)
             FROM schedules
             WHERE route_id=? AND arrival_time>departure_time
             ORDER BY schedule_date DESC,schedule_id DESC LIMIT 1",
            [$routeId],
        ],
    ];

    foreach ($queries as [$sql, $params]) {
        $minutes = (int)(u_scalar($pdo, $sql, $params) ?: 0);
        if ($minutes >= 15 && $minutes <= 360) {
            return $minutes;
        }
    }

    return 60;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = (string)($_POST['action'] ?? '');

    if (!u_verify_csrf($_POST['csrf_token'] ?? null)) {
        u_flash('error', 'Your session expired. Please try again.');
        u_redirect('schedules.php?date=' . rawurlencode($date));
    }
    if (!$fixedShiftReady) {
        u_flash('error', 'Import database/migrations/007_fixed_bus_route_shifts.sql before managing fixed-shift schedules.');
        u_redirect('schedules.php?date=' . rawurlencode($date));
    }

    if ($action === 'assign_bus_route') {
        $routeId = (int)($_POST['route_id'] ?? 0);
        $busId = (int)($_POST['bus_id'] ?? 0);

        $routeOwned = (int)u_scalar(
            $pdo,
            "SELECT COUNT(*) FROM routes
             WHERE route_id=? AND university_id=? AND status='ACTIVE'",
            [$routeId, $uUniversityId]
        );
        $busOwned = (int)u_scalar(
            $pdo,
            "SELECT COUNT(*) FROM buses
             WHERE bus_id=? AND university_id=? AND status='ACTIVE'",
            [$busId, $uUniversityId]
        );
        $alreadyAssigned = (int)u_scalar(
            $pdo,
            'SELECT COUNT(*) FROM bus_route_assignments WHERE bus_id=? AND is_active=1',
            [$busId]
        );

        if (!$routeOwned || !$busOwned) {
            u_flash('error', 'Choose an active bus and route belonging to your university.');
            u_redirect('schedules.php?assign=1&date=' . rawurlencode($date));
        }
        if ($alreadyAssigned > 0) {
            u_flash('error', 'That bus already has a permanent route assignment.');
            u_redirect('schedules.php?assign=1&date=' . rawurlencode($date));
        }

        try {
            $pdo->beginTransaction();
            $stmt = $pdo->prepare(
                'INSERT INTO bus_route_assignments(bus_id,route_id,is_active) VALUES (?,?,1)'
            );
            $stmt->execute([$busId, $routeId]);
            $pdo->commit();
            u_flash('success', 'Bus #' . $busId . ' was assigned to its route.');
            u_redirect('schedules.php?date=' . rawurlencode($date));
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            error_log('[UniRide assign bus route] ' . $e->getMessage());
            u_flash('error', 'The bus could not be assigned. It may already belong to another route.');
            u_redirect('schedules.php?assign=1&date=' . rawurlencode($date));
        }
    }

    if ($action === 'save_schedule') {
        $scheduleId = max(0, (int)($_POST['schedule_id'] ?? 0));
        $routeId = max(0, (int)($_POST['route_id'] ?? 0));
        $busId = max(0, (int)($_POST['bus_id'] ?? 0));
        $scheduleDate = u_valid_date($_POST['schedule_date'] ?? null);
        $shiftName = strtoupper(trim((string)($_POST['shift_name'] ?? '')));
        $shift = uniride_schedule_shift($shiftName);
        $submittedTime = trim((string)($_POST['schedule_time'] ?? ''));
        $normalizedSubmittedTime = preg_match('/^\d{2}:\d{2}$/', $submittedTime)
            ? $submittedTime . ':00'
            : $submittedTime;
        $formQuery = $scheduleId > 0
            ? 'edit=' . $scheduleId . '&date=' . rawurlencode($scheduleDate ?: $date)
            : 'new=1&date=' . rawurlencode($scheduleDate ?: $date);

        if (
            !$scheduleDate
            || $scheduleDate < date('Y-m-d')
            || $shift === null
            || $routeId <= 0
            || $busId <= 0
            || ($normalizedSubmittedTime !== '' && $normalizedSubmittedTime !== $shift['departure'])
        ) {
            u_flash('error', 'Choose an assigned route and bus, a current or future date, and a valid fixed shift.');
            u_redirect('schedules.php?' . $formQuery);
        }
        if ($scheduleDate === date('Y-m-d') && $shift['departure'] <= date('H:i:s')) {
            u_flash('error', 'Choose a shift that has not departed yet.');
            u_redirect('schedules.php?' . $formQuery);
        }

        $assignment = u_one(
            $pdo,
            "SELECT a.assignment_id,a.bus_id,a.route_id
             FROM bus_route_assignments a
             INNER JOIN buses b ON b.bus_id=a.bus_id
             INNER JOIN routes r ON r.route_id=a.route_id
             WHERE a.bus_id=?
               AND a.route_id=?
               AND a.is_active=1
               AND b.university_id=?
               AND r.university_id=?
               AND b.status='ACTIVE'
               AND r.status='ACTIVE'
             LIMIT 1",
            [$busId, $routeId, $uUniversityId, $uUniversityId]
        );

        if (!$assignment) {
            u_flash('error', 'The bus ID must match an active route assignment belonging to your university.');
            u_redirect('schedules.php?' . $formQuery);
        }

        $departure = $shift['departure'];
        $duration = u_schedule_duration_minutes($pdo, $routeId, $busId);
        $departureClock = DateTimeImmutable::createFromFormat('!H:i:s', $departure);
        $arrival = $departureClock
            ? $departureClock->modify('+' . $duration . ' minutes')->format('H:i:s')
            : $departure;

        $isDuplicate = (int)u_scalar(
            $pdo,
            'SELECT COUNT(*) FROM schedules WHERE bus_id=? AND schedule_date=? AND shift_name=? AND schedule_id<>?',
            [$busId, $scheduleDate, $shiftName, $scheduleId]
        );
        if ($isDuplicate > 0) {
            u_flash('error', 'That bus already has a ' . $shift['label'] . ' schedule on this date.');
            u_redirect('schedules.php?' . $formQuery);
        }
        $hasConflict = (int)u_scalar(
            $pdo,
            "SELECT COUNT(*) FROM schedules
             WHERE bus_id=? AND schedule_date=? AND schedule_id<>? AND status<>'CANCELLED'
               AND departure_time<? AND arrival_time>?",
            [$busId, $scheduleDate, $scheduleId, $arrival, $departure]
        );
        if ($hasConflict > 0) {
            u_flash('error', 'That bus already has a trip overlapping the selected shift.');
            u_redirect('schedules.php?' . $formQuery);
        }

        try {
            $pdo->beginTransaction();
            if ($scheduleId > 0) {
                $ownedSchedule = u_one(
                    $pdo,
                    "SELECT s.schedule_id
                     FROM schedules s
                     INNER JOIN routes r ON r.route_id=s.route_id
                     INNER JOIN buses b ON b.bus_id=s.bus_id
                     WHERE s.schedule_id=?
                       AND r.university_id=? AND b.university_id=?
                       AND s.status='SCHEDULED'
                     LIMIT 1 FOR UPDATE",
                    [$scheduleId, $uUniversityId, $uUniversityId]
                );
                if (!$ownedSchedule) {
                    throw new RuntimeException('The selected schedule is no longer available to edit.');
                }
                $stmt = $pdo->prepare(
                    "UPDATE schedules
                     SET route_id=?,bus_id=?,schedule_date=?,departure_time=?,arrival_time=?,shift_name=?
                     WHERE schedule_id=?"
                );
                $stmt->execute([$routeId, $busId, $scheduleDate, $departure, $arrival, $shiftName, $scheduleId]);
            } else {
                $stmt = $pdo->prepare(
                    "INSERT INTO schedules
                        (route_id,bus_id,schedule_date,departure_time,arrival_time,shift_name,status)
                     VALUES (?,?,?,?,?,?,'SCHEDULED')"
                );
                $stmt->execute([$routeId, $busId, $scheduleDate, $departure, $arrival, $shiftName]);
            }
            $pdo->commit();
            u_flash(
                'success',
                $shift['label'] . ' schedule ' . ($scheduleId > 0 ? 'updated' : 'created')
                . ' for ' . $uUniversity['name'] . '.'
            );
            u_redirect('schedules.php?date=' . rawurlencode($scheduleDate));
        } catch (RuntimeException $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            u_flash('error', $e->getMessage());
            u_redirect('schedules.php?' . $formQuery);
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            error_log('[UniRide save fixed schedule] ' . $e->getMessage());
            u_flash('error', 'The schedule could not be saved. Check that the bus, route and shift are still available.');
            u_redirect('schedules.php?' . $formQuery);
        }
    }

    if ($action === 'delete_schedule') {
        $scheduleId = max(0, (int)($_POST['schedule_id'] ?? 0));

        try {
            $pdo->beginTransaction();
            $schedule = u_one(
                $pdo,
                "SELECT s.schedule_id,s.shift_name,s.schedule_date,r.route_code
                 FROM schedules s
                 INNER JOIN routes r ON r.route_id=s.route_id
                 INNER JOIN buses b ON b.bus_id=s.bus_id
                 WHERE s.schedule_id=? AND r.university_id=? AND b.university_id=?
                 LIMIT 1 FOR UPDATE",
                [$scheduleId, $uUniversityId, $uUniversityId]
            );
            if (!$schedule) {
                throw new RuntimeException('The selected schedule was not found for your university.');
            }

            $bookingRecords = (int)u_scalar(
                $pdo,
                'SELECT COUNT(*) FROM bookings WHERE schedule_id=?',
                [$scheduleId]
            );
            $activeBookings = (int)u_scalar(
                $pdo,
                "SELECT COUNT(*) FROM bookings
                 WHERE schedule_id=? AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')",
                [$scheduleId]
            );
            if ($activeBookings > 0) {
                throw new RuntimeException(
                    'Cancel this schedule’s active bookings from the Bookings page before deleting it.'
                );
            }
            if ($bookingRecords > 0) {
                $stmt = $pdo->prepare("UPDATE schedules SET status='CANCELLED' WHERE schedule_id=?");
                $stmt->execute([$scheduleId]);
                $resultMessage = 'Schedule removed from availability. Its completed or cancelled booking history was preserved.';
            } else {
                $stmt = $pdo->prepare('DELETE FROM schedules WHERE schedule_id=?');
                $stmt->execute([$scheduleId]);
                $resultMessage = 'Schedule deleted successfully.';
            }
            $pdo->commit();
            u_flash('success', $resultMessage);
        } catch (RuntimeException $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            u_flash('error', $e->getMessage());
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            error_log('[UniRide delete schedule] ' . $e->getMessage());
            u_flash('error', 'The schedule could not be deleted. No changes were saved.');
        }
        u_redirect('schedules.php?date=' . rawurlencode($date));
    }
}

$routes = u_all(
    $pdo,
    "SELECT route_id,route_code,route_name
     FROM routes WHERE university_id=? AND status='ACTIVE' ORDER BY route_code",
    [$uUniversityId]
);
$assignments = [];
$unassignedBuses = [];
$rows = [];
$editingSchedule = [];

if ($fixedShiftReady) {
    $assignments = u_all(
        $pdo,
        "SELECT a.assignment_id,a.bus_id,a.route_id,b.registration_number,b.bus_type,
                r.route_code,r.route_name
         FROM bus_route_assignments a
         INNER JOIN buses b ON b.bus_id=a.bus_id
         INNER JOIN routes r ON r.route_id=a.route_id
         WHERE a.is_active=1
           AND b.university_id=? AND r.university_id=?
           AND b.status='ACTIVE' AND r.status='ACTIVE'
         ORDER BY r.route_code,b.bus_id",
        [$uUniversityId, $uUniversityId]
    );
    $unassignedBuses = u_all(
        $pdo,
        "SELECT b.bus_id,b.registration_number,b.bus_type
         FROM buses b
         LEFT JOIN bus_route_assignments a
           ON a.bus_id=b.bus_id AND a.is_active=1
         WHERE b.university_id=? AND b.status='ACTIVE' AND a.assignment_id IS NULL
         ORDER BY b.bus_id",
        [$uUniversityId]
    );
    $rows = u_all(
        $pdo,
        "SELECT s.schedule_id,s.shift_name,s.departure_time,s.arrival_time,s.status,
                r.route_code,r.route_name,b.bus_id,b.registration_number,b.bus_type,
                b.seat_capacity,b.standing_capacity,
                COUNT(DISTINCT CASE
                    WHEN bk.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')
                    THEN bk.booking_id END) bookings
         FROM schedules s
         INNER JOIN routes r ON r.route_id=s.route_id
         INNER JOIN buses b ON b.bus_id=s.bus_id
         INNER JOIN bus_route_assignments a
           ON a.bus_id=s.bus_id AND a.route_id=s.route_id AND a.is_active=1
         LEFT JOIN bookings bk ON bk.schedule_id=s.schedule_id
         WHERE r.university_id=? AND b.university_id=? AND s.schedule_date=?
           AND s.status<>'CANCELLED'
           AND ((s.shift_name='NOON' AND s.departure_time='14:00:00')
             OR (s.shift_name='EVENING' AND s.departure_time='17:10:00'))
         GROUP BY s.schedule_id,s.shift_name,s.departure_time,s.arrival_time,s.status,
                  r.route_code,r.route_name,b.bus_id,b.registration_number,b.bus_type,
                  b.seat_capacity,b.standing_capacity
         ORDER BY CASE s.shift_name WHEN 'NOON' THEN 1 WHEN 'EVENING' THEN 2 ELSE 3 END,
                  b.bus_id,s.schedule_id",
        [$uUniversityId, $uUniversityId, $date]
    );

    if ($editScheduleId > 0) {
        $editingSchedule = u_one(
            $pdo,
            "SELECT s.schedule_id,s.route_id,s.bus_id,s.schedule_date,s.shift_name,s.departure_time
             FROM schedules s
             INNER JOIN routes r ON r.route_id=s.route_id
             INNER JOIN buses b ON b.bus_id=s.bus_id
             INNER JOIN bus_route_assignments a
               ON a.bus_id=s.bus_id AND a.route_id=s.route_id AND a.is_active=1
             WHERE s.schedule_id=? AND s.status='SCHEDULED'
               AND r.university_id=? AND b.university_id=?
             LIMIT 1",
            [$editScheduleId, $uUniversityId, $uUniversityId]
        );
        if (!$editingSchedule) {
            u_flash('error', 'The selected schedule is not available to edit.');
            u_redirect('schedules.php?date=' . rawurlencode($date));
        }
    }
}

u_render_start(
    'Schedules',
    'schedules',
    'Operations',
    'Assign each bus to one route, then publish its Noon or Evening trip.'
);
u_render_actions(
    '<a class="up-button-secondary" href="schedules.php?assign=1&date=' . u_h($date) . '">Assign Bus</a>'
    . '<a class="up-button" href="schedules.php?new=1&date=' . u_h($date) . '">+ Create Schedule</a>'
);
u_render_heading_end();
?>

<?php if (!$fixedShiftReady): ?>
    <div class="dashboard-alert is-error" role="status">
        Import <code>database/migrations/007_fixed_bus_route_shifts.sql</code> once to enable fixed bus assignments and shifts.
    </div>
<?php endif; ?>

<?php if ($fixedShiftReady && isset($_GET['assign'])): ?>
    <section class="up-card blue" style="margin-bottom:16px">
        <div class="section-heading-row">
            <div>
                <p class="dashboard-kicker">Permanent assignment</p>
                <h2>Assign One Bus to One Route</h2>
                <p>Once assigned, this bus is used only on the selected route for both shifts.</p>
            </div>
        </div>
        <?php if (!$unassignedBuses || !$routes): ?>
            <div class="up-empty"><div><strong>No assignment can be created.</strong><p>Add an active unassigned bus and an active route first.</p></div></div>
        <?php else: ?>
            <form method="post" class="up-form-grid">
                <input type="hidden" name="csrf_token" value="<?= u_h(u_csrf()) ?>">
                <input type="hidden" name="action" value="assign_bus_route">
                <label class="up-field">
                    <span>Unique bus</span>
                    <select name="bus_id" required>
                        <option value="">Choose unassigned bus</option>
                        <?php foreach ($unassignedBuses as $bus): ?>
                            <option value="<?= (int)$bus['bus_id'] ?>">Bus #<?= (int)$bus['bus_id'] ?> · <?= u_h($bus['registration_number'] . ' · ' . u_bus_type($bus['bus_type'])) ?></option>
                        <?php endforeach; ?>
                    </select>
                </label>
                <label class="up-field">
                    <span>Route</span>
                    <select name="route_id" required>
                        <option value="">Choose route</option>
                        <?php foreach ($routes as $route): ?>
                            <option value="<?= (int)$route['route_id'] ?>"><?= u_h($route['route_code'] . ' · ' . $route['route_name']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </label>
                <div class="up-form-actions">
                    <button class="up-button" type="submit">Save Assignment</button>
                    <a class="up-button-secondary" href="schedules.php?date=<?= u_h($date) ?>">Cancel</a>
                </div>
            </form>
        <?php endif; ?>
    </section>
<?php endif; ?>

<?php if ($fixedShiftReady && (isset($_GET['new']) || $editingSchedule)): ?>
    <?php
    $scheduleFormDate = $editingSchedule
        ? (string)$editingSchedule['schedule_date']
        : max($date, date('Y-m-d'));
    $scheduleFormRouteId = (int)($editingSchedule['route_id'] ?? 0);
    $scheduleFormBusId = (int)($editingSchedule['bus_id'] ?? 0);
    $scheduleFormShift = (string)($editingSchedule['shift_name'] ?? '');
    $scheduleFormTime = (string)($editingSchedule['departure_time'] ?? '');
    ?>
    <section class="up-card blue" style="margin-bottom:16px">
        <div class="section-heading-row">
            <div>
                <p class="dashboard-kicker">Fixed-shift trip</p>
                <h2><?= $editingSchedule ? 'Edit Schedule' : 'Create Schedule' ?></h2>
                <p>Select the assigned route and paste its unique bus ID. The shift determines the schedule time.</p>
            </div>
        </div>
        <?php if (!$assignments): ?>
            <div class="up-empty">
                <div><strong>No active bus-to-route assignments.</strong><p>Assign a bus before creating a schedule.</p></div>
                <a class="up-button" href="?assign=1&date=<?= u_h($date) ?>">Assign Bus</a>
            </div>
        <?php else: ?>
            <form method="post" class="up-form-grid">
                <input type="hidden" name="csrf_token" value="<?= u_h(u_csrf()) ?>">
                <input type="hidden" name="action" value="save_schedule">
                <input type="hidden" name="schedule_id" value="<?= (int)($editingSchedule['schedule_id'] ?? 0) ?>">
                <label class="up-field">
                    <span>Route</span>
                    <select name="route_id" data-schedule-route required>
                        <option value="">Choose assigned route</option>
                        <?php foreach ($routes as $route): ?>
                            <option
                                value="<?= (int)$route['route_id'] ?>"
                                <?= (int)$route['route_id'] === $scheduleFormRouteId ? 'selected' : '' ?>
                            ><?= u_h($route['route_code'] . ' · ' . $route['route_name']) ?></option>
                        <?php endforeach; ?>
                    </select>
                </label>
                <label class="up-field">
                    <span>Assigned bus ID</span>
                    <input
                        type="number"
                        name="bus_id"
                        min="1"
                        list="assignedBusIds"
                        value="<?= $scheduleFormBusId > 0 ? $scheduleFormBusId : '' ?>"
                        placeholder="Paste the unique bus ID"
                        required
                    >
                    <small>Copy this value from the Buses page or the assignment table below.</small>
                    <datalist id="assignedBusIds">
                        <?php foreach ($assignments as $assignment): ?>
                            <option value="<?= (int)$assignment['bus_id'] ?>"><?= u_h($assignment['registration_number'] . ' · ' . $assignment['route_code']) ?></option>
                        <?php endforeach; ?>
                    </datalist>
                </label>
                <label class="up-field">
                    <span>Service date</span>
                    <input type="date" name="schedule_date" min="<?= u_h(date('Y-m-d')) ?>" value="<?= u_h($scheduleFormDate) ?>" required>
                </label>
                <label class="up-field">
                    <span>Shift</span>
                    <select name="shift_name" data-schedule-shift required>
                        <option value="">Choose shift</option>
                        <?php foreach ($shifts as $key => $shift): ?>
                            <option
                                value="<?= u_h($key) ?>"
                                data-departure="<?= u_h($shift['departure']) ?>"
                                <?= $key === $scheduleFormShift ? 'selected' : '' ?>
                            ><?= u_h($shift['label']) ?> · <?= u_h(u_time($shift['departure'])) ?></option>
                        <?php endforeach; ?>
                    </select>
                </label>
                <label class="up-field">
                    <span>Schedule time</span>
                    <input
                        type="time"
                        name="schedule_time"
                        value="<?= u_h(substr($scheduleFormTime, 0, 5)) ?>"
                        data-schedule-time
                        readonly
                        aria-describedby="scheduleTimeHelp"
                    >
                    <small id="scheduleTimeHelp">Automatically set to 2:00 PM for Noon or 5:10 PM for Evening.</small>
                </label>
                <div class="up-form-actions">
                    <button class="up-button" type="submit"><?= $editingSchedule ? 'Update Schedule' : 'Save Schedule' ?></button>
                    <a class="up-button-secondary" href="schedules.php?date=<?= u_h($date) ?>">Cancel</a>
                </div>
            </form>
        <?php endif; ?>
    </section>
<?php endif; ?>

<?php if ($fixedShiftReady && $assignments): ?>
    <section class="up-card" style="margin-bottom:16px">
        <div class="section-heading-row"><div><p class="dashboard-kicker">Current mapping</p><h2>Bus-to-Route Assignments</h2></div></div>
        <div class="up-table-wrap">
            <table class="up-table">
                <thead><tr><th>Bus ID</th><th>Assigned bus</th><th>Route</th><th>Supported shifts</th></tr></thead>
                <tbody>
                <?php foreach ($assignments as $assignment): ?>
                    <tr>
                        <td><strong>#<?= (int)$assignment['bus_id'] ?></strong></td>
                        <td><strong><?= u_h($assignment['registration_number']) ?></strong><small><?= u_h(u_bus_type($assignment['bus_type'])) ?></small></td>
                        <td><strong><?= u_h($assignment['route_code']) ?></strong><small><?= u_h($assignment['route_name']) ?></small></td>
                        <td>Noon · Evening</td>
                    </tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    </section>
<?php endif; ?>

<form method="get" class="up-filter up-filter-date">
    <input type="date" name="date" value="<?= u_h($date) ?>">
    <button class="up-button-secondary" type="submit">View Date</button>
</form>

<?php if ($fixedShiftReady && !$rows): ?>
    <div class="up-empty">
        <div>
            <strong>No Noon or Evening schedules on <?= u_h(u_date($date)) ?>.</strong>
            <p>Create a trip from an existing bus-to-route assignment.</p>
        </div>
        <a class="up-button" href="?new=1&date=<?= u_h($date) ?>">Create Schedule</a>
    </div>
<?php elseif ($fixedShiftReady): ?>
    <div class="up-table-wrap">
        <table class="up-table">
            <thead>
                <tr><th>Shift</th><th>Route</th><th>Bus</th><th>Departure</th><th>Arrival</th><th>Bookings</th><th>Capacity</th><th>Status</th><th>Actions</th></tr>
            </thead>
            <tbody>
                <?php foreach ($rows as $row): ?>
                    <tr>
                        <td><strong><?= u_h(uniride_schedule_shift_label($row['shift_name'], $row['departure_time'])) ?></strong></td>
                        <td><strong><?= u_h($row['route_code']) ?></strong><small><?= u_h($row['route_name']) ?></small></td>
                        <td><strong>Bus #<?= (int)$row['bus_id'] ?> · <?= u_h($row['registration_number']) ?></strong><small><?= u_h(u_bus_type($row['bus_type'])) ?></small></td>
                        <td><?= u_h(u_time($row['departure_time'])) ?></td>
                        <td><?= u_h(u_time($row['arrival_time'])) ?></td>
                        <td><?= (int)$row['bookings'] ?></td>
                        <td><?= (int)$row['seat_capacity'] ?> seats · <?= (int)$row['standing_capacity'] ?> standing</td>
                        <td><span class="up-status <?= u_h(u_status_class($row['status'])) ?>"><?= u_h($row['status']) ?></span></td>
                        <td>
                            <div class="schedule-row-actions">
                                <a class="schedule-edit-button" href="schedules.php?edit=<?= (int)$row['schedule_id'] ?>&amp;date=<?= u_h($date) ?>">Edit</a>
                                <form method="post" onsubmit="return confirm('Delete this schedule? Schedules with booking history will be removed from availability while their history is preserved.');">
                                    <input type="hidden" name="csrf_token" value="<?= u_h(u_csrf()) ?>">
                                    <input type="hidden" name="action" value="delete_schedule">
                                    <input type="hidden" name="schedule_id" value="<?= (int)$row['schedule_id'] ?>">
                                    <input type="hidden" name="schedule_date" value="<?= u_h($date) ?>">
                                    <button class="schedule-delete-button" type="submit">Delete</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
<?php endif; ?>

<style>
    .schedule-row-actions {
        display: flex;
        align-items: center;
        gap: 7px;
        white-space: nowrap;
    }
    .schedule-row-actions form { margin: 0; }
    .schedule-edit-button,
    .schedule-delete-button {
        min-height: 30px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        padding: 0 10px;
        border-radius: 7px;
        font-size: 10px;
        font-weight: 800;
        cursor: pointer;
    }
    .schedule-edit-button {
        border: 1px solid var(--ui-line-strong, #c9d6e5);
        background: var(--ui-surface, #ffffff);
        color: var(--ui-navy, #123f7c);
    }
    .schedule-delete-button {
        border: 1px solid #c93a35;
        background: var(--ui-danger-bg, #fff1ef);
        color: var(--ui-danger, #a5241a);
    }
    .schedule-edit-button:hover { background: var(--ui-navy-soft, #edf4fb); }
    .schedule-delete-button:hover { background: #a5241a; color: #ffffff; }
    .schedule-edit-button:focus-visible,
    .schedule-delete-button:focus-visible {
        outline: 3px solid rgba(18, 63, 124, .25);
        outline-offset: 2px;
    }
    html[data-theme="dark"] .schedule-delete-button {
        border-color: #6e353b;
        background: #351c20;
        color: #ff9e98;
    }
    html[data-theme="dark"] .schedule-delete-button:hover {
        border-color: #ff9e98;
        background: #7b2928;
        color: #ffffff;
    }
</style>

<script>
(() => {
    const shift = document.querySelector('[data-schedule-shift]');
    const time = document.querySelector('[data-schedule-time]');
    if (!shift || !time) return;

    const syncTime = () => {
        const option = shift.options[shift.selectedIndex];
        time.value = option && option.dataset.departure
            ? option.dataset.departure.slice(0, 5)
            : '';
    };
    shift.addEventListener('change', syncTime);
    syncTime();
})();
</script>

<?php u_render_end(); ?>
