<?php
declare(strict_types=1);
require_once __DIR__ . '/_university_shell.php';

if($_SERVER['REQUEST_METHOD']==='POST' && ($_POST['action']??'')==='add_bus'){
    if(!u_verify_csrf($_POST['csrf_token']??null)){u_flash('error','Your session expired. Please try again.');u_redirect('buses.php?new=1');}
    $registration=trim((string)($_POST['registration_number']??''));
    $tax=trim((string)($_POST['tax_number']??''));
    $seat=max(1,min(100,(int)($_POST['seat_capacity']??40)));
    $standing=max(0,min(100,(int)($_POST['standing_capacity']??10)));
    $type=strtoupper((string)($_POST['bus_type']??'STANDARD'));
    if($registration===''||!in_array($type,['STANDARD','STUDENT_ONLY','FACULTY_ONLY'],true)){u_flash('error','Please enter a registration number and valid bus type.');u_redirect('buses.php?new=1');}
    try{
        $stmt=$pdo->prepare("INSERT INTO buses(university_id,registration_number,tax_number,seat_capacity,standing_capacity,bus_type,status) VALUES (?,?,?,?,?,?,'ACTIVE')");
        $stmt->execute([$uUniversityId,$registration,$tax!==''?$tax:null,$seat,$standing,$type]);
        u_flash('success','Bus added to '.$uUniversity['name'].'.');u_redirect('buses.php');
    }catch(Throwable $e){error_log('[UniRide add bus] '.$e->getMessage());u_flash('error','The bus could not be added. Check for a duplicate registration number.');u_redirect('buses.php?new=1');}
}
$rows=[];try{$rows=u_all($pdo,"SELECT bus_id,registration_number,tax_number,seat_capacity,standing_capacity,bus_type,status FROM buses WHERE university_id=? ORDER BY CASE status WHEN 'ACTIVE' THEN 0 WHEN 'MAINTENANCE' THEN 1 ELSE 2 END,registration_number",[$uUniversityId]);}catch(Throwable $e){error_log('[UniRide buses] '.$e->getMessage());}
u_render_start('Buses','buses','Operations','Manage the fleet belonging to this university.');
u_render_actions('<a class="up-button" href="buses.php?new=1">+ Add Bus</a>');u_render_heading_end();
?>
<?php if(isset($_GET['new'])): ?><section class="up-card blue" style="margin-bottom:16px"><div class="section-heading-row"><div><p class="dashboard-kicker">New fleet record</p><h2>Add Bus</h2></div></div><form method="post" class="up-form-grid"><input type="hidden" name="csrf_token" value="<?= u_h(u_csrf()) ?>"><input type="hidden" name="action" value="add_bus"><label class="up-field"><span>Registration number</span><input name="registration_number" required></label><label class="up-field"><span>Tax number</span><input name="tax_number"></label><label class="up-field"><span>Seat capacity</span><input type="number" name="seat_capacity" min="1" max="100" value="40" required></label><label class="up-field"><span>Standing capacity</span><input type="number" name="standing_capacity" min="0" max="100" value="10" required></label><label class="up-field"><span>Bus type</span><select name="bus_type"><option value="STANDARD">Standard</option><option value="STUDENT_ONLY">Student only</option><option value="FACULTY_ONLY">Faculty only</option></select></label><div class="up-form-actions"><button class="up-button" type="submit">Save Bus</button><a class="up-button-secondary" href="buses.php">Cancel</a></div></form></section><?php endif; ?>
<?php if(!$rows): ?>
    <div class="up-empty"><div><strong>No buses registered.</strong><p>Add the first bus for <?= u_h($uUniversity['name']) ?>.</p></div><a class="up-button" href="?new=1">Add Bus</a></div>
<?php else: ?>
    <p class="bus-copy-help">Copy a bus ID or registration number for use in Create Schedule.</p>
    <div class="up-table-wrap">
        <table class="up-table">
            <thead><tr><th>Bus ID</th><th>Registration</th><th>Tax No.</th><th>Type</th><th>Seats</th><th>Standing</th><th>Status</th></tr></thead>
            <tbody>
            <?php foreach($rows as $r): ?>
                <tr>
                    <td>
                        <strong>#<?= (int)$r['bus_id'] ?></strong>
                        <button class="bus-copy-button" type="button" data-copy-bus="<?= (int)$r['bus_id'] ?>" aria-label="Copy bus ID <?= (int)$r['bus_id'] ?>">Copy ID</button>
                    </td>
                    <td>
                        <strong><?= u_h($r['registration_number']) ?></strong>
                        <button class="bus-copy-button" type="button" data-copy-bus="<?= u_h($r['registration_number']) ?>" aria-label="Copy registration number <?= u_h($r['registration_number']) ?>">Copy name</button>
                    </td>
                    <td><?= u_h($r['tax_number']?:'—') ?></td>
                    <td><?= u_h(u_bus_type($r['bus_type'])) ?></td>
                    <td><?= (int)$r['seat_capacity'] ?></td>
                    <td><?= (int)$r['standing_capacity'] ?></td>
                    <td><span class="up-status <?= u_h(u_status_class($r['status'])) ?>"><?= u_h($r['status']) ?></span></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <p class="bus-copy-status" data-copy-status role="status" aria-live="polite"></p>
<?php endif; ?>

<style>
    .bus-copy-help {
        margin: 0 0 12px;
        color: var(--ui-muted, #737a82);
        font-size: 11px;
    }
    .bus-copy-button {
        display: block;
        margin-top: 5px;
        padding: 3px 7px;
        border: 1px solid var(--ui-line-strong, #c9d6e5);
        border-radius: 6px;
        background: var(--ui-surface, #ffffff);
        color: var(--ui-navy, #123f7c);
        font: inherit;
        font-size: 9px;
        font-weight: 800;
        cursor: pointer;
    }
    .bus-copy-button:hover { background: var(--ui-navy-soft, #edf4fb); }
    .bus-copy-button:focus-visible {
        outline: 3px solid rgba(18, 63, 124, .22);
        outline-offset: 2px;
    }
    .bus-copy-status {
        min-height: 18px;
        margin: 8px 0 0;
        color: var(--ui-muted, #737a82);
        font-size: 10px;
    }
</style>

<script>
(() => {
    const status = document.querySelector('[data-copy-status]');

    const fallbackCopy = (value) => {
        const input = document.createElement('textarea');
        input.value = value;
        input.setAttribute('readonly', '');
        input.style.position = 'fixed';
        input.style.opacity = '0';
        document.body.appendChild(input);
        input.select();
        const copied = document.execCommand('copy');
        input.remove();
        return copied;
    };

    document.querySelectorAll('[data-copy-bus]').forEach((button) => {
        button.addEventListener('click', async () => {
            const value = button.dataset.copyBus || '';
            let copied = false;
            try {
                if (navigator.clipboard && window.isSecureContext) {
                    await navigator.clipboard.writeText(value);
                    copied = true;
                } else {
                    copied = fallbackCopy(value);
                }
            } catch (error) {
                copied = fallbackCopy(value);
            }
            if (status) status.textContent = copied ? `Copied ${value}.` : 'Copy failed. Select and copy the value manually.';
        });
    });
})();
</script>
<?php u_render_end(); ?>
