<?php
declare(strict_types=1);

session_start();

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/includes/auth.php';

if (!empty($_SESSION['authenticated'])) {
    header('Location: dashboard.php');
    exit;
}

$error = '';
$success = isset($_GET['reset']) && $_GET['reset'] === 'success'
    ? 'Password changed successfully. You can now sign in.'
    : '';

$accountType = strtoupper((string)($_POST['account_type'] ?? 'PASSENGER'));
$email = strtolower(trim((string)($_POST['email'] ?? '')));

if (!in_array($accountType, ['PASSENGER', 'UNIVERSITY_ADMIN', 'SYSTEM_ADMIN'], true)) {
    $accountType = 'PASSENGER';
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $password = (string)($_POST['password'] ?? '');

    if (!verifyCsrf((string)($_POST['csrf_token'] ?? ''))) {
        $error = 'Your session expired. Please refresh and try again.';
    } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL) || $password === '') {
        $error = 'Invalid email or password.';
    } else {
        try {
            if ($accountType === 'PASSENGER') {
                $stmt = $pdo->prepare(
                    "SELECT
                        passenger_id,
                        university_id,
                        name,
                        email,
                        password_hash,
                        passenger_type,
                        status
                     FROM passengers
                     WHERE LOWER(email)=LOWER(?)
                     LIMIT 1"
                );
                $stmt->execute([$email]);
                $user = $stmt->fetch();

                if (
                    $user &&
                    strtoupper((string)$user['status']) === 'ACTIVE' &&
                    password_verify($password, (string)$user['password_hash'])
                ) {
                    session_regenerate_id(true);

                    $_SESSION['authenticated'] = true;
                    $_SESSION['user_type'] = 'PASSENGER';
                    $_SESSION['user_id'] = (int)$user['passenger_id'];
                    $_SESSION['passenger_id'] = (int)$user['passenger_id'];
                    $_SESSION['university_id'] = (int)$user['university_id'];
                    $_SESSION['passenger_type'] = (string)$user['passenger_type'];
                    $_SESSION['name'] = (string)$user['name'];
                    $_SESSION['email'] = (string)$user['email'];

                    header('Location: dashboard.php');
                    exit;
                }
            } elseif ($accountType === 'UNIVERSITY_ADMIN') {
                $stmt = $pdo->prepare(
                    "SELECT
                        university_user_id,
                        university_id,
                        name,
                        email,
                        password_hash,
                        role,
                        status
                     FROM university_users
                     WHERE LOWER(email)=LOWER(?)
                     LIMIT 1"
                );
                $stmt->execute([$email]);
                $user = $stmt->fetch();

                if (
                    $user &&
                    strtoupper((string)$user['status']) === 'ACTIVE' &&
                    password_verify($password, (string)$user['password_hash'])
                ) {
                    session_regenerate_id(true);

                    $_SESSION['authenticated'] = true;
                    $_SESSION['user_type'] = 'UNIVERSITY_ADMIN';
                    $_SESSION['user_id'] = (int)$user['university_user_id'];
                    $_SESSION['university_user_id'] = (int)$user['university_user_id'];
                    $_SESSION['university_id'] = (int)$user['university_id'];
                    $_SESSION['role'] = (string)$user['role'];
                    $_SESSION['name'] = (string)$user['name'];
                    $_SESSION['email'] = (string)$user['email'];

                    header('Location: dashboard.php');
                    exit;
                }
            } else {
                /*
                 * Your supplied schema uses admins.password for System Admin.
                 */
                $stmt = $pdo->prepare(
                    "SELECT
                        admin_id,
                        name,
                        email,
                        password,
                        status
                     FROM admins
                     WHERE LOWER(email)=LOWER(?)
                     LIMIT 1"
                );
                $stmt->execute([$email]);
                $user = $stmt->fetch();

                if (
                    $user &&
                    strtoupper((string)$user['status']) === 'ACTIVE' &&
                    password_verify($password, (string)$user['password'])
                ) {
                    session_regenerate_id(true);

                    $_SESSION['authenticated'] = true;
                    $_SESSION['user_type'] = 'SYSTEM_ADMIN';
                    $_SESSION['user_id'] = (int)$user['admin_id'];
                    $_SESSION['admin_id'] = (int)$user['admin_id'];
                    $_SESSION['name'] = (string)$user['name'];
                    $_SESSION['email'] = (string)$user['email'];

                    header('Location: dashboard.php');
                    exit;
                }
            }

            $error = 'Invalid email or password.';
        } catch (Throwable $e) {
            error_log('[UniRide login] ' . $e->getMessage());
            $error = 'Sign in is temporarily unavailable.';
        }
    }
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sign in — UniRide</title>

    <link rel="icon" href="img/logo.svg" type="image/svg+xml">
    <link rel="stylesheet" href="css/style.css">
    <script src="js/app.js" defer></script>
</head>
<body class="auth-page">

<header class="topbar">
    <div class="container nav">
        <a class="brand" href="index.php">
            <img src="img/logo.svg" alt="">
            <span>UniRide</span>
        </a>

        <div class="nav-actions">
            <a href="index.php" class="link-btn">Back to home</a>
        </div>
    </div>
</header>

<main class="auth-layout container">
    <section class="auth-copy">
        <p class="kicker">Secure database login</p>

        <h1>
            Welcome<br>
            <em>back.</em>
        </h1>

        <p>
            Students and faculty use Passenger. University transport admins use
            Uni Admin. The central administrator uses Sys Admin.
        </p>
    </section>

    <section class="login-card">
        <div class="login-title">
            <h2>Sign in</h2>
            <p>Your account is verified directly against <strong>uniride2</strong>.</p>
        </div>

        <?php if ($success): ?>
            <div class="alert success"><?= h($success) ?></div>
        <?php endif; ?>

        <?php if ($error): ?>
            <div class="alert error"><?= h($error) ?></div>
        <?php endif; ?>

        <div class="login-tabs">
            <button
                type="button"
                data-auth-tab="PASSENGER"
                class="<?= $accountType === 'PASSENGER' ? 'active' : '' ?>"
            >
                Passenger
            </button>

            <button
                type="button"
                data-auth-tab="UNIVERSITY_ADMIN"
                class="<?= $accountType === 'UNIVERSITY_ADMIN' ? 'active' : '' ?>"
            >
                Uni Admin
            </button>

            <button
                type="button"
                data-auth-tab="SYSTEM_ADMIN"
                class="<?= $accountType === 'SYSTEM_ADMIN' ? 'active' : '' ?>"
            >
                Sys Admin
            </button>
        </div>

        <form method="post" class="login-form">
            <input type="hidden" name="csrf_token" value="<?= h(csrfToken()) ?>">
            <input type="hidden" name="account_type" id="accountType" value="<?= h($accountType) ?>">

            <label class="field">
                <span id="emailLabel">
                    <?= $accountType === 'PASSENGER'
                        ? 'Academic email address'
                        : 'Email address'
                    ?>
                </span>
                <input
                    type="email"
                    name="email"
                    value="<?= h($email) ?>"
                    placeholder="Enter your email"
                    autocomplete="username"
                    required
                >
            </label>

            <label class="field">
                <span>Password</span>

                <span class="password-wrap">
                    <input
                        type="password"
                        name="password"
                        id="passwordInput"
                        placeholder="Enter your password"
                        autocomplete="current-password"
                        required
                    >
                    <button type="button" data-password-toggle>Show</button>
                </span>
            </label>

            <div class="form-options">
                <span></span>

                <a
                    href="forgot-password.php?type=<?= urlencode($accountType) ?>"
                    id="forgotLink"
                >
                    Forgot password?
                </a>
            </div>

            <button type="submit" class="button button-dark button-full">
                Sign in
            </button>
        </form>

        <p class="login-note">
            No quick-fill demo-account section. Any ACTIVE database account
            can log in using its stored password.
        </p>
    </section>
</main>

</body>
</html>
