<?php
declare(strict_types=1);
require_once __DIR__ . '/_page_shell.php';

if($_SERVER['REQUEST_METHOD']==='POST'){
 $stmt=$pdo->prepare("INSERT IGNORE INTO route_day_favorites(passenger_id,route_id,day_of_week)
 VALUES(?,?,?)");
 $stmt->execute([$ppPassengerId,$_POST['route_id'],$_POST['day']]);
}

pp_render_start('Favorite Routes','favorite-routes','Travel',
'Favorite routes appear first when that weekday is selected.');

$routes=$pdo->prepare("SELECT route_id,route_name FROM routes WHERE university_id=?");
$routes->execute([$pp_profile['university_id']??0]);

echo '<div class="card"><form method="post">
<select name="route_id">';
foreach($routes as $r){
 echo '<option value="'.$r['route_id'].'">'.pp_h($r['route_name']).'</option>';
}
echo '</select>
<select name="day">';
foreach(['MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'] as $d)
 echo '<option>'.$d.'</option>';
echo '</select>
<button class="button button-dark">Save Favorite</button></form></div>';

pp_render_end();
