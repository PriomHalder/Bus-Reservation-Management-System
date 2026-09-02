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
    : ((isset($_GET['session']) && $_GET['session'] === 'revoked')
        ? 'That session was signed out. Please sign in again if this was you.'
        : '');

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
        $attemptedUserId = 0;
        try {
            if ($accountType === 'PASSENGER') {
                $stmt = $pdo->prepare(
                    "SELECT
                        p.passenger_id,
                        p.university_id,
                        p.name,
                        p.email,
                        p.password_hash,
                        p.passenger_type,
                        p.status,
                        u.status AS university_status
                     FROM passengers p
                     INNER JOIN universities u ON u.university_id=p.university_id
                     WHERE LOWER(p.email)=LOWER(?)
                     LIMIT 1"
                );
                $stmt->execute([$email]);
                $user = $stmt->fetch();
                $attemptedUserId = (int)($user['passenger_id'] ?? 0);

                if (
                    $user &&
                    strtoupper((string)$user['status']) === 'ACTIVE' &&
                    strtoupper((string)$user['university_status']) === 'ACTIVE' &&
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

                    profile_register_login($pdo, 'PASSENGER', (int)$user['passenger_id']);
                    profile_sync_session($pdo, 'PASSENGER', (int)$user['passenger_id']);

                    header('Location: dashboard.php');
                    exit;
                }
            } elseif ($accountType === 'UNIVERSITY_ADMIN') {
                $stmt = $pdo->prepare(
                    "SELECT
                        uu.university_user_id,
                        uu.university_id,
                        uu.name,
                        uu.email,
                        uu.password_hash,
                        uu.role,
                        uu.status,
                        u.status AS university_status
                     FROM university_users uu
                     INNER JOIN universities u ON u.university_id=uu.university_id
                     WHERE LOWER(uu.email)=LOWER(?)
                     LIMIT 1"
                );
                $stmt->execute([$email]);
                $user = $stmt->fetch();
                $attemptedUserId = (int)($user['university_user_id'] ?? 0);

                if (
                    $user &&
                    strtoupper((string)$user['status']) === 'ACTIVE' &&
                    strtoupper((string)$user['university_status']) === 'ACTIVE' &&
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

                    profile_register_login($pdo, 'UNIVERSITY_ADMIN', (int)$user['university_user_id']);
                    profile_sync_session($pdo, 'UNIVERSITY_ADMIN', (int)$user['university_user_id']);

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
                $attemptedUserId = (int)($user['admin_id'] ?? 0);

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

                    profile_register_login($pdo, 'SYSTEM_ADMIN', (int)$user['admin_id']);
                    profile_sync_session($pdo, 'SYSTEM_ADMIN', (int)$user['admin_id']);

                    header('Location: dashboard.php');
                    exit;
                }
            }

            if ($attemptedUserId > 0) {
                profile_log_event($pdo, $accountType, $attemptedUserId, 'LOGIN_FAILED', 'An unsuccessful sign-in attempt was recorded.');
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
    <?= uniride_theme_head_html('.') ?>

    <link rel="icon" href="img/logo.svg" type="image/svg+xml">
    <link rel="stylesheet" href="css/style.css">

    <style>
        /* ================================================================
           UniRide sign-in — current navy / white theme
           Scoped to body.auth-page.auth-current-theme.
           Authentication PHP/JS behavior is unchanged.
           ================================================================ */
        body.auth-page.auth-current-theme {
            --ur-blue: #184987;
            --ur-blue-dark: #10376a;
            --ur-blue-soft: #eef4fb;
            --ur-blue-pale: #f8fbff;
            --ur-ink: #17191c;
            --ur-muted: #707780;
            --ur-line: #e3e8ee;
            --ur-white: #ffffff;
            margin: 0;
            background: #fff;
            color: var(--ur-ink);
        }

        .auth-current-theme .topbar {
            background: rgba(255,255,255,.97);
            border-bottom: 1px solid var(--ur-line);
            backdrop-filter: blur(16px);
        }

        .auth-current-theme .brand img {
            width: 25px;
            height: 25px;
        }

        .auth-current-theme .brand span {
            color: var(--ur-ink);
            font-weight: 850;
            letter-spacing: -.035em;
        }

        .auth-current-theme .link-btn {
            color: var(--ur-blue);
            font-weight: 700;
        }

        .auth-current-theme .auth-layout {
            min-height: calc(100vh - 64px);
            grid-template-columns: minmax(0, .92fr) minmax(430px, .72fr);
            align-items: center;
            gap: clamp(60px, 8vw, 128px);
            padding-top: 72px;
            padding-bottom: 72px;
        }

        .auth-current-theme .auth-copy {
            position: relative;
            padding: 38px 0;
        }

        .auth-current-theme .auth-copy::before {
            content: "";
            position: absolute;
            width: 350px;
            height: 350px;
            left: -120px;
            top: 50%;
            transform: translateY(-50%);
            border-radius: 50%;
            background: radial-gradient(
                circle,
                rgba(24,73,135,.08) 0%,
                rgba(24,73,135,.025) 46%,
                rgba(24,73,135,0) 72%
            );
            pointer-events: none;
        }

        .auth-current-theme .auth-copy > * {
            position: relative;
            z-index: 1;
        }

        .auth-current-theme .auth-copy .kicker {
            color: var(--ur-blue);
            font-size: 11px;
            font-weight: 900;
            letter-spacing: .11em;
        }

        .auth-current-theme .auth-copy h1 {
            margin-top: 20px;
            color: var(--ur-ink);
            font-size: clamp(72px, 6.4vw, 104px);
            line-height: .88;
            letter-spacing: -.065em;
        }

        .auth-current-theme .auth-copy h1 em {
            color: var(--ur-blue);
            font-weight: inherit;
        }

        .auth-current-theme .auth-copy > p:last-child {
            max-width: 520px;
            margin-top: 34px;
            color: var(--ur-muted);
            font-size: 16px;
            line-height: 1.65;
        }

        .auth-current-theme .login-card {
            width: 100%;
            max-width: 540px;
            justify-self: end;
            padding: 32px;
            border: 1px solid #dfe5ec;
            border-radius: 18px;
            background: #fff;
            box-shadow: 0 18px 54px rgba(16,55,106,.08);
        }

        .auth-current-theme .login-title h2 {
            color: var(--ur-ink);
            font-size: 23px;
        }

        .auth-current-theme .login-title p {
            color: var(--ur-muted);
        }

        .auth-current-theme .login-title strong {
            color: var(--ur-blue);
        }

        .auth-current-theme .login-tabs {
            padding: 5px;
            border: 1px solid #e8ebef;
            background: #f4f6f8;
        }

        .auth-current-theme .login-tabs button {
            color: #6c737b;
            border: 0;
            transition: color .15s ease, background .15s ease, box-shadow .15s ease;
        }

        .auth-current-theme .login-tabs button:hover {
            color: var(--ur-blue);
        }

        .auth-current-theme .login-tabs button.active {
            background: var(--ur-blue);
            color: #fff;
            box-shadow: 0 3px 10px rgba(24,73,135,.16);
        }

        .auth-current-theme .field > span:first-child {
            color: var(--ur-ink);
        }

        .auth-current-theme .field input,
        .auth-current-theme .field select,
        .auth-current-theme .password-wrap {
            border-color: #dce2e8;
            background: #fff;
        }

        .auth-current-theme .field input:focus,
        .auth-current-theme .field select:focus,
        .auth-current-theme .password-wrap:focus-within {
            border-color: #9eb7d4;
            box-shadow: 0 0 0 3px rgba(24,73,135,.08);
        }

        .auth-current-theme .password-wrap input {
            box-shadow: none !important;
        }

        .auth-current-theme [data-password-toggle] {
            color: var(--ur-blue);
            background: var(--ur-blue-soft);
        }

        .auth-current-theme .form-options a,
        .auth-current-theme .login-note a {
            color: var(--ur-blue);
        }

        .auth-current-theme .button-dark {
            border-color: var(--ur-blue);
            background: var(--ur-blue);
            color: #fff;
        }

        .auth-current-theme .button-dark:hover {
            border-color: var(--ur-blue-dark);
            background: var(--ur-blue-dark);
        }

        .auth-current-theme .login-note {
            border-top-color: var(--ur-line);
            color: #858b92;
        }

        .auth-current-theme .alert.success {
            border-color: #cbe2d2;
            background: #f0f8f2;
        }

        .auth-current-theme .alert.error {
            border-color: #efceca;
            background: #fff3f1;
        }

        @media (max-width: 900px) {
            .auth-current-theme .auth-layout {
                grid-template-columns: 1fr;
                gap: 38px;
                padding-top: 54px;
            }

            .auth-current-theme .auth-copy {
                padding-bottom: 0;
            }

            .auth-current-theme .auth-copy h1 {
                font-size: clamp(64px, 13vw, 92px);
            }

            .auth-current-theme .login-card {
                max-width: none;
                justify-self: stretch;
            }
        }

        @media (max-width: 640px) {
            .auth-current-theme .auth-layout {
                padding-top: 36px;
                padding-bottom: 50px;
            }

            .auth-current-theme .auth-copy h1 {
                font-size: clamp(56px, 17vw, 78px);
            }

            .auth-current-theme .auth-copy > p:last-child {
                font-size: 14px;
            }

            .auth-current-theme .login-card {
                padding: 22px;
                border-radius: 14px;
            }
        }
    </style>
    <link rel="stylesheet" href="css/uniride-ui.css">

    <script src="js/app.js" defer></script>
</head>
<body class="auth-page auth-current-theme">

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
            Uni Admin. The central administrator uses System Admin.
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
                System Admin
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
