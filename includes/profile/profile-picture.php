<?php
declare(strict_types=1);

require_once __DIR__ . '/profile-service.php';

function profile_picture_directory(): string
{
    return dirname(__DIR__, 2) . '/uploads/profile';
}

function profile_picture_max_label(): string
{
    $megabytes = PROFILE_PICTURE_MAX_BYTES / 1024 / 1024;
    return rtrim(rtrim(number_format($megabytes, 2, '.', ''), '0'), '.') . ' MB';
}

function profile_existing_picture(PDO $pdo, string $role, int $userId): ?string
{
    $stmt = $pdo->prepare('SELECT profile_picture_path FROM user_profiles WHERE user_type=? AND user_id=? LIMIT 1');
    $stmt->execute([$role, $userId]);
    return profile_safe_picture_path($stmt->fetchColumn() ?: null);
}

function profile_delete_picture_file(?string $relativePath): void
{
    $safe = profile_safe_picture_path($relativePath);
    if ($safe === null) return;
    $root = realpath(dirname(__DIR__, 2));
    $directory = realpath(profile_picture_directory());
    $candidate = $root ? $root . '/' . $safe : '';
    if (!$root || !$directory || $candidate === '' || !str_starts_with($candidate, $directory . DIRECTORY_SEPARATOR)) return;
    if (is_file($candidate)) @unlink($candidate);
}

function profile_upload_picture(PDO $pdo, string $role, int $userId, array $file): string
{
    if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        throw new RuntimeException('Choose a JPEG, PNG or WebP profile picture to upload.');
    }
    $size = (int)($file['size'] ?? 0);
    if ($size < 1 || $size > PROFILE_PICTURE_MAX_BYTES) {
        throw new RuntimeException('The profile picture must be smaller than ' . profile_picture_max_label() . '.');
    }
    $tmp = (string)($file['tmp_name'] ?? '');
    if ($tmp === '' || !is_uploaded_file($tmp)) {
        throw new RuntimeException('The uploaded profile picture could not be verified.');
    }
    $finfo = new finfo(FILEINFO_MIME_TYPE);
    $mime = (string)$finfo->file($tmp);
    $extensions = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'];
    if (!isset($extensions[$mime])) {
        throw new RuntimeException('Only genuine JPEG, PNG and WebP images are accepted.');
    }
    $dimensions = @getimagesize($tmp);
    if (!$dimensions || $dimensions[0] < 32 || $dimensions[1] < 32 || $dimensions[0] > 8000 || $dimensions[1] > 8000) {
        throw new RuntimeException('The image dimensions are invalid or unsupported.');
    }
    $directory = profile_picture_directory();
    if (!is_dir($directory) && !mkdir($directory, 0755, true) && !is_dir($directory)) {
        throw new RuntimeException('Profile-picture storage is not available.');
    }
    $filename = bin2hex(random_bytes(16)) . '.' . $extensions[$mime];
    $destination = $directory . '/' . $filename;
    if (!move_uploaded_file($tmp, $destination)) {
        throw new RuntimeException('The profile picture could not be saved.');
    }
    @chmod($destination, 0644);
    $relative = 'uploads/profile/' . $filename;
    $old = profile_existing_picture($pdo, $role, $userId);
    try {
        $stmt = $pdo->prepare(
            'INSERT INTO user_profiles (user_type,user_id,profile_picture_path) VALUES (?,?,?)
             ON DUPLICATE KEY UPDATE profile_picture_path=VALUES(profile_picture_path)'
        );
        $stmt->execute([$role, $userId, $relative]);
    } catch (Throwable $e) {
        @unlink($destination);
        throw $e;
    }
    if ($old !== null && $old !== $relative) profile_delete_picture_file($old);
    $_SESSION['profile_picture_path'] = $relative;
    profile_log_event($pdo, $role, $userId, 'PROFILE_PICTURE_UPDATED', 'The profile picture was replaced.');
    return $relative;
}

function profile_remove_picture(PDO $pdo, string $role, int $userId): void
{
    $old = profile_existing_picture($pdo, $role, $userId);
    $stmt = $pdo->prepare('UPDATE user_profiles SET profile_picture_path=NULL WHERE user_type=? AND user_id=?');
    $stmt->execute([$role, $userId]);
    profile_delete_picture_file($old);
    unset($_SESSION['profile_picture_path']);
    profile_log_event($pdo, $role, $userId, 'PROFILE_PICTURE_REMOVED', 'The profile picture was removed.');
}
