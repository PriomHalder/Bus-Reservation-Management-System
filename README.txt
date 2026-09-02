UNIRIDE2 — SHARED MULTI-UNIVERSITY DASHBOARDS
==============================================

Copy this folder to:

  C:\xampp\htdocs\uniride\

Then start Apache and MySQL and open:

  http://localhost/uniride/


DATABASE SETUP
--------------

The default PHP connection is:

  Database: uniride2
  Host:     127.0.0.1
  Port:     3306
  User:     root
  Password: empty

If your MySQL credentials are different, edit config/database.php.

For a fresh database, import these files in this order in phpMyAdmin:

  1. uniride2.sql
  2. database/migrations/000_repair_existing_keys.sql
  3. database/migrations/001_add_missing_dashboard_tables.sql
  4. database/migrations/003_shared_dashboard_tenancy.sql
  5. database/migrations/004_shared_profile_management.sql
  6. database/password_reset_tokens.sql

Optional demonstration data:

  database/seeds/002_dashboard_demo_data.sql

The migrations do not create separate dashboard copies for BRAC University,
North South University, AIUB, or any university added later. All universities
use the same application code and are separated by university_id.


SHARED DASHBOARD ARCHITECTURE
-----------------------------

Role and category navigation has one source of truth:

  includes/dashboard/nav.php

Responsive sidebar behaviour also has one source of truth:

  js/dashboard.js

Every dashboard shell identifies its sidebar with data-dashboard-sidebar and
uses the same toggle/scrim controller. Do not add page-specific sidebar
JavaScript. The shared controller handles mobile opening and closing, Escape,
focus restoration, scroll locking and desktop breakpoint resets.

It defines the Passenger, University Admin and System Admin navigation groups,
labels, links and role metadata. The following shared renderers consume it:

  includes/dashboard/layout_top.php
  passenger/dashboard.php
  passenger/_page_shell.php
  university/dashboard.php
  university/_university_shell.php
  admin/dashboard.php
  admin/_admin_context.php

Therefore, changing a category or link in includes/dashboard/nav.php updates
the main dashboard and all subpages for that role. Do not create a university-
specific dashboard file and do not duplicate a role sidebar inside a page.

The final visual contract for every rendered page is centralized in:

  css/uniride-ui.css

It is loaded last by the public, authentication, Passenger, University Admin,
System Admin, diagnostic and access-denied page shells. It owns the shared
navy/white palette, typography, spacing, top bars, sidebars, cards, tables,
forms, buttons, status indicators, focus states and responsive breakpoints.
Legacy CSS files remain for structural and URL backward compatibility, but a
visual change should be made in css/uniride-ui.css so it reaches every current
page and every role automatically.

The University Admin overview and every University Admin subtask still share
university/_university_shell.php and css/university-theme.css for their
role-specific layout. css/uniride-ui.css is the canonical final layer, so the
overview and all subtasks follow the same login-aligned visual identity.

Page implementations are also role-shared:

  passenger/    one dashboard/page set for every passenger
  university/   one UniAdmin dashboard/page set for every university
  admin/        one System Admin dashboard/page set for the platform

Passenger pages derive passenger_id and university_id from the authenticated
session. University Admin pages derive university_id from the authenticated
administrator relationship. University data is never selected from a URL
parameter.


CENTRALIZED LIGHT AND DARK THEMES
---------------------------------

Every rendered page uses the same theme entry points:

  includes/theme.php
  js/theme.js
  css/uniride-ui.css

includes/theme.php applies the saved or operating-system preference before
stylesheets paint, preventing a light-theme flash. js/theme.js mounts one
accessible light/dark control in the current shared header or top bar and
stores the preference under uniride-color-theme. A cookie fallback keeps the
preference usable when localStorage is blocked. css/uniride-ui.css owns both
sets of design tokens and all final dark-theme component states through the
data-theme attribute on the root html element.

Public, authentication, Passenger, University Admin, System Admin, profile,
diagnostic and access-denied pages consume these same files. Theme state is a
browser presentation preference only: it does not read or alter account,
role, passenger or university identifiers. No database migration is required.


SHARED PROFILE ARCHITECTURE
---------------------------

Passenger, University Admin and System Admin profile pages consume the same
role-aware profile module:

  includes/profile/profile-config.php
  includes/profile/profile-service.php
  includes/profile/profile-picture.php
  includes/profile/password-security.php
  includes/profile/session-management.php
  includes/profile/profile-navigation.php
  includes/profile/profile-page.php
  css/profile.css
  js/profile.js

Import database/migrations/004_shared_profile_management.sql once on an
existing database. It adds non-destructive shared profile, preference,
session and security-event tables. Existing account rows and university
ownership remain unchanged. Future accounts use the same module without new
PHP pages or role-specific schema copies.

Profile pictures are saved under uploads/profile with random filenames and
server-side MIME validation. Ensure Apache/PHP can write to that directory.
The included .htaccess blocks script execution and directory listing.

Changing a common profile field, notification category or permission rule in
the centralized role configuration propagates to every applicable account.
Account IDs, roles and university IDs always come from the authenticated
session and database relationships, never editable form or URL parameters.


ADDING A UNIVERSITY
-------------------

Sign in as System Admin and open:

  System Admin > Universities > Add university

This creates the university and its first University Admin in one database
transaction. The new administrator receives the entire shared UniAdmin
dashboard, all categories and all subtasks immediately. No PHP, CSS or
JavaScript files need to be copied or edited.

Additional University Admins can be created from:

  System Admin > University Administrators

Public university names on the home page are loaded from the active rows in
the universities table, so newly activated universities appear automatically.


TENANT-SAFE FEATURE RULE
------------------------

Every university-owned feature table must carry university_id directly, or be
reachable through an ownership-checked join to a university-owned parent. All
University Admin reads and writes must include the session university_id.

The announcements feature is the reference implementation:

  university/announcements.php
  database/migrations/003_shared_dashboard_tenancy.sql

Publishing an announcement creates notifications only for active passengers
of that same university. The same page works for every existing and future
university.


LOGIN TYPES
-----------

Passenger
  Table: passengers
  Password column: password_hash

University Admin
  Table: university_users
  Password column: password_hash

System Admin
  Table: admins
  Password column: password

The website does not hard-code login accounts.


IMPORTANT FILES
---------------

  config/database.php                    Database connection
  includes/auth.php                      Authentication and role routing
  includes/dashboard/nav.php             Shared role/category registry
  includes/dashboard/layout_top.php      Shared dashboard shell
  includes/theme.php                     Pre-paint theme bootstrap
  css/uniride-ui.css                     Canonical cross-page visual system
  js/theme.js                            Shared theme toggle and persistence
  includes/profile/                      Shared profile and security services
  css/profile.css                        Shared responsive profile UI
  js/profile.js                          Tabs, crop preview and password meter
  admin/universities.php                 University onboarding
  admin/administrators.php               University Admin management
  university/_university_context.php     University tenant boundary
  passenger/_page_shell.php              Passenger identity/tenant boundary
  tools/schema_check.php                 Read-only schema diagnostics
