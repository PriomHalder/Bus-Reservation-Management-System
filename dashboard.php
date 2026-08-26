<?php
declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| UniRide — Dashboard router
|--------------------------------------------------------------------------
| signin.php, forgot-password.php and reset-password.php all send an
| authenticated user to /dashboard.php, so this path has to keep working.
| Rather than editing those files, this one stays as the single entry point
| and forwards to the role's own dashboard.
|
| It holds no markup and no queries — each role's page owns its own
| layout and data, so there are no role branches to grow over time.
*/

session_start();

require_once __DIR__ . '/includes/auth.php';

if (empty($_SESSION['authenticated'])) {
    header('Location: signin.php');
    exit;
}

header('Location: ' . dashboardPathFor($_SESSION['user_type'] ?? null));
exit;
