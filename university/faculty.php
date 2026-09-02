<?php
declare(strict_types=1);
require_once __DIR__ . '/_university_shell.php';
$q=trim((string)($_GET['q']??''));
$sql="SELECT DISTINCT p.passenger_id,p.name,p.email,p.status,f.faculty_identifier,f.department,f.designation
      FROM passengers p INNER JOIN faculty f ON f.passenger_id=p.passenger_id
      WHERE p.university_id=? AND p.passenger_type='FACULTY'";$params=[$uUniversityId];
if($q!==''){$sql.=" AND (p.name LIKE ? OR p.email LIKE ? OR f.faculty_identifier LIKE ? OR f.department LIKE ? OR f.designation LIKE ?)";$like='%'.$q.'%';array_push($params,$like,$like,$like,$like,$like);}
$sql.=" ORDER BY p.name LIMIT 250";$rows=[];try{$rows=u_all($pdo,$sql,$params);}catch(Throwable $e){error_log('[UniRide faculty] '.$e->getMessage());}
u_render_start('Faculty','faculty','People','Faculty passengers registered to this university.');
u_render_actions('<a class="up-button-secondary" href="passengers.php">All Passengers</a>');u_render_heading_end();
?>
<form method="get" class="up-filter up-filter-search"><input type="search" name="q" value="<?= u_h($q) ?>" placeholder="Search faculty, ID, department or designation"><button class="up-button-secondary" type="submit">Search</button></form>
<?php if(!$rows): ?><div class="up-empty"><div><strong>No faculty found.</strong><p>Faculty for this university will appear automatically.</p></div></div><?php else: ?>
<div class="up-table-wrap"><table class="up-table"><thead><tr><th>Faculty</th><th>Identifier</th><th>Department</th><th>Designation</th><th>Status</th></tr></thead><tbody>
<?php foreach($rows as $r): ?><tr><td><strong><?= u_h($r['name']) ?></strong><small><?= u_h($r['email']) ?></small></td><td><?= u_h($r['faculty_identifier']) ?></td><td><?= u_h($r['department']) ?></td><td><?= u_h($r['designation']) ?></td><td><span class="up-status <?= u_h(u_status_class($r['status'])) ?>"><?= u_h($r['status']) ?></span></td></tr><?php endforeach; ?>
</tbody></table></div><?php endif; ?>
<?php u_render_end(); ?>
