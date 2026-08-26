<?php
declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| UniRide — Schema check
|--------------------------------------------------------------------------
| A read-only diagnostic page. It answers, in one screen:
|
|   * Did migrations 000 and 001 actually import?
|   * Does every table have a primary key, an auto-increment id and the
|     foreign keys the dashboards assume?
|   * Do the column names the PHP uses match the real database?
|   * Which enum values are genuinely in use, as opposed to declared?
|   * Are there integrity problems in the data — duplicate passengers,
|     double-booked buses, orphan rows, cross-university bookings?
|
| WHY THIS FILE EXISTS
| --------------------
| The spec's database-first rule says to inspect the live schema with
| SHOW TABLES / DESCRIBE before writing queries, and never to assume a
| column name. This page is that inspection, performed by the application
| against the database it is actually connected to, so the answer reflects
| your machine rather than a dump someone read once.
|
| SAFETY
| ------
| - Read-only. Nothing here writes, alters or drops anything.
| - Gated to SYSTEM_ADMIN. A passenger or university admin gets the 403.
| - Every value is bound. The only identifiers interpolated into SQL are
|   table and column names that information_schema just handed back, and
|   even those go through qi(), which refuses anything that is not a plain
|   identifier.
| - Driver error text is shown, because a platform administrator debugging
|   their own import needs it. No stack trace, connection string or
|   credential is ever printed, and every failure is also written to the
|   PHP error log.
|
| Open it at:  http://localhost/uniridedummy/tools/schema_check.php
*/

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/dashboard_helpers.php';

$BASE = '..';

requireRole('SYSTEM_ADMIN', $BASE);

// ---------------------------------------------------------------------
// Identifier and query safety
// ---------------------------------------------------------------------

/**
 * Backtick-quote an identifier, refusing anything that is not a plain
 * name. Only ever called with names read back from information_schema,
 * so this is a second line of defence rather than the first.
 */
function qi(string $name): string
{
    if (preg_match('/\A[A-Za-z0-9_$]+\z/', $name) !== 1) {
        throw new RuntimeException('Unsafe identifier refused');
    }

    return '`' . $name . '`';
}

/** Collects failures so the page can list them instead of dying. */
function sc_errors(?string $message = null): array
{
    static $errors = [];

    if ($message !== null) {
        $errors[] = $message;
        error_log('[UniRide schema_check] ' . $message);
    }

    return $errors;
}

/**
 * Fetch rows with every column key lower-cased.
 *
 * This is not tidiness. information_schema declares its columns in upper
 * case, and a MySQL result set labels a plain column reference with the name
 * from the table definition rather than the text you typed — so
 * "SELECT table_name FROM information_schema.tables" can come back keyed
 * TABLE_NAME on one server and table_name on another, depending on version
 * and driver. Reading $r['table_name'] against an upper-case key would find
 * nothing, and this page would then report every single table as missing:
 * a total false alarm that looks exactly like a failed import.
 *
 * Normalising here fixes it once for every query on the page. It is safe for
 * the non-information_schema queries too, because each of those already
 * aliases its columns in lower case.
 */
function sc_rows(PDO $pdo, string $sql, array $params = [], string $label = 'query'): array
{
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        return array_map(
            static fn (array $row): array => array_change_key_case($row, CASE_LOWER),
            $stmt->fetchAll()
        );
    } catch (Throwable $e) {
        sc_errors($label . ' — ' . $e->getMessage());

        return [];
    }
}

/** Scalar probe. Returns null when the query could not run at all, which
 *  is different from a genuine zero and is rendered differently. */
function sc_scalar(PDO $pdo, string $sql, array $params = [], string $label = 'query'): ?string
{
    try {
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $value = $stmt->fetchColumn();

        return $value === false ? null : (string)$value;
    } catch (Throwable $e) {
        sc_errors($label . ' — ' . $e->getMessage());

        return null;
    }
}

function sc_int(PDO $pdo, string $sql, array $params = [], string $label = 'query'): ?int
{
    $value = sc_scalar($pdo, $sql, $params, $label);

    return $value === null ? null : (int)$value;
}

// ---------------------------------------------------------------------
// 1. Environment
// ---------------------------------------------------------------------

/**
 * Read a PDO attribute without letting an unsupported one take the page
 * down. Not every driver implements every attribute, and with
 * ERRMODE_EXCEPTION an unsupported read throws — which on a default XAMPP
 * install (display_errors On) would print a stack trace containing absolute
 * filesystem paths. A diagnostic page must never be the thing that leaks.
 */
function sc_attr(PDO $pdo, int $attribute, mixed $fallback = null): mixed
{
    try {
        return $pdo->getAttribute($attribute);
    } catch (Throwable $e) {
        return $fallback;
    }
}

$serverVersion  = (string)(sc_attr($pdo, PDO::ATTR_SERVER_VERSION, '') ?? '');
$driverName     = (string)(sc_attr($pdo, PDO::ATTR_DRIVER_NAME, '') ?? '');
$emulatePrepare = (bool)sc_attr($pdo, PDO::ATTR_EMULATE_PREPARES, false);
$currentDb      = (string)(sc_scalar($pdo, 'SELECT DATABASE()', [], 'current database') ?? '');
$sqlMode        = (string)(sc_scalar($pdo, 'SELECT @@sql_mode', [], 'sql_mode') ?? '');
$onlyFullGroup  = str_contains(strtoupper($sqlMode), 'ONLY_FULL_GROUP_BY');

// ---------------------------------------------------------------------
// 2. What the database actually contains
// ---------------------------------------------------------------------

$tableRows = sc_rows(
    $pdo,
    "SELECT table_name, table_type, engine, table_rows, table_collation
       FROM information_schema.tables
      WHERE table_schema = DATABASE()
      ORDER BY table_type, table_name",
    [],
    'table inventory'
);

$tables = [];      // name => meta
foreach ($tableRows as $r) {
    $tables[(string)$r['table_name']] = $r;
}

$columnRows = sc_rows(
    $pdo,
    "SELECT table_name, column_name, column_type, data_type, is_nullable,
            column_key, extra, column_default
       FROM information_schema.columns
      WHERE table_schema = DATABASE()
      ORDER BY table_name, ordinal_position",
    [],
    'column inventory'
);

$columns   = [];   // table => column => meta
$pkColumn  = [];   // table => single PK column, when there is exactly one
$pkCount   = [];   // table => number of PK columns
$autoInc   = [];   // table => auto-increment column

foreach ($columnRows as $r) {
    $t = (string)$r['table_name'];
    $c = (string)$r['column_name'];

    $columns[$t][$c] = $r;

    if ((string)$r['column_key'] === 'PRI') {
        $pkCount[$t] = ($pkCount[$t] ?? 0) + 1;
        $pkColumn[$t] = $c;
    }

    if (str_contains((string)$r['extra'], 'auto_increment')) {
        $autoInc[$t] = $c;
    }
}

// A composite primary key has no single column, so forget the guess.
foreach ($pkCount as $t => $n) {
    if ($n > 1) {
        unset($pkColumn[$t]);
    }
}

$fkRows = sc_rows(
    $pdo,
    "SELECT kcu.table_name, kcu.column_name, kcu.constraint_name,
            kcu.referenced_table_name, kcu.referenced_column_name,
            rc.delete_rule, rc.update_rule
       FROM information_schema.key_column_usage kcu
       JOIN information_schema.referential_constraints rc
         ON rc.constraint_schema = kcu.constraint_schema
        AND rc.constraint_name   = kcu.constraint_name
      WHERE kcu.table_schema = DATABASE()
        AND kcu.referenced_table_name IS NOT NULL
      ORDER BY kcu.table_name, kcu.constraint_name",
    [],
    'foreign keys'
);

$fkByTable  = [];   // table => rows
$fkByColumn = [];   // "table.column" => row
foreach ($fkRows as $r) {
    $t = (string)$r['table_name'];
    $fkByTable[$t][] = $r;
    $fkByColumn[$t . '.' . (string)$r['column_name']] = $r;
}

$indexRows = sc_rows(
    $pdo,
    "SELECT table_name, index_name, non_unique,
            GROUP_CONCAT(column_name ORDER BY seq_in_index SEPARATOR ', ') AS cols
       FROM information_schema.statistics
      WHERE table_schema = DATABASE()
      GROUP BY table_name, index_name, non_unique
      ORDER BY table_name, index_name",
    [],
    'indexes'
);

$indexByTable = [];
foreach ($indexRows as $r) {
    $indexByTable[(string)$r['table_name']][] = $r;
}

$routineRows = sc_rows(
    $pdo,
    "SELECT routine_name, routine_type
       FROM information_schema.routines
      WHERE routine_schema = DATABASE()
      ORDER BY routine_type, routine_name",
    [],
    'routines'
);

$routines = [];
foreach ($routineRows as $r) {
    $routines[(string)$r['routine_name']] = (string)$r['routine_type'];
}

$triggerRows = sc_rows(
    $pdo,
    "SELECT trigger_name, event_object_table, action_timing, event_manipulation
       FROM information_schema.triggers
      WHERE trigger_schema = DATABASE()
      ORDER BY event_object_table, trigger_name",
    [],
    'triggers'
);

$triggers = [];
foreach ($triggerRows as $r) {
    $triggers[(string)$r['trigger_name']] = $r;
}

// Exact row counts. table_rows from information_schema is an InnoDB
// estimate and is routinely wrong by a wide margin, so count properly.
$rowCount = [];
foreach ($tables as $name => $meta) {
    try {
        $rowCount[$name] = (int)$pdo->query('SELECT COUNT(*) FROM ' . qi($name))->fetchColumn();
    } catch (Throwable $e) {
        sc_errors('row count for ' . $name . ' — ' . $e->getMessage());
        $rowCount[$name] = null;
    }
}

// ---------------------------------------------------------------------
// 3. What the application expects
// ---------------------------------------------------------------------

/** table => the file that creates it. */
$expectedTables = [
    'universities'           => 'uniride2.sql',
    'passengers'             => 'uniride2.sql',
    'students'               => 'uniride2.sql',
    'faculty'                => 'uniride2.sql',
    'university_users'       => 'uniride2.sql',
    'admins'                 => 'uniride2.sql',
    'buses'                  => 'uniride2.sql',
    'routes'                 => 'uniride2.sql',
    'bus_route_assignments'  => 'uniride2.sql',
    'schedules'              => 'uniride2.sql',
    'bookings'               => 'uniride2.sql',
    'semesters'              => 'uniride2.sql',
    'billing_transactions'   => 'uniride2.sql',
    'notifications'          => 'uniride2.sql',
    'complaints'             => 'uniride2.sql',
    'favorite_routes'        => 'uniride2.sql',
    'password_reset_tokens'  => 'database/password_reset_tokens.sql',
    'semester_bills'         => 'database/migrations/001_add_missing_dashboard_tables.sql',
    'ticket_transfers'       => 'database/migrations/001_add_missing_dashboard_tables.sql',
    'route_stops'            => 'database/migrations/001_add_missing_dashboard_tables.sql',
    'booking_status_history' => 'database/migrations/001_add_missing_dashboard_tables.sql',
    'announcements'          => 'database/migrations/003_shared_dashboard_tenancy.sql',
    'user_profiles'          => 'database/migrations/004_shared_profile_management.sql',
    'user_notification_preferences' => 'database/migrations/004_shared_profile_management.sql',
    'user_sessions'          => 'database/migrations/004_shared_profile_management.sql',
    'user_security_events'   => 'database/migrations/004_shared_profile_management.sql',
];

/**
 * The two v_* objects ship in uniride2.sql as bodyless CREATE TABLE stubs,
 * which is what phpMyAdmin emits when it cannot dump a view definition.
 * Imported that way they are permanently empty tables that every SELECT
 * reads as zero rows. Migration 001 drops the stubs and creates real
 * views, so "is it a VIEW" is the question worth asking here.
 */
$expectedViews = ['v_schedule_availability', 'v_university_dashboard_stats'];

/** [table, column, why the application cares]. */
$expectedColumns = [
    ['buses', 'seat_capacity', 'Occupancy is read from the bus row. Nothing is hard-coded to 40.'],
    ['buses', 'standing_capacity', 'Standing slots per bus.'],
    ['buses', 'bus_type', 'Decides who may board: STANDARD, STUDENT_ONLY or FACULTY_ONLY.'],
    ['bookings', 'slot_type', 'SEAT or STANDING.'],
    ['bookings', 'seat_number', 'Integer seat; rendered A1..J4 by seat_label().'],
    ['bookings', 'standing_slot', 'Numbered standing slot.'],
    ['bookings', 'booking_reference', 'Shown on tickets. The demo seed marks its own rows DEMO-%.'],
    ['bookings', 'fare_charged', 'Feeds the billing panels.'],
    ['bookings', 'hidden_from_passenger', 'Added by migration 001. sp_archive_booking_history updates it, but uniride2.sql never declared it.'],
    ['passengers', 'passenger_type', 'STUDENT / FACULTY subtype discriminator.'],
    ['passengers', 'password_hash', 'Passenger sign-in.'],
    ['university_users', 'password_hash', 'University admin sign-in.'],
    ['admins', 'password', 'System admin sign-in. This table uses password, not password_hash.'],
    ['schedules', 'schedule_date', 'Today / upcoming filtering.'],
    ['schedules', 'departure_time', 'Trip ordering.'],
    ['notifications', 'is_read', 'Unread badge in the sidebar.'],
    ['complaints', 'university_response', 'Open vs answered.'],
    ['routes', 'university_id', 'The tenancy fence for every university admin query.'],
    ['semester_bills', 'net_balance', 'Passenger and university billing panels.'],
    ['semester_bills', 'university_id', 'Nullable by design: sp_create_booking omits it and a trigger backfills it.'],
    ['ticket_transfers', 'from_passenger_id', 'Transfer direction.'],
    ['ticket_transfers', 'to_passenger_id', 'Transfer direction.'],
    ['booking_status_history', 'old_status', 'The shipped procedures write old_status. A column named previous_status instead would break them.'],
    ['booking_status_history', 'new_status', ''],
    ['route_stops', 'stop_order', 'Position along the route; 1 is the origin.'],
    ['route_stops', 'stop_name', ''],
    ['announcements', 'university_id', 'Tenant boundary for University Admin announcements.'],
    ['announcements', 'created_by', 'University Admin who created the announcement.'],
    ['announcements', 'status', 'DRAFT, PUBLISHED or ARCHIVED.'],
];

$expectedRoutines = [
    'sp_create_booking'              => 'PROCEDURE',
    'sp_cancel_booking'              => 'PROCEDURE',
    'sp_archive_booking_history'     => 'PROCEDURE',
    'sp_mark_all_notifications_read' => 'PROCEDURE',
    'sp_request_ticket_transfer'     => 'PROCEDURE',
    'sp_respond_ticket_transfer'     => 'PROCEDURE',
    'fn_seat_label'                  => 'FUNCTION',
];

$expectedTriggers = [
    'trg_chk_dup_booking_ins'             => 'uniride2.sql',
    'trg_chk_dup_booking_upd'             => 'uniride2.sql',
    'trg_bus_route_assign_ins_check'      => 'uniride2.sql',
    'trg_bus_route_assign_upd_check'      => 'uniride2.sql',
    'trg_complaint_response_notification' => 'uniride2.sql',
    'trg_semester_bills_set_university'   => 'database/migrations/001_add_missing_dashboard_tables.sql',
];

/*
| Uniqueness the application relies on.
|
| A UNIQUE key is not a performance detail here — each one is a rule the
| PHP is allowed to stop re-checking, because the database will refuse the
| write. uq_bill_passenger_semester is the clearest case: sp_create_booking
| uses ON DUPLICATE KEY UPDATE against it, so without the key every booking
| opens a second bill rather than adding to the first.
|
| [index name, table, expected columns, why it matters]
*/
$expectedUnique = [
    ['uq_passenger_email', 'passengers', 'email', 'Two accounts on one address would make sign-in ambiguous.'],
    ['uq_university_user_email', 'university_users', 'email', ''],
    ['uq_admin_email', 'admins', 'email', ''],
    ['uq_student_passenger', 'students', 'passenger_id', 'One specialisation row per passenger — half of what makes the subtype disjoint.'],
    ['uq_faculty_passenger', 'faculty', 'passenger_id', 'The other half.'],
    ['uq_student_identifier', 'students', 'student_identifier', ''],
    ['uq_faculty_identifier', 'faculty', 'faculty_identifier', ''],
    ['uq_university_code', 'universities', 'code', ''],
    ['uq_bus_registration', 'buses', 'registration_number', ''],
    ['uq_route_code', 'routes', 'university_id, route_code', 'Route codes are unique per university, not globally — different universities may both run an R1.'],
    ['uq_bus_route', 'bus_route_assignments', 'bus_id, route_id', 'The relationship table carries no duplicates.'],
    ['uq_booking_reference', 'bookings', 'booking_reference', 'Printed on the ticket, so it has to identify exactly one booking.'],
    ['uq_booking_qr', 'bookings', 'qr_token', 'Scanned at boarding.'],
    ['uq_favorite', 'favorite_routes', 'passenger_id, route_id', 'Stops a route being favourited twice.'],
    ['uq_bill_passenger_semester', 'semester_bills', 'passenger_id, semester_id', 'sp_create_booking depends on this for ON DUPLICATE KEY UPDATE.'],
    ['uq_route_stop_order', 'route_stops', 'route_id, stop_order', 'Two stops cannot both claim position 3.'],
];

/** Look an index up by name, whatever table it sits on. */
function sc_index(array $indexByTable, string $table, string $name): ?array
{
    foreach ($indexByTable[$table] ?? [] as $ix) {
        if ((string)$ix['index_name'] === $name) {
            return $ix;
        }
    }

    return null;
}

$missingTables = [];
foreach ($expectedTables as $name => $source) {
    if (!isset($tables[$name])) {
        $missingTables[$name] = $source;
    }
}

$migration001Tables = ['semester_bills', 'ticket_transfers', 'route_stops', 'booking_status_history'];
$migration001Done   = true;
foreach ($migration001Tables as $t) {
    if (!isset($tables[$t])) {
        $migration001Done = false;
    }
}

$migration003Done = isset($tables['announcements']);
$migration004Done = isset($tables['user_profiles'], $tables['user_notification_preferences'], $tables['user_sessions'], $tables['user_security_events']);

// Migration 000 is the one that adds the keys. Its most visible effect is
// that bookings and passengers gain a primary key, so use that as the tell.
$migration000Done = isset($pkColumn['passengers'], $pkColumn['bookings'], $autoInc['bookings']);

// ---------------------------------------------------------------------
// 4. References that are not enforced by a foreign key
// ---------------------------------------------------------------------

/*
| Derived rather than hard-coded: for every column whose name is, or ends
| with, another table's single-column primary key, the database is being
| asked to hold a relationship. Whether a FOREIGN KEY actually enforces it
| is then a yes or no question, and the same pairing gives us a free
| orphan-row probe below.
|
| This catches the aliased columns a fixed list would miss, such as
| ticket_transfers.from_passenger_id -> passengers.passenger_id.
*/

$references = [];

foreach ($columns as $table => $cols) {
    if (($tables[$table]['table_type'] ?? '') !== 'BASE TABLE') {
        continue;
    }

    // strval() because PHP turns an all-digit array key into an int, and
    // str_ends_with() below is typed string under strict_types — an int would
    // be an uncaught TypeError rather than a skipped row. A column named `12`
    // is legal if it was created backtick-quoted.
    foreach (array_map('strval', array_keys($cols)) as $column) {
        foreach ($pkColumn as $parent => $parentPk) {
            if ($parent === $table) {
                continue;                    // a table's own key is not a reference
            }

            if (($tables[$parent]['table_type'] ?? '') !== 'BASE TABLE') {
                continue;
            }

            $isMatch = ($column === $parentPk)
                || str_ends_with($column, '_' . $parentPk);

            if (!$isMatch) {
                continue;
            }

            $references[] = [
                'child'      => $table,
                'column'     => $column,
                'parent'     => $parent,
                'parent_key' => $parentPk,
                'enforced'   => isset($fkByColumn[$table . '.' . $column]),
                'nullable'   => ((string)$cols[$column]['is_nullable'] === 'YES'),
            ];

            break;                            // first parent match wins
        }
    }
}

// Orphan probe for each reference. Cheap on a dataset this size.
//
// qi() throws on an identifier it does not consider safe, and building the
// SQL happens outside sc_rows()' own try block, so the construction is
// wrapped here too. Otherwise a table named with an unusual character would
// take down the whole page instead of skipping one row of the report.
foreach ($references as $i => $ref) {
    try {
        $sql = 'SELECT COUNT(*) FROM ' . qi($ref['child']) . ' c'
             . ' LEFT JOIN ' . qi($ref['parent']) . ' p'
             . '   ON p.' . qi($ref['parent_key']) . ' = c.' . qi($ref['column'])
             . ' WHERE c.' . qi($ref['column']) . ' IS NOT NULL'
             . '   AND p.' . qi($ref['parent_key']) . ' IS NULL';

        $references[$i]['orphans'] = sc_int(
            $pdo,
            $sql,
            [],
            'orphan probe ' . $ref['child'] . '.' . $ref['column']
        );
    } catch (Throwable $e) {
        sc_errors('orphan probe skipped for ' . $ref['child'] . ' — ' . $e->getMessage());
        $references[$i]['orphans'] = null;
    }
}

$unenforced = array_values(array_filter($references, static fn (array $r): bool => !$r['enforced']));
$orphaned   = array_values(array_filter($references, static fn (array $r): bool => ($r['orphans'] ?? 0) > 0));

// ---------------------------------------------------------------------
// 5. Values actually in use
// ---------------------------------------------------------------------

/*
| The spec is explicit that enum strings must be checked against the
| database rather than assumed. Two things matter here: which values the
| column declares, and which of them any row actually holds. A status the
| PHP branches on but no row ever carries is a hint the branch is dead.
|
| notification_type is a varchar rather than an enum, so it is added by
| hand — its values are still a fixed vocabulary the dashboards read.
*/

$valueColumns = [];

foreach ($columnRows as $r) {
    if ((string)$r['data_type'] === 'enum'
        && ($tables[(string)$r['table_name']]['table_type'] ?? '') === 'BASE TABLE') {
        $valueColumns[] = [(string)$r['table_name'], (string)$r['column_name'], (string)$r['column_type']];
    }
}

foreach ([['notifications', 'notification_type'], ['booking_status_history', 'changed_by']] as [$t, $c]) {
    if (isset($columns[$t][$c]) && (string)$columns[$t][$c]['data_type'] !== 'enum') {
        $valueColumns[] = [$t, $c, (string)$columns[$t][$c]['column_type']];
    }
}

$valueReport = [];

foreach ($valueColumns as [$t, $c, $type]) {
    $declared = [];

    if (str_starts_with(strtolower($type), 'enum')) {
        preg_match_all("/'((?:[^']|'')*)'/", $type, $m);
        $declared = array_map(
            static fn (string $v): string => str_replace("''", "'", $v),
            $m[1]
        );
    }

    $used = [];

    try {
        $used = sc_rows(
            $pdo,
            'SELECT ' . qi($c) . ' AS v, COUNT(*) AS n FROM ' . qi($t)
            . ' GROUP BY ' . qi($c) . ' ORDER BY n DESC, v ASC',
            [],
            'value distribution ' . $t . '.' . $c
        );
    } catch (Throwable $e) {
        sc_errors('value distribution skipped for ' . $t . ' — ' . $e->getMessage());
    }

    $inUse = [];
    foreach ($used as $u) {
        $key = $u['v'] === null ? 'NULL' : (string)$u['v'];
        $inUse[$key] = (int)$u['n'];
    }

    $valueReport[] = [
        'table'    => $t,
        'column'   => $c,
        'declared' => $declared,
        'in_use'   => $inUse,
        'unknown'  => $declared === []
            ? []
            : array_values(array_diff(array_keys($inUse), array_merge($declared, ['NULL']))),
    ];
}

// ---------------------------------------------------------------------
// 6. Integrity probes
// ---------------------------------------------------------------------

/*
| Each probe should return zero. A non-zero count is a real finding, not a
| style complaint, and each one names the fix. Probes whose tables are not
| present are skipped rather than failed — a missing migration is already
| reported above and should not also produce a wall of red here.
*/

$probeDefs = [
    [
        'label'  => 'Passengers duplicated by email',
        'needs'  => ['passengers'],
        'sql'    => "SELECT COALESCE(SUM(c) - COUNT(*), 0)
                       FROM (SELECT COUNT(*) AS c FROM passengers
                              GROUP BY email HAVING COUNT(*) > 1) d",
        'fix'    => 'Extra rows beyond the first for each email. Section 1 of '
                  . 'database/migrations/000_repair_existing_keys.sql removes these before adding the unique key.',
    ],
    [
        'label'  => 'Buses scheduled twice at the same date and time',
        'needs'  => ['schedules'],
        'sql'    => "SELECT COUNT(*) FROM (
                        SELECT bus_id FROM schedules
                         WHERE status <> 'CANCELLED'
                         GROUP BY bus_id, schedule_date, departure_time
                        HAVING COUNT(*) > 1) d",
        'fix'    => 'A bus cannot be in two places at once. uniride2.sql ships one such clash, '
                  . 'which is why migration 000 adds a plain index on (bus_id, schedule_date, departure_time) '
                  . 'rather than a unique key — the unique key would abort the import.',
    ],
    [
        'label'  => 'Same seat sold twice on one trip',
        'needs'  => ['bookings'],
        'sql'    => "SELECT COUNT(*) FROM (
                        SELECT schedule_id FROM bookings
                         WHERE slot_type = 'SEAT'
                           AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING')
                         GROUP BY schedule_id, seat_number
                        HAVING COUNT(*) > 1) d",
        'fix'    => 'trg_chk_dup_booking_ins should make this impossible. A non-zero count means the '
                  . 'trigger is missing or rows were inserted before it existed.',
    ],
    [
        'label'  => 'Bookings on a seat the bus does not have',
        'needs'  => ['bookings', 'schedules', 'buses'],
        'sql'    => "SELECT COUNT(*)
                       FROM bookings bk
                       JOIN schedules s ON s.schedule_id = bk.schedule_id
                       JOIN buses b     ON b.bus_id      = s.bus_id
                      WHERE bk.slot_type = 'SEAT'
                        AND bk.seat_number > b.seat_capacity",
        'fix'    => 'Seat numbers must fall inside buses.seat_capacity for that trip.',
    ],
    [
        'label'  => 'Passengers booked on a bus type they may not board',
        'needs'  => ['bookings', 'passengers', 'schedules', 'buses'],
        'sql'    => "SELECT COUNT(*)
                       FROM bookings bk
                       JOIN passengers p ON p.passenger_id = bk.passenger_id
                       JOIN schedules s  ON s.schedule_id  = bk.schedule_id
                       JOIN buses b      ON b.bus_id       = s.bus_id
                      WHERE (p.passenger_type = 'STUDENT' AND b.bus_type = 'FACULTY_ONLY')
                         OR (p.passenger_type = 'FACULTY' AND b.bus_type = 'STUDENT_ONLY')",
        'fix'    => 'Students may board STANDARD or STUDENT_ONLY buses; faculty may board STANDARD or FACULTY_ONLY.',
    ],
    [
        'label'  => 'Bookings on another university\'s route',
        'needs'  => ['bookings', 'passengers', 'schedules', 'routes'],
        'sql'    => "SELECT COUNT(*)
                       FROM bookings bk
                       JOIN passengers p ON p.passenger_id = bk.passenger_id
                       JOIN schedules s  ON s.schedule_id  = bk.schedule_id
                       JOIN routes r     ON r.route_id     = s.route_id
                      WHERE r.university_id <> p.university_id",
        'fix'    => 'This is the tenancy boundary. A passenger holding a seat on another university\'s route '
                  . 'means the isolation rule has been broken somewhere that writes bookings.',
    ],
    [
        'label'  => 'Buses assigned to another university\'s route',
        'needs'  => ['bus_route_assignments', 'buses', 'routes'],
        'sql'    => "SELECT COUNT(*)
                       FROM bus_route_assignments a
                       JOIN buses b  ON b.bus_id   = a.bus_id
                       JOIN routes r ON r.route_id = a.route_id
                      WHERE b.university_id <> r.university_id",
        'fix'    => 'trg_bus_route_assign_ins_check should reject these.',
    ],
    [
        'label'  => 'Passengers with no STUDENT or FACULTY row',
        'needs'  => ['passengers', 'students', 'faculty'],
        'sql'    => "SELECT COUNT(*)
                       FROM passengers p
                       LEFT JOIN students st ON st.passenger_id = p.passenger_id
                       LEFT JOIN faculty  f  ON f.passenger_id  = p.passenger_id
                      WHERE (p.passenger_type = 'STUDENT' AND st.passenger_id IS NULL)
                         OR (p.passenger_type = 'FACULTY' AND f.passenger_id  IS NULL)",
        'fix'    => 'The subtype is total: every passenger should have exactly one specialisation row.',
    ],
    [
        'label'  => 'Passengers that are both student and faculty',
        'needs'  => ['students', 'faculty'],
        'sql'    => "SELECT COUNT(*)
                       FROM students st
                       JOIN faculty f ON f.passenger_id = st.passenger_id",
        'fix'    => 'The subtype is disjoint: a passenger cannot appear in both tables.',
    ],
    [
        'label'  => 'Semester bills with no university',
        'needs'  => ['semester_bills'],
        'sql'    => "SELECT COUNT(*) FROM semester_bills WHERE university_id IS NULL",
        'fix'    => 'trg_semester_bills_set_university fills this on insert. Rows created before the '
                  . 'trigger existed stay NULL; the backfill at the end of migration 001 clears them.',
    ],
    [
        'label'  => 'Semester bills duplicated for one passenger and semester',
        'needs'  => ['semester_bills'],
        'sql'    => "SELECT COUNT(*) FROM (
                        SELECT passenger_id FROM semester_bills
                         GROUP BY passenger_id, semester_id
                        HAVING COUNT(*) > 1) d",
        'fix'    => 'uq_bill_passenger_semester is what makes ON DUPLICATE KEY UPDATE work inside '
                  . 'sp_create_booking. Without it every booking starts a new bill.',
    ],
    [
        'label'  => 'Transfers between passengers of different universities',
        'needs'  => ['ticket_transfers', 'passengers'],
        'sql'    => "SELECT COUNT(*)
                       FROM ticket_transfers t
                       JOIN passengers pf ON pf.passenger_id = t.from_passenger_id
                       JOIN passengers pt ON pt.passenger_id = t.to_passenger_id
                      WHERE pf.university_id <> pt.university_id",
        'fix'    => 'A ticket is only usable on its own university\'s bus, so a cross-university transfer '
                  . 'hands over something the recipient cannot board.',
    ],
    [
        'label'  => 'SELL transfers with no amount, or GIFT transfers with one',
        'needs'  => ['ticket_transfers'],
        'sql'    => "SELECT COUNT(*) FROM ticket_transfers
                      WHERE (transfer_type = 'SELL' AND sale_amount IS NULL)
                         OR (transfer_type = 'GIFT' AND sale_amount IS NOT NULL)",
        'fix'    => 'MariaDB before 10.2.1 ignores CHECK constraints, so this pairing is verified here instead.',
    ],
    [
        'label'  => 'Route stops sharing a position on the same route',
        'needs'  => ['route_stops'],
        'sql'    => "SELECT COUNT(*) FROM (
                        SELECT route_id FROM route_stops
                         GROUP BY route_id, stop_order
                        HAVING COUNT(*) > 1) d",
        'fix'    => 'uq_route_stop_order prevents this. Two stops claiming position 3 make the sequence meaningless.',
    ],
    [
        'label'  => 'Active schedules on a bus that is not in service',
        'needs'  => ['schedules', 'buses'],
        'sql'    => "SELECT COUNT(*)
                       FROM schedules s
                       JOIN buses b ON b.bus_id = s.bus_id
                      WHERE s.status = 'SCHEDULED'
                        AND s.schedule_date >= CURDATE()
                        AND b.status <> 'ACTIVE'",
        'fix'    => 'A bus in MAINTENANCE or INACTIVE should not be carrying future trips.',
    ],
    [
        'label'  => 'Billing rows whose booking has been deleted',
        'needs'  => ['billing_transactions', 'bookings'],
        'sql'    => "SELECT COUNT(*)
                       FROM billing_transactions bt
                       LEFT JOIN bookings b ON b.booking_id = bt.booking_id
                      WHERE bt.booking_id IS NOT NULL
                        AND b.booking_id IS NULL",
        'fix'    => 'Charges pointing at a booking that no longer exists.',
    ],
];

$probes = [];

foreach ($probeDefs as $def) {
    $missingNeeds = array_values(array_filter(
        $def['needs'],
        static fn (string $t): bool => !isset($tables[$t])
    ));

    if ($missingNeeds !== []) {
        $probes[] = $def + ['count' => null, 'skipped' => implode(', ', $missingNeeds)];
        continue;
    }

    $probes[] = $def + [
        'count'   => sc_int($pdo, $def['sql'], [], 'probe: ' . $def['label']),
        'skipped' => '',
    ];
}

$probeFailures = count(array_filter(
    $probes,
    static fn (array $p): bool => ($p['count'] ?? 0) > 0
));

// ---------------------------------------------------------------------
// 7. Is there anything to look at on the dashboards?
// ---------------------------------------------------------------------

$demoBookings = isset($tables['bookings'])
    ? sc_int($pdo, "SELECT COUNT(*) FROM bookings WHERE booking_reference LIKE 'DEMO-%'", [], 'demo bookings')
    : null;

$futureSchedules = isset($tables['schedules'])
    ? sc_int(
        $pdo,
        "SELECT COUNT(*) FROM schedules WHERE schedule_date >= CURDATE() AND status = 'SCHEDULED'",
        [],
        'future schedules'
    )
    : null;

$openComplaints = isset($tables['complaints'])
    ? sc_int($pdo, "SELECT COUNT(*) FROM complaints WHERE status = 'OPEN'", [], 'open complaints')
    : null;

$unreadNotifications = isset($tables['notifications'])
    ? sc_int($pdo, "SELECT COUNT(*) FROM notifications WHERE is_read = 0", [], 'unread notifications')
    : null;

// Per-university coverage, so it is obvious if only one tenant has data.
$coverageTables = ['universities', 'routes', 'schedules', 'buses', 'passengers', 'bookings'];
$coverageReady  = true;
foreach ($coverageTables as $t) {
    if (!isset($tables[$t])) {
        $coverageReady = false;
    }
}

$universityCoverage = $coverageReady
    ? sc_rows(
        $pdo,
        "SELECT u.university_id, u.name,
                (SELECT COUNT(*) FROM routes r
                  WHERE r.university_id = u.university_id)                        AS routes,
                (SELECT COUNT(*) FROM buses b
                  WHERE b.university_id = u.university_id)                        AS buses,
                (SELECT COUNT(*) FROM passengers p
                  WHERE p.university_id = u.university_id)                        AS passengers,
                (SELECT COUNT(*) FROM schedules s
                   JOIN routes r2 ON r2.route_id = s.route_id
                  WHERE r2.university_id = u.university_id
                    AND s.schedule_date >= CURDATE())                             AS upcoming,
                (SELECT COUNT(*) FROM bookings bk
                   JOIN schedules s2 ON s2.schedule_id = bk.schedule_id
                   JOIN routes r3    ON r3.route_id    = s2.route_id
                  WHERE r3.university_id = u.university_id)                       AS bookings
           FROM universities u
          ORDER BY u.university_id",
        [],
        'university coverage'
    )
    : [];

// ---------------------------------------------------------------------
// 8. Headline
// ---------------------------------------------------------------------

$missingColumns = [];
foreach ($expectedColumns as [$t, $c, $why]) {
    if (!isset($tables[$t])) {
        continue;                             // the table itself is already reported missing
    }

    if (!isset($columns[$t][$c])) {
        $missingColumns[] = [$t, $c, $why];
    }
}

$missingRoutines = array_keys(array_diff_key($expectedRoutines, $routines));
$missingTriggers = array_keys(array_diff_key($expectedTriggers, $triggers));

$missingUnique = [];
foreach ($expectedUnique as [$uName, $uTable, $uCols, $uWhy]) {
    if (!isset($tables[$uTable])) {
        continue;                             // already reported as a missing table
    }

    $ix = sc_index($indexByTable, $uTable, $uName);

    // Present but non-unique is worse than absent: it looks like the
    // constraint is there while guaranteeing nothing.
    if ($ix === null || (int)$ix['non_unique'] !== 0) {
        $missingUnique[] = $uName;
    }
}

$errors = sc_errors();

$blocking = count($missingTables) + count($missingColumns) + count($missingUnique) + $probeFailures;
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Schema check — UniRide</title>
<?= uniride_theme_head_html($BASE) ?>
<link rel="stylesheet" href="<?= h($BASE) ?>/css/style.css">
<style>
/* Scoped to this tool. It is a diagnostic page, not part of the product
   surface, so it borrows the typography and stays out of the design system. */
.sc-wrap   { max-width: 1080px; margin: 0 auto; padding: 56px 24px 96px; }
.sc-head   { margin-bottom: 40px; }
.sc-head h1 { font-family: Georgia, 'Times New Roman', serif; font-weight: 500;
              letter-spacing: -.04em; font-size: 46px; margin: 8px 0 12px; }
.sc-head p  { color: #6b6b6b; margin: 0; max-width: 62ch; line-height: 1.6; }
.sc-kicker  { text-transform: uppercase; letter-spacing: .14em; font-size: 11px;
              color: #999; margin: 0; }
.sc-sum     { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
              gap: 12px; margin: 28px 0 8px; }
.sc-sum div { border: 1px solid #e6e6e6; border-radius: 10px; padding: 16px 18px; background: #fff; }
.sc-sum b   { display: block; font-size: 26px; font-weight: 500; letter-spacing: -.02em; }
.sc-sum span{ color: #888; font-size: 12px; }
.sc-sec     { margin-top: 46px; }
.sc-sec h2  { font-family: Georgia, serif; font-weight: 500; font-size: 25px;
              letter-spacing: -.02em; margin: 0 0 6px; }
.sc-sec > p { color: #6b6b6b; margin: 0 0 18px; max-width: 74ch; line-height: 1.6; font-size: 14px; }
table.sc    { width: 100%; border-collapse: collapse; font-size: 13.5px; background: #fff;
              border: 1px solid #e6e6e6; border-radius: 10px; overflow: hidden; }
table.sc th { text-align: left; font-weight: 500; font-size: 11px; text-transform: uppercase;
              letter-spacing: .1em; color: #8a8a8a; padding: 11px 14px;
              border-bottom: 1px solid #eee; background: #fafafa; white-space: nowrap; }
table.sc td { padding: 11px 14px; border-bottom: 1px solid #f2f2f2; vertical-align: top; }
table.sc tr:last-child td { border-bottom: 0; }
.num        { text-align: right; font-variant-numeric: tabular-nums; }
.muted      { color: #999; }
.tag        { display: inline-block; font-size: 11px; padding: 2px 8px; border-radius: 20px;
              border: 1px solid #ddd; color: #666; white-space: nowrap; }
.tag.ok     { border-color: #bcdcc4; background: #f1f9f3; color: #2f7d43; }
.tag.warn   { border-color: #e6d8ae; background: #fdf8ec; color: #8a6a1a; }
.tag.bad    { border-color: #eec4c4; background: #fdf2f2; color: #9c3232; }
.tag.skip   { border-color: #e2e2e2; background: #fafafa; color: #999; }
code        { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 12.5px;
              background: #f5f5f5; padding: 1px 5px; border-radius: 4px; }
.sc-note    { border: 1px solid #e6e6e6; border-left: 3px solid #cfcfcf; border-radius: 8px;
              padding: 14px 18px; background: #fafafa; color: #555; font-size: 13.5px;
              line-height: 1.65; margin: 0 0 18px; }
.sc-note.bad{ border-left-color: #c96b6b; background: #fdf6f6; }
.sc-note.ok { border-left-color: #7bb08a; background: #f5faf6; }
.sc-back    { display: inline-block; margin-top: 46px; }
@media (max-width: 640px) {
  .sc-wrap { padding: 34px 16px 72px; }
  .sc-head h1 { font-size: 33px; }
  table.sc { display: block; overflow-x: auto; }
}
</style>
<link rel="stylesheet" href="<?= h($BASE) ?>/css/uniride-ui.css">
</head>
<body class="schema-check-page">
<main class="sc-wrap">

<?php
// Small render helpers. Declared here so the markup stays readable.
$tag = static function (string $text, string $tone = ''): string {
    return '<span class="tag' . ($tone !== '' ? ' ' . $tone : '') . '">' . h($text) . '</span>';
};

$yesNo = static function (bool $ok, string $yes = 'Yes', string $no = 'No') use ($tag): string {
    return $ok ? $tag($yes, 'ok') : $tag($no, 'bad');
};
?>

<header class="sc-head">
    <p class="sc-kicker">UniRide diagnostics</p>
    <h1>Schema check</h1>
    <p>
        Read-only. This page inspects the database this application is
        connected to right now, so it reflects your machine rather than
        anything assumed from a dump. Nothing on this page writes.
    </p>

    <div class="sc-sum">
        <div><b><?= h($currentDb === '' ? '—' : $currentDb) ?></b><span>Connected database</span></div>
        <div><b><?= count($tables) ?></b><span>Tables and views</span></div>
        <div><b><?= count($missingTables) ?></b><span>Expected objects missing</span></div>
        <div><b><?= $probeFailures ?></b><span>Integrity findings</span></div>
    </div>
</header>

<?php if ($currentDb !== 'uniride2'): ?>
    <p class="sc-note bad">
        Connected to <code><?= h($currentDb) ?></code>, not <code>uniride2</code>.
        Everything below describes that other database. Check
        <code>config/database.php</code>.
    </p>
<?php endif; ?>

<?php if ($blocking === 0 && $errors === []): ?>
    <p class="sc-note ok">
        No missing objects, no missing columns, every unique key in place and
        no integrity findings. The dashboards have everything they expect.
    </p>
<?php endif; ?>

<?php if ($errors !== []): ?>
    <div class="sc-note bad">
        <strong><?= count($errors) ?> check<?= count($errors) === 1 ? '' : 's' ?> could not run.</strong>
        The message from the database driver is shown because you are a
        platform administrator and this is a diagnostic page. Each one is
        also in the PHP error log.
        <ul style="margin:10px 0 0;padding-left:20px">
            <?php foreach ($errors as $e): ?>
                <li style="margin-bottom:4px"><?= h($e) ?></li>
            <?php endforeach; ?>
        </ul>
    </div>
<?php endif; ?>

<!-- ============================================================== -->
<section class="sc-sec">
    <h2>Environment</h2>
    <p>
        Where the application is running and how it talks to the database.
    </p>

    <table class="sc">
        <tbody>
        <tr>
            <td style="width:230px">Database server</td>
            <td><code><?= h($serverVersion) ?></code> via <code><?= h($driverName) ?></code></td>
        </tr>
        <tr>
            <td>PHP</td>
            <td><code><?= h(PHP_VERSION) ?></code></td>
        </tr>
        <tr>
            <td>Prepared statements</td>
            <td>
                <?= $yesNo(!$emulatePrepare, 'Native', 'Emulated') ?>
                <span class="muted">
                    <?= $emulatePrepare
                        ? 'PDO is rewriting placeholders in PHP. config/database.php sets EMULATE_PREPARES to false, so this is unexpected.'
                        : 'Placeholders are sent to the server, which is what config/database.php asks for.' ?>
                </span>
            </td>
        </tr>
        <tr>
            <td><code>sql_mode</code></td>
            <td>
                <?= $sqlMode === '' ? '<span class="muted">(empty)</span>' : '<code>' . h($sqlMode) . '</code>' ?>
                <?php if ($onlyFullGroup): ?>
                    <div class="muted" style="margin-top:6px">
                        <code>ONLY_FULL_GROUP_BY</code> is on. Every grouped query in this
                        project lists its non-aggregated columns, so this is fine — it is
                        noted because a query written without it will fail here and pass elsewhere.
                    </div>
                <?php endif; ?>
            </td>
        </tr>
        </tbody>
    </table>
</section>

<!-- ============================================================== -->
<section class="sc-sec">
    <h2>Migration status</h2>
    <p>
        The dashboards run against the tables that ship in
        <code>uniride2.sql</code>. Three migrations complete the picture:
        <strong>000</strong> adds the keys the dump omits, and
        <strong>001</strong> creates the four tables the stored procedures
        already reference but the dump never declares. <strong>003</strong>
        adds the university-owned announcement feature. Import 000 first —
        later migrations point foreign keys at the keys 000 creates.
    </p>

    <table class="sc">
        <thead>
        <tr><th>Step</th><th>File</th><th>State</th></tr>
        </thead>
        <tbody>
        <tr>
            <td>Base schema</td>
            <td><code>uniride2.sql</code></td>
            <td><?= $yesNo(isset($tables['bookings']), 'Imported', 'Not imported') ?></td>
        </tr>
        <tr>
            <td>Migration 000 — keys</td>
            <td><code>database/migrations/000_repair_existing_keys.sql</code></td>
            <td>
                <?= $migration000Done ? $tag('Applied', 'ok') : $tag('Not applied', 'bad') ?>
                <?php if (!$migration000Done): ?>
                    <div class="muted" style="margin-top:6px">
                        Core tables still have no primary key or auto-increment id.
                    </div>
                <?php endif; ?>
            </td>
        </tr>
        <tr>
            <td>Migration 001 — dashboard tables</td>
            <td><code>database/migrations/001_add_missing_dashboard_tables.sql</code></td>
            <td>
                <?= $migration001Done ? $tag('Applied', 'ok') : $tag('Not applied', 'warn') ?>
                <?php if (!$migration001Done): ?>
                    <div class="muted" style="margin-top:6px">
                        The billing, transfers and route-stop panels will show a setup
                        notice until this runs. Nothing else is affected.
                    </div>
                <?php endif; ?>
            </td>
        </tr>
        <tr>
            <td>Migration 003 — shared tenancy features</td>
            <td><code>database/migrations/003_shared_dashboard_tenancy.sql</code></td>
            <td>
                <?= $migration003Done ? $tag('Applied', 'ok') : $tag('Not applied', 'warn') ?>
                <?php if (!$migration003Done): ?>
                    <div class="muted" style="margin-top:6px">
                        University announcements remain disabled until this runs.
                    </div>
                <?php endif; ?>
            </td>
        </tr>
        <tr>
            <td>Migration 004 — shared profiles</td>
            <td><code>database/migrations/004_shared_profile_management.sql</code></td>
            <td>
                <?= $migration004Done ? $tag('Applied', 'ok') : $tag('Not applied', 'warn') ?>
                <?php if (!$migration004Done): ?>
                    <div class="muted" style="margin-top:6px">
                        Shared profiles, preferences and active-session management remain disabled until this runs.
                    </div>
                <?php endif; ?>
            </td>
        </tr>
        <tr>
            <td>Demo data (optional)</td>
            <td><code>database/seeds/002_dashboard_demo_data.sql</code></td>
            <td>
                <?php if ($demoBookings === null): ?>
                    <?= $tag('Unknown', 'skip') ?>
                <?php elseif ($demoBookings > 0): ?>
                    <?= $tag('Loaded', 'ok') ?>
                    <span class="muted"><?= (int)$demoBookings ?> demo bookings</span>
                <?php else: ?>
                    <?= $tag('Not loaded', 'skip') ?>
                    <span class="muted">Optional. Dashboards render empty states correctly without it.</span>
                <?php endif; ?>
            </td>
        </tr>
        </tbody>
    </table>
</section>

<!-- ============================================================== -->
<section class="sc-sec">
    <h2>Expected objects</h2>
    <p>
        Every table the PHP touches, and which file is responsible for
        creating it.
    </p>

    <table class="sc">
        <thead>
        <tr>
            <th>Table</th><th>Created by</th><th>Present</th>
            <th class="num">Rows</th><th>Primary key</th><th>Auto id</th>
            <th class="num">FKs</th><th>Engine</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($expectedTables as $name => $source): ?>
            <?php
            $present = isset($tables[$name]);
            $pk      = $pkColumn[$name] ?? null;
            $pkN     = $pkCount[$name] ?? 0;
            ?>
            <tr>
                <td><code><?= h($name) ?></code></td>
                <td class="muted" style="font-size:12px"><?= h($source) ?></td>
                <td><?= $present ? $tag('Yes', 'ok') : $tag('Missing', 'bad') ?></td>
                <td class="num"><?= $present ? ($rowCount[$name] === null ? '—' : number_format($rowCount[$name])) : '' ?></td>
                <td>
                    <?php if (!$present): ?>
                        <span class="muted">—</span>
                    <?php elseif ($pkN === 0): ?>
                        <?= $tag('None', 'bad') ?>
                    <?php elseif ($pk !== null): ?>
                        <code><?= h($pk) ?></code>
                    <?php else: ?>
                        <span class="muted">composite (<?= (int)$pkN ?> cols)</span>
                    <?php endif; ?>
                </td>
                <td>
                    <?php if (!$present): ?>
                        <span class="muted">—</span>
                    <?php elseif (isset($autoInc[$name])): ?>
                        <?= $tag('Yes', 'ok') ?>
                    <?php else: ?>
                        <?= $tag('No', 'warn') ?>
                    <?php endif; ?>
                </td>
                <td class="num"><?= $present ? count($fkByTable[$name] ?? []) : '' ?></td>
                <td class="muted" style="font-size:12px"><?= $present ? h((string)$tables[$name]['engine']) : '' ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>

    <?php
    $extraTables = array_diff(
        array_keys(array_filter($tables, static fn (array $t): bool => $t['table_type'] === 'BASE TABLE')),
        array_keys($expectedTables)
    );
    ?>
    <?php if ($extraTables !== []): ?>
        <p class="sc-note" style="margin-top:18px">
            Also present, and not part of the expected set:
            <?php foreach ($extraTables as $i => $t): ?>
                <?= $i > 0 ? ', ' : '' ?><code><?= h($t) ?></code>
            <?php endforeach; ?>.
            Helper tables named <code>_seed_*</code> mean the demo seed stopped
            part-way through; it drops them at the end of a successful run.
        </p>
    <?php endif; ?>
</section>

<!-- ============================================================== -->
<section class="sc-sec">
    <h2>The two <code>v_</code> objects</h2>
    <p>
        <code>uniride2.sql</code> ships these as bodyless <code>CREATE TABLE</code>
        stubs, which is what phpMyAdmin emits when it cannot dump a view
        definition. Imported that way they are permanently empty tables that
        every <code>SELECT</code> reads as zero rows — present, queryable and
        silently wrong. Migration 001 replaces them with real views. The
        dashboards never read either one; they compute from the base tables.
    </p>

    <table class="sc">
        <thead><tr><th>Object</th><th>Type</th><th class="num">Rows</th><th>Verdict</th></tr></thead>
        <tbody>
        <?php foreach ($expectedViews as $v): ?>
            <?php $type = $tables[$v]['table_type'] ?? null; ?>
            <tr>
                <td><code><?= h($v) ?></code></td>
                <td><?= $type === null ? '<span class="muted">absent</span>' : h((string)$type) ?></td>
                <td class="num"><?= isset($rowCount[$v]) && $rowCount[$v] !== null ? number_format($rowCount[$v]) : '—' ?></td>
                <td>
                    <?php if ($type === 'VIEW'): ?>
                        <?= $tag('Real view', 'ok') ?>
                    <?php elseif ($type === 'BASE TABLE'): ?>
                        <?= $tag('Empty stub', 'warn') ?>
                        <span class="muted">Migration 001 replaces it.</span>
                    <?php else: ?>
                        <?= $tag('Absent', 'skip') ?>
                        <span class="muted">Nothing reads it, so this is harmless.</span>
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>

<!-- ============================================================== -->
<section class="sc-sec">
    <h2>Columns the application depends on</h2>
    <p>
        Column names are read from the database rather than assumed. Anything
        marked missing means the PHP and the schema disagree, and the query
        that uses it will fail.
    </p>

    <?php if ($missingColumns === []): ?>
        <p class="sc-note ok">Every expected column is present with the name the PHP uses.</p>
    <?php endif; ?>

    <table class="sc">
        <thead><tr><th>Column</th><th>Type</th><th>Null</th><th>State</th><th>Why it matters</th></tr></thead>
        <tbody>
        <?php foreach ($expectedColumns as [$t, $c, $why]): ?>
            <?php
            $meta       = $columns[$t][$c] ?? null;
            $tableThere = isset($tables[$t]);
            ?>
            <tr>
                <td><code><?= h($t . '.' . $c) ?></code></td>
                <td class="muted" style="font-size:12px">
                    <?= $meta ? h((string)$meta['column_type']) : '—' ?>
                </td>
                <td class="muted" style="font-size:12px">
                    <?= $meta ? h((string)$meta['is_nullable']) : '—' ?>
                </td>
                <td>
                    <?php if ($meta): ?>
                        <?= $tag('OK', 'ok') ?>
                    <?php elseif (!$tableThere): ?>
                        <?= $tag('Table absent', 'skip') ?>
                    <?php else: ?>
                        <?= $tag('Missing', 'bad') ?>
                    <?php endif; ?>
                </td>
                <td class="muted" style="font-size:12.5px;line-height:1.55"><?= h($why) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>

    <?php
    // The one column-name trap worth calling out by name.
    $hasOld  = isset($columns['booking_status_history']['old_status']);
    $hasPrev = isset($columns['booking_status_history']['previous_status']);
    ?>
    <?php if ($hasPrev && !$hasOld): ?>
        <p class="sc-note bad" style="margin-top:18px">
            <code>booking_status_history</code> has <code>previous_status</code> but not
            <code>old_status</code>. <code>sp_cancel_booking</code> and
            <code>sp_respond_ticket_transfer</code> both write <code>old_status</code>,
            so every booking cancellation will fail against this table. Rename the
            column, or re-import migration 001.
        </p>
    <?php endif; ?>
</section>

<!-- ============================================================== -->
<section class="sc-sec">
    <h2>Relationships</h2>
    <p>
        Derived, not hard-coded: any column that is or ends with another
        table's primary key is holding a relationship, whether or not a
        foreign key enforces it. Each pairing is then checked for rows
        pointing at a parent that does not exist.
    </p>

    <?php if ($unenforced !== []): ?>
        <p class="sc-note">
            <strong><?= count($unenforced) ?></strong> relationship<?= count($unenforced) === 1 ? '' : 's' ?>
            not enforced by a foreign key. Migration 000 adds the missing
            constraints; anything still listed after running it is a reference
            the design deliberately leaves loose.
        </p>
    <?php endif; ?>

    <?php if ($orphaned !== []): ?>
        <p class="sc-note bad">
            <strong><?= count($orphaned) ?></strong> relationship<?= count($orphaned) === 1 ? ' has' : 's have' ?>
            orphan rows. These must be cleared before the matching foreign key
            can be added — MySQL refuses the constraint while a violation exists.
        </p>
    <?php endif; ?>

    <table class="sc">
        <thead>
        <tr><th>From</th><th>To</th><th>Null</th><th>Foreign key</th><th>On delete</th><th class="num">Orphans</th></tr>
        </thead>
        <tbody>
        <?php foreach ($references as $ref): ?>
            <?php $fk = $fkByColumn[$ref['child'] . '.' . $ref['column']] ?? null; ?>
            <tr>
                <td><code><?= h($ref['child'] . '.' . $ref['column']) ?></code></td>
                <td><code><?= h($ref['parent'] . '.' . $ref['parent_key']) ?></code></td>
                <td class="muted" style="font-size:12px"><?= $ref['nullable'] ? 'YES' : 'NO' ?></td>
                <td>
                    <?php if ($fk): ?>
                        <?= $tag('Enforced', 'ok') ?>
                        <div class="muted" style="font-size:11.5px;margin-top:4px">
                            <code><?= h((string)$fk['constraint_name']) ?></code>
                        </div>
                    <?php else: ?>
                        <?= $tag('None', 'warn') ?>
                    <?php endif; ?>
                </td>
                <td class="muted" style="font-size:12px"><?= $fk ? h((string)$fk['delete_rule']) : '—' ?></td>
                <td class="num">
                    <?php if ($ref['orphans'] === null): ?>
                        <span class="muted">—</span>
                    <?php elseif ($ref['orphans'] > 0): ?>
                        <span style="color:#9c3232;font-weight:500"><?= number_format($ref['orphans']) ?></span>
                    <?php else: ?>
                        <span class="muted">0</span>
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
        <?php if ($references === []): ?>
            <tr><td colspan="6" class="muted">No relationships detected. That almost certainly means no table has a primary key yet.</td></tr>
        <?php endif; ?>
        </tbody>
    </table>
</section>

<!-- ============================================================== -->
<section class="sc-sec">
    <h2>Uniqueness</h2>
    <p>
        Each of these is a rule the PHP is allowed to stop re-checking,
        because the database will refuse the write instead. A key that is
        present but <em>not</em> unique is the worst outcome: the constraint
        looks like it exists and guarantees nothing.
    </p>

    <?php if ($missingUnique !== []): ?>
        <p class="sc-note bad">
            <strong><?= count($missingUnique) ?></strong> of
            <?= count($expectedUnique) ?> unique keys missing.
            <code>database/migrations/000_repair_existing_keys.sql</code> adds all
            but the last two; migration 001 adds those. If a key refuses to
            create, the cause is duplicate rows already in the table — the
            integrity probes below name them.
        </p>
    <?php endif; ?>

    <table class="sc">
        <thead><tr><th>Key</th><th>Table</th><th>Columns</th><th>State</th><th>Why it matters</th></tr></thead>
        <tbody>
        <?php foreach ($expectedUnique as [$uName, $uTable, $uCols, $uWhy]): ?>
            <?php
            $tableThere = isset($tables[$uTable]);
            $ix         = $tableThere ? sc_index($indexByTable, $uTable, $uName) : null;
            $actualCols = $ix === null ? '' : (string)$ix['cols'];
            $isUnique   = $ix !== null && (int)$ix['non_unique'] === 0;
            ?>
            <tr>
                <td><code><?= h($uName) ?></code></td>
                <td class="muted" style="font-size:12px"><code><?= h($uTable) ?></code></td>
                <td class="muted" style="font-size:12px">
                    <code><?= h($actualCols === '' ? $uCols : $actualCols) ?></code>
                    <?php if ($actualCols !== '' && $actualCols !== $uCols): ?>
                        <div style="margin-top:4px">expected <code><?= h($uCols) ?></code></div>
                    <?php endif; ?>
                </td>
                <td>
                    <?php if (!$tableThere): ?>
                        <?= $tag('Table absent', 'skip') ?>
                    <?php elseif ($isUnique): ?>
                        <?= $tag('Unique', 'ok') ?>
                    <?php elseif ($ix !== null): ?>
                        <?= $tag('Not unique', 'bad') ?>
                    <?php else: ?>
                        <?= $tag('Missing', 'bad') ?>
                    <?php endif; ?>
                </td>
                <td class="muted" style="font-size:12.5px;line-height:1.55"><?= h($uWhy) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>

    <?php
    // Everything else the schema indexes, minus the primary keys and the
    // unique keys already accounted for above.
    $otherIndexes = 0;
    foreach ($indexByTable as $ixRows) {
        foreach ($ixRows as $ixRow) {
            if ((string)$ixRow['index_name'] !== 'PRIMARY' && (int)$ixRow['non_unique'] === 1) {
                $otherIndexes++;
            }
        }
    }
    ?>
    <p class="muted" style="font-size:12.5px;margin-top:10px;line-height:1.6">
        <?= number_format($otherIndexes) ?> further non-unique
        index<?= $otherIndexes === 1 ? '' : 'es' ?> across the schema. Those are
        for query speed rather than correctness, so a missing one slows a
        dashboard panel down without changing what it reports. InnoDB also
        creates one automatically behind every foreign key, so this number is
        higher than the count of indexes written by hand.
    </p>

    <?php if ($migration000Done && sc_index($indexByTable, 'schedules', 'idx_bus_departure') !== null): ?>
        <p class="sc-note" style="margin-top:14px">
            <code>schedules.idx_bus_departure</code> is deliberately <em>not</em>
            unique. A bus genuinely cannot be in two places at one time, but
            <code>uniride2.sql</code> already ships a pair of trips that breaks
            that rule, so a unique key would abort the migration on import.
            The probe below reports the clash instead.
        </p>
    <?php endif; ?>
</section>

<!-- ============================================================== -->
<section class="sc-sec">
    <h2>Values actually in use</h2>
    <p>
        What each status-like column declares, against what any row really
        holds. This is the check that stops the PHP branching on a string the
        database has never heard of. A declared value with no rows is not a
        fault — it usually just means that state has not occurred yet.
    </p>

    <table class="sc">
        <thead><tr><th>Column</th><th>Declared</th><th>In use</th></tr></thead>
        <tbody>
        <?php foreach ($valueReport as $v): ?>
            <tr>
                <td><code><?= h($v['table'] . '.' . $v['column']) ?></code></td>
                <td style="font-size:12.5px">
                    <?php if ($v['declared'] === []): ?>
                        <span class="muted">free text</span>
                    <?php else: ?>
                        <?php foreach ($v['declared'] as $d): ?>
                            <?php $n = $v['in_use'][$d] ?? 0; ?>
                            <span class="tag <?= $n > 0 ? 'ok' : 'skip' ?>" style="margin:0 4px 4px 0"><?= h($d) ?></span>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </td>
                <td style="font-size:12.5px">
                    <?php if ($v['in_use'] === []): ?>
                        <span class="muted">no rows</span>
                    <?php else: ?>
                        <?php $parts = [];
                        foreach ($v['in_use'] as $val => $n) {
                            $parts[] = '<code>' . h($val) . '</code> <span class="muted">' . number_format($n) . '</span>';
                        }
                        echo implode(' &nbsp; ', $parts); ?>
                    <?php endif; ?>
                    <?php if ($v['unknown'] !== []): ?>
                        <div style="margin-top:6px">
                            <?= $tag('Values outside the declared set', 'bad') ?>
                        </div>
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
        <?php if ($valueReport === []): ?>
            <tr><td colspan="3" class="muted">No status-like columns found.</td></tr>
        <?php endif; ?>
        </tbody>
    </table>
</section>

<!-- ============================================================== -->
<section class="sc-sec">
    <h2>Stored procedures, functions and triggers</h2>
    <p>
        The booking logic lives in the database. A missing routine does not
        break the dashboards, which only read, but it does break booking,
        cancellation and transfers.
    </p>

    <?php if ($missingRoutines === [] && $missingTriggers === []): ?>
        <p class="sc-note ok">
            All <?= count($expectedRoutines) ?> routines and
            <?= count($expectedTriggers) ?> triggers are defined.
        </p>
    <?php else: ?>
        <p class="sc-note<?= $missingRoutines === [] ? '' : ' bad' ?>">
            <?php if ($missingRoutines !== []): ?>
                <strong>Missing <?= count($missingRoutines) ?> of
                <?= count($expectedRoutines) ?> routines.</strong>
                Importing a dump through phpMyAdmin drops procedures silently when
                the <code>DELIMITER</code> lines are lost, which is the usual cause.
                Booking, cancellation and transfers will fail until they are back.
            <?php endif; ?>
            <?php if ($missingTriggers !== []): ?>
                <?= $missingRoutines === [] ? '' : ' ' ?>
                <?= count($missingTriggers) ?> of <?= count($expectedTriggers) ?>
                triggers are also absent. Triggers enforce rules the application
                does not re-check, so their absence is silent rather than noisy —
                the duplicate-seat and cross-university probes below are what
                would catch the consequences.
            <?php endif; ?>
        </p>
    <?php endif; ?>

    <table class="sc">
        <thead><tr><th>Name</th><th>Kind</th><th>State</th><th>Notes</th></tr></thead>
        <tbody>
        <?php foreach ($expectedRoutines as $name => $kind): ?>
            <tr>
                <td><code><?= h($name) ?></code></td>
                <td class="muted" style="font-size:12px"><?= h($kind) ?></td>
                <td><?= isset($routines[$name]) ? $tag('Present', 'ok') : $tag('Missing', 'bad') ?></td>
                <td class="muted" style="font-size:12.5px">
                    <?php if ($name === 'sp_create_booking' && !$migration001Done): ?>
                        Writes to <code>semester_bills</code>, which does not exist yet.
                        Booking will fail until migration 001 runs.
                    <?php elseif (in_array($name, ['sp_request_ticket_transfer', 'sp_respond_ticket_transfer'], true) && !isset($tables['ticket_transfers'])): ?>
                        Writes to <code>ticket_transfers</code>, which does not exist yet.
                    <?php elseif ($name === 'sp_archive_booking_history' && !isset($columns['bookings']['hidden_from_passenger'])): ?>
                        Updates <code>bookings.hidden_from_passenger</code>, which is not declared yet.
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
        <?php foreach ($expectedTriggers as $name => $source): ?>
            <tr>
                <td><code><?= h($name) ?></code></td>
                <td class="muted" style="font-size:12px">
                    TRIGGER
                    <?php if (isset($triggers[$name])): ?>
                        <br><span style="font-size:11px">
                            <?= h((string)$triggers[$name]['action_timing']) ?>
                            <?= h((string)$triggers[$name]['event_manipulation']) ?>
                            on <?= h((string)$triggers[$name]['event_object_table']) ?>
                        </span>
                    <?php endif; ?>
                </td>
                <td><?= isset($triggers[$name]) ? $tag('Present', 'ok') : $tag('Missing', 'warn') ?></td>
                <td class="muted" style="font-size:12.5px"><?= h($source) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>

    <?php
    $extraRoutines = array_diff(array_keys($routines), array_keys($expectedRoutines));
    $extraTriggers = array_diff(array_keys($triggers), array_keys($expectedTriggers));
    ?>
    <?php if ($extraRoutines !== [] || $extraTriggers !== []): ?>
        <p class="sc-note" style="margin-top:18px">
            Also defined:
            <?php foreach (array_merge($extraRoutines, $extraTriggers) as $i => $n): ?>
                <?= $i > 0 ? ', ' : '' ?><code><?= h($n) ?></code>
            <?php endforeach; ?>.
        </p>
    <?php endif; ?>
</section>

<!-- ============================================================== -->
<section class="sc-sec">
    <h2>Integrity probes</h2>
    <p>
        Every one of these should read zero. A non-zero count is a real
        finding about the data, not a style complaint.
    </p>

    <table class="sc">
        <thead><tr><th>Check</th><th class="num">Found</th><th>What it means</th></tr></thead>
        <tbody>
        <?php foreach ($probes as $p): ?>
            <tr>
                <td style="max-width:280px"><?= h($p['label']) ?></td>
                <td class="num">
                    <?php if ($p['skipped'] !== ''): ?>
                        <?= $tag('Skipped', 'skip') ?>
                    <?php elseif ($p['count'] === null): ?>
                        <?= $tag('Failed', 'bad') ?>
                    <?php elseif ($p['count'] > 0): ?>
                        <span style="color:#9c3232;font-weight:500"><?= number_format($p['count']) ?></span>
                    <?php else: ?>
                        <span class="muted">0</span>
                    <?php endif; ?>
                </td>
                <td class="muted" style="font-size:12.5px;line-height:1.6">
                    <?php if ($p['skipped'] !== ''): ?>
                        Needs <code><?= h($p['skipped']) ?></code>, which is not in the database yet.
                    <?php else: ?>
                        <?= h($p['fix']) ?>
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>

<!-- ============================================================== -->
<section class="sc-sec">
    <h2>Is there anything to look at?</h2>
    <p>
        An empty dashboard and a broken dashboard look similar from a
        distance. These counts say which one you are looking at.
    </p>

    <div class="sc-sum">
        <div>
            <b><?= $futureSchedules === null ? '—' : number_format($futureSchedules) ?></b>
            <span>Upcoming scheduled trips</span>
        </div>
        <div>
            <b><?= $openComplaints === null ? '—' : number_format($openComplaints) ?></b>
            <span>Open complaints</span>
        </div>
        <div>
            <b><?= $unreadNotifications === null ? '—' : number_format($unreadNotifications) ?></b>
            <span>Unread notifications</span>
        </div>
        <div>
            <b><?= $demoBookings === null ? '—' : number_format($demoBookings) ?></b>
            <span>Demo bookings</span>
        </div>
    </div>

    <?php if ($futureSchedules === 0): ?>
        <p class="sc-note" style="margin-top:18px">
            No upcoming trips, so every "next trip" and "today's departures"
            panel will correctly show its empty state. The trips in
            <code>uniride2.sql</code> are dated in the past. Run
            <code>database/seeds/002_dashboard_demo_data.sql</code> to add
            future ones — it dates them from <code>CURDATE()</code>, so they
            never go stale.
        </p>
    <?php endif; ?>

    <?php if ($universityCoverage !== []): ?>
        <table class="sc" style="margin-top:18px">
            <thead>
            <tr>
                <th>University</th>
                <th class="num">Routes</th><th class="num">Buses</th>
                <th class="num">Passengers</th><th class="num">Upcoming</th>
                <th class="num">Bookings</th><th>Dashboard</th>
            </tr>
            </thead>
            <tbody>
            <?php foreach ($universityCoverage as $u): ?>
                <?php $thin = ((int)$u['upcoming'] === 0 || (int)$u['bookings'] === 0); ?>
                <tr>
                    <td><?= h((string)$u['name']) ?></td>
                    <td class="num"><?= number_format((int)$u['routes']) ?></td>
                    <td class="num"><?= number_format((int)$u['buses']) ?></td>
                    <td class="num"><?= number_format((int)$u['passengers']) ?></td>
                    <td class="num"><?= number_format((int)$u['upcoming']) ?></td>
                    <td class="num"><?= number_format((int)$u['bookings']) ?></td>
                    <td><?= $thin ? $tag('Sparse', 'warn') : $tag('Populated', 'ok') ?></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
        <p class="muted" style="font-size:12.5px;margin-top:10px;line-height:1.6">
            A university marked sparse still renders correctly — its admin just
            sees empty states. The system admin totals are the sum of this table,
            so if only one row is populated the platform view will look
            single-tenant.
        </p>
    <?php endif; ?>
</section>

<a class="button button-dark sc-back" href="<?= h($BASE) ?>/admin/dashboard.php">Back to dashboard</a>

</main>
</body>
</html>
