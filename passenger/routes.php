<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

// Search and service-date handling
$searchTerm = trim((string)($_GET['q'] ?? ''));
$today = date('Y-m-d');
$requestedDate = trim((string)($_GET['date'] ?? $today));
$parsedDate = DateTimeImmutable::createFromFormat('!Y-m-d', $requestedDate);
$selectedDate = $parsedDate && $parsedDate->format('Y-m-d') === $requestedDate
    && $requestedDate >= $today
    ? $requestedDate
    : $today;
$fixedScheduleReady = uniride_booking_column_exists($pdo, 'schedules', 'shift_name')
    && uniride_booking_column_exists($pdo, 'bus_route_assignments', 'is_active');

// Fetch the latest valid schedule for each route and shift on the selected day.
$routesData = [];
$routeLoadFailed = false;
$scheduleVisibility = [
    'candidate_count' => 0,
    'departed_count' => 0,
    'ineligible_count' => 0,
    'invalid_shift_count' => 0,
    'schedules' => [],
];
try {
    if (!$fixedScheduleReady) {
        throw new RuntimeException('Migration 007 has not been imported.');
    }
    $scheduleVisibility = uniride_load_passenger_schedules(
        $pdo,
        $ppUniversityId,
        (string)$ppProfile['passenger_type'],
        $selectedDate
    );
    $rows = $scheduleVisibility['schedules'];

    if ($searchTerm !== '') {
        $rows = array_values(array_filter(
            $rows,
            static function (array $row) use ($searchTerm): bool {
                foreach (['route_code', 'route_name', 'start_location', 'end_location'] as $field) {
                    if (stripos((string)$row[$field], $searchTerm) !== false) {
                        return true;
                    }
                }
                return false;
            }
        ));
    }

    // The first row for each route/shift is the newest valid publication.
    $latestRows = [];
    foreach ($rows as $row) {
        $latestKey = (int)$row['route_id'] . ':' . strtoupper((string)$row['shift_name']);
        if (!isset($latestRows[$latestKey])) {
            $latestRows[$latestKey] = $row;
        }
    }

    foreach ($latestRows as $row) {
        $rId = (int)$row['route_id'];
        if (!isset($routesData[$rId])) {
            $routesData[$rId] = [
                'route_id'       => $rId,
                'route_code'     => $row['route_code'],
                'route_name'     => $row['route_name'],
                'start_location' => $row['start_location'],
                'end_location'   => $row['end_location'],
                'fare'           => uniride_ticket_fare(),
                'schedules'      => []
            ];
        }

        $routesData[$rId]['schedules'][] = [
            'schedule_id'          => (int)$row['schedule_id'],
            'schedule_date'        => $row['schedule_date'],
            'departure_time'       => $row['departure_time'],
            'arrival_time'         => $row['arrival_time'],
            'shift_name'           => $row['shift_name'],
            'schedule_status'      => 'SCHEDULED',
            'bus_id'               => (int)$row['bus_id'],
            'registration_number'  => $row['registration_number'],
            'bus_type'             => $row['bus_type'],
            'seat_capacity'        => (int)($row['seat_capacity'] ?? 40),
            'standing_capacity'    => (int)($row['standing_capacity'] ?? 10),
            'booked_seats'         => (int)$row['booked_seats'],
            'booked_standing'      => (int)$row['booked_standing'],
        ];
    }
} catch (Throwable $e) {
    $routeLoadFailed = true;
    error_log('[routes.php] ' . $e->getMessage());
}

pp_render_start(
    'Routes & Schedules',
    'routes',
    'Travel',
    'Browse transport routes and upcoming schedules published by your university.'
);
?>

<style>
    .rs-header-bar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 16px;
        margin-top: 20px;
        margin-bottom: 24px;
        flex-wrap: wrap;
    }
    .rs-search-form {
        display: flex;
        gap: 10px;
        flex: 1;
        max-width: 820px;
        align-items: center;
        flex-wrap: wrap;
    }
    .rs-search-input,
    .rs-date-input {
        padding: 10px 14px;
        border-radius: 8px;
        border: 1px solid var(--ui-line-strong, var(--pp-line-blue));
        background: var(--ui-surface, #ffffff);
        color: var(--ui-ink, var(--pp-ink));
        font-size: 13px;
        box-shadow: 0 4px 14px rgba(11, 47, 97, .035);
    }
    .rs-search-input {
        flex: 1 1 320px;
        min-width: 0;
    }
    .rs-date-input {
        flex: 0 1 170px;
    }
    .rs-search-input::placeholder {
        color: var(--ui-muted-2, var(--pp-muted-2));
    }
    .rs-search-input:focus,
    .rs-date-input:focus {
        outline: none;
        border-color: var(--ui-navy, var(--pp-blue));
        box-shadow: 0 0 0 3px rgba(18, 63, 124, .10);
    }
    
    .rs-route-card {
        background: var(--ui-surface, #ffffff);
        border: 1px solid var(--ui-line, var(--pp-line));
        border-radius: 12px;
        padding: 20px;
        margin-bottom: 24px;
        box-shadow: var(--ui-shadow, 0 10px 30px rgba(11, 47, 97, .055));
    }
    .rs-route-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        gap: 18px;
        border-bottom: 1px solid var(--ui-line, var(--pp-line));
        padding-bottom: 14px;
        margin-bottom: 16px;
    }
    .rs-route-title {
        margin: 0;
        font-size: 18px;
        font-weight: 700;
        color: var(--ui-navy, var(--pp-blue));
    }
    .rs-route-subtitle {
        color: var(--ui-muted, var(--pp-muted));
        font-size: 13px;
        margin-top: 4px;
    }
    .rs-fare-badge {
        background: var(--ui-navy-soft, var(--pp-blue-soft));
        color: var(--ui-navy, var(--pp-blue));
        border: 1px solid var(--ui-line-strong, var(--pp-line-blue));
        padding: 6px 12px;
        border-radius: 20px;
        font-size: 13px;
        font-weight: 700;
    }

    /* Schedules Table */
    .rs-table-container {
        overflow-x: auto;
    }
    .rs-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 13px;
        color: var(--ui-text, var(--pp-ink));
    }
    .rs-table th {
        text-align: left;
        padding: 10px 12px;
        color: var(--ui-muted, var(--pp-muted));
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        border-bottom: 1px solid var(--ui-line, var(--pp-line));
    }
    .rs-table td {
        padding: 12px;
        border-bottom: 1px solid var(--ui-line, var(--pp-line));
        vertical-align: middle;
    }
    .rs-table tr:last-child td {
        border-bottom: none;
    }

    .rs-status-tag {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 4px 10px;
        border-radius: 6px;
        font-size: 11px;
        font-weight: 700;
    }
    .rs-status-avail {
        background: var(--ui-success-bg, #eef8f1);
        color: var(--ui-success, #176536);
        border: 1px solid #cbe2d2;
    }
    .rs-status-full {
        background: var(--ui-warning-bg, #fff8e8);
        color: var(--ui-warning, #8a5a00);
        border: 1px solid #eedda8;
    }

    .rs-no-schedules {
        color: var(--ui-muted, var(--pp-muted));
        font-size: 13px;
        padding: 12px 0;
        font-style: italic;
    }
    .rs-empty-card {
        text-align: center;
        padding: 40px 20px;
    }
    .rs-empty-card h3 {
        color: var(--ui-navy, var(--pp-blue));
        margin: 0 0 8px;
    }
    .rs-empty-card p {
        color: var(--ui-muted, var(--pp-muted));
        font-size: 13px;
        margin: 0;
    }
    .rs-secondary-text {
        color: var(--ui-muted, var(--pp-muted));
    }
    html[data-theme="dark"] .rs-status-avail {
        border-color: #28583c;
    }
    html[data-theme="dark"] .rs-status-full {
        border-color: #5b4c25;
    }
    @media (max-width: 720px) {
        .rs-search-form,
        .rs-search-input,
        .rs-date-input {
            width: 100%;
            max-width: none;
            flex-basis: 100%;
        }
        .rs-route-header {
            align-items: flex-start;
        }
    }
</style>

<!-- Top Search & Filter Bar -->
<div class="rs-header-bar">
    <form method="GET" action="" class="rs-search-form">
        <label class="pp-sr-only" for="routeSearch">Search routes</label>
        <input 
            id="routeSearch"
            type="text" 
            name="q" 
            class="rs-search-input" 
            placeholder="Search by route code, location, or destination..." 
            value="<?= pp_h($searchTerm) ?>"
        >
        <label class="pp-sr-only" for="serviceDate">Service date</label>
        <input
            id="serviceDate"
            type="date"
            name="date"
            class="rs-date-input"
            min="<?= pp_h($today) ?>"
            value="<?= pp_h($selectedDate) ?>"
            required
        >
        <button type="submit" class="pp-primary-button" style="white-space:nowrap; height:38px;">
            Search
        </button>
        <?php if ($searchTerm !== ''): ?>
            <a href="routes.php?date=<?= rawurlencode($selectedDate) ?>" class="pp-secondary-button" style="white-space:nowrap; height:38px; display:inline-flex; align-items:center;">Clear</a>
        <?php endif; ?>
    </form>
</div>

<!-- Routes Listing -->
<?php if (!$fixedScheduleReady): ?>
    <div class="rs-route-card rs-empty-card" role="status">
        <h3>Fixed-shift scheduling setup is required</h3>
        <p>Ask an administrator to import <code>database/migrations/007_fixed_bus_route_shifts.sql</code>.</p>
    </div>
<?php elseif ($routeLoadFailed): ?>
    <div class="rs-route-card rs-empty-card" role="alert">
        <h3>Schedules could not be loaded</h3>
        <p>Please try again. If the problem continues, ask your University Admin to check the application log.</p>
    </div>
<?php elseif (empty($routesData)): ?>
    <div class="rs-route-card rs-empty-card" role="status">
        <h3>No Schedules Found</h3>
        <p>
            <?php if ($searchTerm !== ''): ?>
                No published schedules matched your search for the selected service day.
            <?php elseif ((int)$scheduleVisibility['ineligible_count'] > 0): ?>
                Schedules exist for this date, but none use a bus available for your Passenger type.
            <?php elseif ((int)$scheduleVisibility['departed_count'] > 0): ?>
                All schedules for this service date have already departed.
            <?php elseif ((int)$scheduleVisibility['invalid_shift_count'] > 0): ?>
                Published schedules exist, but their Noon or Evening configuration requires correction.
            <?php else: ?>
                There are no active schedules published for the selected service day.
            <?php endif; ?>
        </p>
    </div>
<?php else: ?>
    <?php foreach ($routesData as $route): ?>
        <div class="rs-route-card">
            <div class="rs-route-header">
                <div>
                    <h3 class="rs-route-title">
                        <?= pp_h($route['route_code']) ?>: <?= pp_h($route['route_name']) ?>
                    </h3>
                    <div class="rs-route-subtitle">
                        📍 <strong><?= pp_h($route['start_location']) ?></strong> → <strong><?= pp_h($route['end_location']) ?></strong>
                    </div>
                </div>
                <div class="rs-fare-badge">
                    BDT <?= pp_h((string)$route['fare']) ?>
                </div>
            </div>

            <!-- Schedule Items for this Route -->
            <?php if (empty($route['schedules'])): ?>
                <div class="rs-no-schedules">
                    No upcoming schedules currently posted for this route.
                </div>
            <?php else: ?>
                <div class="rs-table-container">
                    <table class="rs-table">
                        <thead>
                            <tr>
                                <th>Date & Departure</th>
                                <th>Bus Details</th>
                                <th>Occupancy</th>
                                <th>Status</th>
                                <th style="text-align: right;">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($route['schedules'] as $sch): 
                                $seatCap = $sch['seat_capacity'];
                                $bookedSeats = $sch['booked_seats'];
                                $isFull = ($bookedSeats >= $seatCap);
                                $availSeats = max(0, $seatCap - $bookedSeats);
                            ?>
                                <tr>
                                    <td>
                                        <strong><?= pp_h($sch['schedule_date']) ?></strong><br>
                                        <span class="rs-secondary-text" style="font-size:12px;">🕒 <?= pp_h(uniride_schedule_shift_label($sch['shift_name'], $sch['departure_time'])) ?> · <?= pp_h($sch['departure_time']) ?></span>
                                    </td>
                                    <td>
                                        <strong>Bus #<?= (int)$sch['bus_id'] ?> · <?= pp_h($sch['registration_number']) ?></strong><br>
                                        <span class="rs-secondary-text" style="font-size:11px;"><?= pp_h($sch['bus_type']) ?></span>
                                    </td>
                                    <td>
                                        <strong><?= $bookedSeats ?> / <?= $seatCap ?></strong> Seats Booked<br>
                                        <span class="rs-secondary-text" style="font-size:11px;"><?= $sch['booked_standing'] ?> / <?= $sch['standing_capacity'] ?> Standing Booked</span>
                                    </td>
                                    <td>
                                        <?php if ($isFull): ?>
                                            <span class="rs-status-tag rs-status-full">Standing Only</span>
                                        <?php else: ?>
                                            <span class="rs-status-tag rs-status-avail"><?= $availSeats ?> Seats Available</span>
                                        <?php endif; ?>
                                    </td>
                                    <td style="text-align: right;">
                                        <a href="book-ticket.php?date=<?= rawurlencode($selectedDate) ?>&amp;schedule_id=<?= $sch['schedule_id'] ?>" class="pp-primary-button" style="font-size:12px; padding:6px 14px; display:inline-flex;">
                                            Book Ticket
                                        </a>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </div>
    <?php endforeach; ?>
<?php endif; ?>

<?php
pp_render_end();
