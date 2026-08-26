<?php
declare(strict_types=1);
require_once __DIR__ . '/_university_shell.php';

$q=trim((string)($_GET['q']??''));
$type=strtoupper((string)($_GET['type']??'ALL'));
$status=strtoupper((string)($_GET['status']??'ALL'));
if(!in_array($type,['ALL','STUDENT','FACULTY'],true))$type='ALL';
if(!in_array($status,['ALL','ACTIVE','INACTIVE','SUSPENDED'],true))$status='ALL';

$sql="SELECT DISTINCT p.passenger_id,p.name,p.email,p.phone,p.passenger_type,p.status,
             s.student_identifier,s.department student_department,s.program,s.semester_label,
             f.faculty_identifier,f.department faculty_department,f.designation
      FROM passengers p
      LEFT JOIN students s ON s.passenger_id=p.passenger_id
      LEFT JOIN faculty f ON f.passenger_id=p.passenger_id
      WHERE p.university_id=?";
$params=[$uUniversityId];
if($q!==''){$sql.=" AND (p.name LIKE ? OR p.email LIKE ? OR COALESCE(p.phone,'') LIKE ?)";$like='%'.$q.'%';array_push($params,$like,$like,$like);}
if($type!=='ALL'){$sql.=" AND p.passenger_type=?";$params[]=$type;}
if($status!=='ALL'){$sql.=" AND p.status=?";$params[]=$status;}
$sql.=" ORDER BY p.name LIMIT 250";
$rows=[];$error='';
try{$rows=u_all($pdo,$sql,$params);}catch(Throwable $e){error_log('[UniRide passengers] '.$e->getMessage());$error='Passenger information is temporarily unavailable.';}

u_render_start('Passengers','passengers','People','Search and review passengers registered to this university only.');
u_render_actions('<a class="up-button-secondary" href="students.php">Students</a><a class="up-button-secondary" href="faculty.php">Faculty</a>');
u_render_heading_end();
?>
<?php if($error): ?><div class="dashboard-alert is-error"><?= u_h($error) ?></div><?php endif; ?>
<form method="get" class="up-filter">
<input type="search" name="q" value="<?= u_h($q) ?>" placeholder="Search name, email or phone">
<select name="type"><?php foreach(['ALL','STUDENT','FACULTY'] as $v): ?><option value="<?= u_h($v) ?>" <?= $v===$type?'selected':'' ?>><?= u_h($v) ?></option><?php endforeach; ?></select>
<button class="up-button-secondary" type="submit">Filter</button>
<input type="hidden" name="status" value="<?= u_h($status) ?>">
</form>
<div class="up-tabs"><?php foreach(['ALL','ACTIVE','INACTIVE','SUSPENDED'] as $v): ?><a class="up-tab <?= $v===$status?'active':'' ?>" href="?<?= http_build_query(['q'=>$q,'type'=>$type,'status'=>$v]) ?>"><?= u_h($v) ?></a><?php endforeach; ?></div>
<?php if(!$rows): ?><div class="up-empty"><div><strong>No matching passengers.</strong><p>Only passengers belonging to <?= u_h($uUniversity['name']) ?> can appear here.</p></div></div>
<?php else: ?><div class="up-table-wrap"><table class="up-table"><thead><tr><th>Name</th><th>Type</th><th>Identifier</th><th>Department / Program</th><th>Email</th><th>Status</th></tr></thead><tbody>
<?php foreach($rows as $r): ?><tr>
<td><strong><?= u_h($r['name']) ?></strong><small><?= u_h($r['phone']?:'No phone') ?></small></td>
<td><?= u_h(ucfirst(strtolower($r['passenger_type']))) ?></td>
<td><?= u_h($r['passenger_type']==='STUDENT'?($r['student_identifier']?:'—'):($r['faculty_identifier']?:'—')) ?></td>
<td><strong><?= u_h($r['passenger_type']==='STUDENT'?($r['student_department']?:'—'):($r['faculty_department']?:'—')) ?></strong><small><?= u_h($r['passenger_type']==='STUDENT'?($r['program']?:'—'):($r['designation']?:'—')) ?></small></td>
<td><?= u_h($r['email']) ?></td><td><span class="up-status <?= u_h(u_status_class($r['status'])) ?>"><?= u_h($r['status']) ?></span></td>
</tr><?php endforeach; ?></tbody></table></div><?php endif; ?>
<?php u_render_end(); ?>
