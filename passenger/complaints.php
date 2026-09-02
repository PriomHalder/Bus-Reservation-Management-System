<?php
declare(strict_types=1);

require_once __DIR__ . '/_page_shell.php';

/*
    Complaint System Fix:
    - Never trust university_id from the browser.
    - Always get university_id from the logged-in passenger account.
*/

$profileStmt = $pdo->prepare("
    SELECT passenger_id, university_id, name
    FROM passengers
    WHERE passenger_id = ?
");

$profileStmt->execute([$ppPassengerId]);
$pp_profile = $profileStmt->fetch(PDO::FETCH_ASSOC);

if (!$pp_profile) {
    die("Passenger profile not found.");
}


if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $subject = trim($_POST['subject'] ?? '');
    $description = trim($_POST['description'] ?? '');

    if ($subject !== '' && $description !== '') {

        $stmt = $pdo->prepare("
            INSERT INTO complaints
            (
                passenger_id,
                university_id,
                subject,
                description
            )
            VALUES
            (?,?,?,?)
        ");

        $stmt->execute([
            $ppPassengerId,
            (int)$pp_profile['university_id'],
            $subject,
            $description
        ]);

        header("Location: complaints.php");
        exit;
    }
}


pp_render_start(
    'Complaints',
    'complaints',
    'Account',
    'Submit complaints directly to your university transport authority.'
);


$stmt = $pdo->prepare("
    SELECT *
    FROM complaints
    WHERE passenger_id = ?
    ORDER BY submitted_at DESC
");

$stmt->execute([$ppPassengerId]);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);


echo '<div class="card">';
echo '<form method="post">

<input 
    name="subject" 
    placeholder="Complaint subject" 
    required>

<textarea 
    name="description" 
    placeholder="Describe your issue" 
    required></textarea>

<button class="button button-dark">
Submit Complaint
</button>

</form></div>';


echo '<div class="card">';
echo '<h2>Your Complaints</h2>';

foreach ($rows as $r) {

    echo '<p>
    <b>'.pp_h($r['subject']).'</b><br>
    Status: '.pp_h($r['status']).'<br>';

    if (!empty($r['university_response'])) {
        echo 'Response: '.pp_h($r['university_response']).'<br>';
    }

    echo '</p>';
}

echo '</div>';

pp_render_end();
?>
