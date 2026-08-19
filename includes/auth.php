<?php
declare(strict_types=1);

function h(mixed $value): string
{
    return htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
}

function csrfToken(): string
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }

    return (string)$_SESSION['csrf_token'];
}

function verifyCsrf(string $submitted): bool
{
    return hash_equals(csrfToken(), $submitted);
}

function requireLogin(): void
{
    if (empty($_SESSION['authenticated']) || empty($_SESSION['user_type'])) {
        header('Location: signin.php');
        exit;
    }
}
