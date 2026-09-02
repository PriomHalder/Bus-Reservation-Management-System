-- UniRide Shakib feature update
-- Run after importing uniride2.sql

CREATE TABLE IF NOT EXISTS route_day_favorites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    passenger_id INT NOT NULL,
    route_id INT NOT NULL,
    day_of_week ENUM('MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_passenger_route_day(passenger_id,route_id,day_of_week),
    FOREIGN KEY(passenger_id) REFERENCES passengers(passenger_id) ON DELETE CASCADE,
    FOREIGN KEY(route_id) REFERENCES routes(route_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS ticket_marketplace_posts (
    post_id INT AUTO_INCREMENT PRIMARY KEY,
    seller_id INT NOT NULL,
    booking_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    status ENUM('AVAILABLE','SOLD','CANCELLED') DEFAULT 'AVAILABLE',
    buyer_id INT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY(seller_id) REFERENCES passengers(passenger_id),
    FOREIGN KEY(buyer_id) REFERENCES passengers(passenger_id),
    FOREIGN KEY(booking_id) REFERENCES bookings(booking_id)
);

ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS current_owner_id INT NULL;

CREATE INDEX idx_marketplace_status ON ticket_marketplace_posts(status);
CREATE INDEX idx_route_day ON route_day_favorites(day_of_week);
