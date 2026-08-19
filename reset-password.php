<?php
declare(strict_types=1);

session_start();

require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/includes/auth.php';

$type = strtoupper((string)($_POST['account_type'] ?? $_GET['type'] ?? ''));
$token = (string)($_POST['token'] ?? $_GET['token'] ?? '');
$error = '';

if (
    !in_array($type, ['PASSENGER', 'UNIVERSITY_ADMIN', 'SYSTEM_ADMIN'], true) ||
    !preg_match('/^[a-f0-9]{64}$/i', $token)
) {
    $error = 'This password reset link is invalid.';
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !$error) {
    $password = (string)($_POST['password'] ?? '');
    $confirm = (string)($_POST['confirm_password'] ?? '');

    if (!verifyCsrf((string)($_POST['csrf_token'] ?? ''))) {
        $error = 'Your session expired. Refresh and try again.';
    } elseif (strlen($password) < 8) {
        $error = 'Use at least 8 characters.';
    } elseif ($password !== $confirm) {
        $error = 'Passwords do not match.';
    } else {
        try {
            $pdo->beginTransaction();

            $tokenHash = hash('sha256', $token);

            $stmt = $pdo->prepare(
                "SELECT *
                 FROM password_reset_tokens
                 WHERE token_hash=?
                   AND account_type=?
                 LIMIT 1
                 FOR UPDATE"
            );
            $stmt->execute([$tokenHash, $type]);
            $reset = $stmt->fetch();

            if (
                !$reset ||
                $reset['used_at'] !== null ||
                strtotime((string)$reset['expires_at']) < time()
            ) {
                $pdo->rollBack();
                $error = 'This reset link is invalid or expired.';
            } else {
                $hash = password_hash($password, PASSWORD_DEFAULT);
                $accountId = (int)$reset['account_id'];

                if ($type === 'PASSENGER') {
                    $stmt = $pdo->prepare(
                        "UPDATE passengers
                         SET password_hash=?
                         WHERE passenger_id=?"
                    );
                } elseif ($type === 'UNIVERSITY_ADMIN') {
                    $stmt = $pdo->prepare(
                        "UPDATE university_users
                         SET password_hash=?
                         WHERE university_user_id=?"
                    );
                } else {
                    $stmt = $pdo->prepare(
                        "UPDATE admins
                         SET password=?
                         WHERE admin_id=?"
                    );
                }

                $stmt->execute([$hash, $accountId]);

                $stmt = $pdo->prepare(
                    "UPDATE password_reset_tokens
                     SET used_at=NOW()
                     WHERE reset_id=?"
                );
                $stmt->execute([(int)$reset['reset_id']]);

                $pdo->commit();

                header('Location: signin.php?reset=success');
                exit;
            }
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }

            error_log('[UniRide password reset] ' . $e->getMessage());
            $error = 'Password reset failed. Request another link.';
        }
    }
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>New password — UniRide</title>

    <link rel="stylesheet" href="css/style.css">
</head>
<body class="auth-page">

<main class="auth-layout container">
    <section class="auth-copy">
        <p class="kicker">Account recovery</p>
        <h1>Create a new<br><em>password.</em></h1>
        <p>Your new password is stored using PHP password hashing.</p>
    </section>

    <section class="login-card">
        <div class="login-title">
            <h2>New password</h2>
            <p>Use at least 8 characters.</p>
        </div>

        <?php if ($error): ?>
            <div class="alert error"><?= h($error) ?></div>
        <?php endif; ?>

        <?php if ($token && $type): ?>
            <form method="post" class="login-form">
                <input type="hidden" name="csrf_token" value="<?= h(csrfToken()) ?>">
                <input type="hidden" name="account_type" value="<?= h($type) ?>">
                <input type="hidden" name="token" value="<?= h($token) ?>">

                <label class="field">
                    <span>New password</span>
                    <input
                        type="password"
                        name="password"
                        minlength="8"
                        autocomplete="new-password"
                        required
                    >
                </label>

                <label class="field">
                    <span>Confirm password</span>
                    <input
                        type="password"
                        name="confirm_password"
                        minlength="8"
                        autocomplete="new-password"
                        required
                    >
                </label>

                <button type="submit" class="button button-dark button-full">
                    Reset password
                </button>
            </form>
        <?php endif; ?>

        <p class="login-note">
            <a href="signin.php">← Back to sign in</a>
        </p>
    </section>
</main>

</body>
</html>
