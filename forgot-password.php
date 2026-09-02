<?php
declare(strict_types=1);

session_start();

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/includes/auth.php';

$type = strtoupper((string)($_POST['account_type'] ?? $_GET['type'] ?? 'PASSENGER'));

if (!in_array($type, ['PASSENGER', 'UNIVERSITY_ADMIN', 'SYSTEM_ADMIN'], true)) {
    $type = 'PASSENGER';
}

$message = '';
$error = '';
$resetLink = '';

function findAccount(PDO $pdo, string $type, string $email): array|false
{
    if ($type === 'PASSENGER') {
        $stmt = $pdo->prepare(
            "SELECT passenger_id AS account_id, status
             FROM passengers
             WHERE LOWER(email)=LOWER(?)
             LIMIT 1"
        );
    } elseif ($type === 'UNIVERSITY_ADMIN') {
        $stmt = $pdo->prepare(
            "SELECT university_user_id AS account_id, status
             FROM university_users
             WHERE LOWER(email)=LOWER(?)
             LIMIT 1"
        );
    } else {
        $stmt = $pdo->prepare(
            "SELECT admin_id AS account_id, status
             FROM admins
             WHERE LOWER(email)=LOWER(?)
             LIMIT 1"
        );
    }

    $stmt->execute([$email]);
    return $stmt->fetch();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = strtolower(trim((string)($_POST['email'] ?? '')));

    if (!verifyCsrf((string)($_POST['csrf_token'] ?? ''))) {
        $error = 'Your session expired. Refresh and try again.';
    } else {
        try {
            if (filter_var($email, FILTER_VALIDATE_EMAIL)) {
                $account = findAccount($pdo, $type, $email);

                if ($account && strtoupper((string)$account['status']) === 'ACTIVE') {
                    $token = bin2hex(random_bytes(32));
                    $tokenHash = hash('sha256', $token);
                    $expires = (new DateTimeImmutable('+30 minutes'))->format('Y-m-d H:i:s');

                    $stmt = $pdo->prepare(
                        "DELETE FROM password_reset_tokens
                         WHERE account_type=?
                           AND account_id=?
                           AND used_at IS NULL"
                    );
                    $stmt->execute([$type, (int)$account['account_id']]);

                    $stmt = $pdo->prepare(
                        "INSERT INTO password_reset_tokens
                            (account_type, account_id, token_hash, expires_at)
                         VALUES (?, ?, ?, ?)"
                    );
                    $stmt->execute([
                        $type,
                        (int)$account['account_id'],
                        $tokenHash,
                        $expires,
                    ]);

                    $dir = rtrim(
                        str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '/')),
                        '/'
                    );

                    $resetLink =
                        'http://' . ($_SERVER['HTTP_HOST'] ?? 'localhost') .
                        $dir .
                        '/reset-password.php?type=' .
                        rawurlencode($type) .
                        '&token=' .
                        rawurlencode($token);
                }
            }

            $message =
                'If an ACTIVE account exists for that email, ' .
                'reset instructions have been generated.';
        } catch (Throwable $e) {
            error_log('[UniRide reset request] ' . $e->getMessage());
            $error =
                'Password reset is not initialized. Import ' .
                'database/migrations/006_core_schema_consistency.sql in phpMyAdmin.';
        }
    }
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Forgot password — UniRide</title>
    <?= uniride_theme_head_html('.') ?>

    <link rel="icon" href="img/logo.svg" type="image/svg+xml">
    <link rel="stylesheet" href="css/style.css">

    <style>
        /* ================================================================
           UniRide forgot-password — current navy / white theme
           Scoped to body.auth-page.recovery-current-theme.
           Password-reset PHP behavior is unchanged.
           ================================================================ */
        body.auth-page.recovery-current-theme {
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

        .recovery-current-theme .topbar {
            background: rgba(255,255,255,.97);
            border-bottom: 1px solid var(--ur-line);
            backdrop-filter: blur(16px);
        }

        .recovery-current-theme .brand img {
            width: 25px;
            height: 25px;
        }

        .recovery-current-theme .brand span {
            color: var(--ur-ink);
            font-weight: 850;
            letter-spacing: -.035em;
        }

        .recovery-current-theme .link-btn {
            color: var(--ur-blue);
            font-weight: 700;
        }

        .recovery-current-theme .auth-layout {
            min-height: calc(100vh - 64px);
            grid-template-columns: minmax(0,.92fr) minmax(430px,.72fr);
            align-items: center;
            gap: clamp(60px,8vw,128px);
            padding-top: 72px;
            padding-bottom: 72px;
        }

        .recovery-current-theme .auth-copy {
            position: relative;
            padding: 38px 0;
        }

        .recovery-current-theme .auth-copy::before {
            content: "";
            position: absolute;
            width: 360px;
            height: 360px;
            left: -125px;
            top: 50%;
            transform: translateY(-50%);
            border-radius: 50%;
            background: radial-gradient(
                circle,
                rgba(24,73,135,.085) 0%,
                rgba(24,73,135,.026) 47%,
                rgba(24,73,135,0) 72%
            );
            pointer-events: none;
        }

        .recovery-current-theme .auth-copy > * {
            position: relative;
            z-index: 1;
        }

        .recovery-current-theme .auth-copy .kicker {
            color: var(--ur-blue);
            font-size: 11px;
            font-weight: 900;
            letter-spacing: .11em;
        }

        .recovery-current-theme .auth-copy h1 {
            margin-top: 20px;
            color: var(--ur-ink);
            font-size: clamp(72px,6.4vw,104px);
            line-height: .88;
            letter-spacing: -.065em;
        }

        .recovery-current-theme .auth-copy h1 em {
            color: var(--ur-blue);
            font-weight: inherit;
        }

        .recovery-current-theme .auth-copy > p:last-child {
            max-width: 520px;
            margin-top: 34px;
            color: var(--ur-muted);
            font-size: 16px;
            line-height: 1.65;
        }

        .recovery-current-theme .login-card {
            width: 100%;
            max-width: 540px;
            justify-self: end;
            padding: 32px;
            border: 1px solid #dfe5ec;
            border-radius: 18px;
            background: #fff;
            box-shadow: 0 18px 54px rgba(16,55,106,.08);
        }

        .recovery-current-theme .login-title h2 {
            color: var(--ur-ink);
            font-size: 23px;
        }

        .recovery-current-theme .login-title p {
            color: var(--ur-muted);
        }

        .recovery-current-theme .field > span:first-child {
            color: var(--ur-ink);
        }

        .recovery-current-theme .field input,
        .recovery-current-theme .field select {
            border-color: #dce2e8;
            background: #fff;
            color: var(--ur-ink);
        }

        .recovery-current-theme .field input:focus,
        .recovery-current-theme .field select:focus {
            border-color: #9eb7d4;
            box-shadow: 0 0 0 3px rgba(24,73,135,.08);
            outline: 0;
        }

        .recovery-current-theme .button-dark {
            border-color: var(--ur-blue);
            background: var(--ur-blue);
            color: #fff;
        }

        .recovery-current-theme .button-dark:hover {
            border-color: var(--ur-blue-dark);
            background: var(--ur-blue-dark);
        }

        .recovery-current-theme .login-note {
            border-top-color: var(--ur-line);
        }

        .recovery-current-theme .login-note a {
            color: var(--ur-blue);
            font-weight: 700;
        }

        .recovery-current-theme .reset-link-box {
            border-color: #cedceb;
            background: var(--ur-blue-pale);
        }

        .recovery-current-theme .reset-link-box strong {
            color: var(--ur-ink);
        }

        .recovery-current-theme .reset-link-box a {
            color: var(--ur-blue);
            font-weight: 800;
        }

        .recovery-current-theme .alert.success {
            border-color: #cbe2d2;
            background: #f0f8f2;
        }

        .recovery-current-theme .alert.error {
            border-color: #efceca;
            background: #fff3f1;
        }

        @media (max-width: 900px) {
            .recovery-current-theme .auth-layout {
                grid-template-columns: 1fr;
                gap: 38px;
                padding-top: 54px;
            }

            .recovery-current-theme .auth-copy {
                padding-bottom: 0;
            }

            .recovery-current-theme .auth-copy h1 {
                font-size: clamp(64px,13vw,92px);
            }

            .recovery-current-theme .login-card {
                max-width: none;
                justify-self: stretch;
            }
        }

        @media (max-width: 640px) {
            .recovery-current-theme .auth-layout {
                padding-top: 36px;
                padding-bottom: 50px;
            }

            .recovery-current-theme .auth-copy h1 {
                font-size: clamp(56px,17vw,78px);
            }

            .recovery-current-theme .auth-copy > p:last-child {
                font-size: 14px;
            }

            .recovery-current-theme .login-card {
                padding: 22px;
                border-radius: 14px;
            }
        }
    </style>
    <link rel="stylesheet" href="css/uniride-ui.css">

</head>
<body class="auth-page recovery-current-theme">


<header class="topbar">
    <div class="container nav">
        <a class="brand" href="index.php">
            <img src="img/logo.svg" alt="">
            <span>UniRide</span>
        </a>

        <div class="nav-actions">
            <a href="signin.php" class="link-btn">Back to sign in</a>
        </div>
    </div>
</header>

<main class="auth-layout container">
    <section class="auth-copy">
        <p class="kicker">Account recovery</p>
        <h1>Reset your<br><em>password.</em></h1>
        <p>On local XAMPP, a secure reset URL is displayed after submission.</p>
    </section>

    <section class="login-card">
        <div class="login-title">
            <h2>Forgot password</h2>
            <p>Reset links expire after 30 minutes.</p>
        </div>

        <?php if ($message): ?>
            <div class="alert success"><?= h($message) ?></div>
        <?php endif; ?>

        <?php if ($error): ?>
            <div class="alert error"><?= h($error) ?></div>
        <?php endif; ?>

        <?php if ($resetLink): ?>
            <div class="reset-link-box">
                <strong>Local reset link</strong>
                <a href="<?= h($resetLink) ?>">Open password reset ↗</a>
            </div>
        <?php endif; ?>

        <form method="post" class="login-form">
            <input type="hidden" name="csrf_token" value="<?= h(csrfToken()) ?>">

            <label class="field">
                <span>Account type</span>
                <select name="account_type">
                    <option value="PASSENGER" <?= $type === 'PASSENGER' ? 'selected' : '' ?>>
                        Passenger / Faculty
                    </option>
                    <option value="UNIVERSITY_ADMIN" <?= $type === 'UNIVERSITY_ADMIN' ? 'selected' : '' ?>>
                        University Admin
                    </option>
                    <option value="SYSTEM_ADMIN" <?= $type === 'SYSTEM_ADMIN' ? 'selected' : '' ?>>
                        System Admin
                    </option>
                </select>
            </label>

            <label class="field">
                <span>Email address</span>
                <input type="email" name="email" required>
            </label>

            <button type="submit" class="button button-dark button-full">
                Generate reset link
            </button>
        </form>

        <p class="login-note">
            <a href="signin.php">← Back to sign in</a>
        </p>
    </section>
</main>

</body>
</html>
