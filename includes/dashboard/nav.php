<?php
declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| UniRide — Role navigation registry
|--------------------------------------------------------------------------
| Single source of truth for the sidebar of each role, and for the titles
| the Phase 1 placeholder pages render.
|
| The three navigations are intentionally unalike. A passenger navigates
| their own travel; a university admin navigates one university's
| operations; a system admin navigates the platform. Operational actions
| such as "Create Schedule" appear only under UNIVERSITY_ADMIN.
|
| 'soon' => true marks a link whose full feature page arrives in a later
| phase. The link still resolves to a real page, so there are no dead
| hrefs — it is only styled as secondary.
*/

/**
 * Sidebar groups for a role.
 *
 * @param array<string,array{value:int,alert?:bool}> $counts
 *        Optional live badge counts keyed by nav item key.
 * @param array<int,string> $hide
 *        Nav keys to drop entirely. Used for entries that do not apply to
 *        the signed-in account — a faculty passenger has no ticket-transfer
 *        area, because sp_request_ticket_transfer only moves a ticket
 *        between passengers of the same type and ticket sharing is a
 *        student behaviour. Hiding the link is better than showing one that
 *        can never do anything.
 * @return array<int,array{label:?string,items:array}>
 */
function dashboard_nav(string $role, array $counts = [], array $hide = []): array
{
    $groups = match (strtoupper($role)) {
        'PASSENGER'        => passenger_nav_groups(),
        'UNIVERSITY_ADMIN' => university_nav_groups(),
        'SYSTEM_ADMIN'     => system_nav_groups(),
        default            => [],
    };

    $hide = array_flip($hide);

    foreach ($groups as $gi => $group) {
        foreach ($group['items'] as $ii => $item) {
            $key = $item['key'] ?? '';

            if (isset($hide[$key])) {
                unset($groups[$gi]['items'][$ii]);
                continue;
            }

            // Attach any badge count the dashboard resolved from the database.
            if (isset($counts[$key])) {
                $groups[$gi]['items'][$ii]['count'] = $counts[$key];
            }

            foreach ($item['children'] ?? [] as $ci => $child) {
                $childKey = $child['key'] ?? '';

                if (isset($hide[$childKey])) {
                    unset($groups[$gi]['items'][$ii]['children'][$ci]);
                    continue;
                }

                if (isset($counts[$childKey])) {
                    $groups[$gi]['items'][$ii]['children'][$ci]['count'] = $counts[$childKey];
                }
            }
        }

        // Reindex, and drop a group that has been emptied by $hide so no
        // orphan heading is left behind.
        $groups[$gi]['items'] = array_values($groups[$gi]['items']);

        if ($groups[$gi]['items'] === []) {
            unset($groups[$gi]);
        }
    }

    return array_values($groups);
}

/**
 * Canonical metadata for each dashboard genre/role.
 *
 * Add or rename a role here and in its navigation groups once. Every main
 * dashboard, subpage shell and placeholder consumes this same registry.
 */
function dashboard_role(string $role): array
{
    return match (strtoupper($role)) {
        'PASSENGER' => [
            'label' => 'Passenger',
            'dashboard' => 'passenger/dashboard.php',
            'scope' => 'passenger_id',
        ],
        'UNIVERSITY_ADMIN' => [
            'label' => 'University Admin',
            'dashboard' => 'university/dashboard.php',
            'scope' => 'university_id',
        ],
        'SYSTEM_ADMIN' => [
            'label' => 'System Admin',
            'dashboard' => 'admin/dashboard.php',
            'scope' => 'platform',
        ],
        default => [
            'label' => 'Unknown',
            'dashboard' => 'signin.php',
            'scope' => 'none',
        ],
    };
}

/** Escape dashboard navigation output without depending on another helper. */
function dashboard_nav_h(mixed $value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

/**
 * Render a role's categories and links from the shared registry.
 *
 * The class map lets each established dashboard keep its own visual theme
 * while sharing the exact same role/category tree and link availability.
 */
function dashboard_render_navigation(
    string $role,
    string $active,
    array $counts = [],
    array $hide = [],
    string $base = '..',
    array $classes = []
): string {
    $classes = array_merge([
        'group' => '',
        'group_nav' => '',
        'heading' => 'side-heading',
        'link' => 'side-link',
        'active' => 'is-active',
        'disabled' => 'is-disabled',
        'soon' => 'is-soon',
        'count' => 'side-count',
        'count_alert' => 'is-alert',
        'child' => 'side-link-child',
        'children' => '',
    ], $classes);

    $root = dirname(__DIR__, 2);
    $groups = dashboard_nav($role, $counts, $hide);
    $html = '';

    $renderItem = static function (array $item, bool $child = false) use (
        $active,
        $base,
        $classes,
        $root
    ): string {
        $key = (string)($item['key'] ?? '');
        $href = ltrim((string)($item['href'] ?? ''), '/');
        $available = $href !== '' && is_file($root . '/' . $href);
        $itemClasses = [$classes['link']];

        if ($key === $active) {
            $itemClasses[] = $classes['active'];
        }
        if (!empty($item['soon'])) {
            $itemClasses[] = $classes['soon'];
        }
        if ($child && $classes['child'] !== '') {
            $itemClasses[] = $classes['child'];
        }
        if (!$available) {
            $itemClasses[] = $classes['disabled'];
        }

        $count = $item['count'] ?? null;
        $countValue = is_array($count) ? (int)($count['value'] ?? 0) : (int)$count;
        $isAlert = is_array($count) && !empty($count['alert']);
        $countHtml = '';

        if ($countValue > 0) {
            $countClasses = [$classes['count']];
            if ($isAlert && $classes['count_alert'] !== '') {
                $countClasses[] = $classes['count_alert'];
            }
            $countHtml = '<span class="' . dashboard_nav_h(implode(' ', array_filter($countClasses))) . '">'
                . number_format($countValue) . '</span>';
        }

        $classAttr = dashboard_nav_h(implode(' ', array_filter($itemClasses)));
        $label = '<span>' . dashboard_nav_h($item['label'] ?? '') . '</span>';

        if (!$available) {
            return '<span class="' . $classAttr . '" data-nav-key="'
                . dashboard_nav_h($key) . '" aria-disabled="true">'
                . $label . $countHtml . '</span>';
        }

        return '<a class="' . $classAttr . '" href="'
            . dashboard_nav_h(rtrim($base, '/') . '/' . $href) . '"'
            . ' data-nav-key="' . dashboard_nav_h($key) . '"'
            . ($key === $active ? ' aria-current="page"' : '') . '>'
            . $label . $countHtml . '</a>';
    };

    foreach ($groups as $group) {
        if ($classes['group'] !== '') {
            $html .= '<div class="' . dashboard_nav_h($classes['group']) . '">';
        }
        if (!empty($group['label'])) {
            $html .= '<p class="' . dashboard_nav_h($classes['heading']) . '">'
                . dashboard_nav_h($group['label']) . '</p>';
        }
        if ($classes['group_nav'] !== '') {
            $html .= '<nav class="' . dashboard_nav_h($classes['group_nav']) . '">';
        }

        foreach ($group['items'] as $item) {
            $html .= $renderItem($item);
            if (!empty($item['children'])) {
                if ($classes['children'] !== '') {
                    $html .= '<div class="' . dashboard_nav_h($classes['children']) . '">';
                }
                foreach ($item['children'] as $child) {
                    $html .= $renderItem($child, true);
                }
                if ($classes['children'] !== '') {
                    $html .= '</div>';
                }
            }
        }

        if ($classes['group_nav'] !== '') {
            $html .= '</nav>';
        }
        if ($classes['group'] !== '') {
            $html .= '</div>';
        }
    }

    return $html;
}

function passenger_nav_groups(): array
{
    return [
        [
            'label' => null,
            'items' => [
                ['key' => 'overview', 'label' => 'Overview', 'href' => 'passenger/dashboard.php'],
            ],
        ],
        [
            'label' => 'Travel',
            'items' => [
                ['key' => 'book-ticket',     'label' => 'Book Ticket',        'href' => 'passenger/book-ticket.php',     'soon' => true],
                ['key' => 'my-bookings',     'label' => 'My Bookings',        'href' => 'passenger/my-bookings.php',     'soon' => true],
                ['key' => 'routes',    'label' => 'Routes & Schedules', 'href' => 'passenger/routes.php',    'soon' => true],
                                ['key' => 'ticket-transfers','label' => 'Ticket Transfers',   'href' => 'passenger/ticket-transfers.php', 'soon' => true],
            ],
        ],
        [
            'label' => 'Account',
            'items' => [
                ['key' => 'complaints',    'label' => 'Complaints',       'href' => 'passenger/complaints.php',    'soon' => true],
                ['key' => 'semester-billing','label' => 'Semester Billing', 'href' => 'passenger/semester-billing.php', 'soon' => true],
                ['key' => 'notifications', 'label' => 'Notifications',    'href' => 'passenger/notifications.php', 'soon' => true],
                ['key' => 'profile',       'label' => 'Profile',          'href' => 'passenger/profile.php',       'soon' => true],
            ],
        ],
    ];
}

function university_nav_groups(): array
{
    return [
        [
            'label' => null,
            'items' => [
                ['key' => 'overview', 'label' => 'Overview', 'href' => 'university/dashboard.php'],
            ],
        ],
        [
            'label' => 'People',
            'items' => [
                [
                    'key'      => 'passengers',
                    'label'    => 'Passengers',
                    'href'     => 'university/passengers.php',
                    'children' => [
                        ['key' => 'students', 'label' => 'Students', 'href' => 'university/students.php'],
                        ['key' => 'faculty',  'label' => 'Faculty',  'href' => 'university/faculty.php'],
                    ],
                ],
            ],
        ],
        [
            'label' => 'Operations',
            'items' => [
                ['key' => 'buses',       'label' => 'Buses',       'href' => 'university/buses.php'],
                ['key' => 'routes',      'label' => 'Routes',      'href' => 'university/routes.php'],
                ['key' => 'route-stops', 'label' => 'Route Stops', 'href' => 'university/route-stops.php'],
                ['key' => 'schedules',   'label' => 'Schedules',   'href' => 'university/schedules.php'],
                ['key' => 'bookings',    'label' => 'Bookings',    'href' => 'university/bookings.php'],
                ['key' => 'occupancy',   'label' => 'Occupancy',   'href' => 'university/occupancy.php'],
            ],
        ],
        [
            'label' => 'Service',
            'items' => [
                ['key' => 'complaints',    'label' => 'Complaints',    'href' => 'university/complaints.php'],
                ['key' => 'announcements', 'label' => 'Announcements', 'href' => 'university/announcements.php'],
            ],
        ],
        [
            'label' => 'Configuration',
            'items' => [
                ['key' => 'semester-fares', 'label' => 'Semester & Fares', 'href' => 'university/semester-fares.php'],
                ['key' => 'profile',  'label' => 'Profile',          'href' => 'university/profile.php'],
            ],
        ],
    ];
}

function system_nav_groups(): array
{
    return [
        [
            'label' => null,
            'items' => [
                ['key' => 'overview', 'label' => 'Overview', 'href' => 'admin/dashboard.php'],
            ],
        ],
        [
            'label' => 'Platform',
            'items' => [
                ['key' => 'universities',   'label' => 'Universities',              'href' => 'admin/universities.php'],
                ['key' => 'administrators', 'label' => 'University Administrators', 'href' => 'admin/administrators.php'],
            ],
        ],
        [
            'label' => 'Insight',
            'items' => [
                ['key' => 'statistics', 'label' => 'Platform Statistics', 'href' => 'admin/statistics.php', 'soon' => true],
                ['key' => 'activity',   'label' => 'System Activity',     'href' => 'admin/activity.php',   'soon' => true],
            ],
        ],
        [
            'label' => 'Account',
            'items' => [
                ['key' => 'profile', 'label' => 'Profile', 'href' => 'admin/profile.php', 'soon' => true],
            ],
        ],
        [
            // Not a Phase 2 stub. tools/schema_check.php is a working,
            // read-only diagnostic and is reachable only by a system admin,
            // so it carries no 'soon' flag.
            'label' => 'Diagnostics',
            'items' => [
                ['key' => 'schema', 'label' => 'Schema Check', 'href' => 'tools/schema_check.php'],
            ],
        ],
    ];
}

/**
 * Copy for the Phase 1 placeholder pages, keyed by "role/script-name".
 * Keeping it beside the navigation means a new sidebar entry and its
 * stub page are described in one place.
 *
 * @return array{title:string,blurb:string,nav:string}|null
 */
function placeholder_section(string $role, string $script): ?array
{
    $map = [
        'PASSENGER' => [
            'book-ticket.php'   => ['Book a Ticket',      'Seat map, standing slots and fare confirmation for the 10-row, 4-across bus layout.', 'book-ticket'],
            'my-bookings.php'   => ['My Bookings',        'Your full booking history with QR tickets, cancellations and status changes.',        'my-bookings'],
            'routes.php'        => ['Routes & Schedules', 'Every route and departure your university runs, with live seat availability.',        'routes'],
            'favorite-routes.php'=> ['Favorite Routes',   'The routes you travel most, saved for one-tap booking.',                              'favorite-routes'],
            'ticket-transfers.php'=> ['Ticket Transfers', 'Send a booked ticket to another passenger, or respond to a transfer request.',        'ticket-transfers'],
            'complaints.php'    => ['Complaints',         'Raise a transport issue and follow your university transport office\'s response.',    'complaints'],
            'semester-billing.php'=> ['Semester Billing', 'Your transport charges for the semester, itemised by trip.',                          'semester-billing'],
            'notifications.php' => ['Notifications',      'Booking confirmations, schedule changes and complaint responses.',                    'notifications'],
            'profile.php'       => ['Profile',            'Your contact details, academic record and notification preferences.',                 'profile'],
        ],
        'UNIVERSITY_ADMIN' => [
            'passengers.php'    => ['Passengers',           'Every student and faculty passenger registered to your university.',              'passengers'],
            'students.php'      => ['Students',             'Student passengers, their departments, programmes and current semester.',         'students'],
            'faculty.php'       => ['Faculty',              'Faculty passengers, their departments and designations.',                         'faculty'],
            'buses.php'         => ['Buses',                'Your fleet: registration, seat and standing capacity, type and service status.',  'buses'],
            'routes.php'        => ['Routes',               'Your route network, endpoints and fares.',                                        'routes'],
            'route-stops.php'   => ['Route Stops',          'The ordered stop sequence along each of your routes.',                            'route-stops'],
            'schedules.php'     => ['Schedules',            'Assign buses to routes by date and departure time.',                              'schedules'],
            'bookings.php'      => ['Bookings',             'Every booking made against your university\'s schedules.',                        'bookings'],
            'occupancy.php'     => ['Occupancy',            'Seated and standing load per trip, measured against each bus\'s capacity.',        'occupancy'],
            'complaints.php'    => ['Complaints',           'Triage passenger complaints and publish your response.',                          'complaints'],
            'announcements.php' => ['Announcements',        'Broadcast a notification to your university\'s passengers.',                      'announcements'],
            'semester-fares.php'=> ['Semester & Fares',     'Semester windows and the fare table applied to your routes.',                     'semester-fares'],
            'profile.php'       => ['Profile',              'Your transport office account and contact details.',                              'profile'],
        ],
        'SYSTEM_ADMIN' => [
            'universities.php'   => ['Universities',              'Onboard a university, edit its record, or change its platform status.', 'universities'],
            'administrators.php' => ['University Administrators', 'Create and manage the admin accounts that run each university.',        'administrators'],
            'statistics.php'     => ['Platform Statistics',       'Cross-university totals and growth across all of UniRide.',             'statistics'],
            'activity.php'       => ['System Activity',           'Platform-level events: onboarding, status changes and admin creation.', 'activity'],
            'profile.php'        => ['Profile',                   'Your system administrator account.',                                    'profile'],
        ],
    ];

    $entry = $map[strtoupper($role)][$script] ?? null;

    if ($entry === null) {
        return null;
    }

    return ['title' => $entry[0], 'blurb' => $entry[1], 'nav' => $entry[2]];
}
