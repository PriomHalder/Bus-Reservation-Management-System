<?php
declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| UniRide — Shared dashboard helpers
|--------------------------------------------------------------------------
| Phase 1. Used by:
|   passenger/dashboard.php
|   university/dashboard.php
|   admin/dashboard.php
|
| Design rules honoured here:
|   - Every parameterised query uses PDO prepared statements.
|   - No query is ever built by concatenating request data.
|   - A failed query is logged with error_log() and degrades to a safe
|     default. It never leaks SQL, credentials or a stack trace.
|   - Nothing about the schema is assumed. Optional tables are probed
|     once per request against information_schema before being queried.
|
| NOTE ON THE TWO v_* OBJECTS
| uniride2.sql ships `v_schedule_availability` and
| `v_university_dashboard_stats` as bodyless `CREATE TABLE` stubs, which is
| what phpMyAdmin emits when it cannot dump a view definition. If they were
| imported that way they are permanently empty InnoDB tables, so probing
| for their existence would succeed while every SELECT returned zero rows.
| These helpers therefore never read the v_* objects. All availability and
| occupancy figures are computed from the base tables instead.
*/

// ---------------------------------------------------------------------
// Schema introspection (cached per request)
// ---------------------------------------------------------------------

/**
 * Does a base table exist in the connected database?
 *
 * Results are memoised so a dashboard rendering a dozen panels only pays
 * for one information_schema lookup per distinct table name.
 */
function db_table_exists(PDO $pdo, string $table): bool
{
    static $cache = [];

    if (array_key_exists($table, $cache)) {
        return $cache[$table];
    }

    try {
        $stmt = $pdo->prepare(
            "SELECT COUNT(*)
               FROM information_schema.tables
              WHERE table_schema = DATABASE()
                AND table_name = ?"
        );
        $stmt->execute([$table]);
        $cache[$table] = ((int)$stmt->fetchColumn() > 0);
    } catch (Throwable $e) {
        error_log('[UniRide schema] table probe failed for ' . $table . ': ' . $e->getMessage());
        $cache[$table] = false;
    }

    return $cache[$table];
}

/**
 * Does a column exist on a table? Guards the panels whose column names
 * differ between schema revisions.
 */
function db_column_exists(PDO $pdo, string $table, string $column): bool
{
    static $cache = [];
    $key = $table . '.' . $column;

    if (array_key_exists($key, $cache)) {
        return $cache[$key];
    }

    try {
        $stmt = $pdo->prepare(
            "SELECT COUNT(*)
               FROM information_schema.columns
              WHERE table_schema = DATABASE()
                AND table_name = ?
                AND column_name = ?"
        );
        $stmt->execute([$table, $column]);
        $cache[$key] = ((int)$stmt->fetchColumn() > 0);
    } catch (Throwable $e) {
        error_log('[UniRide schema] column probe failed for ' . $key . ': ' . $e->getMessage());
        $cache[$key] = false;
    }

    return $cache[$key];
}

/** True only when every named table is present. */
function db_tables_exist(PDO $pdo, array $tables): bool
{
    foreach ($tables as $table) {
        if (!db_table_exists($pdo, $table)) {
            return false;
        }
    }

    return true;
}

// ---------------------------------------------------------------------
// Migration-gated features
// ---------------------------------------------------------------------

/*
| Four tables arrive with database/migrations/001_add_missing_dashboard_tables.sql
| rather than with uniride2.sql: semester_bills, ticket_transfers,
| route_stops and booking_status_history.
|
| The panels that read them must behave correctly in three separate
| situations, which are easy to confuse:
|
|   table absent   -> the migration has not been imported. Say so, and for
|                     an admin say which file fixes it. This is a setup
|                     step, not an error.
|   table present,
|   no rows        -> ordinary empty state. Nothing is wrong.
|   query failed   -> logged via error_log(); the panel shows the same
|                     empty state, because a passenger cannot act on a
|                     database fault and should not be shown one.
|
| Collapsing the first case into the second is the trap: the panel silently
| vanishes and there is nothing on screen to explain why.
*/

/** Which tables a named dashboard feature depends on. */
function feature_tables(string $feature): array
{
    return match ($feature) {
        'billing'        => ['semester_bills'],
        'transfers'      => ['ticket_transfers'],
        'route_stops'    => ['route_stops'],
        'status_history' => ['booking_status_history'],
        default          => [],
    };
}

/**
 * Tables this feature needs that are not in the database yet.
 * Empty array means the feature is ready to query.
 */
function feature_missing(PDO $pdo, string $feature): array
{
    $missing = [];

    foreach (feature_tables($feature) as $table) {
        if (!db_table_exists($pdo, $table)) {
            $missing[] = $table;
        }
    }

    return $missing;
}

function feature_ready(PDO $pdo, string $feature): bool
{
    return feature_missing($pdo, $feature) === [];
}

/**
 * The "not set up yet" message for a feature whose tables are absent.
 *
 * $technical is true for the two admin roles, who can act on the
 * information. A passenger gets the plain sentence and no file path —
 * naming a migration script to a student is noise, and the spec is explicit
 * that interface messages stay clean.
 *
 * Returns '' when the feature is ready, so callers can treat a non-empty
 * return as "render this instead of the panel body".
 */
function setup_notice(PDO $pdo, string $feature, bool $technical = false): string
{
    $missing = feature_missing($pdo, $feature);

    if ($missing === []) {
        return '';
    }

    $label = match ($feature) {
        'billing'        => 'Semester billing',
        'transfers'      => 'Ticket transfers',
        'route_stops'    => 'Route stops',
        'status_history' => 'Booking history',
        default          => 'This feature',
    };

    if (!$technical) {
        return '<p class="notice">' . h($label) .
               ' is not available yet. Please check back once your university has finished setting it up.</p>';
    }

    $tables = implode(', ', array_map(
        static fn (string $t): string => '<code>' . h($t) . '</code>',
        $missing
    ));

    return '<p class="notice">' . h($label) . ' needs a database table that has not been created yet (' .
           $tables . '). Import <code>database/migrations/001_add_missing_dashboard_tables.sql</code> ' .
           'through phpMyAdmin to enable this panel. Nothing else on this dashboard is affected.</p>';
}

/**
 * The operations-facing counterpart to setup_notice().
 *
 * setup_notice($pdo, $feature, true) names the missing table and the
 * migration file. That is right for a system administrator, who is the
 * person who can import it, and wrong for everyone else: a transport
 * officer cannot run a migration and should never be shown a table name, a
 * file path or an SQLSTATE. This returns the plain sentence instead and
 * leaves the technical detail in the error log, where it is useful.
 *
 * Returns '' when the feature is ready, so callers can treat a non-empty
 * return as "render this instead of the panel body" — the same contract as
 * setup_notice().
 */
function unavailable_notice(PDO $pdo, string $feature): string
{
    $missing = feature_missing($pdo, $feature);

    if ($missing === []) {
        return '';
    }

    error_log(
        '[UniRide dashboard] feature "' . $feature . '" is unavailable; missing table(s): '
        . implode(', ', $missing)
    );

    return '<p class="notice">This feature has not been configured yet.</p>';
}

// ---------------------------------------------------------------------
// Safe query wrappers
// ---------------------------------------------------------------------

/**
 * Single scalar value, or $default when the query cannot run.
 */
function dash_scalar(PDO $pdo, string $sql, array $params = [], mixed $default = 0): mixed
{
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $value = $stmt->fetchColumn();

        return $value === false || $value === null ? $default : $value;
    } catch (Throwable $e) {
        error_log('[UniRide dashboard] scalar query failed: ' . $e->getMessage());

        return $default;
    }
}

function dash_int(PDO $pdo, string $sql, array $params = []): int
{
    return (int)dash_scalar($pdo, $sql, $params, 0);
}

function dash_float(PDO $pdo, string $sql, array $params = []): float
{
    return (float)dash_scalar($pdo, $sql, $params, 0.0);
}

/**
 * Result set, or [] when the query cannot run. Callers can therefore
 * treat an error and a genuinely empty table identically and render the
 * same empty state.
 */
function dash_rows(PDO $pdo, string $sql, array $params = []): array
{
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    } catch (Throwable $e) {
        error_log('[UniRide dashboard] row query failed: ' . $e->getMessage());

        return [];
    }
}

/** Single row, or null. */
function dash_row(PDO $pdo, string $sql, array $params = []): ?array
{
    $rows = dash_rows($pdo, $sql . ' LIMIT 1', $params);

    return $rows[0] ?? null;
}

// ---------------------------------------------------------------------
// Seating model
// ---------------------------------------------------------------------

/** The project's fixed bus layout: 10 rows of 4, labelled A1..J4. */
const UNIRIDE_SEATS_PER_ROW = 4;

/**
 * Convert a stored integer seat number into the project's 10-row,
 * 4-across label. bookings.seat_number is an INT, so seat 1 is A1,
 * seat 5 is B1 and seat 40 is J4.
 */
function seat_label(?int $seatNumber): string
{
    if ($seatNumber === null || $seatNumber < 1) {
        return '—';
    }

    $row = intdiv($seatNumber - 1, UNIRIDE_SEATS_PER_ROW);
    $pos = (($seatNumber - 1) % UNIRIDE_SEATS_PER_ROW) + 1;

    return chr(65 + $row) . $pos;
}

/**
 * Human label for whichever slot a booking actually holds.
 * A booking is either a numbered seat or a numbered standing slot.
 */
function slot_label(array $booking): string
{
    $type = strtoupper((string)($booking['slot_type'] ?? ''));

    if ($type === 'STANDING') {
        $slot = $booking['standing_slot'] ?? null;

        return $slot === null ? 'Standing' : 'Standing ' . (int)$slot;
    }

    return seat_label(isset($booking['seat_number']) ? (int)$booking['seat_number'] : null);
}

/**
 * Which bus_type values this passenger may travel on.
 * Matches the live enum: 'STANDARD','STUDENT_ONLY','FACULTY_ONLY'.
 */
function eligible_bus_types(string $passengerType): array
{
    return strtoupper($passengerType) === 'FACULTY'
        ? ['STANDARD', 'FACULTY_ONLY']
        : ['STANDARD', 'STUDENT_ONLY'];
}

// ---------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------

/** Taka amount, no decimals — matches the homepage treatment. */
function bdt(float|int|string|null $amount): string
{
    return '৳' . number_format((float)$amount);
}

/** Taka amount with poisha, for billing rows. */
function bdt_exact(float|int|string|null $amount): string
{
    return '৳' . number_format((float)$amount, 2);
}

function fmt_time(?string $time): string
{
    if (!$time) {
        return '—';
    }

    $ts = strtotime($time);

    return $ts === false ? '—' : date('g:i A', $ts);
}

function fmt_date(?string $date): string
{
    if (!$date) {
        return '—';
    }

    $ts = strtotime($date);

    return $ts === false ? '—' : date('j M Y', $ts);
}

function fmt_datetime(?string $value): string
{
    if (!$value) {
        return '—';
    }

    $ts = strtotime($value);

    return $ts === false ? '—' : date('j M Y, g:i A', $ts);
}

/**
 * Relative time for notification lists, falling back to a date once the
 * item is more than a week old.
 */
function fmt_ago(?string $value): string
{
    if (!$value) {
        return '';
    }

    $ts = strtotime($value);

    if ($ts === false) {
        return '';
    }

    $diff = time() - $ts;

    if ($diff < 60) {
        return 'just now';
    }

    if ($diff < 3600) {
        $m = intdiv($diff, 60);

        return $m . ($m === 1 ? ' minute ago' : ' minutes ago');
    }

    if ($diff < 86400) {
        $h = intdiv($diff, 3600);

        return $h . ($h === 1 ? ' hour ago' : ' hours ago');
    }

    if ($diff < 604800) {
        $d = intdiv($diff, 86400);

        return $d . ($d === 1 ? ' day ago' : ' days ago');
    }

    return date('j M Y', $ts);
}

/** Integer percentage, divide-by-zero safe. */
function pct(int|float $numerator, int|float $denominator): int
{
    if ($denominator <= 0) {
        return 0;
    }

    return (int)round(($numerator / $denominator) * 100);
}

/**
 * Render a value that is ALREADY a percentage as a display string.
 *
 * The distinction from pct() matters: pct() divides two raw figures to
 * produce a percentage, while this one only rounds and labels a percentage
 * that has already been worked out. Passing an existing percentage to
 * pct() is a mistake, and because pct() has two required parameters that
 * mistake is a fatal ArgumentCountError rather than a wrong number — which
 * is exactly how it should behave.
 *
 * Kept separate rather than giving pct() a default denominator, because a
 * default of 100 would silently accept the mixed-up call.
 */
function pct_label(int|float $percent): string
{
    return (int)round($percent) . '%';
}

/**
 * Map a domain status onto a badge tone. Anything unrecognised renders
 * neutral rather than breaking the layout.
 */
function status_tone(?string $status): string
{
    return match (strtoupper((string)$status)) {
        'CONFIRMED', 'ACTIVE', 'COMPLETED', 'RESOLVED', 'PAID', 'ACCEPTED'
            => 'is-good',
        'BOOKED', 'SCHEDULED', 'IN_PROGRESS', 'PENDING', 'TRANSFER_PENDING', 'PARTIAL'
            => 'is-warn',
        'CANCELLED', 'INACTIVE', 'SUSPENDED', 'MAINTENANCE', 'OPEN', 'UNPAID', 'REJECTED', 'EXPIRED'
            => 'is-bad',
        default
            => '',
    };
}

/** Turn CONFIRMED / TRANSFER_PENDING into Confirmed / Transfer pending. */
function status_text(?string $status): string
{
    $clean = str_replace('_', ' ', strtolower((string)$status));

    return $clean === '' ? '—' : ucfirst($clean);
}

/** Badge markup. Escapes its own content. */
function status_badge(?string $status): string
{
    $tone = status_tone($status);
    $class = 'badge' . ($tone !== '' ? ' ' . $tone : '');

    return '<span class="' . $class . '">' . h(status_text($status)) . '</span>';
}

// ---------------------------------------------------------------------
// Occupancy
// ---------------------------------------------------------------------

/**
 * Statuses that still hold a slot on a bus. A cancelled booking frees its
 * seat; a completed trip has already consumed it, so neither counts
 * toward current load.
 */
function active_booking_statuses(): array
{
    return ['BOOKED', 'CONFIRMED', 'TRANSFER_PENDING'];
}

/**
 * Build the "?,?,?" fragment and matching bindings for an IN () clause.
 *
 * The placeholder string is derived purely from the count of values, so
 * no caller-supplied text ever reaches the SQL. Values stay bound.
 *
 * @return array{0:string,1:array}
 */
function in_clause(array $values): array
{
    if ($values === []) {
        // Guarantees a false predicate instead of invalid "IN ()".
        return ['NULL', []];
    }

    return [implode(',', array_fill(0, count($values), '?')), array_values($values)];
}

/**
 * Per-schedule seat and standing load, computed from bookings against the
 * capacities stored on the bus row. Capacities are never hard-coded to
 * 40/10 — the bus record is the source of truth.
 *
 * Returns keys: booked_seats, booked_standing, seat_capacity,
 * standing_capacity, available_seats, available_standing,
 * seat_occupancy_percent, total_load.
 */
function schedule_load(PDO $pdo, int $scheduleId): array
{
    [$statusIn, $statusParams] = in_clause(active_booking_statuses());

    $row = dash_row(
        $pdo,
        "SELECT
             b.seat_capacity,
             b.standing_capacity,
             COALESCE(SUM(bk.slot_type = 'SEAT'), 0)     AS booked_seats,
             COALESCE(SUM(bk.slot_type = 'STANDING'), 0) AS booked_standing
           FROM schedules s
           JOIN buses b ON b.bus_id = s.bus_id
           LEFT JOIN bookings bk
                  ON bk.schedule_id = s.schedule_id
                 AND bk.status IN ($statusIn)
          WHERE s.schedule_id = ?
          GROUP BY s.schedule_id, b.seat_capacity, b.standing_capacity",
        array_merge($statusParams, [$scheduleId])
    );

    return normalise_load($row);
}

/**
 * Shape a raw capacity/booked row into the full derived set. Shared by
 * schedule_load() and the batched schedule listings so both present
 * identical keys.
 */
function normalise_load(?array $row): array
{
    $seatCapacity     = (int)($row['seat_capacity'] ?? 0);
    $standingCapacity = (int)($row['standing_capacity'] ?? 0);
    $bookedSeats      = (int)($row['booked_seats'] ?? 0);
    $bookedStanding   = (int)($row['booked_standing'] ?? 0);

    return [
        'seat_capacity'          => $seatCapacity,
        'standing_capacity'      => $standingCapacity,
        'booked_seats'           => $bookedSeats,
        'booked_standing'        => $bookedStanding,
        'available_seats'        => max(0, $seatCapacity - $bookedSeats),
        'available_standing'     => max(0, $standingCapacity - $bookedStanding),
        'seat_occupancy_percent' => pct($bookedSeats, $seatCapacity),
        'total_load'             => $bookedSeats + $bookedStanding,
    ];
}
