<?php
declare(strict_types=1);
require_once __DIR__ . '/_university_shell.php';
$q=trim((string)($_GET['q']??''));
$sql="SELECT DISTINCT p.passenger_id,p.name,p.email,p.status,s.student_identifier,s.department,s.program,s.semester_label
      FROM passengers p INNER JOIN students s ON s.passenger_id=p.passenger_id
      WHERE p.university_id=? AND p.passenger_type='STUDENT'";$params=[$uUniversityId];
if($q!==''){$sql.=" AND (p.name LIKE ? OR p.email LIKE ? OR s.student_identifier LIKE ? OR s.department LIKE ? OR s.program LIKE ?)";$like='%'.$q.'%';array_push($params,$like,$like,$like,$like,$like);}
$sql.=" ORDER BY p.name LIMIT 250";$rows=[];try{$rows=u_all($pdo,$sql,$params);}catch(Throwable $e){error_log('[UniRide students] '.$e->getMessage());}
u_render_start('Students','students','People','Student passengers registered to this university.');
u_render_actions('<a class="up-button-secondary" href="passengers.php">All Passengers</a>');u_render_heading_end();
?>
<form method="get" class="up-filter up-filter-search"><input type="search" name="q" value="<?= u_h($q) ?>" placeholder="Search student, ID, department or program"><button class="up-button-secondary" type="submit">Search</button></form>
<?php if(!$rows): ?><div class="up-empty"><div><strong>No students found.</strong><p>Students for this university will appear automatically.</p></div></div><?php else: ?>
<div class="up-table-wrap"><table class="up-table"><thead><tr><th>Student</th><th>Identifier</th><th>Department</th><th>Program</th><th>Semester</th><th>Status</th></tr></thead><tbody>
<?php foreach($rows as $r): ?><tr><td><strong><?= u_h($r['name']) ?></strong><small><?= u_h($r['email']) ?></small></td><td><?= u_h($r['student_identifier']) ?></td><td><?= u_h($r['department']) ?></td><td><?= u_h($r['program']) ?></td><td><?= u_h($r['semester_label']) ?></td><td><span class="up-status <?= u_h(u_status_class($r['status'])) ?>"><?= u_h($r['status']) ?></span></td></tr><?php endforeach; ?>
</tbody></table></div><?php endif; ?>
<?php u_render_end(); ?>
