-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 19, 2026 at 11:21 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

-- phpMyAdmin-compatible import header
-- Duplicate exact data rows removed from all INSERT statements.
CREATE DATABASE IF NOT EXISTS `uniride2`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `uniride2`;

DROP PROCEDURE IF EXISTS `sp_archive_booking_history`;
DROP PROCEDURE IF EXISTS `sp_cancel_booking`;
DROP PROCEDURE IF EXISTS `sp_create_booking`;
DROP PROCEDURE IF EXISTS `sp_mark_all_notifications_read`;
DROP PROCEDURE IF EXISTS `sp_request_ticket_transfer`;
DROP PROCEDURE IF EXISTS `sp_respond_ticket_transfer`;
DROP FUNCTION IF EXISTS `fn_seat_label`;
DROP TRIGGER IF EXISTS `trg_chk_dup_booking_ins`;
DROP TRIGGER IF EXISTS `trg_chk_dup_booking_upd`;
DROP TRIGGER IF EXISTS `trg_bus_route_assign_ins_check`;
DROP TRIGGER IF EXISTS `trg_bus_route_assign_upd_check`;
DROP TRIGGER IF EXISTS `trg_complaint_response_notification`;
DROP TABLE IF EXISTS `admins`;
DROP TABLE IF EXISTS `billing_transactions`;
DROP TABLE IF EXISTS `bookings`;
DROP TABLE IF EXISTS `buses`;
DROP TABLE IF EXISTS `bus_route_assignments`;
DROP TABLE IF EXISTS `complaints`;
DROP TABLE IF EXISTS `faculty`;
DROP TABLE IF EXISTS `favorite_routes`;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `passengers`;
DROP TABLE IF EXISTS `routes`;
DROP TABLE IF EXISTS `schedules`;
DROP TABLE IF EXISTS `semesters`;
DROP TABLE IF EXISTS `students`;
DROP TABLE IF EXISTS `universities`;
DROP TABLE IF EXISTS `university_users`;
DROP TABLE IF EXISTS `v_schedule_availability`;
DROP TABLE IF EXISTS `v_university_dashboard_stats`;


SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `uniride2`
--

DELIMITER $$
--
-- Procedures
--
CREATE PROCEDURE `sp_archive_booking_history` (IN `p_booking_id` INT, IN `p_passenger_id` INT)   BEGIN
    DECLARE v_status VARCHAR(20);
    
    SELECT status INTO v_status FROM bookings WHERE booking_id = p_booking_id AND passenger_id = p_passenger_id;
    
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found.';
    END IF;
    
    IF v_status NOT IN ('CANCELLED','COMPLETED') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only completed or cancelled bookings can be archived.';
    END IF;
    
    UPDATE bookings SET hidden_from_passenger = 1 WHERE booking_id = p_booking_id;
END$$

CREATE PROCEDURE `sp_cancel_booking` (IN `p_booking_id` INT, IN `p_passenger_id` INT)   BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_fare DECIMAL(10,2);
    DECLARE v_sem_id INT;
    
    SELECT status, fare_charged INTO v_status, v_fare FROM bookings 
    WHERE booking_id = p_booking_id AND passenger_id = p_passenger_id;
    
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking not found or access denied.';
    END IF;
    
    IF v_status NOT IN ('BOOKED','CONFIRMED') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This booking cannot be cancelled.';
    END IF;
    
    UPDATE bookings SET status = 'CANCELLED' WHERE booking_id = p_booking_id;
    
    INSERT INTO booking_status_history (booking_id, old_status, new_status, changed_by)
    VALUES (p_booking_id, v_status, 'CANCELLED', 'PASSENGER');
    
    SELECT semester_id INTO v_sem_id FROM semesters WHERE is_active = 1 LIMIT 1;
    
    IF v_sem_id IS NOT NULL THEN
        UPDATE semester_bills 
        SET total_credits = total_credits + v_fare, net_balance = net_balance - v_fare
        WHERE passenger_id = p_passenger_id AND semester_id = v_sem_id;
        
        INSERT INTO billing_transactions (passenger_id, semester_id, booking_id, transaction_type, amount, description)
        VALUES (p_passenger_id, v_sem_id, p_booking_id, 'CANCELLATION_CREDIT', -v_fare, 'Credit for cancelled booking');
    END IF;
    
    INSERT INTO notifications (passenger_id, title, message, notification_type, reference_id)
    VALUES (p_passenger_id, 'Booking Cancelled', 'Your booking has been cancelled successfully.', 'BOOKING', p_booking_id);

END$$

CREATE PROCEDURE `sp_create_booking` (IN `p_passenger_id` INT, IN `p_schedule_id` INT, IN `p_slot_type` VARCHAR(10), IN `p_slot_number` INT)   BEGIN
    DECLARE v_p_uni_id INT;
    DECLARE v_p_type VARCHAR(20);
    DECLARE v_p_status VARCHAR(20);
    DECLARE v_s_status VARCHAR(20);
    DECLARE v_route_id INT;
    DECLARE v_bus_id INT;
    DECLARE v_r_uni_id INT;
    DECLARE v_bus_type VARCHAR(20);
    DECLARE v_seat_cap INT;
    DECLARE v_stand_cap INT;
    DECLARE v_booked_seats INT;
    DECLARE v_fare DECIMAL(10,2);
    DECLARE v_conflict INT;
    DECLARE v_bkg_ref VARCHAR(20);
    DECLARE v_qr_token VARCHAR(100);
    DECLARE v_active_sem_id INT;
    DECLARE v_new_bkg_id INT;

    -- Validate passenger exists & active
    SELECT university_id, passenger_type, status INTO v_p_uni_id, v_p_type, v_p_status
    FROM passengers WHERE passenger_id = p_passenger_id;
    
    IF v_p_status != 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Passenger is not active.';
    END IF;

    -- Validate schedule exists & status
    SELECT route_id, bus_id, status INTO v_route_id, v_bus_id, v_s_status
    FROM schedules WHERE schedule_id = p_schedule_id;
    
    IF v_s_status != 'SCHEDULED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Schedule is not open for booking.';
    END IF;

    -- Get route/bus details
    SELECT university_id, fare INTO v_r_uni_id, v_fare FROM routes WHERE route_id = v_route_id;
    SELECT bus_type, seat_capacity, standing_capacity INTO v_bus_type, v_seat_cap, v_stand_cap FROM buses WHERE bus_id = v_bus_id;

    -- Validate same university
    IF v_p_uni_id != v_r_uni_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot book a schedule for a different university.';
    END IF;

    -- Validate bus type eligibility
    IF v_bus_type = 'STUDENT_ONLY' AND v_p_type != 'STUDENT' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This bus is restricted to students only.';
    END IF;
    IF v_bus_type = 'FACULTY_ONLY' AND v_p_type != 'FACULTY' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This bus is restricted to faculty only.';
    END IF;

    -- Check for conflicting booking for same passenger on this schedule
    SELECT COUNT(*) INTO v_conflict FROM bookings 
    WHERE passenger_id = p_passenger_id AND schedule_id = p_schedule_id AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING');
    
    IF v_conflict > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You already have a booking for this schedule.';
    END IF;

    -- Handle Slot Types
    IF p_slot_type = 'SEAT' THEN
        IF p_slot_number < 1 OR p_slot_number > v_seat_cap THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid seat number.';
        END IF;
    ELSEIF p_slot_type = 'STANDING' THEN
        SELECT COUNT(*) INTO v_booked_seats FROM bookings 
        WHERE schedule_id = p_schedule_id AND slot_type = 'SEAT' AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING');
        
        IF v_booked_seats < v_seat_cap THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Seats are still available. Standing slots open only when all seats are booked.';
        END IF;
        
        IF p_slot_number < 1 OR p_slot_number > v_stand_cap THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid standing slot number.';
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid slot type.';
    END IF;

    -- Generate tokens
    SET v_bkg_ref = CONCAT('BKG-', UPPER(SUBSTRING(UUID(), 1, 8)));
    SET v_qr_token = UUID();

    -- Insert Booking (Unique constraints are handled by Triggers)
    INSERT INTO bookings (booking_reference, passenger_id, schedule_id, slot_type, seat_number, standing_slot, fare_charged, qr_token, status)
    VALUES (
        v_bkg_ref, p_passenger_id, p_schedule_id, p_slot_type, 
        IF(p_slot_type = 'SEAT', p_slot_number, NULL), 
        IF(p_slot_type = 'STANDING', p_slot_number, NULL), 
        v_fare, v_qr_token, 'BOOKED'
    );
    
    SET v_new_bkg_id = LAST_INSERT_ID();

    -- Status history
    INSERT INTO booking_status_history (booking_id, old_status, new_status, changed_by)
    VALUES (v_new_bkg_id, NULL, 'BOOKED', 'SYSTEM');

    -- Billing logic
    SELECT semester_id INTO v_active_sem_id FROM semesters WHERE is_active = 1 LIMIT 1;
    
    IF v_active_sem_id IS NOT NULL THEN
        INSERT INTO semester_bills (passenger_id, semester_id, total_charges, net_balance)
        VALUES (p_passenger_id, v_active_sem_id, v_fare, v_fare)
        ON DUPLICATE KEY UPDATE 
            total_charges = total_charges + v_fare,
            net_balance = net_balance + v_fare;
            
        INSERT INTO billing_transactions (passenger_id, semester_id, booking_id, transaction_type, amount, description)
        VALUES (p_passenger_id, v_active_sem_id, v_new_bkg_id, 'BOOKING_CHARGE', v_fare, CONCAT('Charge for booking ', v_bkg_ref));
    END IF;

    -- Notification
    INSERT INTO notifications (passenger_id, title, message, notification_type, reference_id)
    VALUES (p_passenger_id, 'Booking Confirmed', CONCAT('Your booking ', v_bkg_ref, ' is confirmed.'), 'BOOKING', v_new_bkg_id);

    -- Return the created booking
    SELECT * FROM bookings WHERE booking_id = v_new_bkg_id;

END$$

CREATE PROCEDURE `sp_mark_all_notifications_read` (IN `p_passenger_id` INT)   BEGIN
    UPDATE notifications SET is_read = 1, read_at = NOW() WHERE passenger_id = p_passenger_id AND is_read = 0;
END$$

CREATE PROCEDURE `sp_request_ticket_transfer` (IN `p_booking_id` INT, IN `p_from_passenger_id` INT, IN `p_to_passenger_id` INT, IN `p_transfer_type` VARCHAR(10), IN `p_sale_amount` DECIMAL(10,2))   BEGIN
    DECLARE v_bkg_status VARCHAR(20);
    DECLARE v_sched_id INT;
    DECLARE v_f_uni INT;
    DECLARE v_t_uni INT;
    DECLARE v_f_type VARCHAR(20);
    DECLARE v_t_type VARCHAR(20);
    DECLARE v_t_status VARCHAR(20);
    DECLARE v_bus_type VARCHAR(20);
    DECLARE v_conflict INT;

    SELECT status, schedule_id INTO v_bkg_status, v_sched_id FROM bookings WHERE booking_id = p_booking_id AND passenger_id = p_from_passenger_id;
    IF v_bkg_status IS NULL OR v_bkg_status NOT IN ('BOOKED','CONFIRMED') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking is invalid or not in a transferable state.';
    END IF;

    SELECT university_id, passenger_type, status INTO v_t_uni, v_t_type, v_t_status FROM passengers WHERE passenger_id = p_to_passenger_id;
    SELECT university_id, passenger_type INTO v_f_uni, v_f_type FROM passengers WHERE passenger_id = p_from_passenger_id;

    IF v_t_status != 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Target passenger is not active.';
    END IF;
    
    IF v_f_uni != v_t_uni THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot transfer ticket to someone in a different university.';
    END IF;
    
    IF v_f_type != v_t_type THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Can only transfer tickets between users of the same role (e.g. Student to Student).';
    END IF;

    SELECT COUNT(*) INTO v_conflict FROM bookings WHERE passenger_id = p_to_passenger_id AND schedule_id = v_sched_id AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING');
    IF v_conflict > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Target passenger already has a booking for this schedule.';
    END IF;

    SELECT b.bus_type INTO v_bus_type FROM schedules s JOIN buses b ON s.bus_id = b.bus_id WHERE s.schedule_id = v_sched_id;
    IF v_bus_type = 'STUDENT_ONLY' AND v_t_type != 'STUDENT' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bus is student only.'; END IF;
    IF v_bus_type = 'FACULTY_ONLY' AND v_t_type != 'FACULTY' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bus is faculty only.'; END IF;

    UPDATE bookings SET status = 'TRANSFER_PENDING' WHERE booking_id = p_booking_id;
    
    INSERT INTO ticket_transfers (booking_id, from_passenger_id, to_passenger_id, transfer_type, sale_amount, status)
    VALUES (p_booking_id, p_from_passenger_id, p_to_passenger_id, p_transfer_type, p_sale_amount, 'PENDING');
    
    INSERT INTO booking_status_history (booking_id, old_status, new_status, changed_by)
    VALUES (p_booking_id, v_bkg_status, 'TRANSFER_PENDING', 'SYSTEM');
    
    INSERT INTO notifications (passenger_id, title, message, notification_type, reference_id)
    VALUES (p_to_passenger_id, 'Ticket Transfer Request', 'Someone wants to transfer a ticket to you.', 'TRANSFER', LAST_INSERT_ID());
END$$

CREATE PROCEDURE `sp_respond_ticket_transfer` (IN `p_transfer_id` INT, IN `p_recipient_passenger_id` INT, IN `p_action` VARCHAR(10))   BEGIN
    DECLARE v_bkg_id INT;
    DECLARE v_from_pid INT;
    DECLARE v_t_status VARCHAR(20);
    DECLARE v_t_type VARCHAR(10);
    DECLARE v_amount DECIMAL(10,2);
    DECLARE v_active_sem INT;

    SELECT booking_id, from_passenger_id, status, transfer_type, sale_amount 
    INTO v_bkg_id, v_from_pid, v_t_status, v_t_type, v_amount 
    FROM ticket_transfers WHERE transfer_id = p_transfer_id AND to_passenger_id = p_recipient_passenger_id;

    IF v_t_status IS NULL OR v_t_status != 'PENDING' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid transfer request or it has already been processed.';
    END IF;

    IF p_action = 'ACCEPT' THEN
        UPDATE bookings SET passenger_id = p_recipient_passenger_id, status = 'BOOKED' WHERE booking_id = v_bkg_id;
        UPDATE ticket_transfers SET status = 'COMPLETED', responded_at = NOW() WHERE transfer_id = p_transfer_id;
        
        INSERT INTO booking_status_history (booking_id, old_status, new_status, changed_by)
        VALUES (v_bkg_id, 'TRANSFER_PENDING', 'BOOKED', 'SYSTEM');
        
        IF v_t_type = 'SELL' THEN
            SELECT semester_id INTO v_active_sem FROM semesters WHERE is_active = 1 LIMIT 1;
            IF v_active_sem IS NOT NULL THEN
                -- Charge recipient
                INSERT INTO billing_transactions (passenger_id, semester_id, booking_id, transaction_type, amount, description)
                VALUES (p_recipient_passenger_id, v_active_sem, v_bkg_id, 'TRANSFER_CHARGE', v_amount, 'Purchased ticket transfer');
                UPDATE semester_bills SET total_charges = total_charges + v_amount, net_balance = net_balance + v_amount WHERE passenger_id = p_recipient_passenger_id AND semester_id = v_active_sem;
                
                -- Credit sender
                INSERT INTO billing_transactions (passenger_id, semester_id, booking_id, transaction_type, amount, description)
                VALUES (v_from_pid, v_active_sem, v_bkg_id, 'TRANSFER_CREDIT', -v_amount, 'Sold ticket transfer');
                UPDATE semester_bills SET total_credits = total_credits + v_amount, net_balance = net_balance - v_amount WHERE passenger_id = v_from_pid AND semester_id = v_active_sem;
            END IF;
        END IF;

        INSERT INTO notifications (passenger_id, title, message, notification_type, reference_id)
        VALUES (v_from_pid, 'Transfer Accepted', 'Your ticket transfer was accepted.', 'TRANSFER', p_transfer_id);
        
    ELSEIF p_action = 'REJECT' THEN
        UPDATE bookings SET status = 'BOOKED' WHERE booking_id = v_bkg_id;
        UPDATE ticket_transfers SET status = 'REJECTED', responded_at = NOW() WHERE transfer_id = p_transfer_id;
        
        INSERT INTO booking_status_history (booking_id, old_status, new_status, changed_by)
        VALUES (v_bkg_id, 'TRANSFER_PENDING', 'BOOKED', 'SYSTEM');
        
        INSERT INTO notifications (passenger_id, title, message, notification_type, reference_id)
        VALUES (v_from_pid, 'Transfer Rejected', 'Your ticket transfer request was rejected.', 'TRANSFER', p_transfer_id);
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid action. Must be ACCEPT or REJECT.';
    END IF;
END$$

--
-- Functions
--
CREATE FUNCTION `fn_seat_label` (`p_seat_number` INT) RETURNS VARCHAR(5) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci DETERMINISTIC BEGIN
    DECLARE v_row CHAR(1);
    DECLARE v_col INT;
    
    IF p_seat_number IS NULL THEN
        RETURN NULL;
    END IF;
    
    SET v_row = CHAR(64 + CEIL(p_seat_number / 4.0));
    SET v_col = ((p_seat_number - 1) MOD 4) + 1;
    
    RETURN CONCAT(v_row, v_col);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `admins`
--

CREATE TABLE `admins` (
  `admin_id` int(11) NOT NULL,
  `name` varchar(50) DEFAULT NULL,
  `email` varchar(50) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `admins`
--

INSERT INTO `admins` (`admin_id`, `name`, `email`, `password`, `status`, `created_at`) VALUES
(1, 'UniRide System Admin', 'uniride.admin@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ACTIVE', '2026-08-19 14:38:27');

-- --------------------------------------------------------

--
-- Table structure for table `billing_transactions`
--

CREATE TABLE `billing_transactions` (
  `transaction_id` int(11) NOT NULL,
  `passenger_id` int(11) NOT NULL,
  `semester_id` int(11) NOT NULL,
  `booking_id` int(11) DEFAULT NULL,
  `transaction_type` enum('BOOKING_CHARGE','CANCELLATION_CREDIT','TRANSFER_CHARGE','TRANSFER_CREDIT') DEFAULT 'BOOKING_CHARGE',
  `amount` decimal(10,2) NOT NULL,
  `description` text DEFAULT NULL,
  `transaction_date` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `booking_id` int(11) NOT NULL,
  `booking_reference` varchar(20) NOT NULL,
  `passenger_id` int(11) NOT NULL,
  `schedule_id` int(11) NOT NULL,
  `slot_type` enum('SEAT','STANDING') NOT NULL,
  `seat_number` int(11) DEFAULT NULL,
  `standing_slot` int(11) DEFAULT NULL,
  `fare_charged` decimal(10,2) NOT NULL,
  `qr_token` varchar(100) NOT NULL,
  `status` enum('BOOKED','CONFIRMED','CANCELLED','COMPLETED','TRANSFER_PENDING') DEFAULT 'BOOKED',
  `booking_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `bookings`
--
DELIMITER $$
CREATE TRIGGER `trg_chk_dup_booking_ins` BEFORE INSERT ON `bookings` FOR EACH ROW BEGIN
    DECLARE existing_count INT;
    
    IF NEW.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING') THEN
        IF NEW.slot_type = 'SEAT' AND NEW.seat_number IS NOT NULL THEN
            SELECT COUNT(*) INTO existing_count FROM bookings 
            WHERE schedule_id = NEW.schedule_id AND seat_number = NEW.seat_number AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING');
            
            IF existing_count > 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Seat already booked for this schedule.';
            END IF;
        ELSEIF NEW.slot_type = 'STANDING' AND NEW.standing_slot IS NOT NULL THEN
            SELECT COUNT(*) INTO existing_count FROM bookings 
            WHERE schedule_id = NEW.schedule_id AND standing_slot = NEW.standing_slot AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING');
            
            IF existing_count > 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Standing slot already taken for this schedule.';
            END IF;
        END IF;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_chk_dup_booking_upd` BEFORE UPDATE ON `bookings` FOR EACH ROW BEGIN
    DECLARE existing_count INT;
    
    IF NEW.status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING') THEN
        IF NEW.slot_type = 'SEAT' AND NEW.seat_number IS NOT NULL THEN
            SELECT COUNT(*) INTO existing_count FROM bookings 
            WHERE schedule_id = NEW.schedule_id AND seat_number = NEW.seat_number AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING') AND booking_id != NEW.booking_id;
            
            IF existing_count > 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Seat already booked for this schedule.';
            END IF;
        ELSEIF NEW.slot_type = 'STANDING' AND NEW.standing_slot IS NOT NULL THEN
            SELECT COUNT(*) INTO existing_count FROM bookings 
            WHERE schedule_id = NEW.schedule_id AND standing_slot = NEW.standing_slot AND status IN ('BOOKED','CONFIRMED','TRANSFER_PENDING') AND booking_id != NEW.booking_id;
            
            IF existing_count > 0 THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Standing slot already taken for this schedule.';
            END IF;
        END IF;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `buses`
--

CREATE TABLE `buses` (
  `bus_id` int(11) NOT NULL,
  `university_id` int(11) NOT NULL,
  `registration_number` varchar(50) NOT NULL,
  `tax_number` varchar(50) DEFAULT NULL,
  `seat_capacity` int(11) DEFAULT 40,
  `standing_capacity` int(11) DEFAULT 10,
  `bus_type` enum('STANDARD','STUDENT_ONLY','FACULTY_ONLY') DEFAULT 'STANDARD',
  `status` enum('ACTIVE','INACTIVE','MAINTENANCE') DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `buses`
--

INSERT INTO `buses` (`bus_id`, `university_id`, `registration_number`, `tax_number`, `seat_capacity`, `standing_capacity`, `bus_type`, `status`, `created_at`) VALUES
(1, 1, 'DHA-1234', NULL, 40, 10, 'STUDENT_ONLY', 'ACTIVE', '2026-08-19 14:38:27'),
(2, 1, 'DHA-5678', NULL, 40, 10, 'STUDENT_ONLY', 'ACTIVE', '2026-08-19 14:38:27'),
(3, 1, 'DHA-9012', NULL, 40, 10, 'FACULTY_ONLY', 'ACTIVE', '2026-08-19 14:38:27'),
(4, 1, 'DHA-3456', NULL, 40, 10, 'STUDENT_ONLY', 'MAINTENANCE', '2026-08-19 14:38:27'),
(5, 2, 'DHA-7777', NULL, 40, 10, 'STUDENT_ONLY', 'ACTIVE', '2026-08-19 14:38:27'),
(6, 3, 'DHA-8888', NULL, 40, 10, 'STUDENT_ONLY', 'ACTIVE', '2026-08-19 14:38:27');

-- --------------------------------------------------------

--
-- Table structure for table `bus_route_assignments`
--

CREATE TABLE `bus_route_assignments` (
  `assignment_id` int(11) NOT NULL,
  `bus_id` int(11) NOT NULL,
  `route_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `bus_route_assignments`
--

INSERT INTO `bus_route_assignments` (`assignment_id`, `bus_id`, `route_id`, `created_at`) VALUES
(1, 1, 1, '2026-08-19 14:38:27'),
(2, 1, 2, '2026-08-19 14:38:27'),
(3, 2, 3, '2026-08-19 14:38:27'),
(4, 3, 4, '2026-08-19 14:38:27'),
(5, 5, 6, '2026-08-19 14:38:27'),
(6, 6, 7, '2026-08-19 14:38:27');

--
-- Triggers `bus_route_assignments`
--
DELIMITER $$
CREATE TRIGGER `trg_bus_route_assign_ins_check` BEFORE INSERT ON `bus_route_assignments` FOR EACH ROW BEGIN
    DECLARE v_bus_uni INT;
    DECLARE v_route_uni INT;
    
    SELECT university_id INTO v_bus_uni FROM buses WHERE bus_id = NEW.bus_id;
    SELECT university_id INTO v_route_uni FROM routes WHERE route_id = NEW.route_id;
    
    IF v_bus_uni != v_route_uni THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bus and Route must belong to the same university.';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_bus_route_assign_upd_check` BEFORE UPDATE ON `bus_route_assignments` FOR EACH ROW BEGIN
    DECLARE v_bus_uni INT;
    DECLARE v_route_uni INT;
    
    SELECT university_id INTO v_bus_uni FROM buses WHERE bus_id = NEW.bus_id;
    SELECT university_id INTO v_route_uni FROM routes WHERE route_id = NEW.route_id;
    
    IF v_bus_uni != v_route_uni THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bus and Route must belong to the same university.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `complaints`
--

CREATE TABLE `complaints` (
  `complaint_id` int(11) NOT NULL,
  `passenger_id` int(11) NOT NULL,
  `university_id` int(11) NOT NULL,
  `subject` varchar(300) NOT NULL,
  `description` text NOT NULL,
  `status` enum('OPEN','IN_PROGRESS','RESOLVED','CLOSED') DEFAULT 'OPEN',
  `university_response` text DEFAULT NULL,
  `submitted_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `complaints`
--

INSERT INTO `complaints` (`complaint_id`, `passenger_id`, `university_id`, `subject`, `description`, `status`, `university_response`, `submitted_at`, `updated_at`) VALUES
(1, 1, 1, 'AC Cooling issue on bus DHA-1234', 'The air conditioning on bus DHA-1234 was not cooling adequately during the 5:20 PM trip on BRACU-R01.', 'RESOLVED', 'The AC unit on bus DHA-1234 has been serviced by our maintenance team.', '2026-08-19 14:38:27', '2026-08-19 14:38:27'),
(2, 2, 1, 'Request for earlier departure on Mirpur route', 'Would it be possible to add an early morning run around 7:00 AM for the Mirpur route?', 'IN_PROGRESS', 'We are reviewing the student demand survey to evaluate adding this schedule.', '2026-08-19 14:38:27', '2026-08-19 14:38:27'),
(3, 7, 2, 'Route NSU-R01 departure delay', 'The afternoon bus departed 10 minutes late due to traffic at the main gate.', 'RESOLVED', 'Security staff has been assigned to keep the bus exit gate clear before departure.', '2026-08-19 14:38:27', '2026-08-19 14:38:27');

--
-- Triggers `complaints`
--
DELIMITER $$
CREATE TRIGGER `trg_complaint_response_notification` AFTER UPDATE ON `complaints` FOR EACH ROW BEGIN
    IF NEW.university_response IS NOT NULL AND (OLD.university_response IS NULL OR OLD.university_response != NEW.university_response) THEN
        INSERT INTO notifications (passenger_id, title, message, notification_type, reference_id)
        VALUES (NEW.passenger_id, 'Complaint Updated', CONCAT('Your complaint has received a response: ', NEW.university_response), 'COMPLAINT', NEW.complaint_id);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `faculty`
--

CREATE TABLE `faculty` (
  `faculty_id` int(11) NOT NULL,
  `passenger_id` int(11) NOT NULL,
  `faculty_identifier` varchar(50) NOT NULL,
  `department` varchar(200) NOT NULL,
  `designation` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `faculty`
--

INSERT INTO `faculty` (`faculty_id`, `passenger_id`, `faculty_identifier`, `department`, `designation`) VALUES
(1, 5, 'FAC-BRACU-001', 'CSE', 'Professor'),
(2, 6, 'FAC-BRACU-002', 'EEE', 'Associate Professor'),
(3, 8, 'FAC-NSU-001', 'ECE', 'Assistant Professor'),
(4, 10, 'FAC-AIUB-001', 'CS', 'Senior Lecturer');

-- --------------------------------------------------------

--
-- Table structure for table `favorite_routes`
--

CREATE TABLE `favorite_routes` (
  `favorite_id` int(11) NOT NULL,
  `passenger_id` int(11) NOT NULL,
  `route_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` int(11) NOT NULL,
  `passenger_id` int(11) NOT NULL,
  `title` varchar(300) NOT NULL,
  `message` text NOT NULL,
  `notification_type` varchar(50) DEFAULT 'GENERAL',
  `reference_id` int(11) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `passengers`
--

CREATE TABLE `passengers` (
  `passenger_id` int(11) NOT NULL,
  `university_id` int(11) NOT NULL,
  `name` varchar(200) NOT NULL,
  `email` varchar(200) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `passenger_type` enum('STUDENT','FACULTY') NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email_notifications` tinyint(1) DEFAULT 1,
  `in_app_notifications` tinyint(1) DEFAULT 1,
  `status` enum('ACTIVE','INACTIVE','SUSPENDED') DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `passengers`
--

INSERT INTO `passengers` (`passenger_id`, `university_id`, `name`, `email`, `password_hash`, `passenger_type`, `phone`, `email_notifications`, `in_app_notifications`, `status`, `created_at`) VALUES
(1, 1, 'Samiha Tasnim', 'samiha.tasnim@g.bracu.ac.bd', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 14:38:27'),
(2, 1, 'Samir Hossain', 'samir.hossain@g.bracu.ac.bd', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 14:38:27'),
(3, 1, 'Nadia Islam', 'nadia.islam@g.bracu.ac.bd', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 14:38:27'),
(4, 1, 'Tanvir Hasan', 'tanvir.hasan@g.bracu.ac.bd', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 14:38:27'),
(5, 1, 'Kamal Uddin', 'kamal.uddin@g.bracu.ac.bd', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'FACULTY', NULL, 1, 1, 'ACTIVE', '2026-08-19 14:38:27'),
(6, 1, 'Nusrat Karim', 'nusrat.karim@g.bracu.ac.bd', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'FACULTY', NULL, 1, 1, 'ACTIVE', '2026-08-19 14:38:27'),
(7, 2, 'Rafi Hasan', 'rafi.hasan@g.nsu.ac.bd', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 14:38:27'),
(8, 2, 'Samira Ahmed', 'samira.ahmed@g.nsu.ac.bd', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'FACULTY', NULL, 1, 1, 'ACTIVE', '2026-08-19 14:38:27'),
(9, 3, 'Tahmid Islam', 'tahmid.islam@g.aiub.ac.bd', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 14:38:27'),
(10, 3, 'Farhana Noor', 'farhana.noor@g.aiub.ac.bd', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'FACULTY', NULL, 1, 1, 'ACTIVE', '2026-08-19 14:38:27'),
(11, 1, 'Ovi Karim', 'ovi.karim@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(12, 1, 'Sajjad Ali', 'sajjad.ali@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(13, 1, 'Tamim Hasan', 'tamim.hasan@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(14, 1, 'Mehedi Mahmud', 'mehedi.mahmud@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(15, 1, 'Tanvir Khan', 'tanvir.khan@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(16, 1, 'Sakib Sultana', 'sakib.sultana@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(17, 1, 'Nila Mirza', 'nila.mirza@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(18, 1, 'Tania Mahmud', 'tania.mahmud@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(19, 1, 'Lamia Das', 'lamia.das@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(20, 1, 'Israt Bhuiyan', 'israt.bhuiyan@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(21, 1, 'Parvez Miah', 'parvez.miah@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(22, 1, 'Mehjabin Kabir', 'mehjabin.kabir@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(23, 1, 'Momin Miah', 'momin.miah@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(24, 1, 'Samin Bhuiyan', 'samin.bhuiyan@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(25, 1, 'Sumon Jahan', 'sumon.jahan@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(26, 1, 'Nusrat Sikder', 'nusrat.sikder@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(27, 1, 'Nafis Karim', 'nafis.karim@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(28, 1, 'Israt Chowdhury', 'israt.chowdhury@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(29, 1, 'Nafisa Islam', 'nafisa.islam@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(30, 1, 'Hasan Majumder', 'hasan.majumder@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(31, 1, 'Sadiya Sarkar', 'sadiya.sarkar@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(32, 1, 'Nabila Noor', 'nabila.noor@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(33, 1, 'Naim Sheikh', 'naim.sheikh@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(34, 1, 'Sara Mahmud', 'sara.mahmud@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(35, 1, 'Rayhan Begum', 'rayhan.begum@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(36, 1, 'Tanvir Miah', 'tanvir.miah@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(37, 1, 'Rakib Miah', 'rakib.miah@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(38, 1, 'Nabila Dewan', 'nabila.dewan@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(39, 1, 'Sonia Sikder', 'sonia.sikder@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(40, 1, 'Mahmud Sultana', 'mahmud.sultana@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(41, 1, 'Faria Mirza', 'faria.mirza@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(42, 1, 'Sifat Karim', 'sifat.karim@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(43, 1, 'Rashid Kabir', 'rashid.kabir@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(44, 1, 'Faria Talukder', 'faria.talukder@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(45, 1, 'Ratul Haque', 'ratul.haque@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(46, 1, 'Adnan Das', 'adnan.das@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(47, 1, 'Mim Sheikh', 'mim.sheikh@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(48, 1, 'Shamim Dewan', 'shamim.dewan@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(49, 1, 'Ritu Islam', 'ritu.islam@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(50, 1, 'Tahsin Bishwas', 'tahsin.bishwas@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(51, 1, 'Nabila Bhuiyan', 'nabila.bhuiyan@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(52, 1, 'Siam Rahman', 'siam.rahman@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(53, 1, 'Jamil Talukder', 'jamil.talukder@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(54, 1, 'Sabrina Majumder', 'sabrina.majumder@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(55, 1, 'Lamia Hossain', 'lamia.hossain@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(56, 1, 'Nusrat Miah', 'nusrat.miah@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(57, 1, 'Khadija Mahmud', 'khadija.mahmud@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(58, 1, 'Shawon Sheikh', 'shawon.sheikh@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(59, 1, 'Jahid Sultana', 'jahid.sultana@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(60, 1, 'Sakib Rahman', 'sakib.rahman@g.bracu.ac.bd', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(61, 2, 'Sadiya Rahman', 'sadiya.rahman@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(62, 2, 'Sanjida Chowdhury', 'sanjida.chowdhury@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(63, 2, 'Tanjim Mahmud', 'tanjim.mahmud@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(64, 2, 'Rubel Rahman', 'rubel.rahman@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(65, 2, 'Imran Chowdhury', 'imran.chowdhury@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(66, 2, 'Mahmud Karim', 'mahmud.karim@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(67, 2, 'Salman Mahmud', 'salman.mahmud@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(68, 2, 'Shamim Hasan', 'shamim.hasan@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(69, 2, 'Hasan Talukder', 'hasan.talukder@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(70, 2, 'Fahim Chowdhury', 'fahim.chowdhury@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(71, 2, 'Shawon Hossain', 'shawon.hossain@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(72, 2, 'Tahsin Miah', 'tahsin.miah@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(73, 2, 'Faria Mahmud', 'faria.mahmud@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(74, 2, 'Iqbal Dewan', 'iqbal.dewan@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(75, 2, 'Nazmul Sultana', 'nazmul.sultana@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(76, 2, 'Adnan Ali', 'adnan.ali@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(77, 2, 'Tania Sheikh', 'tania.sheikh@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(78, 2, 'Tahmid Rahman', 'tahmid.rahman@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(79, 2, 'Lamia Islam', 'lamia.islam@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(80, 2, 'Ria Dewan', 'ria.dewan@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(81, 2, 'Shahriar Khatun', 'shahriar.khatun@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(82, 2, 'Tamim Sikder', 'tamim.sikder@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(83, 2, 'Tanvir Rahman', 'tanvir.rahman@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(84, 2, 'Sohan Begum', 'sohan.begum@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(85, 2, 'Shahriar Haque', 'shahriar.haque@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(86, 2, 'Tareq Mahmud', 'tareq.mahmud@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(87, 2, 'Sakib Sikder', 'sakib.sikder@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(88, 2, 'Tanjim Sikder', 'tanjim.sikder@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(89, 2, 'Ovi Majumder', 'ovi.majumder@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(90, 2, 'Sajjad Khan', 'sajjad.khan@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(91, 2, 'Jamil Khan', 'jamil.khan@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(92, 2, 'Ayesha Khatun', 'ayesha.khatun@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(93, 2, 'Mahmud Ahmed', 'mahmud.ahmed@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(94, 2, 'Kamrul Khan', 'kamrul.khan@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(95, 2, 'Arif Sarkar', 'arif.sarkar@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(96, 2, 'Kamrul Bishwas', 'kamrul.bishwas@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(97, 2, 'Tasnim Hossain', 'tasnim.hossain@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(98, 2, 'Jamil Bhuiyan', 'jamil.bhuiyan@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(99, 2, 'Mahin Khatun', 'mahin.khatun@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(100, 2, 'Fahim Khan', 'fahim.khan@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(101, 2, 'Mim Bhuiyan', 'mim.bhuiyan@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(102, 2, 'Nishat Khan', 'nishat.khan@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(103, 2, 'Priya Sikder', 'priya.sikder@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(104, 2, 'Sakib Islam', 'sakib.islam@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(105, 2, 'Sajjad Mahmud', 'sajjad.mahmud@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(106, 2, 'Farah Bhuiyan', 'farah.bhuiyan@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(107, 2, 'Iqbal Mahmud', 'iqbal.mahmud@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(108, 2, 'Nusrat Akter', 'nusrat.akter@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(109, 2, 'Sara Mahmud', 'sara.mahmud@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(110, 2, 'Rifat Miah', 'rifat.miah@northsouth.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(111, 3, 'Rashid Mahmud', '26-90001-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(112, 3, 'Riad Dewan', '26-90002-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(113, 3, 'Shafiq Majumder', '26-90003-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(114, 3, 'Momin Bhuiyan', '26-90004-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(115, 3, 'Israt Sheikh', '26-90005-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(116, 3, 'Parvez Mirza', '26-90006-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(117, 3, 'Nila Kabir', '26-90007-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(118, 3, 'Israt Chowdhury', '26-90008-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(119, 3, 'Tahmid Sheikh', '26-90009-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(120, 3, 'Sakib Sarkar', '26-90010-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(121, 3, 'Zarin Islam', '26-90011-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(122, 3, 'Sifat Jahan', '26-90012-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(123, 3, 'Sagor Sarkar', '26-90013-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(124, 3, 'Rubel Khatun', '26-90014-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(125, 3, 'Jamil Bishwas', '26-90015-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(126, 3, 'Rubel Dewan', '26-90016-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(127, 3, 'Parvez Karim', '26-90017-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(128, 3, 'Sohail Mahmud', '26-90018-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(129, 3, 'Nazmul Sarkar', '26-90019-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(130, 3, 'Riad Islam', '26-90020-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(131, 3, 'Jamil Sikder', '26-90021-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(132, 3, 'Sohail Talukder', '26-90022-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(133, 3, 'Suraiya Akter', '26-90023-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(134, 3, 'Jahid Kabir', '26-90024-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(135, 3, 'Salman Bhuiyan', '26-90025-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(136, 3, 'Emon Khatun', '26-90026-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(137, 3, 'Rifat Haque', '26-90027-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(138, 3, 'Rashid Begum', '26-90028-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(139, 3, 'Nafisa Kabir', '26-90029-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(140, 3, 'Naim Islam', '26-90030-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(141, 3, 'Rakib Majumder', '26-90031-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(142, 3, 'Tanvir Hasan', '26-90032-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(143, 3, 'Zarin Miah', '26-90033-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(144, 3, 'Sifat Majumder', '26-90034-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(145, 3, 'Priya Ali', '26-90035-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(146, 3, 'Tariq Sheikh', '26-90036-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(147, 3, 'Sara Karim', '26-90037-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(148, 3, 'Sara Bishwas', '26-90038-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(149, 3, 'Mashrafe Rahman', '26-90039-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(150, 3, 'Afsana Bhuiyan', '26-90040-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(151, 3, 'Siam Dewan', '26-90041-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(152, 3, 'Samiul Haque', '26-90042-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(153, 3, 'Tanvir Sultana', '26-90043-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(154, 3, 'Tanvir Das', '26-90044-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(155, 3, 'Mehedi Kabir', '26-90045-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(156, 3, 'Zarin Dewan', '26-90046-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(157, 3, 'Shawon Sheikh', '26-90047-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(158, 3, 'Jamil Akter', '26-90048-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(159, 3, 'Israt Bhuiyan', '26-90049-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(160, 3, 'Tanjim Majumder', '26-90050-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19');
INSERT INTO `passengers` (`passenger_id`, `university_id`, `name`, `email`, `password_hash`, `passenger_type`, `phone`, `email_notifications`, `in_app_notifications`, `status`, `created_at`) VALUES
(127, 3, 'Parvez Karim', '26-90017-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(128, 3, 'Sohail Mahmud', '26-90018-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(129, 3, 'Nazmul Sarkar', '26-90019-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(130, 3, 'Riad Islam', '26-90020-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(131, 3, 'Jamil Sikder', '26-90021-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(132, 3, 'Sohail Talukder', '26-90022-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(133, 3, 'Suraiya Akter', '26-90023-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(134, 3, 'Jahid Kabir', '26-90024-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(135, 3, 'Salman Bhuiyan', '26-90025-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(136, 3, 'Emon Khatun', '26-90026-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(137, 3, 'Rifat Haque', '26-90027-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(138, 3, 'Rashid Begum', '26-90028-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(139, 3, 'Nafisa Kabir', '26-90029-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(140, 3, 'Naim Islam', '26-90030-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(141, 3, 'Rakib Majumder', '26-90031-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(142, 3, 'Tanvir Hasan', '26-90032-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(143, 3, 'Zarin Miah', '26-90033-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(144, 3, 'Sifat Majumder', '26-90034-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(145, 3, 'Priya Ali', '26-90035-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(146, 3, 'Tariq Sheikh', '26-90036-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(147, 3, 'Sara Karim', '26-90037-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(148, 3, 'Sara Bishwas', '26-90038-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(149, 3, 'Mashrafe Rahman', '26-90039-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(150, 3, 'Afsana Bhuiyan', '26-90040-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(151, 3, 'Siam Dewan', '26-90041-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(152, 3, 'Samiul Haque', '26-90042-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(153, 3, 'Tanvir Sultana', '26-90043-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(154, 3, 'Tanvir Das', '26-90044-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(155, 3, 'Mehedi Kabir', '26-90045-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(156, 3, 'Zarin Dewan', '26-90046-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(157, 3, 'Shawon Sheikh', '26-90047-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(158, 3, 'Jamil Akter', '26-90048-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(159, 3, 'Israt Bhuiyan', '26-90049-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19'),
(160, 3, 'Tanjim Majumder', '26-90050-1@student.aiub.edu', '$2y$10$FRbYYU1sMpq2XXf8sfeRdOwCRNZ/8vZQTBEFEBkoD1.PGhf4HRVr6', 'STUDENT', NULL, 1, 1, 'ACTIVE', '2026-08-19 15:36:19');

-- --------------------------------------------------------

--
-- Table structure for table `routes`
--

CREATE TABLE `routes` (
  `route_id` int(11) NOT NULL,
  `university_id` int(11) NOT NULL,
  `route_code` varchar(20) NOT NULL,
  `route_name` varchar(200) NOT NULL,
  `start_location` varchar(200) NOT NULL,
  `end_location` varchar(200) NOT NULL,
  `fare` decimal(10,2) NOT NULL,
  `status` enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `routes`
--

INSERT INTO `routes` (`route_id`, `university_id`, `route_code`, `route_name`, `start_location`, `end_location`, `fare`, `status`, `created_at`) VALUES
(1, 1, 'BRACU-R01', 'Campus - Mirpur 12', 'BRACU Campus', 'Mirpur 12', 150.00, 'ACTIVE', '2026-08-19 14:38:27'),
(2, 1, 'BRACU-R02', 'Campus - Dhanmondi', 'BRACU Campus', 'Dhanmondi', 100.00, 'ACTIVE', '2026-08-19 14:38:27'),
(3, 1, 'BRACU-R03', 'Campus - Abdullahpur', 'BRACU Campus', 'Abdullahpur', 120.00, 'ACTIVE', '2026-08-19 14:38:27'),
(4, 1, 'BRACU-R04', 'Campus - Jatrabari', 'BRACU Campus', 'Jatrabari', 150.00, 'ACTIVE', '2026-08-19 14:38:27'),
(5, 1, 'BRACU-R05', 'Campus - Shewrapara', 'BRACU Campus', 'Shewrapara', 120.00, 'ACTIVE', '2026-08-19 14:38:27'),
(6, 2, 'NSU-R01', 'NSU Campus - Uttara', 'NSU Campus', 'Uttara Sector 10', 100.00, 'ACTIVE', '2026-08-19 14:38:27'),
(7, 3, 'AIUB-R01', 'AIUB Campus - Dhanmondi', 'AIUB Campus', 'Dhanmondi 27', 120.00, 'ACTIVE', '2026-08-19 14:38:27');

-- --------------------------------------------------------

--
-- Table structure for table `schedules`
--

CREATE TABLE `schedules` (
  `schedule_id` int(11) NOT NULL,
  `route_id` int(11) NOT NULL,
  `bus_id` int(11) NOT NULL,
  `schedule_date` date NOT NULL,
  `departure_time` time NOT NULL,
  `arrival_time` time NOT NULL,
  `status` enum('SCHEDULED','IN_PROGRESS','COMPLETED','CANCELLED') DEFAULT 'SCHEDULED',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `schedules`
--

INSERT INTO `schedules` (`schedule_id`, `route_id`, `bus_id`, `schedule_date`, `departure_time`, `arrival_time`, `status`, `created_at`) VALUES
(1, 1, 1, '2026-08-20', '17:20:00', '18:50:00', 'SCHEDULED', '2026-08-19 14:38:27'),
(2, 2, 1, '2026-08-20', '17:20:00', '18:30:00', 'SCHEDULED', '2026-08-19 14:38:27'),
(3, 3, 2, '2026-08-20', '17:20:00', '18:20:00', 'SCHEDULED', '2026-08-19 14:38:27'),
(4, 4, 3, '2026-08-20', '17:20:00', '18:45:00', 'SCHEDULED', '2026-08-19 14:38:27'),
(5, 5, 1, '2026-08-20', '19:30:00', '20:40:00', 'SCHEDULED', '2026-08-19 14:38:27'),
(6, 6, 5, '2026-08-20', '17:00:00', '18:00:00', 'SCHEDULED', '2026-08-19 14:38:27'),
(7, 7, 6, '2026-08-20', '17:15:00', '18:15:00', 'SCHEDULED', '2026-08-19 14:38:27');

-- --------------------------------------------------------

--
-- Table structure for table `semesters`
--

CREATE TABLE `semesters` (
  `semester_id` int(11) NOT NULL,
  `semester_name` varchar(100) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `is_active` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `semesters`
--

INSERT INTO `semesters` (`semester_id`, `semester_name`, `start_date`, `end_date`, `is_active`, `created_at`) VALUES
(1, 'Fall 2026', '2026-08-01', '2026-12-15', 1, '2026-08-19 14:38:27'),
(2, 'Spring 2026', '2026-01-15', '2026-05-30', 0, '2026-08-19 14:38:27');

-- --------------------------------------------------------

--
-- Table structure for table `students`
--

CREATE TABLE `students` (
  `student_id` int(11) NOT NULL,
  `passenger_id` int(11) NOT NULL,
  `student_identifier` varchar(50) NOT NULL,
  `department` varchar(200) NOT NULL,
  `program` varchar(200) NOT NULL,
  `semester_label` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `students`
--

INSERT INTO `students` (`student_id`, `passenger_id`, `student_identifier`, `department`, `program`, `semester_label`) VALUES
(1, 1, '20301123', 'CSE', 'B.Sc. in CSE', 'Fall 2026'),
(2, 2, '20301456', 'CSE', 'B.Sc. in CSE', 'Fall 2026'),
(3, 3, '20301789', 'EEE', 'B.Sc. in EEE', 'Fall 2026'),
(4, 4, '21201234', 'BBA', 'BBA', 'Fall 2026'),
(5, 7, '2021101', 'ECE', 'B.Sc. in ECE', 'Fall 2026'),
(6, 9, '22-45678-1', 'CS', 'B.Sc. in CS', 'Fall 2026'),
(7, 11, 'BRACU-26-0001', 'Architecture', 'Bachelor of Architecture', '2nd'),
(8, 12, 'BRACU-26-0002', 'Business', 'Bachelor of Business Administration', '3rd'),
(9, 13, 'BRACU-26-0003', 'Biotechnology', 'Bachelor of Science in Biotechnology', '6th'),
(10, 14, 'BRACU-26-0004', 'Business', 'Bachelor of Business Administration', '3rd'),
(11, 15, 'BRACU-26-0005', 'Microbiology', 'Bachelor of Science in Microbiology', '4th'),
(12, 16, 'BRACU-26-0006', 'Business', 'Bachelor of Business Administration', '5th'),
(13, 17, 'BRACU-26-0007', 'CSE', 'Bachelor of Science in Computer Science and Engineering', '5th'),
(14, 18, 'BRACU-26-0008', 'Business', 'Bachelor of Business Administration', '1st'),
(15, 19, 'BRACU-26-0009', 'Computer Science', 'Bachelor of Science in Computer Science', '3rd'),
(16, 20, 'BRACU-26-0010', 'CSE', 'Bachelor of Science in Computer Science and Engineering', '3rd'),
(17, 21, 'BRACU-26-0011', 'English', 'Bachelor of Arts in English', '8th'),
(18, 22, 'BRACU-26-0012', 'CSE', 'Bachelor of Science in Computer Science and Engineering', '8th'),
(19, 23, 'BRACU-26-0013', 'Biotechnology', 'Bachelor of Science in Biotechnology', '2nd'),
(20, 24, 'BRACU-26-0014', 'CSE', 'Bachelor of Science in Computer Science and Engineering', '5th'),
(21, 25, 'BRACU-26-0015', 'Architecture', 'Bachelor of Architecture', '3rd'),
(22, 26, 'BRACU-26-0016', 'CSE', 'Bachelor of Science in Computer Science and Engineering', '2nd'),
(23, 27, 'BRACU-26-0017', 'Business', 'Bachelor of Business Administration', '1st'),
(24, 28, 'BRACU-26-0018', 'CSE', 'Bachelor of Science in Computer Science and Engineering', '5th'),
(25, 29, 'BRACU-26-0019', 'Economics', 'Bachelor of Social Science in Economics', '5th'),
(26, 30, 'BRACU-26-0020', 'CSE', 'Bachelor of Science in Computer Science and Engineering', '7th'),
(27, 31, 'BRACU-26-0021', 'EEE', 'Bachelor of Science in Electrical and Electronic Engineering', '1st'),
(28, 32, 'BRACU-26-0022', 'EEE', 'Bachelor of Science in Electrical and Electronic Engineering', '4th'),
(29, 33, 'BRACU-26-0023', 'Business', 'Bachelor of Business Administration', '4th'),
(30, 34, 'BRACU-26-0024', 'EEE', 'Bachelor of Science in Electrical and Electronic Engineering', '7th'),
(31, 35, 'BRACU-26-0025', 'CSE', 'Bachelor of Science in Computer Science and Engineering', '2nd'),
(32, 36, 'BRACU-26-0026', 'ECE', 'Bachelor of Science in Electronic and Communication Engineering', '1st'),
(33, 37, 'BRACU-26-0027', 'CSE', 'Bachelor of Science in Computer Science and Engineering', '8th'),
(34, 38, 'BRACU-26-0028', 'ECE', 'Bachelor of Science in Electronic and Communication Engineering', '3rd'),
(35, 39, 'BRACU-26-0029', 'EEE', 'Bachelor of Science in Electrical and Electronic Engineering', '2nd'),
(36, 40, 'BRACU-26-0030', 'Architecture', 'Bachelor of Architecture', '5th'),
(37, 41, 'BRACU-26-0031', 'CSE', 'Bachelor of Science in Computer Science and Engineering', '5th'),
(38, 42, 'BRACU-26-0032', 'Business', 'Bachelor of Business Administration', '8th'),
(39, 43, 'BRACU-26-0033', 'Law', 'Bachelor of Laws', '3rd'),
(40, 44, 'BRACU-26-0034', 'EEE', 'Bachelor of Science in Electrical and Electronic Engineering', '7th'),
(41, 45, 'BRACU-26-0035', 'English', 'Bachelor of Arts in English', '5th'),
(42, 46, 'BRACU-26-0036', 'CSE', 'Bachelor of Science in Computer Science and Engineering', '4th'),
(43, 47, 'BRACU-26-0037', 'English', 'Bachelor of Arts in English', '7th'),
(44, 48, 'BRACU-26-0038', 'Economics', 'Bachelor of Social Science in Economics', '6th'),
(45, 49, 'BRACU-26-0039', 'EEE', 'Bachelor of Science in Electrical and Electronic Engineering', '3rd'),
(46, 50, 'BRACU-26-0040', 'Computer Science', 'Bachelor of Science in Computer Science', '2nd'),
(47, 51, 'BRACU-26-0041', 'Economics', 'Bachelor of Social Science in Economics', '1st'),
(48, 52, 'BRACU-26-0042', 'Law', 'Bachelor of Laws', '6th'),
(49, 53, 'BRACU-26-0043', 'Economics', 'Bachelor of Social Science in Economics', '3rd'),
(50, 54, 'BRACU-26-0044', 'ECE', 'Bachelor of Science in Electronic and Communication Engineering', '8th'),
(51, 55, 'BRACU-26-0045', 'English', 'Bachelor of Arts in English', '4th'),
(52, 56, 'BRACU-26-0046', 'Business', 'Bachelor of Business Administration', '1st'),
(53, 57, 'BRACU-26-0047', 'ECE', 'Bachelor of Science in Electronic and Communication Engineering', '2nd'),
(54, 58, 'BRACU-26-0048', 'CSE', 'Bachelor of Science in Computer Science and Engineering', '3rd'),
(55, 59, 'BRACU-26-0049', 'Microbiology', 'Bachelor of Science in Microbiology', '4th'),
(56, 60, 'BRACU-26-0050', 'Biotechnology', 'Bachelor of Science in Biotechnology', '6th'),
(57, 61, 'NSU-26-0001', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Computer Science & Engineering', '3rd'),
(58, 62, 'NSU-26-0002', 'Biochemistry & Biotechnology', 'Bachelor of Science in Biochemistry & Biotechnology', '8th'),
(59, 63, 'NSU-26-0003', 'Biochemistry & Biotechnology', 'Bachelor of Science in Biochemistry & Biotechnology', '4th'),
(60, 64, 'NSU-26-0004', 'Pharmacy', 'Bachelor of Pharmacy', '3rd'),
(61, 65, 'NSU-26-0005', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Computer Science & Engineering', '3rd'),
(62, 66, 'NSU-26-0006', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Electrical & Electronic Engineering', '8th'),
(63, 67, 'NSU-26-0007', 'Architecture', 'Bachelor of Architecture', '8th'),
(64, 68, 'NSU-26-0008', 'Business', 'Bachelor of Business Administration', '5th'),
(65, 69, 'NSU-26-0009', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Computer Science & Engineering', '4th'),
(66, 70, 'NSU-26-0010', 'Business', 'Bachelor of Business Administration', '3rd'),
(67, 71, 'NSU-26-0011', 'Microbiology', 'Bachelor of Science in Microbiology', '4th'),
(68, 72, 'NSU-26-0012', 'Microbiology', 'Bachelor of Science in Microbiology', '4th'),
(69, 73, 'NSU-26-0013', 'Business', 'Bachelor of Business Administration', '2nd'),
(70, 74, 'NSU-26-0014', 'Pharmacy', 'Bachelor of Pharmacy', '8th'),
(71, 75, 'NSU-26-0015', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Computer Science & Engineering', '7th'),
(72, 76, 'NSU-26-0016', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Computer Science & Engineering', '4th'),
(73, 77, 'NSU-26-0017', 'Business', 'Bachelor of Business Administration', '3rd'),
(74, 78, 'NSU-26-0018', 'Business', 'Bachelor of Business Administration', '6th'),
(75, 79, 'NSU-26-0019', 'Pharmacy', 'Bachelor of Pharmacy', '4th'),
(76, 80, 'NSU-26-0020', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Computer Science & Engineering', '6th'),
(77, 81, 'NSU-26-0021', 'Business', 'Bachelor of Business Administration', '7th'),
(78, 82, 'NSU-26-0022', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Computer Science & Engineering', '7th'),
(79, 83, 'NSU-26-0023', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Electrical & Electronic Engineering', '7th'),
(80, 84, 'NSU-26-0024', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Electrical & Electronic Engineering', '2nd'),
(81, 85, 'NSU-26-0025', 'Architecture', 'Bachelor of Architecture', '3rd'),
(82, 86, 'NSU-26-0026', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Electronic & Telecommunication Eng.', '5th'),
(83, 87, 'NSU-26-0027', 'Economics', 'Bachelor of Science in Economics', '8th'),
(84, 88, 'NSU-26-0028', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Electrical & Electronic Engineering', '6th'),
(85, 89, 'NSU-26-0029', 'Economics', 'Bachelor of Science in Economics', '4th'),
(86, 90, 'NSU-26-0030', 'Economics', 'Bachelor of Science in Economics', '1st'),
(87, 91, 'NSU-26-0031', 'Economics', 'Bachelor of Science in Economics', '8th'),
(88, 92, 'NSU-26-0032', 'Business', 'Bachelor of Business Administration', '1st'),
(89, 93, 'NSU-26-0033', 'Business', 'Bachelor of Business Administration', '2nd'),
(90, 94, 'NSU-26-0034', 'Microbiology', 'Bachelor of Science in Microbiology', '1st'),
(91, 95, 'NSU-26-0035', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Electrical & Electronic Engineering', '1st'),
(92, 96, 'NSU-26-0036', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Computer Science & Engineering', '1st'),
(93, 97, 'NSU-26-0037', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Electronic & Telecommunication Eng.', '7th'),
(94, 98, 'NSU-26-0038', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Electronic & Telecommunication Eng.', '3rd'),
(95, 99, 'NSU-26-0039', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Electrical & Electronic Engineering', '8th'),
(96, 100, 'NSU-26-0040', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Computer Science & Engineering', '6th'),
(97, 101, 'NSU-26-0041', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Electronic & Telecommunication Eng.', '1st'),
(98, 102, 'NSU-26-0042', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Computer Science & Engineering', '3rd'),
(99, 103, 'NSU-26-0043', 'Architecture', 'Bachelor of Architecture', '6th'),
(100, 104, 'NSU-26-0044', 'Business', 'Bachelor of Business Administration', '7th'),
(101, 105, 'NSU-26-0045', 'Business', 'Bachelor of Business Administration', '3rd'),
(102, 106, 'NSU-26-0046', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Computer Science & Engineering', '1st'),
(103, 107, 'NSU-26-0047', 'Electrical Engineering & Computer Science', 'Bachelor of Science in Computer Science & Engineering', '5th'),
(104, 108, 'NSU-26-0048', 'Business', 'Bachelor of Business Administration', '2nd'),
(105, 109, 'NSU-26-0049', 'Economics', 'Bachelor of Science in Economics', '5th'),
(106, 110, 'NSU-26-0050', 'Business', 'Bachelor of Business Administration', '5th'),
(107, 111, '26-90001-1', 'Computer Science', 'Bachelor of Science in Computer Network & Cyber Security', '3rd'),
(108, 112, '26-90002-1', 'Electrical & Electronic Engineering', 'Bachelor of Science in Electrical & Electronic Engineering', '1st'),
(109, 113, '26-90003-1', 'Journalism & Mass Communication', 'Bachelor of Arts in Journalism & Mass Communication', '4th'),
(110, 114, '26-90004-1', 'Electrical & Electronic Engineering', 'Bachelor of Science in Electrical & Electronic Engineering', '7th'),
(111, 115, '26-90005-1', 'Computer Engineering', 'Bachelor of Science in Computer Engineering', '7th'),
(112, 116, '26-90006-1', 'Architecture', 'Bachelor of Architecture', '3rd'),
(113, 117, '26-90007-1', 'Computer Science', 'Bachelor of Science in Data Science', '6th'),
(114, 118, '26-90008-1', 'Architecture', 'Bachelor of Architecture', '2nd'),
(115, 119, '26-90009-1', 'Business Administration', 'Bachelor of Business Administration', '5th'),
(116, 120, '26-90010-1', 'Architecture', 'Bachelor of Architecture', '5th'),
(117, 121, '26-90011-1', 'Computer Science', 'Bachelor of Science in Computer Network & Cyber Security', '2nd'),
(118, 122, '26-90012-1', 'Business Administration', 'Bachelor of Business Administration', '2nd'),
(119, 123, '26-90013-1', 'Electrical & Electronic Engineering', 'Bachelor of Science in Electrical & Electronic Engineering', '8th'),
(120, 124, '26-90014-1', 'Computer Science', 'Bachelor of Science in Computer Science & Engineering', '1st'),
(121, 125, '26-90015-1', 'Electrical & Electronic Engineering', 'Bachelor of Science in Electrical & Electronic Engineering', '8th'),
(122, 126, '26-90016-1', 'Electrical & Electronic Engineering', 'Bachelor of Science in Electrical & Electronic Engineering', '7th'),
(123, 127, '26-90017-1', 'Computer Science', 'Bachelor of Science in Computer Science & Engineering', '2nd'),
(124, 128, '26-90018-1', 'Computer Science', 'Bachelor of Science in Computer Science & Engineering', '2nd'),
(125, 129, '26-90019-1', 'Computer Science', 'Bachelor of Science in Computer Science & Engineering', '3rd'),
(126, 130, '26-90020-1', 'Computer Science', 'Bachelor of Science in Computer Science & Engineering', '7th'),
(127, 131, '26-90021-1', 'Computer Engineering', 'Bachelor of Science in Computer Engineering', '3rd'),
(128, 132, '26-90022-1', 'Computer Science', 'Bachelor of Science in Data Science', '4th'),
(129, 133, '26-90023-1', 'Business Administration', 'Bachelor of Business Administration', '6th'),
(130, 134, '26-90024-1', 'Industrial & Production Engineering', 'Bachelor of Science in Industrial & Production Engineering', '8th'),
(131, 135, '26-90025-1', 'Business Administration', 'Bachelor of Business Administration', '2nd'),
(132, 136, '26-90026-1', 'Business Administration', 'Bachelor of Business Administration', '1st'),
(133, 137, '26-90027-1', 'Computer Science', 'Bachelor of Science in Computer Science & Engineering', '8th'),
(134, 138, '26-90028-1', 'Business Administration', 'Bachelor of Business Administration', '5th'),
(135, 139, '26-90029-1', 'Business Administration', 'Bachelor of Business Administration', '5th'),
(136, 140, '26-90030-1', 'Industrial & Production Engineering', 'Bachelor of Science in Industrial & Production Engineering', '4th'),
(137, 141, '26-90031-1', 'Electrical & Electronic Engineering', 'Bachelor of Science in Electrical & Electronic Engineering', '4th'),
(138, 142, '26-90032-1', 'Computer Engineering', 'Bachelor of Science in Computer Engineering', '2nd'),
(139, 143, '26-90033-1', 'Computer Science', 'Bachelor of Science in Computer Network & Cyber Security', '7th'),
(140, 144, '26-90034-1', 'Computer Engineering', 'Bachelor of Science in Computer Engineering', '4th'),
(141, 145, '26-90035-1', 'Computer Science', 'Bachelor of Science in Data Science', '1st'),
(142, 146, '26-90036-1', 'Computer Science', 'Bachelor of Science in Computer Science & Engineering', '4th'),
(143, 147, '26-90037-1', 'English', 'Bachelor of Arts in English', '8th'),
(144, 148, '26-90038-1', 'Business Administration', 'Bachelor of Business Administration', '3rd'),
(145, 149, '26-90039-1', 'Computer Science', 'Bachelor of Science in Computer Science & Engineering', '7th'),
(146, 150, '26-90040-1', 'Computer Science', 'Bachelor of Science in Computer Science & Engineering', '1st'),
(147, 151, '26-90041-1', 'Industrial & Production Engineering', 'Bachelor of Science in Industrial & Production Engineering', '1st'),
(148, 152, '26-90042-1', 'Economics', 'Bachelor of Social Science in Economics', '4th'),
(149, 153, '26-90043-1', 'Computer Science', 'Bachelor of Science in Computer Network & Cyber Security', '7th'),
(150, 154, '26-90044-1', 'Computer Science', 'Bachelor of Science in Computer Science & Engineering', '7th'),
(151, 155, '26-90045-1', 'Computer Science', 'Bachelor of Science in Data Science', '2nd'),
(152, 156, '26-90046-1', 'Electrical & Electronic Engineering', 'Bachelor of Science in Electrical & Electronic Engineering', '4th'),
(153, 157, '26-90047-1', 'Computer Science', 'Bachelor of Science in Computer Science & Engineering', '6th'),
(154, 158, '26-90048-1', 'Computer Science', 'Bachelor of Science in Data Science', '3rd'),
(155, 159, '26-90049-1', 'Computer Science', 'Bachelor of Science in Computer Science & Engineering', '6th'),
(156, 160, '26-90050-1', 'Computer Science', 'Bachelor of Science in Computer Network & Cyber Security', '4th');

-- --------------------------------------------------------

--
-- Table structure for table `universities`
--

CREATE TABLE `universities` (
  `university_id` int(11) NOT NULL,
  `name` varchar(200) NOT NULL,
  `code` varchar(20) NOT NULL,
  `academic_domain` varchar(100) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `contact_email` varchar(200) DEFAULT NULL,
  `logo_path` varchar(500) DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `universities`
--

INSERT INTO `universities` (`university_id`, `name`, `code`, `academic_domain`, `address`, `contact_email`, `logo_path`, `status`, `created_at`) VALUES
(1, 'BRAC University', 'BRACU', 'bracu.ac.bd', 'Kha 224, Bir Uttam Rafiqul Islam Ave, Merul Badda, Dhaka 1212', 'info@bracu.ac.bd', NULL, 'ACTIVE', '2026-08-19 14:38:27'),
(2, 'North South University', 'NSU', 'nsu.ac.bd', 'Plot # 15, Block # B, Bashundhara R/A, Dhaka 1229', 'info@northsouth.edu', NULL, 'ACTIVE', '2026-08-19 14:38:27'),
(3, 'American International University-Bangladesh', 'AIUB', 'aiub.ac.bd', '408/1, Kuratoli, Khilkhet, Dhaka 1229', 'info@aiub.edu', NULL, 'ACTIVE', '2026-08-19 14:38:27');

-- --------------------------------------------------------

--
-- Table structure for table `university_users`
--

CREATE TABLE `university_users` (
  `university_user_id` int(11) NOT NULL,
  `university_id` int(11) NOT NULL,
  `name` varchar(200) NOT NULL,
  `email` varchar(200) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('ADMIN','MODERATOR') DEFAULT 'ADMIN',
  `status` enum('ACTIVE','INACTIVE') DEFAULT 'ACTIVE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `university_users`
--

INSERT INTO `university_users` (`university_user_id`, `university_id`, `name`, `email`, `password_hash`, `role`, `status`, `created_at`) VALUES
(1, 1, 'BRACU Transport Admin', 'bracu.transport@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ADMIN', 'ACTIVE', '2026-08-19 14:38:27'),
(2, 2, 'NSU Transport Admin', 'nsu.transport@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ADMIN', 'ACTIVE', '2026-08-19 14:38:27'),
(3, 3, 'AIUB Transport Admin', 'aiub.transport@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ADMIN', 'ACTIVE', '2026-08-19 14:38:27');

-- --------------------------------------------------------

--
-- Table structure for table `v_schedule_availability`
--

CREATE TABLE `v_schedule_availability` (
  `schedule_id` int(11) DEFAULT NULL,
  `schedule_date` date DEFAULT NULL,
  `departure_time` time DEFAULT NULL,
  `arrival_time` time DEFAULT NULL,
  `schedule_status` enum('SCHEDULED','IN_PROGRESS','COMPLETED','CANCELLED') DEFAULT NULL,
  `route_id` int(11) DEFAULT NULL,
  `route_code` varchar(20) DEFAULT NULL,
  `route_name` varchar(200) DEFAULT NULL,
  `start_location` varchar(200) DEFAULT NULL,
  `end_location` varchar(200) DEFAULT NULL,
  `fare` decimal(10,2) DEFAULT NULL,
  `university_id` int(11) DEFAULT NULL,
  `university_name` varchar(200) DEFAULT NULL,
  `bus_id` int(11) DEFAULT NULL,
  `registration_number` varchar(50) DEFAULT NULL,
  `bus_type` enum('STANDARD','STUDENT_ONLY','FACULTY_ONLY') DEFAULT NULL,
  `seat_capacity` int(11) DEFAULT NULL,
  `standing_capacity` int(11) DEFAULT NULL,
  `booked_seats` bigint(21) DEFAULT NULL,
  `available_seats` bigint(22) DEFAULT NULL,
  `booked_standing` bigint(21) DEFAULT NULL,
  `available_standing` bigint(22) DEFAULT NULL,
  `seated_occupancy_percent` decimal(25,1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `v_university_dashboard_stats`
--

CREATE TABLE `v_university_dashboard_stats` (
  `university_id` int(11) DEFAULT NULL,
  `total_buses` bigint(21) DEFAULT NULL,
  `active_buses` bigint(21) DEFAULT NULL,
  `total_routes` bigint(21) DEFAULT NULL,
  `active_routes` bigint(21) DEFAULT NULL,
  `total_passengers` bigint(21) DEFAULT NULL,
  `total_students` bigint(21) DEFAULT NULL,
  `total_faculty` bigint(21) DEFAULT NULL,
  `total_bookings` bigint(21) DEFAULT NULL,
  `active_bookings` bigint(21) DEFAULT NULL,
  `pending_complaints` bigint(21) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
