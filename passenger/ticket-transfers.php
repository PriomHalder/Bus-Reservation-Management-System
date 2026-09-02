<?php

declare(strict_types=1);
require_once __DIR__ . '/_page_shell.php';

$message = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    // Create a sell post
    if (isset($_POST['create_sell_post'])) {
        $bookingId = (int)($_POST['booking_id'] ?? 0);
        $price = (float)($_POST['price'] ?? 0);
        $description = trim((string)($_POST['description'] ?? ''));

        $check = $pdo->prepare("
            SELECT b.booking_id
            FROM bookings b
            INNER JOIN passengers p ON p.passenger_id = b.current_owner_id
            WHERE b.booking_id = ?
              AND b.current_owner_id = ?
              AND p.university_id = ?
              AND p.passenger_type = 'STUDENT'
              AND b.status IN ('BOOKED','CONFIRMED')
        ");
        $check->execute([$bookingId, $ppPassengerId, $ppUniversityId]);

        if ($check->fetch()) {
            $stmt = $pdo->prepare("INSERT INTO ticket_marketplace_posts
                (seller_id, booking_id, price, description)
                VALUES (?, ?, ?, ?)");
            $stmt->execute([$ppPassengerId, $bookingId, $price, $description]);
            $message = 'Your ticket selling post has been created.';
        } else {
            $message = 'You can only create a post for your own active student ticket.';
        }
    }

    // Buy ticket from marketplace
    if (isset($_POST['buy_ticket'])) {
        try {
            $pdo->beginTransaction();
            $postId = (int)$_POST['post_id'];

            $stmt = $pdo->prepare("
                SELECT tm.booking_id, tm.seller_id
                FROM ticket_marketplace_posts tm
                INNER JOIN passengers seller ON seller.passenger_id = tm.seller_id
                INNER JOIN passengers buyer ON buyer.passenger_id = ?
                WHERE tm.post_id = ?
                AND tm.status='AVAILABLE'
                AND seller.university_id = buyer.university_id
                FOR UPDATE
            ");
            $stmt->execute([$ppPassengerId, $postId]);
            $post = $stmt->fetch();

            if (!$post) {
                throw new Exception('This ticket is not available for you.');
            }

            $pdo->prepare("UPDATE bookings SET current_owner_id=?, passenger_id=? WHERE booking_id=?")
                ->execute([$ppPassengerId, $ppPassengerId, $post['booking_id']]);

            $pdo->prepare("UPDATE billing_transactions SET passenger_id=? WHERE booking_id=?")
                ->execute([$ppPassengerId, $post['booking_id']]);

            $pdo->prepare("UPDATE ticket_marketplace_posts SET status='SOLD', buyer_id=? WHERE post_id=?")
                ->execute([$ppPassengerId, $postId]);

            $pdo->commit();
            $message = 'Ticket purchased successfully.';
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            $message = $e->getMessage();
        }
    }
}

pp_render_start(
    'Ticket Transfers',
    'ticket-transfers',
    'Travel',
    'Buy and sell tickets from students of your university only.'
);

if ($message) echo '<div class="card"><strong>'.pp_h($message).'</strong></div>';

echo '<div class="card">
<h2>Ticket Transfer</h2>
<button class="button button-dark" onclick="document.getElementById(\'posts\').style.display=\'block\';document.getElementById(\'create\').style.display=\'none\';">Available Posts</button>
<button class="button button-dark" onclick="document.getElementById(\'posts\').style.display=\'none\';document.getElementById(\'create\').style.display=\'block\';">Create a Sell Post</button>
</div>';

// Posts tab
echo '<div id="posts" class="card"><h2>Tickets For Sale</h2>';
$stmt=$pdo->prepare("
SELECT tm.post_id,tm.price,tm.description,b.booking_reference,
       r.route_name,s.schedule_date,s.departure_time,s.arrival_time
FROM ticket_marketplace_posts tm
JOIN bookings b ON b.booking_id=tm.booking_id
JOIN schedules s ON s.schedule_id=b.schedule_id
JOIN routes r ON r.route_id=s.route_id
JOIN passengers p ON p.passenger_id=tm.seller_id
WHERE tm.status='AVAILABLE' AND p.university_id=?
");
$stmt->execute([$ppUniversityId]);

foreach($stmt as $row){
 echo '<form method="post" class="card">
 <h3>'.pp_h($row['route_name']).'</h3>
 Schedule: '.pp_h($row['schedule_date']).' '.pp_h($row['departure_time']).' - '.pp_h($row['arrival_time']).'<br>
 Price: '.pp_h($row['price']).'<br>
 '.pp_h($row['description']).'
 <input type="hidden" name="post_id" value="'.$row['post_id'].'">
 <button class="button button-dark" name="buy_ticket">Buy Ticket</button>
 </form>';
}
echo '</div>';

// Create post tab
echo '<div id="create" class="card" style="display:none"><h2>Create a Sell Post</h2>
<form method="post">
<input type="hidden" name="create_sell_post" value="1">
<select name="booking_id" required>';

$stmt=$pdo->prepare("
SELECT booking_id,booking_reference FROM bookings
WHERE current_owner_id=? AND status IN ('BOOKED','CONFIRMED')");
$stmt->execute([$ppPassengerId]);
foreach($stmt as $b){
 echo '<option value="'.$b['booking_id'].'">'.pp_h($b['booking_reference']).'</option>';
}

echo '</select>
<input name="price" placeholder="Selling price" required>
<textarea name="description" placeholder="Description"></textarea>
<button class="button button-dark">Create Post</button>
</form></div>';

pp_render_end();
