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
                'database/password_reset_tokens.sql in phpMyAdmin.';
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

    <link rel="stylesheet" href="css/style.css">
</head>
<body class="auth-page">

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
