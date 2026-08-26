<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

// Search query handling
$searchTerm = trim((string)($_GET['q'] ?? ''));

// Fetch Routes & Upcoming Schedules for Passenger's University
$routesData = [];
try {
    $sql = "
        SELECT 
            r.route_id,
            r.route_code,
            r.route_name,
            r.start_location,
            r.end_location,
            r.fare,
            s.schedule_id,
            s.schedule_date,
            s.departure_time,
            s.arrival_time,
            s.status AS schedule_status,
            b.registration_number,
            b.bus_type,
            b.seat_capacity,
            b.standing_capacity,
            (
                SELECT COUNT(*) 
                FROM bookings bk 
                WHERE bk.schedule_id = s.schedule_id 
                  AND bk.status IN ('BOOKED', 'CONFIRMED', 'TRANSFER_PENDING')
            ) AS booked_count
        FROM routes r
        LEFT JOIN schedules s ON s.route_id = r.route_id 
            AND s.status = 'SCHEDULED'
            AND s.schedule_date >= CURDATE()
            AND EXISTS (
                SELECT 1
                FROM buses eligible_bus
                WHERE eligible_bus.bus_id=s.bus_id
                  AND eligible_bus.status='ACTIVE'
                  AND (
                      eligible_bus.bus_type='STANDARD'
                      OR (?='STUDENT' AND eligible_bus.bus_type='STUDENT_ONLY')
                      OR (?='FACULTY' AND eligible_bus.bus_type='FACULTY_ONLY')
                  )
            )
        LEFT JOIN buses b ON b.bus_id = s.bus_id
        WHERE r.university_id = ?
          AND r.status = 'ACTIVE'
    ";

    $params = [
        (string)$ppProfile['passenger_type'],
        (string)$ppProfile['passenger_type'],
        $ppUniversityId,
    ];

    if ($searchTerm !== '') {
        $sql .= " AND (r.route_code LIKE ? OR r.route_name LIKE ? OR r.start_location LIKE ? OR r.end_location LIKE ?)";
        $like = '%' . $searchTerm . '%';
        $params[] = $like;
        $params[] = $like;
        $params[] = $like;
        $params[] = $like;
    }

    $sql .= " ORDER BY r.route_code ASC, s.schedule_date ASC, s.departure_time ASC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($rows as $row) {
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

        if ($row['schedule_id']) {
            $routesData[$rId]['schedules'][] = [
                'schedule_id'         => (int)$row['schedule_id'],
                'schedule_date'       => $row['schedule_date'],
                'departure_time'     => $row['departure_time'],
                'arrival_time'       => $row['arrival_time'],
                'schedule_status'    => $row['schedule_status'],
                'registration_number' => $row['registration_number'],
                'bus_type'            => $row['bus_type'],
                'seat_capacity'       => (int)($row['seat_capacity'] ?? 40),
                'standing_capacity'   => (int)($row['standing_capacity'] ?? 10),
                'booked_count'        => (int)$row['booked_count']
            ];
        }
    }
} catch (PDOException $e) {
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
        max-width: 480px;
    }
    .rs-search-input {
        width: 100%;
        padding: 10px 14px;
        border-radius: 8px;
        border: 1px solid #334155;
        background: #0f172a;
        color: #f8fafc;
        font-size: 13px;
    }
    .rs-search-input:focus {
        outline: none;
        border-color: #0284c7;
    }
    
    .rs-route-card {
        background: rgba(15, 23, 42, 0.75);
        border: 1px solid #1e293b;
        border-radius: 12px;
        padding: 20px;
        margin-bottom: 24px;
    }
    .rs-route-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        border-bottom: 1px solid #334155;
        padding-bottom: 14px;
        margin-bottom: 16px;
    }
    .rs-route-title {
        margin: 0;
        font-size: 18px;
        font-weight: 700;
        color: #f8fafc;
    }
    .rs-route-subtitle {
        color: #94a3b8;
        font-size: 13px;
        margin-top: 4px;
    }
    .rs-fare-badge {
        background: rgba(2, 132, 199, 0.15);
        color: #38bdf8;
        border: 1px solid rgba(56, 189, 248, 0.3);
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
        color: #e2e8f0;
    }
    .rs-table th {
        text-align: left;
        padding: 10px 12px;
        color: #94a3b8;
        font-size: 11px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        border-bottom: 1px solid #334155;
    }
    .rs-table td {
        padding: 12px;
        border-bottom: 1px solid #1e293b;
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
    .rs-status-avail { background: rgba(22, 163, 74, 0.2); color: #4ade80; border: 1px solid rgba(74, 222, 128, 0.3); }
    .rs-status-full { background: rgba(239, 68, 68, 0.2); color: #f87171; border: 1px solid rgba(248, 113, 113, 0.3); }

    .rs-no-schedules {
        color: #64748b;
        font-size: 13px;
        padding: 12px 0;
        font-style: italic;
    }
</style>

<!-- Top Search & Filter Bar -->
<div class="rs-header-bar">
    <form method="GET" action="" class="rs-search-form">
        <input 
            type="text" 
            name="q" 
            class="rs-search-input" 
            placeholder="Search by route code, location, or destination..." 
            value="<?= pp_h($searchTerm) ?>"
        >
        <button type="submit" class="pp-primary-button" style="white-space:nowrap; height:38px;">
            Search
        </button>
        <?php if ($searchTerm !== ''): ?>
            <a href="routes.php" class="pp-secondary-button" style="white-space:nowrap; height:38px; display:inline-flex; align-items:center;">Clear</a>
        <?php endif; ?>
    </form>
</div>

<!-- Routes Listing -->
<?php if (empty($routesData)): ?>
    <div class="rs-route-card" style="text-align: center; padding: 40px 20px;">
        <h3 style="color:#f8fafc; margin: 0 0 8px;">No Routes Found</h3>
        <p style="color:#94a3b8; font-size:13px; margin:0;">
            <?= $searchTerm !== '' ? 'No transport routes matched your query.' : 'There are currently no active routes published for your university.' ?>
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
                                $booked = $sch['booked_count'];
                                $isFull = ($booked >= $seatCap);
                                $availSeats = max(0, $seatCap - $booked);
                            ?>
                                <tr>
                                    <td>
                                        <strong><?= pp_h($sch['schedule_date']) ?></strong><br>
                                        <span style="color:#94a3b8; font-size:12px;">🕒 <?= pp_h($sch['departure_time']) ?></span>
                                    </td>
                                    <td>
                                        <strong><?= pp_h($sch['registration_number']) ?></strong><br>
                                        <span style="color:#94a3b8; font-size:11px;"><?= pp_h($sch['bus_type']) ?></span>
                                    </td>
                                    <td>
                                        <strong><?= $booked ?> / <?= $seatCap ?></strong> Seats Booked<br>
                                        <span style="color:#64748b; font-size:11px;"><?= $sch['standing_capacity'] ?> Standing Slots</span>
                                    </td>
                                    <td>
                                        <?php if ($isFull): ?>
                                            <span class="rs-status-tag rs-status-full">Standing Only</span>
                                        <?php else: ?>
                                            <span class="rs-status-tag rs-status-avail"><?= $availSeats ?> Seats Available</span>
                                        <?php endif; ?>
                                    </td>
                                    <td style="text-align: right;">
                                        <a href="book-ticket.php?schedule_id=<?= $sch['schedule_id'] ?>" class="pp-primary-button" style="font-size:12px; padding:6px 14px; display:inline-flex;">
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
