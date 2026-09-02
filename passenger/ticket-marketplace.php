<?php
declare(strict_types=1);
require_once __DIR__ . '/_page_shell.php';

if($_SERVER['REQUEST_METHOD']==='POST' && isset($_POST['sell'])){
 $stmt=$pdo->prepare("INSERT INTO ticket_marketplace_posts
(seller_id,booking_id,price,description) VALUES(?,?,?,?)");
 $stmt->execute([$ppPassengerId,$_POST['booking_id'],$_POST['price'],$_POST['description']]);
}

if(isset($_POST['buy'])){
 $pdo->beginTransaction();
 $pdo->prepare("UPDATE ticket_marketplace_posts SET status='SOLD',buyer_id=? WHERE post_id=?")
 ->execute([$ppPassengerId,$_POST['post_id']]);
 $pdo->prepare("UPDATE bookings SET current_owner_id=? WHERE booking_id=
 (SELECT booking_id FROM ticket_marketplace_posts WHERE post_id=?)")
 ->execute([$ppPassengerId,$_POST['post_id']]);
 $pdo->commit();
}

pp_render_start('Ticket Marketplace','ticket-marketplace','Travel',
'Students can sell and buy tickets from other students.');

echo '<div class="card">
<h2>Create Sale Post</h2>
<form method="post">
<input type="hidden" name="sell" value="1">
<input name="booking_id" placeholder="Booking ID" required>
<input name="price" placeholder="Price" required>
<textarea name="description" placeholder="Details"></textarea>
<button class="button button-dark">Post Ticket</button>
</form></div>';

$posts=$pdo->query("SELECT * FROM ticket_marketplace_posts WHERE status='AVAILABLE'");
echo '<div class="card"><h2>Available Tickets</h2>';
foreach($posts as $p){
 echo '<form method="post">
Ticket #'.pp_h($p['booking_id']).' Price '.pp_h($p['price']).'
<input type="hidden" name="post_id" value="'.$p['post_id'].'">
<button name="buy" class="button button-dark">Buy</button></form><hr>';
}
echo '</div>';
pp_render_end();
