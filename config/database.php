<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/includes/theme.php';

/*
|--------------------------------------------------------------------------
| UniRide2 MySQL Connection
|--------------------------------------------------------------------------
| XAMPP default:
| Host: 127.0.0.1
| Port: 3306
| Database: uniride2
| User: root
| Password: empty
*/

$dbHost = '127.0.0.1';
$dbPort = '3306';
$dbName = 'uniride2';
$dbUser = 'root';
$dbPass = '';
$charset = 'utf8mb4';

$dsn = "mysql:host={$dbHost};port={$dbPort};dbname={$dbName};charset={$charset}";

$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $dbUser, $dbPass, $options);
} catch (PDOException $e) {
    error_log('[UniRide DB] ' . $e->getMessage());

    if (!empty($UNI_DB_OPTIONAL)) {
        $pdo = null;
        return;
    }

    http_response_code(500);
    uniride_render_error_page(
        'Database connection failed. Start MySQL in XAMPP and confirm ' .
        'that phpMyAdmin contains the database "uniride2".'
    );
}
