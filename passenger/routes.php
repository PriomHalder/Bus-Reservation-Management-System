<?php
declare(strict_types=1);
require_once __DIR__ . '/_page_shell.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['toggle_favorite_schedule'])) {
    $scheduleId = (int)($_POST['schedule_id'] ?? 0);
    $routeId = (int)($_POST['route_id'] ?? 0);
    $check = $pdo->prepare("SELECT schedule_id FROM schedules WHERE schedule_id=?");
    $check->execute([$scheduleId]);
    if ($check->fetchColumn()) {
        $exists = $pdo->prepare("SELECT favorite_id FROM schedule_favorites WHERE passenger_id=? AND route_id=? AND schedule_id=?");
        $exists->execute([$ppPassengerId,$routeId,$scheduleId]);
        if ($exists->fetchColumn()) {
            $pdo->prepare("DELETE FROM schedule_favorites WHERE passenger_id=? AND route_id=? AND schedule_id=?")->execute([$ppPassengerId,$routeId,$scheduleId]);
        } else {
            $pdo->prepare("INSERT INTO schedule_favorites(passenger_id,route_id,schedule_id) VALUES(?,?,?)")->execute([$ppPassengerId,$routeId,$scheduleId]);
        }
    }
    header('Location: routes.php'); exit;
}

pp_render_start('Routes & Schedules','routes','Travel','Routes of your university with all schedules. Favorite schedules appear first.');

$favStmt=$pdo->prepare("SELECT s.*, r.route_id, r.route_name, r.start_location, r.end_location
FROM schedule_favorites sf
JOIN schedules s ON s.schedule_id=sf.schedule_id
JOIN routes r ON r.route_id=sf.route_id AND r.university_id=?
WHERE sf.passenger_id=?
ORDER BY sf.created_at DESC");
$favStmt->execute([$ppUniversityId,$ppPassengerId]);

$routesStmt=$pdo->prepare("SELECT * FROM routes WHERE university_id=? AND status='ACTIVE' ORDER BY route_id");
$routesStmt->execute([$ppUniversityId]);

// IMPORTANT: Every route displays every schedule from schedules table.
$schedulesStmt=$pdo->prepare("SELECT s.*, b.registration_number AS bus_number,
CASE WHEN sf.favorite_id IS NULL THEN 0 ELSE 1 END AS favorite
FROM schedules s
LEFT JOIN buses b ON b.bus_id=s.bus_id
LEFT JOIN schedule_favorites sf ON sf.schedule_id=s.schedule_id AND sf.route_id=? AND sf.passenger_id=?
ORDER BY s.schedule_id ASC");

?>
<div class="card">
<?php
$favorites=[];
foreach($favStmt as $f){$favorites[]=$f;}
if($favorites){
 echo '<h2 style="color:#111">★ Favorite Schedules</h2>';
 foreach($favorites as $f){
 echo '<div style="border:2px solid #888;padding:12px;margin:8px 0;border-radius:8px;background:#fff;color:#111">';
 echo '<b>Route #'.pp_h($f['route_id']).': '.pp_h($f['route_name']).'</b><br>';
 echo 'Schedule #'.pp_h($f['schedule_id']).' | '.pp_h($f['schedule_date']).' | '.pp_h($f['departure_time']).' - '.pp_h($f['arrival_time']);
 echo '</div>';
 }
}

foreach($routesStmt as $r){
 echo '<div style="border:1px solid #aaa;padding:18px;margin:18px 0;border-radius:12px">';
 echo '<h3 style="color:#111">Route #'.pp_h($r['route_id']).': '.pp_h($r['route_name']).'</h3>';
 echo '<p style="color:#111">'.pp_h($r['start_location']).' → '.pp_h($r['end_location']).' | Fare: '.pp_h($r['fare']).'</p>';
 $schedulesStmt->execute([$r['route_id'],$ppPassengerId]);
 foreach($schedulesStmt as $s){
 echo '<div style="display:flex;justify-content:space-between;align-items:center;padding:10px;background:#fff;color:#111;margin:8px 0;border-radius:8px">';
 echo '<span style="color:#111"><b>Schedule #'.pp_h($s['schedule_id']).'</b> | '.pp_h($s['schedule_date']).' | '.pp_h($s['departure_time']).' - '.pp_h($s['arrival_time']).'</span>';
 echo '<form method="post"><input type="hidden" name="route_id" value="'.pp_h($r['route_id']).'"><input type="hidden" name="schedule_id" value="'.pp_h($s['schedule_id']).'"><button class="button button-dark" name="toggle_favorite_schedule">'.($s['favorite']?'★ Favorite':'☆ Mark Favorite').'</button></form>';
 echo '</div>';
 }
 echo '</div>';
}
?>
</div>
<?php pp_render_end(); ?>
