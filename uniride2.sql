-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 26, 2026 at 07:00 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `bank_12345678`
--
CREATE DATABASE IF NOT EXISTS `bank_12345678` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `bank_12345678`;

-- --------------------------------------------------------

--
-- Table structure for table `account`
--

CREATE TABLE `account` (
  `branch_name` varchar(15) DEFAULT NULL,
  `account_number` varchar(10) NOT NULL,
  `balance` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `borrower`
--

CREATE TABLE `borrower` (
  `customer_id` varchar(10) NOT NULL,
  `loan_number` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `branch`
--

CREATE TABLE `branch` (
  `branch_name` varchar(15) NOT NULL,
  `branch_city` varchar(30) DEFAULT NULL,
  `assets` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `branch`
--

INSERT INTO `branch` (`branch_name`, `branch_city`, `assets`) VALUES
('Brighton', 'Brooklyn', 7100000),
('Downtown', 'Brooklyn', 9000000),
('Mianus', 'Horseneck', 400000),
('North Town', 'Rye', 3700000),
('Perryridge', 'Horseneck', 1700000),
('Pownal', 'Bennington', 300000),
('Redwood', 'Palo Alto', 2100000),
('Round Hill', 'Horseneck', 8000000);

-- --------------------------------------------------------

--
-- Table structure for table `customer`
--

CREATE TABLE `customer` (
  `customer_id` varchar(10) NOT NULL,
  `customer_name` varchar(20) NOT NULL,
  `customer_street` varchar(30) DEFAULT NULL,
  `customer_city` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `customer`
--

INSERT INTO `customer` (`customer_id`, `customer_name`, `customer_street`, `customer_city`) VALUES
('C-101', 'Jones', 'Main', 'Harrison'),
('C-201', 'Smith', 'North', 'Rye'),
('C-211', 'Hayes', 'Main', 'Harrison'),
('C-212', 'Curry', 'North', 'Rye'),
('C-215', 'Lindsay', 'Park', 'Pittsfield'),
('C-220', 'Turner', 'Putnam', 'Stamford'),
('C-222', 'Williams', 'Nassau', 'Princeton'),
('C-225', 'Adams', 'Spring', 'Pittsfield'),
('C-226', 'Johnson', 'Alma', 'Palo Alto'),
('C-233', 'Glenn', 'Sand Hill', 'Woodside'),
('C-234', 'Brooks', 'Senator', 'Brooklyn'),
('C-255', 'Green', 'Walnut', 'Stamford');

-- --------------------------------------------------------

--
-- Table structure for table `depositor`
--

CREATE TABLE `depositor` (
  `customer_id` varchar(10) NOT NULL,
  `account_number` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `loan`
--

CREATE TABLE `loan` (
  `loan_number` varchar(10) NOT NULL,
  `branch_name` varchar(15) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `account`
--
ALTER TABLE `account`
  ADD PRIMARY KEY (`account_number`);

--
-- Indexes for table `borrower`
--
ALTER TABLE `borrower`
  ADD PRIMARY KEY (`customer_id`,`loan_number`),
  ADD KEY `loan_number` (`loan_number`);

--
-- Indexes for table `branch`
--
ALTER TABLE `branch`
  ADD PRIMARY KEY (`branch_name`);

--
-- Indexes for table `customer`
--
ALTER TABLE `customer`
  ADD PRIMARY KEY (`customer_id`);

--
-- Indexes for table `depositor`
--
ALTER TABLE `depositor`
  ADD PRIMARY KEY (`customer_id`,`account_number`),
  ADD KEY `account_number` (`account_number`);

--
-- Indexes for table `loan`
--
ALTER TABLE `loan`
  ADD PRIMARY KEY (`loan_number`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `borrower`
--
ALTER TABLE `borrower`
  ADD CONSTRAINT `borrower_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`customer_id`),
  ADD CONSTRAINT `borrower_ibfk_2` FOREIGN KEY (`loan_number`) REFERENCES `loan` (`loan_number`);

--
-- Constraints for table `depositor`
--
ALTER TABLE `depositor`
  ADD CONSTRAINT `depositor_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`customer_id`),
  ADD CONSTRAINT `depositor_ibfk_2` FOREIGN KEY (`account_number`) REFERENCES `account` (`account_number`);
--
-- Database: `bank_24101268`
--
CREATE DATABASE IF NOT EXISTS `bank_24101268` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `bank_24101268`;

-- --------------------------------------------------------

--
-- Table structure for table `account`
--

CREATE TABLE `account` (
  `branch_name` varchar(15) DEFAULT NULL,
  `account_number` varchar(10) NOT NULL,
  `balance` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `account`
--

INSERT INTO `account` (`branch_name`, `account_number`, `balance`) VALUES
('Downtown', 'A-101', 500),
('Perryridge', 'A-102', 400),
('Brighton', 'A-201', 900),
('Mianus', 'A-215', 700),
('Brighton', 'A-217', 750),
('Redwood', 'A-222', 700),
('Round Hill', 'A-305', 350);

-- --------------------------------------------------------

--
-- Table structure for table `borrower`
--

CREATE TABLE `borrower` (
  `customer_id` varchar(10) NOT NULL,
  `loan_number` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `borrower`
--

INSERT INTO `borrower` (`customer_id`, `loan_number`) VALUES
('C-101', 'L-17'),
('C-201', 'L-11'),
('C-201', 'L-23'),
('C-211', 'L-15'),
('C-212', 'L-93'),
('C-222', 'L-17'),
('C-225', 'L-16'),
('C-226', 'L-14');

-- --------------------------------------------------------

--
-- Table structure for table `branch`
--

CREATE TABLE `branch` (
  `branch_name` varchar(15) NOT NULL,
  `branch_city` varchar(30) DEFAULT NULL,
  `assets` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `branch`
--

INSERT INTO `branch` (`branch_name`, `branch_city`, `assets`) VALUES
('Brighton', 'Brooklyn', 7100000),
('Downtown', 'Brooklyn', 9000000),
('Mianus', 'Horseneck', 400000),
('North Town', 'Rye', 3700000),
('Perryridge', 'Horseneck', 1700000),
('Pownal', 'Bennington', 300000),
('Redwood', 'Palo Alto', 2100000),
('Round Hill', 'Horseneck', 8000000);

-- --------------------------------------------------------

--
-- Table structure for table `customer`
--

CREATE TABLE `customer` (
  `customer_id` varchar(10) NOT NULL,
  `customer_name` varchar(20) NOT NULL,
  `customer_street` varchar(30) DEFAULT NULL,
  `customer_city` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `customer`
--

INSERT INTO `customer` (`customer_id`, `customer_name`, `customer_street`, `customer_city`) VALUES
('C-101', 'Jones', 'Main', 'Harrison'),
('C-201', 'Smith', 'North', 'Rye'),
('C-211', 'Hayes', 'Main', 'Harrison'),
('C-212', 'Curry', 'North', 'Rye'),
('C-215', 'Lindsay', 'Park', 'Pittsfield'),
('C-220', 'Turner', 'Putnam', 'Stamford'),
('C-222', 'Williams', 'Nassau', 'Princeton'),
('C-225', 'Adams', 'Spring', 'Pittsfield'),
('C-226', 'Johnson', 'Alma', 'Palo Alto'),
('C-233', 'Glenn', 'Sand Hill', 'Woodside'),
('C-234', 'Brooks', 'Senator', 'Brooklyn'),
('C-255', 'Green', 'Walnut', 'Stamford');

-- --------------------------------------------------------

--
-- Table structure for table `depositor`
--

CREATE TABLE `depositor` (
  `customer_id` varchar(10) NOT NULL,
  `account_number` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `depositor`
--

INSERT INTO `depositor` (`customer_id`, `account_number`) VALUES
('C-101', 'A-217'),
('C-201', 'A-215'),
('C-211', 'A-102'),
('C-215', 'A-222'),
('C-220', 'A-305'),
('C-226', 'A-101'),
('C-226', 'A-201');

-- --------------------------------------------------------

--
-- Table structure for table `loan`
--

CREATE TABLE `loan` (
  `loan_number` varchar(10) NOT NULL,
  `branch_name` varchar(15) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `loan`
--

INSERT INTO `loan` (`loan_number`, `branch_name`, `amount`) VALUES
('L-11', 'Round Hill', 900),
('L-14', 'Downtown', 1500),
('L-15', 'Perryridge', 1500),
('L-16', 'Perryridge', 1300),
('L-17', 'Downtown', 1000),
('L-23', 'Redwood', 2000),
('L-93', 'Mianus', 500);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `account`
--
ALTER TABLE `account`
  ADD PRIMARY KEY (`account_number`);

--
-- Indexes for table `borrower`
--
ALTER TABLE `borrower`
  ADD PRIMARY KEY (`customer_id`,`loan_number`),
  ADD KEY `loan_number` (`loan_number`);

--
-- Indexes for table `branch`
--
ALTER TABLE `branch`
  ADD PRIMARY KEY (`branch_name`);

--
-- Indexes for table `customer`
--
ALTER TABLE `customer`
  ADD PRIMARY KEY (`customer_id`);

--
-- Indexes for table `depositor`
--
ALTER TABLE `depositor`
  ADD PRIMARY KEY (`customer_id`,`account_number`),
  ADD KEY `account_number` (`account_number`);

--
-- Indexes for table `loan`
--
ALTER TABLE `loan`
  ADD PRIMARY KEY (`loan_number`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `borrower`
--
ALTER TABLE `borrower`
  ADD CONSTRAINT `borrower_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`customer_id`),
  ADD CONSTRAINT `borrower_ibfk_2` FOREIGN KEY (`loan_number`) REFERENCES `loan` (`loan_number`);

--
-- Constraints for table `depositor`
--
ALTER TABLE `depositor`
  ADD CONSTRAINT `depositor_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`customer_id`),
  ADD CONSTRAINT `depositor_ibfk_2` FOREIGN KEY (`account_number`) REFERENCES `account` (`account_number`);
--
-- Database: `bus_reservation_management_system`
--
CREATE DATABASE IF NOT EXISTS `bus_reservation_management_system` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `bus_reservation_management_system`;
--
-- Database: `bus_reservation_system`
--
CREATE DATABASE IF NOT EXISTS `bus_reservation_system` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `bus_reservation_system`;

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
--
-- Database: `phpmyadmin`
--
CREATE DATABASE IF NOT EXISTS `phpmyadmin` DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
USE `phpmyadmin`;

-- --------------------------------------------------------

--
-- Table structure for table `pma__bookmark`
--

CREATE TABLE `pma__bookmark` (
  `id` int(10) UNSIGNED NOT NULL,
  `dbase` varchar(255) NOT NULL DEFAULT '',
  `user` varchar(255) NOT NULL DEFAULT '',
  `label` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `query` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Bookmarks';

-- --------------------------------------------------------

--
-- Table structure for table `pma__central_columns`
--

CREATE TABLE `pma__central_columns` (
  `db_name` varchar(64) NOT NULL,
  `col_name` varchar(64) NOT NULL,
  `col_type` varchar(64) NOT NULL,
  `col_length` text DEFAULT NULL,
  `col_collation` varchar(64) NOT NULL,
  `col_isNull` tinyint(1) NOT NULL,
  `col_extra` varchar(255) DEFAULT '',
  `col_default` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Central list of columns';

-- --------------------------------------------------------

--
-- Table structure for table `pma__column_info`
--

CREATE TABLE `pma__column_info` (
  `id` int(5) UNSIGNED NOT NULL,
  `db_name` varchar(64) NOT NULL DEFAULT '',
  `table_name` varchar(64) NOT NULL DEFAULT '',
  `column_name` varchar(64) NOT NULL DEFAULT '',
  `comment` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `mimetype` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `transformation` varchar(255) NOT NULL DEFAULT '',
  `transformation_options` varchar(255) NOT NULL DEFAULT '',
  `input_transformation` varchar(255) NOT NULL DEFAULT '',
  `input_transformation_options` varchar(255) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Column information for phpMyAdmin';

-- --------------------------------------------------------

--
-- Table structure for table `pma__designer_settings`
--

CREATE TABLE `pma__designer_settings` (
  `username` varchar(64) NOT NULL,
  `settings_data` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Settings related to Designer';

-- --------------------------------------------------------

--
-- Table structure for table `pma__export_templates`
--

CREATE TABLE `pma__export_templates` (
  `id` int(5) UNSIGNED NOT NULL,
  `username` varchar(64) NOT NULL,
  `export_type` varchar(10) NOT NULL,
  `template_name` varchar(64) NOT NULL,
  `template_data` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Saved export templates';

-- --------------------------------------------------------

--
-- Table structure for table `pma__favorite`
--

CREATE TABLE `pma__favorite` (
  `username` varchar(64) NOT NULL,
  `tables` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Favorite tables';

-- --------------------------------------------------------

--
-- Table structure for table `pma__history`
--

CREATE TABLE `pma__history` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `username` varchar(64) NOT NULL DEFAULT '',
  `db` varchar(64) NOT NULL DEFAULT '',
  `table` varchar(64) NOT NULL DEFAULT '',
  `timevalue` timestamp NOT NULL DEFAULT current_timestamp(),
  `sqlquery` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='SQL history for phpMyAdmin';

-- --------------------------------------------------------

--
-- Table structure for table `pma__navigationhiding`
--

CREATE TABLE `pma__navigationhiding` (
  `username` varchar(64) NOT NULL,
  `item_name` varchar(64) NOT NULL,
  `item_type` varchar(64) NOT NULL,
  `db_name` varchar(64) NOT NULL,
  `table_name` varchar(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Hidden items of navigation tree';

-- --------------------------------------------------------

--
-- Table structure for table `pma__pdf_pages`
--

CREATE TABLE `pma__pdf_pages` (
  `db_name` varchar(64) NOT NULL DEFAULT '',
  `page_nr` int(10) UNSIGNED NOT NULL,
  `page_descr` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='PDF relation pages for phpMyAdmin';

-- --------------------------------------------------------

--
-- Table structure for table `pma__recent`
--

CREATE TABLE `pma__recent` (
  `username` varchar(64) NOT NULL,
  `tables` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Recently accessed tables';

--
-- Dumping data for table `pma__recent`
--

INSERT INTO `pma__recent` (`username`, `tables`) VALUES
('root', '[{\"db\":\"uniride2\",\"table\":\"admins\"},{\"db\":\"uniride2\",\"table\":\"university_users\"},{\"db\":\"uniride2\",\"table\":\"passengers\"},{\"db\":\"uniride2\",\"table\":\"billing_transactions\"}]');

-- --------------------------------------------------------

--
-- Table structure for table `pma__relation`
--

CREATE TABLE `pma__relation` (
  `master_db` varchar(64) NOT NULL DEFAULT '',
  `master_table` varchar(64) NOT NULL DEFAULT '',
  `master_field` varchar(64) NOT NULL DEFAULT '',
  `foreign_db` varchar(64) NOT NULL DEFAULT '',
  `foreign_table` varchar(64) NOT NULL DEFAULT '',
  `foreign_field` varchar(64) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Relation table';

-- --------------------------------------------------------

--
-- Table structure for table `pma__savedsearches`
--

CREATE TABLE `pma__savedsearches` (
  `id` int(5) UNSIGNED NOT NULL,
  `username` varchar(64) NOT NULL DEFAULT '',
  `db_name` varchar(64) NOT NULL DEFAULT '',
  `search_name` varchar(64) NOT NULL DEFAULT '',
  `search_data` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Saved searches';

-- --------------------------------------------------------

--
-- Table structure for table `pma__table_coords`
--

CREATE TABLE `pma__table_coords` (
  `db_name` varchar(64) NOT NULL DEFAULT '',
  `table_name` varchar(64) NOT NULL DEFAULT '',
  `pdf_page_number` int(11) NOT NULL DEFAULT 0,
  `x` float UNSIGNED NOT NULL DEFAULT 0,
  `y` float UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Table coordinates for phpMyAdmin PDF output';

-- --------------------------------------------------------

--
-- Table structure for table `pma__table_info`
--

CREATE TABLE `pma__table_info` (
  `db_name` varchar(64) NOT NULL DEFAULT '',
  `table_name` varchar(64) NOT NULL DEFAULT '',
  `display_field` varchar(64) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Table information for phpMyAdmin';

-- --------------------------------------------------------

--
-- Table structure for table `pma__table_uiprefs`
--

CREATE TABLE `pma__table_uiprefs` (
  `username` varchar(64) NOT NULL,
  `db_name` varchar(64) NOT NULL,
  `table_name` varchar(64) NOT NULL,
  `prefs` text NOT NULL,
  `last_update` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Tables'' UI preferences';

-- --------------------------------------------------------

--
-- Table structure for table `pma__tracking`
--

CREATE TABLE `pma__tracking` (
  `db_name` varchar(64) NOT NULL,
  `table_name` varchar(64) NOT NULL,
  `version` int(10) UNSIGNED NOT NULL,
  `date_created` datetime NOT NULL,
  `date_updated` datetime NOT NULL,
  `schema_snapshot` text NOT NULL,
  `schema_sql` text DEFAULT NULL,
  `data_sql` longtext DEFAULT NULL,
  `tracking` set('UPDATE','REPLACE','INSERT','DELETE','TRUNCATE','CREATE DATABASE','ALTER DATABASE','DROP DATABASE','CREATE TABLE','ALTER TABLE','RENAME TABLE','DROP TABLE','CREATE INDEX','DROP INDEX','CREATE VIEW','ALTER VIEW','DROP VIEW') DEFAULT NULL,
  `tracking_active` int(1) UNSIGNED NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Database changes tracking for phpMyAdmin';

-- --------------------------------------------------------

--
-- Table structure for table `pma__userconfig`
--

CREATE TABLE `pma__userconfig` (
  `username` varchar(64) NOT NULL,
  `timevalue` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `config_data` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='User preferences storage for phpMyAdmin';

--
-- Dumping data for table `pma__userconfig`
--

INSERT INTO `pma__userconfig` (`username`, `timevalue`, `config_data`) VALUES
('root', '2026-08-26 16:58:37', '{\"Console\\/Mode\":\"collapse\",\"lang\":\"en_GB\"}');

-- --------------------------------------------------------

--
-- Table structure for table `pma__usergroups`
--

CREATE TABLE `pma__usergroups` (
  `usergroup` varchar(64) NOT NULL,
  `tab` varchar(64) NOT NULL,
  `allowed` enum('Y','N') NOT NULL DEFAULT 'N'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='User groups with configured menu items';

-- --------------------------------------------------------

--
-- Table structure for table `pma__users`
--

CREATE TABLE `pma__users` (
  `username` varchar(64) NOT NULL,
  `usergroup` varchar(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='Users and their assignments to user groups';

--
-- Indexes for dumped tables
--

--
-- Indexes for table `pma__bookmark`
--
ALTER TABLE `pma__bookmark`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pma__central_columns`
--
ALTER TABLE `pma__central_columns`
  ADD PRIMARY KEY (`db_name`,`col_name`);

--
-- Indexes for table `pma__column_info`
--
ALTER TABLE `pma__column_info`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `db_name` (`db_name`,`table_name`,`column_name`);

--
-- Indexes for table `pma__designer_settings`
--
ALTER TABLE `pma__designer_settings`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `pma__export_templates`
--
ALTER TABLE `pma__export_templates`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `u_user_type_template` (`username`,`export_type`,`template_name`);

--
-- Indexes for table `pma__favorite`
--
ALTER TABLE `pma__favorite`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `pma__history`
--
ALTER TABLE `pma__history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `username` (`username`,`db`,`table`,`timevalue`);

--
-- Indexes for table `pma__navigationhiding`
--
ALTER TABLE `pma__navigationhiding`
  ADD PRIMARY KEY (`username`,`item_name`,`item_type`,`db_name`,`table_name`);

--
-- Indexes for table `pma__pdf_pages`
--
ALTER TABLE `pma__pdf_pages`
  ADD PRIMARY KEY (`page_nr`),
  ADD KEY `db_name` (`db_name`);

--
-- Indexes for table `pma__recent`
--
ALTER TABLE `pma__recent`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `pma__relation`
--
ALTER TABLE `pma__relation`
  ADD PRIMARY KEY (`master_db`,`master_table`,`master_field`),
  ADD KEY `foreign_field` (`foreign_db`,`foreign_table`);

--
-- Indexes for table `pma__savedsearches`
--
ALTER TABLE `pma__savedsearches`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `u_savedsearches_username_dbname` (`username`,`db_name`,`search_name`);

--
-- Indexes for table `pma__table_coords`
--
ALTER TABLE `pma__table_coords`
  ADD PRIMARY KEY (`db_name`,`table_name`,`pdf_page_number`);

--
-- Indexes for table `pma__table_info`
--
ALTER TABLE `pma__table_info`
  ADD PRIMARY KEY (`db_name`,`table_name`);

--
-- Indexes for table `pma__table_uiprefs`
--
ALTER TABLE `pma__table_uiprefs`
  ADD PRIMARY KEY (`username`,`db_name`,`table_name`);

--
-- Indexes for table `pma__tracking`
--
ALTER TABLE `pma__tracking`
  ADD PRIMARY KEY (`db_name`,`table_name`,`version`);

--
-- Indexes for table `pma__userconfig`
--
ALTER TABLE `pma__userconfig`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `pma__usergroups`
--
ALTER TABLE `pma__usergroups`
  ADD PRIMARY KEY (`usergroup`,`tab`,`allowed`);

--
-- Indexes for table `pma__users`
--
ALTER TABLE `pma__users`
  ADD PRIMARY KEY (`username`,`usergroup`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `pma__bookmark`
--
ALTER TABLE `pma__bookmark`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pma__column_info`
--
ALTER TABLE `pma__column_info`
  MODIFY `id` int(5) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pma__export_templates`
--
ALTER TABLE `pma__export_templates`
  MODIFY `id` int(5) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pma__history`
--
ALTER TABLE `pma__history`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pma__pdf_pages`
--
ALTER TABLE `pma__pdf_pages`
  MODIFY `page_nr` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pma__savedsearches`
--
ALTER TABLE `pma__savedsearches`
  MODIFY `id` int(5) UNSIGNED NOT NULL AUTO_INCREMENT;
--
-- Database: `test`
--
CREATE DATABASE IF NOT EXISTS `test` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `test`;
--
-- Database: `uniride2`
--
CREATE DATABASE IF NOT EXISTS `uniride2` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `uniride2`;

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
(1, 'UniRide System Admin', 'uniride.admin@gmail.com', '$2y$10$AusFJQXEFcCoQYij/GmDt.ilaeMElqAgu3/I0504NnknHZ7y/2fIm', 'ACTIVE', '2026-08-19 14:38:27');

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

--
-- Dumping data for table `billing_transactions`
--

INSERT INTO `billing_transactions` (`transaction_id`, `passenger_id`, `semester_id`, `booking_id`, `transaction_type`, `amount`, `description`, `transaction_date`) VALUES
(1, 3, 1, NULL, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-417539E6', '2026-08-25 18:39:07'),
(2, 3, 1, NULL, 'BOOKING_CHARGE', 120.00, 'Charge for booking BKG-19D40DC2', '2026-08-25 18:45:10'),
(3, 3, 2, NULL, 'CANCELLATION_CREDIT', -150.00, 'Credit for cancelled booking', '2026-08-25 19:13:37'),
(4, 3, 2, NULL, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-21D7E455', '2026-08-25 19:14:02'),
(5, 3, 2, NULL, 'BOOKING_CHARGE', 120.00, 'Charge for booking BKG-2B2131D8', '2026-08-25 19:14:17'),
(6, 3, 2, NULL, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-3C35D543', '2026-08-25 19:14:46'),
(7, 4, 2, NULL, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-AD48A1BF', '2026-08-25 19:17:56'),
(8, 4, 2, NULL, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-575DB078', '2026-08-25 19:22:41'),
(9, 4, 2, NULL, 'BOOKING_CHARGE', 100.00, 'Charge for booking BKG-5FC13F47', '2026-08-25 19:22:55'),
(10, 4, 2, NULL, 'BOOKING_CHARGE', 120.00, 'Charge for booking BKG-98CC7731', '2026-08-25 19:24:31'),
(11, 4, 2, NULL, 'BOOKING_CHARGE', 120.00, 'Charge for booking BKG-0AE7A8FB', '2026-08-25 19:27:42'),
(12, 4, 2, NULL, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-BAACB941', '2026-08-26 08:11:24'),
(13, 4, 2, 1, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-B92EFDE0', '2026-08-26 08:25:40'),
(14, 4, 2, 2, 'BOOKING_CHARGE', 120.00, 'Charge for booking BKG-D61215CC', '2026-08-26 08:26:29'),
(15, 4, 2, 1, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-3C13CD3E', '2026-08-26 08:36:29'),
(16, 4, 2, 2, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-B50C4652', '2026-08-26 08:39:52'),
(17, 4, 2, 3, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-BB1156B7', '2026-08-26 08:40:02'),
(18, 4, 2, 4, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-C5BB0FBC', '2026-08-26 08:40:20'),
(19, 4, 2, 68, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-699929D5', '2026-08-26 08:44:55'),
(20, 4, 2, 69, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-77970F38', '2026-08-26 08:45:19'),
(21, 4, 2, 70, 'BOOKING_CHARGE', 120.00, 'Charge for booking BKG-48F4B9A6', '2026-08-26 08:51:10'),
(22, 4, 2, 71, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-657AB72F', '2026-08-26 08:59:07'),
(23, 4, 2, 72, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-B412CB3F', '2026-08-26 14:01:57'),
(24, 4, 2, 73, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-DB07E6E4', '2026-08-26 14:03:03'),
(25, 4, 2, 74, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-3044FCB3', '2026-08-26 14:05:26'),
(26, 4, 2, 75, 'BOOKING_CHARGE', 150.00, 'Charge for booking BKG-521B3FE2', '2026-08-26 14:06:22'),
(27, 2, 2, 76, 'BOOKING_CHARGE', 110.00, 'Charge for booking BKG-5233811A19D2', '2026-08-26 16:30:41'),
(28, 2, 2, 77, 'BOOKING_CHARGE', 110.00, 'Charge for booking BKG-5972515C06F5', '2026-08-26 16:31:33'),
(29, 2, 2, 78, 'BOOKING_CHARGE', 110.00, 'Charge for booking BKG-E60F1E039C47', '2026-08-26 16:34:10'),
(30, 2, 2, 79, 'BOOKING_CHARGE', 110.00, 'Charge for booking BKG-06E6BF71264E', '2026-08-26 16:38:00'),
(31, 2, 2, 80, 'BOOKING_CHARGE', 110.00, 'Charge for booking BKG-7646DBF37FC6', '2026-08-26 16:43:08');

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
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `hidden_from_passenger` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`booking_id`, `booking_reference`, `passenger_id`, `schedule_id`, `slot_type`, `seat_number`, `standing_slot`, `fare_charged`, `qr_token`, `status`, `booking_date`, `created_at`, `hidden_from_passenger`) VALUES
(1, 'BKG-3C13CD3E', 101, 8, 'SEAT', 2, NULL, 150.00, '3c13cd56-a129-11f1-81cb-e0d55ee5bc15', 'CANCELLED', '2026-08-26 08:36:29', '2026-08-26 08:36:29', 0),
(2, 'BKG-B50C4652', 102, 8, 'SEAT', 1, NULL, 150.00, 'b50c466a-a129-11f1-81cb-e0d55ee5bc15', 'CANCELLED', '2026-08-26 08:39:52', '2026-08-26 08:39:52', 0),
(3, 'BKG-BB1156B7', 103, 8, 'SEAT', 23, NULL, 150.00, 'bb1156d0-a129-11f1-81cb-e0d55ee5bc15', 'CANCELLED', '2026-08-26 08:40:02', '2026-08-26 08:40:02', 0),
(4, 'BKG-C5BB0FBC', 104, 8, 'SEAT', 13, NULL, 150.00, 'c5bb0fd4-a129-11f1-81cb-e0d55ee5bc15', 'CANCELLED', '2026-08-26 08:40:20', '2026-08-26 08:40:20', 0),
(5, 'BKG-061035D4', 105, 8, 'SEAT', 1, NULL, 150.00, 'legacy-qr-0005', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(6, 'BKG-BFC50D5D', 106, 8, 'SEAT', 2, NULL, 150.00, 'legacy-qr-0006', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(7, 'BKG-D5026DC1', 107, 8, 'SEAT', 3, NULL, 150.00, 'legacy-qr-0007', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(8, 'BKG-66365606', 108, 8, 'SEAT', 4, NULL, 150.00, 'legacy-qr-0008', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(9, 'BKG-9F96A558', 109, 8, 'SEAT', 5, NULL, 150.00, 'legacy-qr-0009', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(10, 'BKG-6D9AA2E1', 110, 8, 'SEAT', 6, NULL, 150.00, 'legacy-qr-0010', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(11, 'BKG-7000E056', 111, 8, 'SEAT', 7, NULL, 150.00, 'legacy-qr-0011', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(12, 'BKG-C0C4E773', 112, 8, 'SEAT', 8, NULL, 150.00, 'legacy-qr-0012', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(13, 'BKG-3A3BADAD', 113, 8, 'SEAT', 9, NULL, 150.00, 'legacy-qr-0013', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(14, 'BKG-E18B1C17', 114, 8, 'SEAT', 10, NULL, 150.00, 'legacy-qr-0014', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(15, 'BKG-DC80997D', 115, 8, 'SEAT', 11, NULL, 150.00, 'legacy-qr-0015', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(16, 'BKG-B232AF37', 116, 8, 'SEAT', 12, NULL, 150.00, 'legacy-qr-0016', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(17, 'BKG-3046A8AD', 117, 8, 'SEAT', 13, NULL, 150.00, 'legacy-qr-0017', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(18, 'BKG-74670771', 118, 8, 'SEAT', 14, NULL, 150.00, 'legacy-qr-0018', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(19, 'BKG-0A429398', 119, 8, 'SEAT', 15, NULL, 150.00, 'legacy-qr-0019', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(20, 'BKG-F9ADC760', 120, 8, 'SEAT', 16, NULL, 150.00, 'legacy-qr-0020', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(21, 'BKG-82EC9D26', 121, 8, 'SEAT', 17, NULL, 150.00, 'legacy-qr-0021', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(22, 'BKG-B15B851F', 122, 8, 'SEAT', 18, NULL, 150.00, 'legacy-qr-0022', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(23, 'BKG-445C7C73', 123, 8, 'SEAT', 19, NULL, 150.00, 'legacy-qr-0023', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(24, 'BKG-5436F672', 124, 8, 'SEAT', 20, NULL, 150.00, 'legacy-qr-0024', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(25, 'BKG-214E7551', 125, 8, 'SEAT', 21, NULL, 150.00, 'legacy-qr-0025', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(26, 'BKG-3B346008', 126, 8, 'SEAT', 22, NULL, 150.00, 'legacy-qr-0026', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(27, 'BKG-4ACF44AF', 127, 8, 'SEAT', 23, NULL, 150.00, 'legacy-qr-0027', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(28, 'BKG-8FB75D63', 128, 8, 'SEAT', 24, NULL, 150.00, 'legacy-qr-0028', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(29, 'BKG-440ADEAB', 129, 8, 'SEAT', 25, NULL, 150.00, 'legacy-qr-0029', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(30, 'BKG-BB2F2167', 130, 8, 'SEAT', 26, NULL, 150.00, 'legacy-qr-0030', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(31, 'BKG-2D4AFDE1', 131, 8, 'SEAT', 27, NULL, 150.00, 'legacy-qr-0031', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(32, 'BKG-79F17419', 132, 8, 'SEAT', 28, NULL, 150.00, 'legacy-qr-0032', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(33, 'BKG-AD6E47FD', 133, 8, 'SEAT', 29, NULL, 150.00, 'legacy-qr-0033', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(34, 'BKG-FCC733BA', 134, 8, 'SEAT', 30, NULL, 150.00, 'legacy-qr-0034', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(35, 'BKG-6A138990', 135, 8, 'SEAT', 31, NULL, 150.00, 'legacy-qr-0035', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(36, 'BKG-4CA20CE9', 136, 8, 'SEAT', 32, NULL, 150.00, 'legacy-qr-0036', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(37, 'BKG-C5A7204A', 137, 8, 'SEAT', 33, NULL, 150.00, 'legacy-qr-0037', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(38, 'BKG-620127FD', 138, 8, 'SEAT', 34, NULL, 150.00, 'legacy-qr-0038', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(39, 'BKG-E3921679', 139, 8, 'SEAT', 35, NULL, 150.00, 'legacy-qr-0039', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(40, 'BKG-64F22F34', 140, 8, 'SEAT', 36, NULL, 150.00, 'legacy-qr-0040', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(41, 'BKG-BA323F57', 141, 8, 'SEAT', 37, NULL, 150.00, 'legacy-qr-0041', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(42, 'BKG-77DDE875', 142, 8, 'SEAT', 38, NULL, 150.00, 'legacy-qr-0042', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(43, 'BKG-F5DB753F', 143, 8, 'SEAT', 39, NULL, 150.00, 'legacy-qr-0043', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(44, 'BKG-A3E81FCE', 144, 8, 'SEAT', 40, NULL, 150.00, 'legacy-qr-0044', 'BOOKED', '2026-08-26 08:41:53', '2026-08-26 08:41:53', 0),
(68, 'BKG-699929D5', 4, 8, 'STANDING', NULL, 3, 150.00, '699929f2-a12a-11f1-81cb-e0d55ee5bc15', 'CANCELLED', '2026-08-26 08:44:55', '2026-08-26 08:44:55', 0),
(69, 'BKG-77970F38', 4, 10, 'SEAT', 28, NULL, 150.00, '77970f53-a12a-11f1-81cb-e0d55ee5bc15', 'CANCELLED', '2026-08-26 08:45:19', '2026-08-26 08:45:19', 0),
(70, 'BKG-48F4B9A6', 4, 3, 'SEAT', 31, NULL, 120.00, '48f4b9be-a12b-11f1-81cb-e0d55ee5bc15', 'CANCELLED', '2026-08-26 08:51:10', '2026-08-26 08:51:10', 0),
(71, 'BKG-657AB72F', 4, 1, 'SEAT', 17, NULL, 150.00, '657ab74a-a12c-11f1-81cb-e0d55ee5bc15', 'CANCELLED', '2026-08-26 08:59:07', '2026-08-26 08:59:07', 0),
(72, 'BKG-B412CB3F', 4, 10, 'SEAT', 10, NULL, 150.00, 'b412cb59-a156-11f1-b03f-e0d55ee5bc15', 'CANCELLED', '2026-08-26 14:01:57', '2026-08-26 14:01:57', 0),
(73, 'BKG-DB07E6E4', 4, 8, 'STANDING', NULL, 3, 150.00, 'db07e701-a156-11f1-b03f-e0d55ee5bc15', 'CANCELLED', '2026-08-26 14:03:03', '2026-08-26 14:03:03', 0),
(74, 'BKG-3044FCB3', 4, 8, 'STANDING', NULL, 3, 150.00, '3044fcce-a157-11f1-b03f-e0d55ee5bc15', 'BOOKED', '2026-08-26 14:05:26', '2026-08-26 14:05:26', 0),
(75, 'BKG-521B3FE2', 4, 9, 'SEAT', 20, NULL, 150.00, '521b3ffd-a157-11f1-b03f-e0d55ee5bc15', 'BOOKED', '2026-08-26 14:06:22', '2026-08-26 14:06:22', 0),
(76, 'BKG-5233811A19D2', 2, 8, 'STANDING', NULL, 2, 110.00, '2282e19d69bfba7e7f41c7e3f4aff6db9c043d1278753ef74758ad9490a21583', 'CANCELLED', '2026-08-26 16:30:41', '2026-08-26 16:30:41', 0),
(77, 'BKG-5972515C06F5', 2, 8, 'STANDING', NULL, 2, 110.00, 'b406c2413d9c4cca0097b05fe75a9651258d2643248b90ddca76fe48799e99bc', 'CANCELLED', '2026-08-26 16:31:33', '2026-08-26 16:31:33', 0),
(78, 'BKG-E60F1E039C47', 2, 8, 'STANDING', NULL, 10, 110.00, 'ed0bb54a9d25f97932ab3cbc126636af611fbe8be84110c2ce081239d48a029b', 'CANCELLED', '2026-08-26 16:34:10', '2026-08-26 16:34:10', 0),
(79, 'BKG-06E6BF71264E', 2, 5, 'SEAT', 19, NULL, 110.00, '6bb839d50ed8a438231bd908bdc1799c0e2b3eea15b47adff5056c7760ed9e3c', 'CANCELLED', '2026-08-26 16:38:00', '2026-08-26 16:38:00', 0),
(80, 'BKG-7646DBF37FC6', 2, 8, 'STANDING', NULL, 4, 110.00, '9bedf27766426357373665b1fb05badd1090145f81a24e3861a74f4501738045', 'BOOKED', '2026-08-26 16:43:08', '2026-08-26 16:43:08', 0);

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
-- Table structure for table `booking_status_history`
--

CREATE TABLE `booking_status_history` (
  `history_id` int(11) NOT NULL,
  `booking_id` int(11) DEFAULT NULL,
  `old_status` varchar(20) DEFAULT NULL,
  `new_status` varchar(20) NOT NULL,
  `changed_by` varchar(50) DEFAULT 'SYSTEM',
  `changed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `booking_status_history`
--

INSERT INTO `booking_status_history` (`history_id`, `booking_id`, `old_status`, `new_status`, `changed_by`, `changed_at`) VALUES
(1, NULL, NULL, 'BOOKED', 'SYSTEM', '2026-08-25 17:28:44'),
(2, NULL, NULL, 'BOOKED', 'SYSTEM', '2026-08-25 18:39:07'),
(3, NULL, NULL, 'BOOKED', 'SYSTEM', '2026-08-25 18:45:10'),
(4, NULL, 'BOOKED', 'CANCELLED', 'PASSENGER', '2026-08-25 19:13:37'),
(5, NULL, NULL, 'BOOKED', 'SYSTEM', '2026-08-25 19:14:02'),
(6, NULL, NULL, 'BOOKED', 'SYSTEM', '2026-08-25 19:14:17'),
(7, NULL, NULL, 'BOOKED', 'SYSTEM', '2026-08-25 19:14:46'),
(8, NULL, NULL, 'BOOKED', 'SYSTEM', '2026-08-25 19:17:56'),
(9, NULL, NULL, 'BOOKED', 'SYSTEM', '2026-08-25 19:22:41'),
(10, NULL, NULL, 'BOOKED', 'SYSTEM', '2026-08-25 19:22:55'),
(11, NULL, NULL, 'BOOKED', 'SYSTEM', '2026-08-25 19:24:31'),
(12, NULL, NULL, 'BOOKED', 'SYSTEM', '2026-08-25 19:27:42'),
(13, NULL, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 08:11:24'),
(14, 1, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 08:25:40'),
(15, 2, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 08:26:29'),
(16, 1, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 08:36:29'),
(17, 2, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 08:39:52'),
(18, 3, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 08:40:02'),
(19, 4, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 08:40:20'),
(20, 68, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 08:44:55'),
(21, 69, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 08:45:19'),
(22, 70, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 08:51:10'),
(23, 71, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 08:59:07'),
(24, 72, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 14:01:57'),
(25, 73, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 14:03:03'),
(26, 74, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 14:05:26'),
(27, 75, NULL, 'BOOKED', 'SYSTEM', '2026-08-26 14:06:22'),
(28, 76, NULL, 'BOOKED', 'PASSENGER', '2026-08-26 16:30:41'),
(29, 77, NULL, 'BOOKED', 'PASSENGER', '2026-08-26 16:31:33'),
(30, 78, NULL, 'BOOKED', 'PASSENGER', '2026-08-26 16:34:10'),
(31, 79, NULL, 'BOOKED', 'PASSENGER', '2026-08-26 16:38:00'),
(32, 80, NULL, 'BOOKED', 'PASSENGER', '2026-08-26 16:43:08');

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
(6, 3, 'DHA-8888', NULL, 40, 10, 'STUDENT_ONLY', 'ACTIVE', '2026-08-19 14:38:27'),
(7, 1, 'DHAKA-METRO-CHA-12-3456', NULL, 40, 10, 'STANDARD', 'ACTIVE', '2026-08-25 14:44:28');

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

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`notification_id`, `passenger_id`, `title`, `message`, `notification_type`, `reference_id`, `is_read`, `read_at`, `created_at`) VALUES
(1, 3, 'Booking Confirmed', 'Your booking BKG-417539E6 is confirmed.', 'BOOKING', 0, 0, NULL, '2026-08-25 18:39:07'),
(2, 3, 'Booking Confirmed', 'Your booking BKG-19D40DC2 is confirmed.', 'BOOKING', 0, 0, NULL, '2026-08-25 18:45:10'),
(3, 3, 'Booking Cancelled', 'Your booking has been cancelled successfully.', 'BOOKING', 0, 0, NULL, '2026-08-25 19:13:37'),
(4, 3, 'Booking Confirmed', 'Your booking BKG-21D7E455 is confirmed.', 'BOOKING', 0, 0, NULL, '2026-08-25 19:14:02'),
(5, 3, 'Booking Confirmed', 'Your booking BKG-2B2131D8 is confirmed.', 'BOOKING', 0, 0, NULL, '2026-08-25 19:14:17'),
(6, 3, 'Booking Confirmed', 'Your booking BKG-3C35D543 is confirmed.', 'BOOKING', 0, 0, NULL, '2026-08-25 19:14:46'),
(7, 4, 'Booking Confirmed', 'Your booking BKG-AD48A1BF is confirmed.', 'BOOKING', 0, 1, NULL, '2026-08-25 19:17:56'),
(8, 4, 'Booking Confirmed', 'Your booking BKG-575DB078 is confirmed.', 'BOOKING', 0, 1, NULL, '2026-08-25 19:22:41'),
(9, 4, 'Booking Confirmed', 'Your booking BKG-5FC13F47 is confirmed.', 'BOOKING', 0, 1, NULL, '2026-08-25 19:22:55'),
(10, 4, 'Booking Confirmed', 'Your booking BKG-98CC7731 is confirmed.', 'BOOKING', 0, 1, NULL, '2026-08-25 19:24:31'),
(11, 4, 'Booking Confirmed', 'Your booking BKG-0AE7A8FB is confirmed.', 'BOOKING', 0, 1, NULL, '2026-08-25 19:27:42'),
(12, 4, 'Booking Confirmed', 'Your booking BKG-BAACB941 is confirmed.', 'BOOKING', 0, 1, NULL, '2026-08-26 08:11:24'),
(13, 4, 'Booking Confirmed', 'Your booking BKG-B92EFDE0 is confirmed.', 'BOOKING', 1, 1, NULL, '2026-08-26 08:25:40'),
(14, 4, 'Booking Confirmed', 'Your booking BKG-D61215CC is confirmed.', 'BOOKING', 2, 1, NULL, '2026-08-26 08:26:29'),
(15, 4, 'Booking Confirmed', 'Your booking BKG-3C13CD3E is confirmed.', 'BOOKING', 1, 1, NULL, '2026-08-26 08:36:29'),
(16, 4, 'Booking Confirmed', 'Your booking BKG-B50C4652 is confirmed.', 'BOOKING', 2, 1, NULL, '2026-08-26 08:39:52'),
(17, 4, 'Booking Confirmed', 'Your booking BKG-BB1156B7 is confirmed.', 'BOOKING', 3, 1, NULL, '2026-08-26 08:40:02'),
(18, 4, 'Booking Confirmed', 'Your booking BKG-C5BB0FBC is confirmed.', 'BOOKING', 4, 1, NULL, '2026-08-26 08:40:20'),
(19, 4, 'Booking Confirmed', 'Your booking BKG-699929D5 is confirmed.', 'BOOKING', 68, 1, NULL, '2026-08-26 08:44:55'),
(20, 4, 'Booking Confirmed', 'Your booking BKG-77970F38 is confirmed.', 'BOOKING', 69, 1, NULL, '2026-08-26 08:45:19'),
(21, 4, 'Booking Confirmed', 'Your booking BKG-48F4B9A6 is confirmed.', 'BOOKING', 70, 1, NULL, '2026-08-26 08:51:10'),
(22, 4, 'Booking Confirmed', 'Your booking BKG-657AB72F is confirmed.', 'BOOKING', 71, 1, NULL, '2026-08-26 08:59:07'),
(23, 4, 'Booking Confirmed', 'Your booking BKG-B412CB3F is confirmed.', 'BOOKING', 72, 0, NULL, '2026-08-26 14:01:57'),
(24, 4, 'Booking Confirmed', 'Your booking BKG-DB07E6E4 is confirmed.', 'BOOKING', 73, 0, NULL, '2026-08-26 14:03:03'),
(25, 4, 'Booking Confirmed', 'Your booking BKG-3044FCB3 is confirmed.', 'BOOKING', 74, 0, NULL, '2026-08-26 14:05:26'),
(26, 4, 'Booking Confirmed', 'Your booking BKG-521B3FE2 is confirmed.', 'BOOKING', 75, 0, NULL, '2026-08-26 14:06:22'),
(27, 2, 'Booking Confirmed', 'Your booking BKG-5233811A19D2 is confirmed at BDT 110.00.', 'BOOKING', 76, 0, NULL, '2026-08-26 16:30:41'),
(28, 2, 'Booking Confirmed', 'Your booking BKG-5972515C06F5 is confirmed at BDT 110.00.', 'BOOKING', 77, 0, NULL, '2026-08-26 16:31:33'),
(29, 2, 'Booking Confirmed', 'Your booking BKG-E60F1E039C47 is confirmed at BDT 110.00.', 'BOOKING', 78, 0, NULL, '2026-08-26 16:34:10'),
(30, 2, 'Booking Confirmed', 'Your booking BKG-06E6BF71264E is confirmed at BDT 110.00.', 'BOOKING', 79, 0, NULL, '2026-08-26 16:38:00'),
(31, 2, 'Booking Confirmed', 'Your booking BKG-7646DBF37FC6 is confirmed at BDT 110.00.', 'BOOKING', 80, 0, NULL, '2026-08-26 16:43:08');

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
(5, 1, 'BRACU-R05', 'Campus - Shewrapara', 'BRACU Campus', 'Shewrapara', 110.00, 'ACTIVE', '2026-08-19 14:38:27'),
(6, 2, 'NSU-R01', 'NSU Campus - Uttara', 'NSU Campus', 'Uttara Sector 10', 100.00, 'ACTIVE', '2026-08-19 14:38:27'),
(7, 3, 'AIUB-R01', 'AIUB Campus - Dhanmondi', 'AIUB Campus', 'Dhanmondi 27', 120.00, 'ACTIVE', '2026-08-19 14:38:27'),
(8, 1, 'R-101', 'BRACU - Uttara Express', 'Merul Badda', 'Uttara', 110.00, 'ACTIVE', '2026-08-25 14:44:28');

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
(1, 1, 1, '2026-08-26', '17:20:00', '18:50:00', 'SCHEDULED', '2026-08-19 14:38:27'),
(2, 2, 1, '2026-08-26', '17:20:00', '18:30:00', 'SCHEDULED', '2026-08-19 14:38:27'),
(3, 3, 2, '2026-08-26', '17:20:00', '18:20:00', 'SCHEDULED', '2026-08-19 14:38:27'),
(4, 4, 3, '2026-08-26', '17:20:00', '18:45:00', 'SCHEDULED', '2026-08-19 14:38:27'),
(5, 5, 1, '2026-08-27', '19:30:00', '20:40:00', 'SCHEDULED', '2026-08-19 14:38:27'),
(6, 6, 5, '2026-08-27', '17:00:00', '18:00:00', 'SCHEDULED', '2026-08-19 14:38:27'),
(7, 7, 6, '2026-08-27', '17:15:00', '18:15:00', 'SCHEDULED', '2026-08-19 14:38:27'),
(8, 8, 7, '2026-08-26', '10:00:00', '11:30:00', 'SCHEDULED', '2026-08-25 14:44:28'),
(9, 8, 7, '2026-08-26', '14:30:00', '16:00:00', 'SCHEDULED', '2026-08-25 14:44:28'),
(10, 8, 7, '2026-08-27', '08:00:00', '09:30:00', 'SCHEDULED', '2026-08-25 14:44:28');

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
(1, 'Fall 2026', '2026-08-01', '2026-12-15', 0, '2026-08-19 14:38:27'),
(2, 'Spring 2026', '2026-01-15', '2026-05-30', 1, '2026-08-19 14:38:27');

-- --------------------------------------------------------

--
-- Table structure for table `semester_bills`
--

CREATE TABLE `semester_bills` (
  `bill_id` int(11) NOT NULL,
  `passenger_id` int(11) NOT NULL,
  `semester_id` int(11) NOT NULL,
  `total_charges` decimal(10,2) NOT NULL DEFAULT 0.00,
  `net_balance` decimal(10,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `total_credits` decimal(10,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `semester_bills`
--

INSERT INTO `semester_bills` (`bill_id`, `passenger_id`, `semester_id`, `total_charges`, `net_balance`, `created_at`, `updated_at`, `total_credits`) VALUES
(1, 3, 1, 270.00, 270.00, '2026-08-25 18:39:07', '2026-08-25 18:45:10', 0.00),
(3, 3, 2, 420.00, 420.00, '2026-08-25 19:14:02', '2026-08-25 19:14:46', 0.00),
(6, 4, 2, 2830.00, 2830.00, '2026-08-25 19:17:56', '2026-08-26 14:06:22', 0.00),
(7, 2, 2, 550.00, 550.00, '2026-08-26 16:30:41', '2026-08-26 16:43:08', 0.00);

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
(1, 1, 'BRACU Transport Admin', 'bracu.transport@gmail.com', '$2y$10$/SLxFOdu2WIGCxTMzCO0LuWOTD1vjwy7P4kJd.nwezzWckQFB8Nx6', 'ADMIN', 'ACTIVE', '2026-08-19 14:38:27'),
(2, 2, 'NSU Transport Admin', 'nsu.transport@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ADMIN', 'ACTIVE', '2026-08-19 14:38:27'),
(3, 3, 'AIUB Transport Admin', 'aiub.transport@gmail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'ADMIN', 'ACTIVE', '2026-08-19 14:38:27');

-- --------------------------------------------------------

--
-- Table structure for table `user_notification_preferences`
--

CREATE TABLE `user_notification_preferences` (
  `preference_id` bigint(20) UNSIGNED NOT NULL,
  `user_type` enum('PASSENGER','UNIVERSITY_ADMIN','SYSTEM_ADMIN') NOT NULL,
  `user_id` int(11) NOT NULL,
  `preference_key` varchar(80) NOT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_notification_preferences`
--

INSERT INTO `user_notification_preferences` (`preference_id`, `user_type`, `user_id`, `preference_key`, `enabled`, `updated_at`) VALUES
(1, 'PASSENGER', 1, 'master_notifications', 1, '2026-08-26 16:42:06'),
(2, 'PASSENGER', 1, 'security_alerts', 1, '2026-08-26 16:42:06'),
(3, 'PASSENGER', 1, 'password_changes', 1, '2026-08-26 16:42:06'),
(4, 'PASSENGER', 1, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(5, 'PASSENGER', 1, 'profile_updates', 1, '2026-08-26 16:42:06'),
(6, 'PASSENGER', 1, 'service_announcements', 1, '2026-08-26 16:42:06'),
(7, 'PASSENGER', 1, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(8, 'PASSENGER', 2, 'master_notifications', 1, '2026-08-26 16:42:06'),
(9, 'PASSENGER', 2, 'security_alerts', 1, '2026-08-26 16:42:06'),
(10, 'PASSENGER', 2, 'password_changes', 1, '2026-08-26 16:42:06'),
(11, 'PASSENGER', 2, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(12, 'PASSENGER', 2, 'profile_updates', 1, '2026-08-26 16:42:06'),
(13, 'PASSENGER', 2, 'service_announcements', 1, '2026-08-26 16:42:06'),
(14, 'PASSENGER', 2, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(15, 'PASSENGER', 3, 'master_notifications', 1, '2026-08-26 16:42:06'),
(16, 'PASSENGER', 3, 'security_alerts', 1, '2026-08-26 16:42:06'),
(17, 'PASSENGER', 3, 'password_changes', 1, '2026-08-26 16:42:06'),
(18, 'PASSENGER', 3, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(19, 'PASSENGER', 3, 'profile_updates', 1, '2026-08-26 16:42:06'),
(20, 'PASSENGER', 3, 'service_announcements', 1, '2026-08-26 16:42:06'),
(21, 'PASSENGER', 3, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(22, 'PASSENGER', 4, 'master_notifications', 1, '2026-08-26 16:42:06'),
(23, 'PASSENGER', 4, 'security_alerts', 1, '2026-08-26 16:42:06'),
(24, 'PASSENGER', 4, 'password_changes', 1, '2026-08-26 16:42:06'),
(25, 'PASSENGER', 4, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(26, 'PASSENGER', 4, 'profile_updates', 1, '2026-08-26 16:42:06'),
(27, 'PASSENGER', 4, 'service_announcements', 1, '2026-08-26 16:42:06'),
(28, 'PASSENGER', 4, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(29, 'PASSENGER', 5, 'master_notifications', 1, '2026-08-26 16:42:06'),
(30, 'PASSENGER', 5, 'security_alerts', 1, '2026-08-26 16:42:06'),
(31, 'PASSENGER', 5, 'password_changes', 1, '2026-08-26 16:42:06'),
(32, 'PASSENGER', 5, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(33, 'PASSENGER', 5, 'profile_updates', 1, '2026-08-26 16:42:06'),
(34, 'PASSENGER', 5, 'service_announcements', 1, '2026-08-26 16:42:06'),
(35, 'PASSENGER', 5, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(36, 'PASSENGER', 6, 'master_notifications', 1, '2026-08-26 16:42:06'),
(37, 'PASSENGER', 6, 'security_alerts', 1, '2026-08-26 16:42:06'),
(38, 'PASSENGER', 6, 'password_changes', 1, '2026-08-26 16:42:06'),
(39, 'PASSENGER', 6, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(40, 'PASSENGER', 6, 'profile_updates', 1, '2026-08-26 16:42:06'),
(41, 'PASSENGER', 6, 'service_announcements', 1, '2026-08-26 16:42:06'),
(42, 'PASSENGER', 6, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(43, 'PASSENGER', 11, 'master_notifications', 1, '2026-08-26 16:42:06'),
(44, 'PASSENGER', 11, 'security_alerts', 1, '2026-08-26 16:42:06'),
(45, 'PASSENGER', 11, 'password_changes', 1, '2026-08-26 16:42:06'),
(46, 'PASSENGER', 11, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(47, 'PASSENGER', 11, 'profile_updates', 1, '2026-08-26 16:42:06'),
(48, 'PASSENGER', 11, 'service_announcements', 1, '2026-08-26 16:42:06'),
(49, 'PASSENGER', 11, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(50, 'PASSENGER', 12, 'master_notifications', 1, '2026-08-26 16:42:06'),
(51, 'PASSENGER', 12, 'security_alerts', 1, '2026-08-26 16:42:06'),
(52, 'PASSENGER', 12, 'password_changes', 1, '2026-08-26 16:42:06'),
(53, 'PASSENGER', 12, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(54, 'PASSENGER', 12, 'profile_updates', 1, '2026-08-26 16:42:06'),
(55, 'PASSENGER', 12, 'service_announcements', 1, '2026-08-26 16:42:06'),
(56, 'PASSENGER', 12, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(57, 'PASSENGER', 13, 'master_notifications', 1, '2026-08-26 16:42:06'),
(58, 'PASSENGER', 13, 'security_alerts', 1, '2026-08-26 16:42:06'),
(59, 'PASSENGER', 13, 'password_changes', 1, '2026-08-26 16:42:06'),
(60, 'PASSENGER', 13, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(61, 'PASSENGER', 13, 'profile_updates', 1, '2026-08-26 16:42:06'),
(62, 'PASSENGER', 13, 'service_announcements', 1, '2026-08-26 16:42:06'),
(63, 'PASSENGER', 13, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(64, 'PASSENGER', 14, 'master_notifications', 1, '2026-08-26 16:42:06'),
(65, 'PASSENGER', 14, 'security_alerts', 1, '2026-08-26 16:42:06'),
(66, 'PASSENGER', 14, 'password_changes', 1, '2026-08-26 16:42:06'),
(67, 'PASSENGER', 14, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(68, 'PASSENGER', 14, 'profile_updates', 1, '2026-08-26 16:42:06'),
(69, 'PASSENGER', 14, 'service_announcements', 1, '2026-08-26 16:42:06'),
(70, 'PASSENGER', 14, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(71, 'PASSENGER', 15, 'master_notifications', 1, '2026-08-26 16:42:06'),
(72, 'PASSENGER', 15, 'security_alerts', 1, '2026-08-26 16:42:06'),
(73, 'PASSENGER', 15, 'password_changes', 1, '2026-08-26 16:42:06'),
(74, 'PASSENGER', 15, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(75, 'PASSENGER', 15, 'profile_updates', 1, '2026-08-26 16:42:06'),
(76, 'PASSENGER', 15, 'service_announcements', 1, '2026-08-26 16:42:06'),
(77, 'PASSENGER', 15, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(78, 'PASSENGER', 16, 'master_notifications', 1, '2026-08-26 16:42:06'),
(79, 'PASSENGER', 16, 'security_alerts', 1, '2026-08-26 16:42:06'),
(80, 'PASSENGER', 16, 'password_changes', 1, '2026-08-26 16:42:06'),
(81, 'PASSENGER', 16, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(82, 'PASSENGER', 16, 'profile_updates', 1, '2026-08-26 16:42:06'),
(83, 'PASSENGER', 16, 'service_announcements', 1, '2026-08-26 16:42:06'),
(84, 'PASSENGER', 16, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(85, 'PASSENGER', 17, 'master_notifications', 1, '2026-08-26 16:42:06'),
(86, 'PASSENGER', 17, 'security_alerts', 1, '2026-08-26 16:42:06'),
(87, 'PASSENGER', 17, 'password_changes', 1, '2026-08-26 16:42:06'),
(88, 'PASSENGER', 17, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(89, 'PASSENGER', 17, 'profile_updates', 1, '2026-08-26 16:42:06'),
(90, 'PASSENGER', 17, 'service_announcements', 1, '2026-08-26 16:42:06'),
(91, 'PASSENGER', 17, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(92, 'PASSENGER', 18, 'master_notifications', 1, '2026-08-26 16:42:06'),
(93, 'PASSENGER', 18, 'security_alerts', 1, '2026-08-26 16:42:06'),
(94, 'PASSENGER', 18, 'password_changes', 1, '2026-08-26 16:42:06'),
(95, 'PASSENGER', 18, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(96, 'PASSENGER', 18, 'profile_updates', 1, '2026-08-26 16:42:06'),
(97, 'PASSENGER', 18, 'service_announcements', 1, '2026-08-26 16:42:06'),
(98, 'PASSENGER', 18, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(99, 'PASSENGER', 19, 'master_notifications', 1, '2026-08-26 16:42:06'),
(100, 'PASSENGER', 19, 'security_alerts', 1, '2026-08-26 16:42:06'),
(101, 'PASSENGER', 19, 'password_changes', 1, '2026-08-26 16:42:06'),
(102, 'PASSENGER', 19, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(103, 'PASSENGER', 19, 'profile_updates', 1, '2026-08-26 16:42:06'),
(104, 'PASSENGER', 19, 'service_announcements', 1, '2026-08-26 16:42:06'),
(105, 'PASSENGER', 19, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(106, 'PASSENGER', 20, 'master_notifications', 1, '2026-08-26 16:42:06'),
(107, 'PASSENGER', 20, 'security_alerts', 1, '2026-08-26 16:42:06'),
(108, 'PASSENGER', 20, 'password_changes', 1, '2026-08-26 16:42:06'),
(109, 'PASSENGER', 20, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(110, 'PASSENGER', 20, 'profile_updates', 1, '2026-08-26 16:42:06'),
(111, 'PASSENGER', 20, 'service_announcements', 1, '2026-08-26 16:42:06'),
(112, 'PASSENGER', 20, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(113, 'PASSENGER', 21, 'master_notifications', 1, '2026-08-26 16:42:06'),
(114, 'PASSENGER', 21, 'security_alerts', 1, '2026-08-26 16:42:06'),
(115, 'PASSENGER', 21, 'password_changes', 1, '2026-08-26 16:42:06'),
(116, 'PASSENGER', 21, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(117, 'PASSENGER', 21, 'profile_updates', 1, '2026-08-26 16:42:06'),
(118, 'PASSENGER', 21, 'service_announcements', 1, '2026-08-26 16:42:06'),
(119, 'PASSENGER', 21, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(120, 'PASSENGER', 22, 'master_notifications', 1, '2026-08-26 16:42:06'),
(121, 'PASSENGER', 22, 'security_alerts', 1, '2026-08-26 16:42:06'),
(122, 'PASSENGER', 22, 'password_changes', 1, '2026-08-26 16:42:06'),
(123, 'PASSENGER', 22, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(124, 'PASSENGER', 22, 'profile_updates', 1, '2026-08-26 16:42:06'),
(125, 'PASSENGER', 22, 'service_announcements', 1, '2026-08-26 16:42:06'),
(126, 'PASSENGER', 22, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(127, 'PASSENGER', 23, 'master_notifications', 1, '2026-08-26 16:42:06'),
(128, 'PASSENGER', 23, 'security_alerts', 1, '2026-08-26 16:42:06'),
(129, 'PASSENGER', 23, 'password_changes', 1, '2026-08-26 16:42:06'),
(130, 'PASSENGER', 23, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(131, 'PASSENGER', 23, 'profile_updates', 1, '2026-08-26 16:42:06'),
(132, 'PASSENGER', 23, 'service_announcements', 1, '2026-08-26 16:42:06'),
(133, 'PASSENGER', 23, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(134, 'PASSENGER', 24, 'master_notifications', 1, '2026-08-26 16:42:06'),
(135, 'PASSENGER', 24, 'security_alerts', 1, '2026-08-26 16:42:06'),
(136, 'PASSENGER', 24, 'password_changes', 1, '2026-08-26 16:42:06'),
(137, 'PASSENGER', 24, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(138, 'PASSENGER', 24, 'profile_updates', 1, '2026-08-26 16:42:06'),
(139, 'PASSENGER', 24, 'service_announcements', 1, '2026-08-26 16:42:06'),
(140, 'PASSENGER', 24, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(141, 'PASSENGER', 25, 'master_notifications', 1, '2026-08-26 16:42:06'),
(142, 'PASSENGER', 25, 'security_alerts', 1, '2026-08-26 16:42:06'),
(143, 'PASSENGER', 25, 'password_changes', 1, '2026-08-26 16:42:06'),
(144, 'PASSENGER', 25, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(145, 'PASSENGER', 25, 'profile_updates', 1, '2026-08-26 16:42:06'),
(146, 'PASSENGER', 25, 'service_announcements', 1, '2026-08-26 16:42:06'),
(147, 'PASSENGER', 25, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(148, 'PASSENGER', 26, 'master_notifications', 1, '2026-08-26 16:42:06'),
(149, 'PASSENGER', 26, 'security_alerts', 1, '2026-08-26 16:42:06'),
(150, 'PASSENGER', 26, 'password_changes', 1, '2026-08-26 16:42:06'),
(151, 'PASSENGER', 26, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(152, 'PASSENGER', 26, 'profile_updates', 1, '2026-08-26 16:42:06'),
(153, 'PASSENGER', 26, 'service_announcements', 1, '2026-08-26 16:42:06'),
(154, 'PASSENGER', 26, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(155, 'PASSENGER', 27, 'master_notifications', 1, '2026-08-26 16:42:06'),
(156, 'PASSENGER', 27, 'security_alerts', 1, '2026-08-26 16:42:06'),
(157, 'PASSENGER', 27, 'password_changes', 1, '2026-08-26 16:42:06'),
(158, 'PASSENGER', 27, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(159, 'PASSENGER', 27, 'profile_updates', 1, '2026-08-26 16:42:06'),
(160, 'PASSENGER', 27, 'service_announcements', 1, '2026-08-26 16:42:06'),
(161, 'PASSENGER', 27, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(162, 'PASSENGER', 28, 'master_notifications', 1, '2026-08-26 16:42:06'),
(163, 'PASSENGER', 28, 'security_alerts', 1, '2026-08-26 16:42:06'),
(164, 'PASSENGER', 28, 'password_changes', 1, '2026-08-26 16:42:06'),
(165, 'PASSENGER', 28, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(166, 'PASSENGER', 28, 'profile_updates', 1, '2026-08-26 16:42:06'),
(167, 'PASSENGER', 28, 'service_announcements', 1, '2026-08-26 16:42:06'),
(168, 'PASSENGER', 28, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(169, 'PASSENGER', 29, 'master_notifications', 1, '2026-08-26 16:42:06'),
(170, 'PASSENGER', 29, 'security_alerts', 1, '2026-08-26 16:42:06'),
(171, 'PASSENGER', 29, 'password_changes', 1, '2026-08-26 16:42:06'),
(172, 'PASSENGER', 29, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(173, 'PASSENGER', 29, 'profile_updates', 1, '2026-08-26 16:42:06'),
(174, 'PASSENGER', 29, 'service_announcements', 1, '2026-08-26 16:42:06'),
(175, 'PASSENGER', 29, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(176, 'PASSENGER', 30, 'master_notifications', 1, '2026-08-26 16:42:06'),
(177, 'PASSENGER', 30, 'security_alerts', 1, '2026-08-26 16:42:06'),
(178, 'PASSENGER', 30, 'password_changes', 1, '2026-08-26 16:42:06'),
(179, 'PASSENGER', 30, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(180, 'PASSENGER', 30, 'profile_updates', 1, '2026-08-26 16:42:06'),
(181, 'PASSENGER', 30, 'service_announcements', 1, '2026-08-26 16:42:06'),
(182, 'PASSENGER', 30, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(183, 'PASSENGER', 31, 'master_notifications', 1, '2026-08-26 16:42:06'),
(184, 'PASSENGER', 31, 'security_alerts', 1, '2026-08-26 16:42:06'),
(185, 'PASSENGER', 31, 'password_changes', 1, '2026-08-26 16:42:06'),
(186, 'PASSENGER', 31, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(187, 'PASSENGER', 31, 'profile_updates', 1, '2026-08-26 16:42:06'),
(188, 'PASSENGER', 31, 'service_announcements', 1, '2026-08-26 16:42:06'),
(189, 'PASSENGER', 31, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(190, 'PASSENGER', 32, 'master_notifications', 1, '2026-08-26 16:42:06'),
(191, 'PASSENGER', 32, 'security_alerts', 1, '2026-08-26 16:42:06'),
(192, 'PASSENGER', 32, 'password_changes', 1, '2026-08-26 16:42:06'),
(193, 'PASSENGER', 32, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(194, 'PASSENGER', 32, 'profile_updates', 1, '2026-08-26 16:42:06'),
(195, 'PASSENGER', 32, 'service_announcements', 1, '2026-08-26 16:42:06'),
(196, 'PASSENGER', 32, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(197, 'PASSENGER', 33, 'master_notifications', 1, '2026-08-26 16:42:06'),
(198, 'PASSENGER', 33, 'security_alerts', 1, '2026-08-26 16:42:06'),
(199, 'PASSENGER', 33, 'password_changes', 1, '2026-08-26 16:42:06'),
(200, 'PASSENGER', 33, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(201, 'PASSENGER', 33, 'profile_updates', 1, '2026-08-26 16:42:06'),
(202, 'PASSENGER', 33, 'service_announcements', 1, '2026-08-26 16:42:06'),
(203, 'PASSENGER', 33, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(204, 'PASSENGER', 34, 'master_notifications', 1, '2026-08-26 16:42:06'),
(205, 'PASSENGER', 34, 'security_alerts', 1, '2026-08-26 16:42:06'),
(206, 'PASSENGER', 34, 'password_changes', 1, '2026-08-26 16:42:06'),
(207, 'PASSENGER', 34, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(208, 'PASSENGER', 34, 'profile_updates', 1, '2026-08-26 16:42:06'),
(209, 'PASSENGER', 34, 'service_announcements', 1, '2026-08-26 16:42:06'),
(210, 'PASSENGER', 34, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(211, 'PASSENGER', 35, 'master_notifications', 1, '2026-08-26 16:42:06'),
(212, 'PASSENGER', 35, 'security_alerts', 1, '2026-08-26 16:42:06'),
(213, 'PASSENGER', 35, 'password_changes', 1, '2026-08-26 16:42:06'),
(214, 'PASSENGER', 35, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(215, 'PASSENGER', 35, 'profile_updates', 1, '2026-08-26 16:42:06'),
(216, 'PASSENGER', 35, 'service_announcements', 1, '2026-08-26 16:42:06'),
(217, 'PASSENGER', 35, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(218, 'PASSENGER', 36, 'master_notifications', 1, '2026-08-26 16:42:06'),
(219, 'PASSENGER', 36, 'security_alerts', 1, '2026-08-26 16:42:06'),
(220, 'PASSENGER', 36, 'password_changes', 1, '2026-08-26 16:42:06'),
(221, 'PASSENGER', 36, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(222, 'PASSENGER', 36, 'profile_updates', 1, '2026-08-26 16:42:06'),
(223, 'PASSENGER', 36, 'service_announcements', 1, '2026-08-26 16:42:06'),
(224, 'PASSENGER', 36, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(225, 'PASSENGER', 37, 'master_notifications', 1, '2026-08-26 16:42:06'),
(226, 'PASSENGER', 37, 'security_alerts', 1, '2026-08-26 16:42:06'),
(227, 'PASSENGER', 37, 'password_changes', 1, '2026-08-26 16:42:06'),
(228, 'PASSENGER', 37, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(229, 'PASSENGER', 37, 'profile_updates', 1, '2026-08-26 16:42:06'),
(230, 'PASSENGER', 37, 'service_announcements', 1, '2026-08-26 16:42:06'),
(231, 'PASSENGER', 37, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(232, 'PASSENGER', 38, 'master_notifications', 1, '2026-08-26 16:42:06'),
(233, 'PASSENGER', 38, 'security_alerts', 1, '2026-08-26 16:42:06'),
(234, 'PASSENGER', 38, 'password_changes', 1, '2026-08-26 16:42:06'),
(235, 'PASSENGER', 38, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(236, 'PASSENGER', 38, 'profile_updates', 1, '2026-08-26 16:42:06'),
(237, 'PASSENGER', 38, 'service_announcements', 1, '2026-08-26 16:42:06'),
(238, 'PASSENGER', 38, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(239, 'PASSENGER', 39, 'master_notifications', 1, '2026-08-26 16:42:06'),
(240, 'PASSENGER', 39, 'security_alerts', 1, '2026-08-26 16:42:06'),
(241, 'PASSENGER', 39, 'password_changes', 1, '2026-08-26 16:42:06'),
(242, 'PASSENGER', 39, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(243, 'PASSENGER', 39, 'profile_updates', 1, '2026-08-26 16:42:06'),
(244, 'PASSENGER', 39, 'service_announcements', 1, '2026-08-26 16:42:06'),
(245, 'PASSENGER', 39, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(246, 'PASSENGER', 40, 'master_notifications', 1, '2026-08-26 16:42:06'),
(247, 'PASSENGER', 40, 'security_alerts', 1, '2026-08-26 16:42:06'),
(248, 'PASSENGER', 40, 'password_changes', 1, '2026-08-26 16:42:06'),
(249, 'PASSENGER', 40, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(250, 'PASSENGER', 40, 'profile_updates', 1, '2026-08-26 16:42:06'),
(251, 'PASSENGER', 40, 'service_announcements', 1, '2026-08-26 16:42:06'),
(252, 'PASSENGER', 40, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(253, 'PASSENGER', 41, 'master_notifications', 1, '2026-08-26 16:42:06'),
(254, 'PASSENGER', 41, 'security_alerts', 1, '2026-08-26 16:42:06'),
(255, 'PASSENGER', 41, 'password_changes', 1, '2026-08-26 16:42:06'),
(256, 'PASSENGER', 41, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(257, 'PASSENGER', 41, 'profile_updates', 1, '2026-08-26 16:42:06'),
(258, 'PASSENGER', 41, 'service_announcements', 1, '2026-08-26 16:42:06'),
(259, 'PASSENGER', 41, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(260, 'PASSENGER', 42, 'master_notifications', 1, '2026-08-26 16:42:06'),
(261, 'PASSENGER', 42, 'security_alerts', 1, '2026-08-26 16:42:06'),
(262, 'PASSENGER', 42, 'password_changes', 1, '2026-08-26 16:42:06'),
(263, 'PASSENGER', 42, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(264, 'PASSENGER', 42, 'profile_updates', 1, '2026-08-26 16:42:06'),
(265, 'PASSENGER', 42, 'service_announcements', 1, '2026-08-26 16:42:06'),
(266, 'PASSENGER', 42, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(267, 'PASSENGER', 43, 'master_notifications', 1, '2026-08-26 16:42:06'),
(268, 'PASSENGER', 43, 'security_alerts', 1, '2026-08-26 16:42:06'),
(269, 'PASSENGER', 43, 'password_changes', 1, '2026-08-26 16:42:06'),
(270, 'PASSENGER', 43, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(271, 'PASSENGER', 43, 'profile_updates', 1, '2026-08-26 16:42:06'),
(272, 'PASSENGER', 43, 'service_announcements', 1, '2026-08-26 16:42:06'),
(273, 'PASSENGER', 43, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(274, 'PASSENGER', 44, 'master_notifications', 1, '2026-08-26 16:42:06'),
(275, 'PASSENGER', 44, 'security_alerts', 1, '2026-08-26 16:42:06'),
(276, 'PASSENGER', 44, 'password_changes', 1, '2026-08-26 16:42:06'),
(277, 'PASSENGER', 44, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(278, 'PASSENGER', 44, 'profile_updates', 1, '2026-08-26 16:42:06'),
(279, 'PASSENGER', 44, 'service_announcements', 1, '2026-08-26 16:42:06'),
(280, 'PASSENGER', 44, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(281, 'PASSENGER', 45, 'master_notifications', 1, '2026-08-26 16:42:06'),
(282, 'PASSENGER', 45, 'security_alerts', 1, '2026-08-26 16:42:06'),
(283, 'PASSENGER', 45, 'password_changes', 1, '2026-08-26 16:42:06'),
(284, 'PASSENGER', 45, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(285, 'PASSENGER', 45, 'profile_updates', 1, '2026-08-26 16:42:06'),
(286, 'PASSENGER', 45, 'service_announcements', 1, '2026-08-26 16:42:06'),
(287, 'PASSENGER', 45, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(288, 'PASSENGER', 46, 'master_notifications', 1, '2026-08-26 16:42:06'),
(289, 'PASSENGER', 46, 'security_alerts', 1, '2026-08-26 16:42:06'),
(290, 'PASSENGER', 46, 'password_changes', 1, '2026-08-26 16:42:06'),
(291, 'PASSENGER', 46, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(292, 'PASSENGER', 46, 'profile_updates', 1, '2026-08-26 16:42:06'),
(293, 'PASSENGER', 46, 'service_announcements', 1, '2026-08-26 16:42:06'),
(294, 'PASSENGER', 46, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(295, 'PASSENGER', 47, 'master_notifications', 1, '2026-08-26 16:42:06'),
(296, 'PASSENGER', 47, 'security_alerts', 1, '2026-08-26 16:42:06'),
(297, 'PASSENGER', 47, 'password_changes', 1, '2026-08-26 16:42:06'),
(298, 'PASSENGER', 47, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(299, 'PASSENGER', 47, 'profile_updates', 1, '2026-08-26 16:42:06'),
(300, 'PASSENGER', 47, 'service_announcements', 1, '2026-08-26 16:42:06'),
(301, 'PASSENGER', 47, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(302, 'PASSENGER', 48, 'master_notifications', 1, '2026-08-26 16:42:06'),
(303, 'PASSENGER', 48, 'security_alerts', 1, '2026-08-26 16:42:06'),
(304, 'PASSENGER', 48, 'password_changes', 1, '2026-08-26 16:42:06'),
(305, 'PASSENGER', 48, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(306, 'PASSENGER', 48, 'profile_updates', 1, '2026-08-26 16:42:06'),
(307, 'PASSENGER', 48, 'service_announcements', 1, '2026-08-26 16:42:06'),
(308, 'PASSENGER', 48, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(309, 'PASSENGER', 49, 'master_notifications', 1, '2026-08-26 16:42:06'),
(310, 'PASSENGER', 49, 'security_alerts', 1, '2026-08-26 16:42:06'),
(311, 'PASSENGER', 49, 'password_changes', 1, '2026-08-26 16:42:06'),
(312, 'PASSENGER', 49, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(313, 'PASSENGER', 49, 'profile_updates', 1, '2026-08-26 16:42:06'),
(314, 'PASSENGER', 49, 'service_announcements', 1, '2026-08-26 16:42:06'),
(315, 'PASSENGER', 49, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(316, 'PASSENGER', 50, 'master_notifications', 1, '2026-08-26 16:42:06'),
(317, 'PASSENGER', 50, 'security_alerts', 1, '2026-08-26 16:42:06'),
(318, 'PASSENGER', 50, 'password_changes', 1, '2026-08-26 16:42:06'),
(319, 'PASSENGER', 50, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(320, 'PASSENGER', 50, 'profile_updates', 1, '2026-08-26 16:42:06'),
(321, 'PASSENGER', 50, 'service_announcements', 1, '2026-08-26 16:42:06'),
(322, 'PASSENGER', 50, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(323, 'PASSENGER', 51, 'master_notifications', 1, '2026-08-26 16:42:06'),
(324, 'PASSENGER', 51, 'security_alerts', 1, '2026-08-26 16:42:06'),
(325, 'PASSENGER', 51, 'password_changes', 1, '2026-08-26 16:42:06'),
(326, 'PASSENGER', 51, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(327, 'PASSENGER', 51, 'profile_updates', 1, '2026-08-26 16:42:06'),
(328, 'PASSENGER', 51, 'service_announcements', 1, '2026-08-26 16:42:06'),
(329, 'PASSENGER', 51, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(330, 'PASSENGER', 52, 'master_notifications', 1, '2026-08-26 16:42:06'),
(331, 'PASSENGER', 52, 'security_alerts', 1, '2026-08-26 16:42:06'),
(332, 'PASSENGER', 52, 'password_changes', 1, '2026-08-26 16:42:06'),
(333, 'PASSENGER', 52, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(334, 'PASSENGER', 52, 'profile_updates', 1, '2026-08-26 16:42:06'),
(335, 'PASSENGER', 52, 'service_announcements', 1, '2026-08-26 16:42:06'),
(336, 'PASSENGER', 52, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(337, 'PASSENGER', 53, 'master_notifications', 1, '2026-08-26 16:42:06'),
(338, 'PASSENGER', 53, 'security_alerts', 1, '2026-08-26 16:42:06'),
(339, 'PASSENGER', 53, 'password_changes', 1, '2026-08-26 16:42:06'),
(340, 'PASSENGER', 53, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(341, 'PASSENGER', 53, 'profile_updates', 1, '2026-08-26 16:42:06'),
(342, 'PASSENGER', 53, 'service_announcements', 1, '2026-08-26 16:42:06'),
(343, 'PASSENGER', 53, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(344, 'PASSENGER', 54, 'master_notifications', 1, '2026-08-26 16:42:06'),
(345, 'PASSENGER', 54, 'security_alerts', 1, '2026-08-26 16:42:06'),
(346, 'PASSENGER', 54, 'password_changes', 1, '2026-08-26 16:42:06'),
(347, 'PASSENGER', 54, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(348, 'PASSENGER', 54, 'profile_updates', 1, '2026-08-26 16:42:06'),
(349, 'PASSENGER', 54, 'service_announcements', 1, '2026-08-26 16:42:06'),
(350, 'PASSENGER', 54, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(351, 'PASSENGER', 55, 'master_notifications', 1, '2026-08-26 16:42:06'),
(352, 'PASSENGER', 55, 'security_alerts', 1, '2026-08-26 16:42:06'),
(353, 'PASSENGER', 55, 'password_changes', 1, '2026-08-26 16:42:06'),
(354, 'PASSENGER', 55, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(355, 'PASSENGER', 55, 'profile_updates', 1, '2026-08-26 16:42:06'),
(356, 'PASSENGER', 55, 'service_announcements', 1, '2026-08-26 16:42:06'),
(357, 'PASSENGER', 55, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(358, 'PASSENGER', 56, 'master_notifications', 1, '2026-08-26 16:42:06'),
(359, 'PASSENGER', 56, 'security_alerts', 1, '2026-08-26 16:42:06'),
(360, 'PASSENGER', 56, 'password_changes', 1, '2026-08-26 16:42:06'),
(361, 'PASSENGER', 56, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(362, 'PASSENGER', 56, 'profile_updates', 1, '2026-08-26 16:42:06'),
(363, 'PASSENGER', 56, 'service_announcements', 1, '2026-08-26 16:42:06'),
(364, 'PASSENGER', 56, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(365, 'PASSENGER', 57, 'master_notifications', 1, '2026-08-26 16:42:06'),
(366, 'PASSENGER', 57, 'security_alerts', 1, '2026-08-26 16:42:06'),
(367, 'PASSENGER', 57, 'password_changes', 1, '2026-08-26 16:42:06'),
(368, 'PASSENGER', 57, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(369, 'PASSENGER', 57, 'profile_updates', 1, '2026-08-26 16:42:06'),
(370, 'PASSENGER', 57, 'service_announcements', 1, '2026-08-26 16:42:06'),
(371, 'PASSENGER', 57, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(372, 'PASSENGER', 58, 'master_notifications', 1, '2026-08-26 16:42:06'),
(373, 'PASSENGER', 58, 'security_alerts', 1, '2026-08-26 16:42:06'),
(374, 'PASSENGER', 58, 'password_changes', 1, '2026-08-26 16:42:06'),
(375, 'PASSENGER', 58, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(376, 'PASSENGER', 58, 'profile_updates', 1, '2026-08-26 16:42:06'),
(377, 'PASSENGER', 58, 'service_announcements', 1, '2026-08-26 16:42:06'),
(378, 'PASSENGER', 58, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(379, 'PASSENGER', 59, 'master_notifications', 1, '2026-08-26 16:42:06'),
(380, 'PASSENGER', 59, 'security_alerts', 1, '2026-08-26 16:42:06'),
(381, 'PASSENGER', 59, 'password_changes', 1, '2026-08-26 16:42:06'),
(382, 'PASSENGER', 59, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(383, 'PASSENGER', 59, 'profile_updates', 1, '2026-08-26 16:42:06'),
(384, 'PASSENGER', 59, 'service_announcements', 1, '2026-08-26 16:42:06'),
(385, 'PASSENGER', 59, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(386, 'PASSENGER', 60, 'master_notifications', 1, '2026-08-26 16:42:06'),
(387, 'PASSENGER', 60, 'security_alerts', 1, '2026-08-26 16:42:06'),
(388, 'PASSENGER', 60, 'password_changes', 1, '2026-08-26 16:42:06'),
(389, 'PASSENGER', 60, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(390, 'PASSENGER', 60, 'profile_updates', 1, '2026-08-26 16:42:06'),
(391, 'PASSENGER', 60, 'service_announcements', 1, '2026-08-26 16:42:06'),
(392, 'PASSENGER', 60, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(393, 'PASSENGER', 7, 'master_notifications', 1, '2026-08-26 16:42:06'),
(394, 'PASSENGER', 7, 'security_alerts', 1, '2026-08-26 16:42:06'),
(395, 'PASSENGER', 7, 'password_changes', 1, '2026-08-26 16:42:06'),
(396, 'PASSENGER', 7, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(397, 'PASSENGER', 7, 'profile_updates', 1, '2026-08-26 16:42:06'),
(398, 'PASSENGER', 7, 'service_announcements', 1, '2026-08-26 16:42:06'),
(399, 'PASSENGER', 7, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(400, 'PASSENGER', 8, 'master_notifications', 1, '2026-08-26 16:42:06'),
(401, 'PASSENGER', 8, 'security_alerts', 1, '2026-08-26 16:42:06'),
(402, 'PASSENGER', 8, 'password_changes', 1, '2026-08-26 16:42:06'),
(403, 'PASSENGER', 8, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(404, 'PASSENGER', 8, 'profile_updates', 1, '2026-08-26 16:42:06'),
(405, 'PASSENGER', 8, 'service_announcements', 1, '2026-08-26 16:42:06'),
(406, 'PASSENGER', 8, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(407, 'PASSENGER', 61, 'master_notifications', 1, '2026-08-26 16:42:06'),
(408, 'PASSENGER', 61, 'security_alerts', 1, '2026-08-26 16:42:06'),
(409, 'PASSENGER', 61, 'password_changes', 1, '2026-08-26 16:42:06'),
(410, 'PASSENGER', 61, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(411, 'PASSENGER', 61, 'profile_updates', 1, '2026-08-26 16:42:06'),
(412, 'PASSENGER', 61, 'service_announcements', 1, '2026-08-26 16:42:06'),
(413, 'PASSENGER', 61, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(414, 'PASSENGER', 62, 'master_notifications', 1, '2026-08-26 16:42:06'),
(415, 'PASSENGER', 62, 'security_alerts', 1, '2026-08-26 16:42:06'),
(416, 'PASSENGER', 62, 'password_changes', 1, '2026-08-26 16:42:06'),
(417, 'PASSENGER', 62, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(418, 'PASSENGER', 62, 'profile_updates', 1, '2026-08-26 16:42:06'),
(419, 'PASSENGER', 62, 'service_announcements', 1, '2026-08-26 16:42:06'),
(420, 'PASSENGER', 62, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(421, 'PASSENGER', 63, 'master_notifications', 1, '2026-08-26 16:42:06'),
(422, 'PASSENGER', 63, 'security_alerts', 1, '2026-08-26 16:42:06'),
(423, 'PASSENGER', 63, 'password_changes', 1, '2026-08-26 16:42:06'),
(424, 'PASSENGER', 63, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(425, 'PASSENGER', 63, 'profile_updates', 1, '2026-08-26 16:42:06'),
(426, 'PASSENGER', 63, 'service_announcements', 1, '2026-08-26 16:42:06'),
(427, 'PASSENGER', 63, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(428, 'PASSENGER', 64, 'master_notifications', 1, '2026-08-26 16:42:06'),
(429, 'PASSENGER', 64, 'security_alerts', 1, '2026-08-26 16:42:06'),
(430, 'PASSENGER', 64, 'password_changes', 1, '2026-08-26 16:42:06'),
(431, 'PASSENGER', 64, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(432, 'PASSENGER', 64, 'profile_updates', 1, '2026-08-26 16:42:06'),
(433, 'PASSENGER', 64, 'service_announcements', 1, '2026-08-26 16:42:06'),
(434, 'PASSENGER', 64, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(435, 'PASSENGER', 65, 'master_notifications', 1, '2026-08-26 16:42:06'),
(436, 'PASSENGER', 65, 'security_alerts', 1, '2026-08-26 16:42:06'),
(437, 'PASSENGER', 65, 'password_changes', 1, '2026-08-26 16:42:06'),
(438, 'PASSENGER', 65, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(439, 'PASSENGER', 65, 'profile_updates', 1, '2026-08-26 16:42:06'),
(440, 'PASSENGER', 65, 'service_announcements', 1, '2026-08-26 16:42:06'),
(441, 'PASSENGER', 65, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(442, 'PASSENGER', 66, 'master_notifications', 1, '2026-08-26 16:42:06'),
(443, 'PASSENGER', 66, 'security_alerts', 1, '2026-08-26 16:42:06'),
(444, 'PASSENGER', 66, 'password_changes', 1, '2026-08-26 16:42:06'),
(445, 'PASSENGER', 66, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(446, 'PASSENGER', 66, 'profile_updates', 1, '2026-08-26 16:42:06'),
(447, 'PASSENGER', 66, 'service_announcements', 1, '2026-08-26 16:42:06'),
(448, 'PASSENGER', 66, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(449, 'PASSENGER', 67, 'master_notifications', 1, '2026-08-26 16:42:06'),
(450, 'PASSENGER', 67, 'security_alerts', 1, '2026-08-26 16:42:06'),
(451, 'PASSENGER', 67, 'password_changes', 1, '2026-08-26 16:42:06'),
(452, 'PASSENGER', 67, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(453, 'PASSENGER', 67, 'profile_updates', 1, '2026-08-26 16:42:06'),
(454, 'PASSENGER', 67, 'service_announcements', 1, '2026-08-26 16:42:06'),
(455, 'PASSENGER', 67, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(456, 'PASSENGER', 68, 'master_notifications', 1, '2026-08-26 16:42:06'),
(457, 'PASSENGER', 68, 'security_alerts', 1, '2026-08-26 16:42:06'),
(458, 'PASSENGER', 68, 'password_changes', 1, '2026-08-26 16:42:06'),
(459, 'PASSENGER', 68, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(460, 'PASSENGER', 68, 'profile_updates', 1, '2026-08-26 16:42:06'),
(461, 'PASSENGER', 68, 'service_announcements', 1, '2026-08-26 16:42:06'),
(462, 'PASSENGER', 68, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(463, 'PASSENGER', 69, 'master_notifications', 1, '2026-08-26 16:42:06'),
(464, 'PASSENGER', 69, 'security_alerts', 1, '2026-08-26 16:42:06'),
(465, 'PASSENGER', 69, 'password_changes', 1, '2026-08-26 16:42:06'),
(466, 'PASSENGER', 69, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(467, 'PASSENGER', 69, 'profile_updates', 1, '2026-08-26 16:42:06'),
(468, 'PASSENGER', 69, 'service_announcements', 1, '2026-08-26 16:42:06'),
(469, 'PASSENGER', 69, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(470, 'PASSENGER', 70, 'master_notifications', 1, '2026-08-26 16:42:06'),
(471, 'PASSENGER', 70, 'security_alerts', 1, '2026-08-26 16:42:06'),
(472, 'PASSENGER', 70, 'password_changes', 1, '2026-08-26 16:42:06'),
(473, 'PASSENGER', 70, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(474, 'PASSENGER', 70, 'profile_updates', 1, '2026-08-26 16:42:06'),
(475, 'PASSENGER', 70, 'service_announcements', 1, '2026-08-26 16:42:06'),
(476, 'PASSENGER', 70, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(477, 'PASSENGER', 71, 'master_notifications', 1, '2026-08-26 16:42:06'),
(478, 'PASSENGER', 71, 'security_alerts', 1, '2026-08-26 16:42:06'),
(479, 'PASSENGER', 71, 'password_changes', 1, '2026-08-26 16:42:06'),
(480, 'PASSENGER', 71, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(481, 'PASSENGER', 71, 'profile_updates', 1, '2026-08-26 16:42:06'),
(482, 'PASSENGER', 71, 'service_announcements', 1, '2026-08-26 16:42:06'),
(483, 'PASSENGER', 71, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(484, 'PASSENGER', 72, 'master_notifications', 1, '2026-08-26 16:42:06'),
(485, 'PASSENGER', 72, 'security_alerts', 1, '2026-08-26 16:42:06'),
(486, 'PASSENGER', 72, 'password_changes', 1, '2026-08-26 16:42:06'),
(487, 'PASSENGER', 72, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(488, 'PASSENGER', 72, 'profile_updates', 1, '2026-08-26 16:42:06'),
(489, 'PASSENGER', 72, 'service_announcements', 1, '2026-08-26 16:42:06'),
(490, 'PASSENGER', 72, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(491, 'PASSENGER', 73, 'master_notifications', 1, '2026-08-26 16:42:06'),
(492, 'PASSENGER', 73, 'security_alerts', 1, '2026-08-26 16:42:06'),
(493, 'PASSENGER', 73, 'password_changes', 1, '2026-08-26 16:42:06'),
(494, 'PASSENGER', 73, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(495, 'PASSENGER', 73, 'profile_updates', 1, '2026-08-26 16:42:06'),
(496, 'PASSENGER', 73, 'service_announcements', 1, '2026-08-26 16:42:06'),
(497, 'PASSENGER', 73, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(498, 'PASSENGER', 74, 'master_notifications', 1, '2026-08-26 16:42:06'),
(499, 'PASSENGER', 74, 'security_alerts', 1, '2026-08-26 16:42:06'),
(500, 'PASSENGER', 74, 'password_changes', 1, '2026-08-26 16:42:06'),
(501, 'PASSENGER', 74, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(502, 'PASSENGER', 74, 'profile_updates', 1, '2026-08-26 16:42:06'),
(503, 'PASSENGER', 74, 'service_announcements', 1, '2026-08-26 16:42:06'),
(504, 'PASSENGER', 74, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(505, 'PASSENGER', 75, 'master_notifications', 1, '2026-08-26 16:42:06'),
(506, 'PASSENGER', 75, 'security_alerts', 1, '2026-08-26 16:42:06'),
(507, 'PASSENGER', 75, 'password_changes', 1, '2026-08-26 16:42:06'),
(508, 'PASSENGER', 75, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(509, 'PASSENGER', 75, 'profile_updates', 1, '2026-08-26 16:42:06'),
(510, 'PASSENGER', 75, 'service_announcements', 1, '2026-08-26 16:42:06'),
(511, 'PASSENGER', 75, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(512, 'PASSENGER', 76, 'master_notifications', 1, '2026-08-26 16:42:06'),
(513, 'PASSENGER', 76, 'security_alerts', 1, '2026-08-26 16:42:06'),
(514, 'PASSENGER', 76, 'password_changes', 1, '2026-08-26 16:42:06'),
(515, 'PASSENGER', 76, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(516, 'PASSENGER', 76, 'profile_updates', 1, '2026-08-26 16:42:06'),
(517, 'PASSENGER', 76, 'service_announcements', 1, '2026-08-26 16:42:06'),
(518, 'PASSENGER', 76, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(519, 'PASSENGER', 77, 'master_notifications', 1, '2026-08-26 16:42:06'),
(520, 'PASSENGER', 77, 'security_alerts', 1, '2026-08-26 16:42:06'),
(521, 'PASSENGER', 77, 'password_changes', 1, '2026-08-26 16:42:06'),
(522, 'PASSENGER', 77, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(523, 'PASSENGER', 77, 'profile_updates', 1, '2026-08-26 16:42:06'),
(524, 'PASSENGER', 77, 'service_announcements', 1, '2026-08-26 16:42:06'),
(525, 'PASSENGER', 77, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(526, 'PASSENGER', 78, 'master_notifications', 1, '2026-08-26 16:42:06'),
(527, 'PASSENGER', 78, 'security_alerts', 1, '2026-08-26 16:42:06'),
(528, 'PASSENGER', 78, 'password_changes', 1, '2026-08-26 16:42:06'),
(529, 'PASSENGER', 78, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(530, 'PASSENGER', 78, 'profile_updates', 1, '2026-08-26 16:42:06'),
(531, 'PASSENGER', 78, 'service_announcements', 1, '2026-08-26 16:42:06'),
(532, 'PASSENGER', 78, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(533, 'PASSENGER', 79, 'master_notifications', 1, '2026-08-26 16:42:06'),
(534, 'PASSENGER', 79, 'security_alerts', 1, '2026-08-26 16:42:06'),
(535, 'PASSENGER', 79, 'password_changes', 1, '2026-08-26 16:42:06'),
(536, 'PASSENGER', 79, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(537, 'PASSENGER', 79, 'profile_updates', 1, '2026-08-26 16:42:06'),
(538, 'PASSENGER', 79, 'service_announcements', 1, '2026-08-26 16:42:06'),
(539, 'PASSENGER', 79, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(540, 'PASSENGER', 80, 'master_notifications', 1, '2026-08-26 16:42:06'),
(541, 'PASSENGER', 80, 'security_alerts', 1, '2026-08-26 16:42:06'),
(542, 'PASSENGER', 80, 'password_changes', 1, '2026-08-26 16:42:06'),
(543, 'PASSENGER', 80, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(544, 'PASSENGER', 80, 'profile_updates', 1, '2026-08-26 16:42:06'),
(545, 'PASSENGER', 80, 'service_announcements', 1, '2026-08-26 16:42:06'),
(546, 'PASSENGER', 80, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(547, 'PASSENGER', 81, 'master_notifications', 1, '2026-08-26 16:42:06'),
(548, 'PASSENGER', 81, 'security_alerts', 1, '2026-08-26 16:42:06'),
(549, 'PASSENGER', 81, 'password_changes', 1, '2026-08-26 16:42:06'),
(550, 'PASSENGER', 81, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(551, 'PASSENGER', 81, 'profile_updates', 1, '2026-08-26 16:42:06'),
(552, 'PASSENGER', 81, 'service_announcements', 1, '2026-08-26 16:42:06'),
(553, 'PASSENGER', 81, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(554, 'PASSENGER', 82, 'master_notifications', 1, '2026-08-26 16:42:06'),
(555, 'PASSENGER', 82, 'security_alerts', 1, '2026-08-26 16:42:06'),
(556, 'PASSENGER', 82, 'password_changes', 1, '2026-08-26 16:42:06'),
(557, 'PASSENGER', 82, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(558, 'PASSENGER', 82, 'profile_updates', 1, '2026-08-26 16:42:06'),
(559, 'PASSENGER', 82, 'service_announcements', 1, '2026-08-26 16:42:06'),
(560, 'PASSENGER', 82, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(561, 'PASSENGER', 83, 'master_notifications', 1, '2026-08-26 16:42:06'),
(562, 'PASSENGER', 83, 'security_alerts', 1, '2026-08-26 16:42:06'),
(563, 'PASSENGER', 83, 'password_changes', 1, '2026-08-26 16:42:06'),
(564, 'PASSENGER', 83, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(565, 'PASSENGER', 83, 'profile_updates', 1, '2026-08-26 16:42:06'),
(566, 'PASSENGER', 83, 'service_announcements', 1, '2026-08-26 16:42:06'),
(567, 'PASSENGER', 83, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(568, 'PASSENGER', 84, 'master_notifications', 1, '2026-08-26 16:42:06'),
(569, 'PASSENGER', 84, 'security_alerts', 1, '2026-08-26 16:42:06'),
(570, 'PASSENGER', 84, 'password_changes', 1, '2026-08-26 16:42:06'),
(571, 'PASSENGER', 84, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(572, 'PASSENGER', 84, 'profile_updates', 1, '2026-08-26 16:42:06'),
(573, 'PASSENGER', 84, 'service_announcements', 1, '2026-08-26 16:42:06'),
(574, 'PASSENGER', 84, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(575, 'PASSENGER', 85, 'master_notifications', 1, '2026-08-26 16:42:06'),
(576, 'PASSENGER', 85, 'security_alerts', 1, '2026-08-26 16:42:06'),
(577, 'PASSENGER', 85, 'password_changes', 1, '2026-08-26 16:42:06'),
(578, 'PASSENGER', 85, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(579, 'PASSENGER', 85, 'profile_updates', 1, '2026-08-26 16:42:06'),
(580, 'PASSENGER', 85, 'service_announcements', 1, '2026-08-26 16:42:06'),
(581, 'PASSENGER', 85, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(582, 'PASSENGER', 86, 'master_notifications', 1, '2026-08-26 16:42:06'),
(583, 'PASSENGER', 86, 'security_alerts', 1, '2026-08-26 16:42:06'),
(584, 'PASSENGER', 86, 'password_changes', 1, '2026-08-26 16:42:06'),
(585, 'PASSENGER', 86, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(586, 'PASSENGER', 86, 'profile_updates', 1, '2026-08-26 16:42:06'),
(587, 'PASSENGER', 86, 'service_announcements', 1, '2026-08-26 16:42:06'),
(588, 'PASSENGER', 86, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(589, 'PASSENGER', 87, 'master_notifications', 1, '2026-08-26 16:42:06'),
(590, 'PASSENGER', 87, 'security_alerts', 1, '2026-08-26 16:42:06'),
(591, 'PASSENGER', 87, 'password_changes', 1, '2026-08-26 16:42:06'),
(592, 'PASSENGER', 87, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(593, 'PASSENGER', 87, 'profile_updates', 1, '2026-08-26 16:42:06'),
(594, 'PASSENGER', 87, 'service_announcements', 1, '2026-08-26 16:42:06'),
(595, 'PASSENGER', 87, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(596, 'PASSENGER', 88, 'master_notifications', 1, '2026-08-26 16:42:06'),
(597, 'PASSENGER', 88, 'security_alerts', 1, '2026-08-26 16:42:06'),
(598, 'PASSENGER', 88, 'password_changes', 1, '2026-08-26 16:42:06'),
(599, 'PASSENGER', 88, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(600, 'PASSENGER', 88, 'profile_updates', 1, '2026-08-26 16:42:06'),
(601, 'PASSENGER', 88, 'service_announcements', 1, '2026-08-26 16:42:06'),
(602, 'PASSENGER', 88, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(603, 'PASSENGER', 89, 'master_notifications', 1, '2026-08-26 16:42:06'),
(604, 'PASSENGER', 89, 'security_alerts', 1, '2026-08-26 16:42:06'),
(605, 'PASSENGER', 89, 'password_changes', 1, '2026-08-26 16:42:06'),
(606, 'PASSENGER', 89, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(607, 'PASSENGER', 89, 'profile_updates', 1, '2026-08-26 16:42:06'),
(608, 'PASSENGER', 89, 'service_announcements', 1, '2026-08-26 16:42:06'),
(609, 'PASSENGER', 89, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(610, 'PASSENGER', 90, 'master_notifications', 1, '2026-08-26 16:42:06'),
(611, 'PASSENGER', 90, 'security_alerts', 1, '2026-08-26 16:42:06'),
(612, 'PASSENGER', 90, 'password_changes', 1, '2026-08-26 16:42:06'),
(613, 'PASSENGER', 90, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(614, 'PASSENGER', 90, 'profile_updates', 1, '2026-08-26 16:42:06'),
(615, 'PASSENGER', 90, 'service_announcements', 1, '2026-08-26 16:42:06'),
(616, 'PASSENGER', 90, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(617, 'PASSENGER', 91, 'master_notifications', 1, '2026-08-26 16:42:06'),
(618, 'PASSENGER', 91, 'security_alerts', 1, '2026-08-26 16:42:06'),
(619, 'PASSENGER', 91, 'password_changes', 1, '2026-08-26 16:42:06'),
(620, 'PASSENGER', 91, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(621, 'PASSENGER', 91, 'profile_updates', 1, '2026-08-26 16:42:06'),
(622, 'PASSENGER', 91, 'service_announcements', 1, '2026-08-26 16:42:06'),
(623, 'PASSENGER', 91, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(624, 'PASSENGER', 92, 'master_notifications', 1, '2026-08-26 16:42:06'),
(625, 'PASSENGER', 92, 'security_alerts', 1, '2026-08-26 16:42:06'),
(626, 'PASSENGER', 92, 'password_changes', 1, '2026-08-26 16:42:06'),
(627, 'PASSENGER', 92, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(628, 'PASSENGER', 92, 'profile_updates', 1, '2026-08-26 16:42:06'),
(629, 'PASSENGER', 92, 'service_announcements', 1, '2026-08-26 16:42:06'),
(630, 'PASSENGER', 92, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(631, 'PASSENGER', 93, 'master_notifications', 1, '2026-08-26 16:42:06'),
(632, 'PASSENGER', 93, 'security_alerts', 1, '2026-08-26 16:42:06'),
(633, 'PASSENGER', 93, 'password_changes', 1, '2026-08-26 16:42:06'),
(634, 'PASSENGER', 93, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(635, 'PASSENGER', 93, 'profile_updates', 1, '2026-08-26 16:42:06'),
(636, 'PASSENGER', 93, 'service_announcements', 1, '2026-08-26 16:42:06'),
(637, 'PASSENGER', 93, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(638, 'PASSENGER', 94, 'master_notifications', 1, '2026-08-26 16:42:06'),
(639, 'PASSENGER', 94, 'security_alerts', 1, '2026-08-26 16:42:06'),
(640, 'PASSENGER', 94, 'password_changes', 1, '2026-08-26 16:42:06'),
(641, 'PASSENGER', 94, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(642, 'PASSENGER', 94, 'profile_updates', 1, '2026-08-26 16:42:06'),
(643, 'PASSENGER', 94, 'service_announcements', 1, '2026-08-26 16:42:06'),
(644, 'PASSENGER', 94, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(645, 'PASSENGER', 95, 'master_notifications', 1, '2026-08-26 16:42:06'),
(646, 'PASSENGER', 95, 'security_alerts', 1, '2026-08-26 16:42:06'),
(647, 'PASSENGER', 95, 'password_changes', 1, '2026-08-26 16:42:06'),
(648, 'PASSENGER', 95, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(649, 'PASSENGER', 95, 'profile_updates', 1, '2026-08-26 16:42:06'),
(650, 'PASSENGER', 95, 'service_announcements', 1, '2026-08-26 16:42:06'),
(651, 'PASSENGER', 95, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(652, 'PASSENGER', 96, 'master_notifications', 1, '2026-08-26 16:42:06'),
(653, 'PASSENGER', 96, 'security_alerts', 1, '2026-08-26 16:42:06'),
(654, 'PASSENGER', 96, 'password_changes', 1, '2026-08-26 16:42:06'),
(655, 'PASSENGER', 96, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(656, 'PASSENGER', 96, 'profile_updates', 1, '2026-08-26 16:42:06'),
(657, 'PASSENGER', 96, 'service_announcements', 1, '2026-08-26 16:42:06'),
(658, 'PASSENGER', 96, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(659, 'PASSENGER', 97, 'master_notifications', 1, '2026-08-26 16:42:06'),
(660, 'PASSENGER', 97, 'security_alerts', 1, '2026-08-26 16:42:06'),
(661, 'PASSENGER', 97, 'password_changes', 1, '2026-08-26 16:42:06'),
(662, 'PASSENGER', 97, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(663, 'PASSENGER', 97, 'profile_updates', 1, '2026-08-26 16:42:06'),
(664, 'PASSENGER', 97, 'service_announcements', 1, '2026-08-26 16:42:06'),
(665, 'PASSENGER', 97, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(666, 'PASSENGER', 98, 'master_notifications', 1, '2026-08-26 16:42:06'),
(667, 'PASSENGER', 98, 'security_alerts', 1, '2026-08-26 16:42:06'),
(668, 'PASSENGER', 98, 'password_changes', 1, '2026-08-26 16:42:06'),
(669, 'PASSENGER', 98, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(670, 'PASSENGER', 98, 'profile_updates', 1, '2026-08-26 16:42:06'),
(671, 'PASSENGER', 98, 'service_announcements', 1, '2026-08-26 16:42:06'),
(672, 'PASSENGER', 98, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(673, 'PASSENGER', 99, 'master_notifications', 1, '2026-08-26 16:42:06'),
(674, 'PASSENGER', 99, 'security_alerts', 1, '2026-08-26 16:42:06'),
(675, 'PASSENGER', 99, 'password_changes', 1, '2026-08-26 16:42:06'),
(676, 'PASSENGER', 99, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(677, 'PASSENGER', 99, 'profile_updates', 1, '2026-08-26 16:42:06'),
(678, 'PASSENGER', 99, 'service_announcements', 1, '2026-08-26 16:42:06'),
(679, 'PASSENGER', 99, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(680, 'PASSENGER', 100, 'master_notifications', 1, '2026-08-26 16:42:06'),
(681, 'PASSENGER', 100, 'security_alerts', 1, '2026-08-26 16:42:06'),
(682, 'PASSENGER', 100, 'password_changes', 1, '2026-08-26 16:42:06'),
(683, 'PASSENGER', 100, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(684, 'PASSENGER', 100, 'profile_updates', 1, '2026-08-26 16:42:06'),
(685, 'PASSENGER', 100, 'service_announcements', 1, '2026-08-26 16:42:06'),
(686, 'PASSENGER', 100, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(687, 'PASSENGER', 101, 'master_notifications', 1, '2026-08-26 16:42:06'),
(688, 'PASSENGER', 101, 'security_alerts', 1, '2026-08-26 16:42:06'),
(689, 'PASSENGER', 101, 'password_changes', 1, '2026-08-26 16:42:06'),
(690, 'PASSENGER', 101, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(691, 'PASSENGER', 101, 'profile_updates', 1, '2026-08-26 16:42:06'),
(692, 'PASSENGER', 101, 'service_announcements', 1, '2026-08-26 16:42:06'),
(693, 'PASSENGER', 101, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(694, 'PASSENGER', 102, 'master_notifications', 1, '2026-08-26 16:42:06'),
(695, 'PASSENGER', 102, 'security_alerts', 1, '2026-08-26 16:42:06'),
(696, 'PASSENGER', 102, 'password_changes', 1, '2026-08-26 16:42:06'),
(697, 'PASSENGER', 102, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(698, 'PASSENGER', 102, 'profile_updates', 1, '2026-08-26 16:42:06'),
(699, 'PASSENGER', 102, 'service_announcements', 1, '2026-08-26 16:42:06'),
(700, 'PASSENGER', 102, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(701, 'PASSENGER', 103, 'master_notifications', 1, '2026-08-26 16:42:06'),
(702, 'PASSENGER', 103, 'security_alerts', 1, '2026-08-26 16:42:06'),
(703, 'PASSENGER', 103, 'password_changes', 1, '2026-08-26 16:42:06'),
(704, 'PASSENGER', 103, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(705, 'PASSENGER', 103, 'profile_updates', 1, '2026-08-26 16:42:06'),
(706, 'PASSENGER', 103, 'service_announcements', 1, '2026-08-26 16:42:06'),
(707, 'PASSENGER', 103, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(708, 'PASSENGER', 104, 'master_notifications', 1, '2026-08-26 16:42:06'),
(709, 'PASSENGER', 104, 'security_alerts', 1, '2026-08-26 16:42:06'),
(710, 'PASSENGER', 104, 'password_changes', 1, '2026-08-26 16:42:06'),
(711, 'PASSENGER', 104, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(712, 'PASSENGER', 104, 'profile_updates', 1, '2026-08-26 16:42:06'),
(713, 'PASSENGER', 104, 'service_announcements', 1, '2026-08-26 16:42:06'),
(714, 'PASSENGER', 104, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(715, 'PASSENGER', 105, 'master_notifications', 1, '2026-08-26 16:42:06'),
(716, 'PASSENGER', 105, 'security_alerts', 1, '2026-08-26 16:42:06'),
(717, 'PASSENGER', 105, 'password_changes', 1, '2026-08-26 16:42:06');
INSERT INTO `user_notification_preferences` (`preference_id`, `user_type`, `user_id`, `preference_key`, `enabled`, `updated_at`) VALUES
(718, 'PASSENGER', 105, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(719, 'PASSENGER', 105, 'profile_updates', 1, '2026-08-26 16:42:06'),
(720, 'PASSENGER', 105, 'service_announcements', 1, '2026-08-26 16:42:06'),
(721, 'PASSENGER', 105, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(722, 'PASSENGER', 106, 'master_notifications', 1, '2026-08-26 16:42:06'),
(723, 'PASSENGER', 106, 'security_alerts', 1, '2026-08-26 16:42:06'),
(724, 'PASSENGER', 106, 'password_changes', 1, '2026-08-26 16:42:06'),
(725, 'PASSENGER', 106, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(726, 'PASSENGER', 106, 'profile_updates', 1, '2026-08-26 16:42:06'),
(727, 'PASSENGER', 106, 'service_announcements', 1, '2026-08-26 16:42:06'),
(728, 'PASSENGER', 106, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(729, 'PASSENGER', 107, 'master_notifications', 1, '2026-08-26 16:42:06'),
(730, 'PASSENGER', 107, 'security_alerts', 1, '2026-08-26 16:42:06'),
(731, 'PASSENGER', 107, 'password_changes', 1, '2026-08-26 16:42:06'),
(732, 'PASSENGER', 107, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(733, 'PASSENGER', 107, 'profile_updates', 1, '2026-08-26 16:42:06'),
(734, 'PASSENGER', 107, 'service_announcements', 1, '2026-08-26 16:42:06'),
(735, 'PASSENGER', 107, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(736, 'PASSENGER', 108, 'master_notifications', 1, '2026-08-26 16:42:06'),
(737, 'PASSENGER', 108, 'security_alerts', 1, '2026-08-26 16:42:06'),
(738, 'PASSENGER', 108, 'password_changes', 1, '2026-08-26 16:42:06'),
(739, 'PASSENGER', 108, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(740, 'PASSENGER', 108, 'profile_updates', 1, '2026-08-26 16:42:06'),
(741, 'PASSENGER', 108, 'service_announcements', 1, '2026-08-26 16:42:06'),
(742, 'PASSENGER', 108, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(743, 'PASSENGER', 109, 'master_notifications', 1, '2026-08-26 16:42:06'),
(744, 'PASSENGER', 109, 'security_alerts', 1, '2026-08-26 16:42:06'),
(745, 'PASSENGER', 109, 'password_changes', 1, '2026-08-26 16:42:06'),
(746, 'PASSENGER', 109, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(747, 'PASSENGER', 109, 'profile_updates', 1, '2026-08-26 16:42:06'),
(748, 'PASSENGER', 109, 'service_announcements', 1, '2026-08-26 16:42:06'),
(749, 'PASSENGER', 109, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(750, 'PASSENGER', 110, 'master_notifications', 1, '2026-08-26 16:42:06'),
(751, 'PASSENGER', 110, 'security_alerts', 1, '2026-08-26 16:42:06'),
(752, 'PASSENGER', 110, 'password_changes', 1, '2026-08-26 16:42:06'),
(753, 'PASSENGER', 110, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(754, 'PASSENGER', 110, 'profile_updates', 1, '2026-08-26 16:42:06'),
(755, 'PASSENGER', 110, 'service_announcements', 1, '2026-08-26 16:42:06'),
(756, 'PASSENGER', 110, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(757, 'PASSENGER', 9, 'master_notifications', 1, '2026-08-26 16:42:06'),
(758, 'PASSENGER', 9, 'security_alerts', 1, '2026-08-26 16:42:06'),
(759, 'PASSENGER', 9, 'password_changes', 1, '2026-08-26 16:42:06'),
(760, 'PASSENGER', 9, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(761, 'PASSENGER', 9, 'profile_updates', 1, '2026-08-26 16:42:06'),
(762, 'PASSENGER', 9, 'service_announcements', 1, '2026-08-26 16:42:06'),
(763, 'PASSENGER', 9, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(764, 'PASSENGER', 10, 'master_notifications', 1, '2026-08-26 16:42:06'),
(765, 'PASSENGER', 10, 'security_alerts', 1, '2026-08-26 16:42:06'),
(766, 'PASSENGER', 10, 'password_changes', 1, '2026-08-26 16:42:06'),
(767, 'PASSENGER', 10, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(768, 'PASSENGER', 10, 'profile_updates', 1, '2026-08-26 16:42:06'),
(769, 'PASSENGER', 10, 'service_announcements', 1, '2026-08-26 16:42:06'),
(770, 'PASSENGER', 10, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(771, 'PASSENGER', 111, 'master_notifications', 1, '2026-08-26 16:42:06'),
(772, 'PASSENGER', 111, 'security_alerts', 1, '2026-08-26 16:42:06'),
(773, 'PASSENGER', 111, 'password_changes', 1, '2026-08-26 16:42:06'),
(774, 'PASSENGER', 111, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(775, 'PASSENGER', 111, 'profile_updates', 1, '2026-08-26 16:42:06'),
(776, 'PASSENGER', 111, 'service_announcements', 1, '2026-08-26 16:42:06'),
(777, 'PASSENGER', 111, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(778, 'PASSENGER', 112, 'master_notifications', 1, '2026-08-26 16:42:06'),
(779, 'PASSENGER', 112, 'security_alerts', 1, '2026-08-26 16:42:06'),
(780, 'PASSENGER', 112, 'password_changes', 1, '2026-08-26 16:42:06'),
(781, 'PASSENGER', 112, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(782, 'PASSENGER', 112, 'profile_updates', 1, '2026-08-26 16:42:06'),
(783, 'PASSENGER', 112, 'service_announcements', 1, '2026-08-26 16:42:06'),
(784, 'PASSENGER', 112, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(785, 'PASSENGER', 113, 'master_notifications', 1, '2026-08-26 16:42:06'),
(786, 'PASSENGER', 113, 'security_alerts', 1, '2026-08-26 16:42:06'),
(787, 'PASSENGER', 113, 'password_changes', 1, '2026-08-26 16:42:06'),
(788, 'PASSENGER', 113, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(789, 'PASSENGER', 113, 'profile_updates', 1, '2026-08-26 16:42:06'),
(790, 'PASSENGER', 113, 'service_announcements', 1, '2026-08-26 16:42:06'),
(791, 'PASSENGER', 113, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(792, 'PASSENGER', 114, 'master_notifications', 1, '2026-08-26 16:42:06'),
(793, 'PASSENGER', 114, 'security_alerts', 1, '2026-08-26 16:42:06'),
(794, 'PASSENGER', 114, 'password_changes', 1, '2026-08-26 16:42:06'),
(795, 'PASSENGER', 114, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(796, 'PASSENGER', 114, 'profile_updates', 1, '2026-08-26 16:42:06'),
(797, 'PASSENGER', 114, 'service_announcements', 1, '2026-08-26 16:42:06'),
(798, 'PASSENGER', 114, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(799, 'PASSENGER', 115, 'master_notifications', 1, '2026-08-26 16:42:06'),
(800, 'PASSENGER', 115, 'security_alerts', 1, '2026-08-26 16:42:06'),
(801, 'PASSENGER', 115, 'password_changes', 1, '2026-08-26 16:42:06'),
(802, 'PASSENGER', 115, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(803, 'PASSENGER', 115, 'profile_updates', 1, '2026-08-26 16:42:06'),
(804, 'PASSENGER', 115, 'service_announcements', 1, '2026-08-26 16:42:06'),
(805, 'PASSENGER', 115, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(806, 'PASSENGER', 116, 'master_notifications', 1, '2026-08-26 16:42:06'),
(807, 'PASSENGER', 116, 'security_alerts', 1, '2026-08-26 16:42:06'),
(808, 'PASSENGER', 116, 'password_changes', 1, '2026-08-26 16:42:06'),
(809, 'PASSENGER', 116, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(810, 'PASSENGER', 116, 'profile_updates', 1, '2026-08-26 16:42:06'),
(811, 'PASSENGER', 116, 'service_announcements', 1, '2026-08-26 16:42:06'),
(812, 'PASSENGER', 116, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(813, 'PASSENGER', 117, 'master_notifications', 1, '2026-08-26 16:42:06'),
(814, 'PASSENGER', 117, 'security_alerts', 1, '2026-08-26 16:42:06'),
(815, 'PASSENGER', 117, 'password_changes', 1, '2026-08-26 16:42:06'),
(816, 'PASSENGER', 117, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(817, 'PASSENGER', 117, 'profile_updates', 1, '2026-08-26 16:42:06'),
(818, 'PASSENGER', 117, 'service_announcements', 1, '2026-08-26 16:42:06'),
(819, 'PASSENGER', 117, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(820, 'PASSENGER', 118, 'master_notifications', 1, '2026-08-26 16:42:06'),
(821, 'PASSENGER', 118, 'security_alerts', 1, '2026-08-26 16:42:06'),
(822, 'PASSENGER', 118, 'password_changes', 1, '2026-08-26 16:42:06'),
(823, 'PASSENGER', 118, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(824, 'PASSENGER', 118, 'profile_updates', 1, '2026-08-26 16:42:06'),
(825, 'PASSENGER', 118, 'service_announcements', 1, '2026-08-26 16:42:06'),
(826, 'PASSENGER', 118, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(827, 'PASSENGER', 119, 'master_notifications', 1, '2026-08-26 16:42:06'),
(828, 'PASSENGER', 119, 'security_alerts', 1, '2026-08-26 16:42:06'),
(829, 'PASSENGER', 119, 'password_changes', 1, '2026-08-26 16:42:06'),
(830, 'PASSENGER', 119, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(831, 'PASSENGER', 119, 'profile_updates', 1, '2026-08-26 16:42:06'),
(832, 'PASSENGER', 119, 'service_announcements', 1, '2026-08-26 16:42:06'),
(833, 'PASSENGER', 119, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(834, 'PASSENGER', 120, 'master_notifications', 1, '2026-08-26 16:42:06'),
(835, 'PASSENGER', 120, 'security_alerts', 1, '2026-08-26 16:42:06'),
(836, 'PASSENGER', 120, 'password_changes', 1, '2026-08-26 16:42:06'),
(837, 'PASSENGER', 120, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(838, 'PASSENGER', 120, 'profile_updates', 1, '2026-08-26 16:42:06'),
(839, 'PASSENGER', 120, 'service_announcements', 1, '2026-08-26 16:42:06'),
(840, 'PASSENGER', 120, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(841, 'PASSENGER', 121, 'master_notifications', 1, '2026-08-26 16:42:06'),
(842, 'PASSENGER', 121, 'security_alerts', 1, '2026-08-26 16:42:06'),
(843, 'PASSENGER', 121, 'password_changes', 1, '2026-08-26 16:42:06'),
(844, 'PASSENGER', 121, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(845, 'PASSENGER', 121, 'profile_updates', 1, '2026-08-26 16:42:06'),
(846, 'PASSENGER', 121, 'service_announcements', 1, '2026-08-26 16:42:06'),
(847, 'PASSENGER', 121, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(848, 'PASSENGER', 122, 'master_notifications', 1, '2026-08-26 16:42:06'),
(849, 'PASSENGER', 122, 'security_alerts', 1, '2026-08-26 16:42:06'),
(850, 'PASSENGER', 122, 'password_changes', 1, '2026-08-26 16:42:06'),
(851, 'PASSENGER', 122, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(852, 'PASSENGER', 122, 'profile_updates', 1, '2026-08-26 16:42:06'),
(853, 'PASSENGER', 122, 'service_announcements', 1, '2026-08-26 16:42:06'),
(854, 'PASSENGER', 122, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(855, 'PASSENGER', 123, 'master_notifications', 1, '2026-08-26 16:42:06'),
(856, 'PASSENGER', 123, 'security_alerts', 1, '2026-08-26 16:42:06'),
(857, 'PASSENGER', 123, 'password_changes', 1, '2026-08-26 16:42:06'),
(858, 'PASSENGER', 123, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(859, 'PASSENGER', 123, 'profile_updates', 1, '2026-08-26 16:42:06'),
(860, 'PASSENGER', 123, 'service_announcements', 1, '2026-08-26 16:42:06'),
(861, 'PASSENGER', 123, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(862, 'PASSENGER', 124, 'master_notifications', 1, '2026-08-26 16:42:06'),
(863, 'PASSENGER', 124, 'security_alerts', 1, '2026-08-26 16:42:06'),
(864, 'PASSENGER', 124, 'password_changes', 1, '2026-08-26 16:42:06'),
(865, 'PASSENGER', 124, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(866, 'PASSENGER', 124, 'profile_updates', 1, '2026-08-26 16:42:06'),
(867, 'PASSENGER', 124, 'service_announcements', 1, '2026-08-26 16:42:06'),
(868, 'PASSENGER', 124, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(869, 'PASSENGER', 125, 'master_notifications', 1, '2026-08-26 16:42:06'),
(870, 'PASSENGER', 125, 'security_alerts', 1, '2026-08-26 16:42:06'),
(871, 'PASSENGER', 125, 'password_changes', 1, '2026-08-26 16:42:06'),
(872, 'PASSENGER', 125, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(873, 'PASSENGER', 125, 'profile_updates', 1, '2026-08-26 16:42:06'),
(874, 'PASSENGER', 125, 'service_announcements', 1, '2026-08-26 16:42:06'),
(875, 'PASSENGER', 125, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(876, 'PASSENGER', 126, 'master_notifications', 1, '2026-08-26 16:42:06'),
(877, 'PASSENGER', 126, 'security_alerts', 1, '2026-08-26 16:42:06'),
(878, 'PASSENGER', 126, 'password_changes', 1, '2026-08-26 16:42:06'),
(879, 'PASSENGER', 126, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(880, 'PASSENGER', 126, 'profile_updates', 1, '2026-08-26 16:42:06'),
(881, 'PASSENGER', 126, 'service_announcements', 1, '2026-08-26 16:42:06'),
(882, 'PASSENGER', 126, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(883, 'PASSENGER', 127, 'master_notifications', 1, '2026-08-26 16:42:06'),
(884, 'PASSENGER', 127, 'security_alerts', 1, '2026-08-26 16:42:06'),
(885, 'PASSENGER', 127, 'password_changes', 1, '2026-08-26 16:42:06'),
(886, 'PASSENGER', 127, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(887, 'PASSENGER', 127, 'profile_updates', 1, '2026-08-26 16:42:06'),
(888, 'PASSENGER', 127, 'service_announcements', 1, '2026-08-26 16:42:06'),
(889, 'PASSENGER', 127, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(890, 'PASSENGER', 128, 'master_notifications', 1, '2026-08-26 16:42:06'),
(891, 'PASSENGER', 128, 'security_alerts', 1, '2026-08-26 16:42:06'),
(892, 'PASSENGER', 128, 'password_changes', 1, '2026-08-26 16:42:06'),
(893, 'PASSENGER', 128, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(894, 'PASSENGER', 128, 'profile_updates', 1, '2026-08-26 16:42:06'),
(895, 'PASSENGER', 128, 'service_announcements', 1, '2026-08-26 16:42:06'),
(896, 'PASSENGER', 128, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(897, 'PASSENGER', 129, 'master_notifications', 1, '2026-08-26 16:42:06'),
(898, 'PASSENGER', 129, 'security_alerts', 1, '2026-08-26 16:42:06'),
(899, 'PASSENGER', 129, 'password_changes', 1, '2026-08-26 16:42:06'),
(900, 'PASSENGER', 129, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(901, 'PASSENGER', 129, 'profile_updates', 1, '2026-08-26 16:42:06'),
(902, 'PASSENGER', 129, 'service_announcements', 1, '2026-08-26 16:42:06'),
(903, 'PASSENGER', 129, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(904, 'PASSENGER', 130, 'master_notifications', 1, '2026-08-26 16:42:06'),
(905, 'PASSENGER', 130, 'security_alerts', 1, '2026-08-26 16:42:06'),
(906, 'PASSENGER', 130, 'password_changes', 1, '2026-08-26 16:42:06'),
(907, 'PASSENGER', 130, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(908, 'PASSENGER', 130, 'profile_updates', 1, '2026-08-26 16:42:06'),
(909, 'PASSENGER', 130, 'service_announcements', 1, '2026-08-26 16:42:06'),
(910, 'PASSENGER', 130, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(911, 'PASSENGER', 131, 'master_notifications', 1, '2026-08-26 16:42:06'),
(912, 'PASSENGER', 131, 'security_alerts', 1, '2026-08-26 16:42:06'),
(913, 'PASSENGER', 131, 'password_changes', 1, '2026-08-26 16:42:06'),
(914, 'PASSENGER', 131, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(915, 'PASSENGER', 131, 'profile_updates', 1, '2026-08-26 16:42:06'),
(916, 'PASSENGER', 131, 'service_announcements', 1, '2026-08-26 16:42:06'),
(917, 'PASSENGER', 131, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(918, 'PASSENGER', 132, 'master_notifications', 1, '2026-08-26 16:42:06'),
(919, 'PASSENGER', 132, 'security_alerts', 1, '2026-08-26 16:42:06'),
(920, 'PASSENGER', 132, 'password_changes', 1, '2026-08-26 16:42:06'),
(921, 'PASSENGER', 132, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(922, 'PASSENGER', 132, 'profile_updates', 1, '2026-08-26 16:42:06'),
(923, 'PASSENGER', 132, 'service_announcements', 1, '2026-08-26 16:42:06'),
(924, 'PASSENGER', 132, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(925, 'PASSENGER', 133, 'master_notifications', 1, '2026-08-26 16:42:06'),
(926, 'PASSENGER', 133, 'security_alerts', 1, '2026-08-26 16:42:06'),
(927, 'PASSENGER', 133, 'password_changes', 1, '2026-08-26 16:42:06'),
(928, 'PASSENGER', 133, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(929, 'PASSENGER', 133, 'profile_updates', 1, '2026-08-26 16:42:06'),
(930, 'PASSENGER', 133, 'service_announcements', 1, '2026-08-26 16:42:06'),
(931, 'PASSENGER', 133, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(932, 'PASSENGER', 134, 'master_notifications', 1, '2026-08-26 16:42:06'),
(933, 'PASSENGER', 134, 'security_alerts', 1, '2026-08-26 16:42:06'),
(934, 'PASSENGER', 134, 'password_changes', 1, '2026-08-26 16:42:06'),
(935, 'PASSENGER', 134, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(936, 'PASSENGER', 134, 'profile_updates', 1, '2026-08-26 16:42:06'),
(937, 'PASSENGER', 134, 'service_announcements', 1, '2026-08-26 16:42:06'),
(938, 'PASSENGER', 134, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(939, 'PASSENGER', 135, 'master_notifications', 1, '2026-08-26 16:42:06'),
(940, 'PASSENGER', 135, 'security_alerts', 1, '2026-08-26 16:42:06'),
(941, 'PASSENGER', 135, 'password_changes', 1, '2026-08-26 16:42:06'),
(942, 'PASSENGER', 135, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(943, 'PASSENGER', 135, 'profile_updates', 1, '2026-08-26 16:42:06'),
(944, 'PASSENGER', 135, 'service_announcements', 1, '2026-08-26 16:42:06'),
(945, 'PASSENGER', 135, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(946, 'PASSENGER', 136, 'master_notifications', 1, '2026-08-26 16:42:06'),
(947, 'PASSENGER', 136, 'security_alerts', 1, '2026-08-26 16:42:06'),
(948, 'PASSENGER', 136, 'password_changes', 1, '2026-08-26 16:42:06'),
(949, 'PASSENGER', 136, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(950, 'PASSENGER', 136, 'profile_updates', 1, '2026-08-26 16:42:06'),
(951, 'PASSENGER', 136, 'service_announcements', 1, '2026-08-26 16:42:06'),
(952, 'PASSENGER', 136, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(953, 'PASSENGER', 137, 'master_notifications', 1, '2026-08-26 16:42:06'),
(954, 'PASSENGER', 137, 'security_alerts', 1, '2026-08-26 16:42:06'),
(955, 'PASSENGER', 137, 'password_changes', 1, '2026-08-26 16:42:06'),
(956, 'PASSENGER', 137, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(957, 'PASSENGER', 137, 'profile_updates', 1, '2026-08-26 16:42:06'),
(958, 'PASSENGER', 137, 'service_announcements', 1, '2026-08-26 16:42:06'),
(959, 'PASSENGER', 137, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(960, 'PASSENGER', 138, 'master_notifications', 1, '2026-08-26 16:42:06'),
(961, 'PASSENGER', 138, 'security_alerts', 1, '2026-08-26 16:42:06'),
(962, 'PASSENGER', 138, 'password_changes', 1, '2026-08-26 16:42:06'),
(963, 'PASSENGER', 138, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(964, 'PASSENGER', 138, 'profile_updates', 1, '2026-08-26 16:42:06'),
(965, 'PASSENGER', 138, 'service_announcements', 1, '2026-08-26 16:42:06'),
(966, 'PASSENGER', 138, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(967, 'PASSENGER', 139, 'master_notifications', 1, '2026-08-26 16:42:06'),
(968, 'PASSENGER', 139, 'security_alerts', 1, '2026-08-26 16:42:06'),
(969, 'PASSENGER', 139, 'password_changes', 1, '2026-08-26 16:42:06'),
(970, 'PASSENGER', 139, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(971, 'PASSENGER', 139, 'profile_updates', 1, '2026-08-26 16:42:06'),
(972, 'PASSENGER', 139, 'service_announcements', 1, '2026-08-26 16:42:06'),
(973, 'PASSENGER', 139, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(974, 'PASSENGER', 140, 'master_notifications', 1, '2026-08-26 16:42:06'),
(975, 'PASSENGER', 140, 'security_alerts', 1, '2026-08-26 16:42:06'),
(976, 'PASSENGER', 140, 'password_changes', 1, '2026-08-26 16:42:06'),
(977, 'PASSENGER', 140, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(978, 'PASSENGER', 140, 'profile_updates', 1, '2026-08-26 16:42:06'),
(979, 'PASSENGER', 140, 'service_announcements', 1, '2026-08-26 16:42:06'),
(980, 'PASSENGER', 140, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(981, 'PASSENGER', 141, 'master_notifications', 1, '2026-08-26 16:42:06'),
(982, 'PASSENGER', 141, 'security_alerts', 1, '2026-08-26 16:42:06'),
(983, 'PASSENGER', 141, 'password_changes', 1, '2026-08-26 16:42:06'),
(984, 'PASSENGER', 141, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(985, 'PASSENGER', 141, 'profile_updates', 1, '2026-08-26 16:42:06'),
(986, 'PASSENGER', 141, 'service_announcements', 1, '2026-08-26 16:42:06'),
(987, 'PASSENGER', 141, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(988, 'PASSENGER', 142, 'master_notifications', 1, '2026-08-26 16:42:06'),
(989, 'PASSENGER', 142, 'security_alerts', 1, '2026-08-26 16:42:06'),
(990, 'PASSENGER', 142, 'password_changes', 1, '2026-08-26 16:42:06'),
(991, 'PASSENGER', 142, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(992, 'PASSENGER', 142, 'profile_updates', 1, '2026-08-26 16:42:06'),
(993, 'PASSENGER', 142, 'service_announcements', 1, '2026-08-26 16:42:06'),
(994, 'PASSENGER', 142, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(995, 'PASSENGER', 143, 'master_notifications', 1, '2026-08-26 16:42:06'),
(996, 'PASSENGER', 143, 'security_alerts', 1, '2026-08-26 16:42:06'),
(997, 'PASSENGER', 143, 'password_changes', 1, '2026-08-26 16:42:06'),
(998, 'PASSENGER', 143, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(999, 'PASSENGER', 143, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1000, 'PASSENGER', 143, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1001, 'PASSENGER', 143, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1002, 'PASSENGER', 144, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1003, 'PASSENGER', 144, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1004, 'PASSENGER', 144, 'password_changes', 1, '2026-08-26 16:42:06'),
(1005, 'PASSENGER', 144, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1006, 'PASSENGER', 144, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1007, 'PASSENGER', 144, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1008, 'PASSENGER', 144, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1009, 'PASSENGER', 145, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1010, 'PASSENGER', 145, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1011, 'PASSENGER', 145, 'password_changes', 1, '2026-08-26 16:42:06'),
(1012, 'PASSENGER', 145, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1013, 'PASSENGER', 145, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1014, 'PASSENGER', 145, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1015, 'PASSENGER', 145, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1016, 'PASSENGER', 146, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1017, 'PASSENGER', 146, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1018, 'PASSENGER', 146, 'password_changes', 1, '2026-08-26 16:42:06'),
(1019, 'PASSENGER', 146, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1020, 'PASSENGER', 146, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1021, 'PASSENGER', 146, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1022, 'PASSENGER', 146, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1023, 'PASSENGER', 147, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1024, 'PASSENGER', 147, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1025, 'PASSENGER', 147, 'password_changes', 1, '2026-08-26 16:42:06'),
(1026, 'PASSENGER', 147, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1027, 'PASSENGER', 147, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1028, 'PASSENGER', 147, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1029, 'PASSENGER', 147, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1030, 'PASSENGER', 148, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1031, 'PASSENGER', 148, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1032, 'PASSENGER', 148, 'password_changes', 1, '2026-08-26 16:42:06'),
(1033, 'PASSENGER', 148, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1034, 'PASSENGER', 148, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1035, 'PASSENGER', 148, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1036, 'PASSENGER', 148, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1037, 'PASSENGER', 149, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1038, 'PASSENGER', 149, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1039, 'PASSENGER', 149, 'password_changes', 1, '2026-08-26 16:42:06'),
(1040, 'PASSENGER', 149, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1041, 'PASSENGER', 149, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1042, 'PASSENGER', 149, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1043, 'PASSENGER', 149, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1044, 'PASSENGER', 150, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1045, 'PASSENGER', 150, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1046, 'PASSENGER', 150, 'password_changes', 1, '2026-08-26 16:42:06'),
(1047, 'PASSENGER', 150, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1048, 'PASSENGER', 150, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1049, 'PASSENGER', 150, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1050, 'PASSENGER', 150, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1051, 'PASSENGER', 151, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1052, 'PASSENGER', 151, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1053, 'PASSENGER', 151, 'password_changes', 1, '2026-08-26 16:42:06'),
(1054, 'PASSENGER', 151, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1055, 'PASSENGER', 151, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1056, 'PASSENGER', 151, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1057, 'PASSENGER', 151, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1058, 'PASSENGER', 152, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1059, 'PASSENGER', 152, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1060, 'PASSENGER', 152, 'password_changes', 1, '2026-08-26 16:42:06'),
(1061, 'PASSENGER', 152, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1062, 'PASSENGER', 152, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1063, 'PASSENGER', 152, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1064, 'PASSENGER', 152, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1065, 'PASSENGER', 153, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1066, 'PASSENGER', 153, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1067, 'PASSENGER', 153, 'password_changes', 1, '2026-08-26 16:42:06'),
(1068, 'PASSENGER', 153, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1069, 'PASSENGER', 153, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1070, 'PASSENGER', 153, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1071, 'PASSENGER', 153, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1072, 'PASSENGER', 154, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1073, 'PASSENGER', 154, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1074, 'PASSENGER', 154, 'password_changes', 1, '2026-08-26 16:42:06'),
(1075, 'PASSENGER', 154, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1076, 'PASSENGER', 154, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1077, 'PASSENGER', 154, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1078, 'PASSENGER', 154, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1079, 'PASSENGER', 155, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1080, 'PASSENGER', 155, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1081, 'PASSENGER', 155, 'password_changes', 1, '2026-08-26 16:42:06'),
(1082, 'PASSENGER', 155, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1083, 'PASSENGER', 155, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1084, 'PASSENGER', 155, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1085, 'PASSENGER', 155, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1086, 'PASSENGER', 156, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1087, 'PASSENGER', 156, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1088, 'PASSENGER', 156, 'password_changes', 1, '2026-08-26 16:42:06'),
(1089, 'PASSENGER', 156, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1090, 'PASSENGER', 156, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1091, 'PASSENGER', 156, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1092, 'PASSENGER', 156, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1093, 'PASSENGER', 157, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1094, 'PASSENGER', 157, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1095, 'PASSENGER', 157, 'password_changes', 1, '2026-08-26 16:42:06'),
(1096, 'PASSENGER', 157, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1097, 'PASSENGER', 157, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1098, 'PASSENGER', 157, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1099, 'PASSENGER', 157, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1100, 'PASSENGER', 158, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1101, 'PASSENGER', 158, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1102, 'PASSENGER', 158, 'password_changes', 1, '2026-08-26 16:42:06'),
(1103, 'PASSENGER', 158, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1104, 'PASSENGER', 158, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1105, 'PASSENGER', 158, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1106, 'PASSENGER', 158, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1107, 'PASSENGER', 159, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1108, 'PASSENGER', 159, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1109, 'PASSENGER', 159, 'password_changes', 1, '2026-08-26 16:42:06'),
(1110, 'PASSENGER', 159, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1111, 'PASSENGER', 159, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1112, 'PASSENGER', 159, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1113, 'PASSENGER', 159, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1114, 'PASSENGER', 160, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1115, 'PASSENGER', 160, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1116, 'PASSENGER', 160, 'password_changes', 1, '2026-08-26 16:42:06'),
(1117, 'PASSENGER', 160, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1118, 'PASSENGER', 160, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1119, 'PASSENGER', 160, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1120, 'PASSENGER', 160, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1121, 'UNIVERSITY_ADMIN', 1, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1122, 'UNIVERSITY_ADMIN', 1, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(1123, 'UNIVERSITY_ADMIN', 1, 'email_notifications', 1, '2026-08-26 16:42:06'),
(1124, 'UNIVERSITY_ADMIN', 1, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1125, 'UNIVERSITY_ADMIN', 1, 'password_changes', 1, '2026-08-26 16:42:06'),
(1126, 'UNIVERSITY_ADMIN', 1, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1127, 'UNIVERSITY_ADMIN', 1, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1128, 'UNIVERSITY_ADMIN', 1, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1129, 'UNIVERSITY_ADMIN', 1, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1130, 'UNIVERSITY_ADMIN', 2, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1131, 'UNIVERSITY_ADMIN', 2, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(1132, 'UNIVERSITY_ADMIN', 2, 'email_notifications', 1, '2026-08-26 16:42:06'),
(1133, 'UNIVERSITY_ADMIN', 2, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1134, 'UNIVERSITY_ADMIN', 2, 'password_changes', 1, '2026-08-26 16:42:06'),
(1135, 'UNIVERSITY_ADMIN', 2, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1136, 'UNIVERSITY_ADMIN', 2, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1137, 'UNIVERSITY_ADMIN', 2, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1138, 'UNIVERSITY_ADMIN', 2, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1139, 'UNIVERSITY_ADMIN', 3, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1140, 'UNIVERSITY_ADMIN', 3, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(1141, 'UNIVERSITY_ADMIN', 3, 'email_notifications', 1, '2026-08-26 16:42:06'),
(1142, 'UNIVERSITY_ADMIN', 3, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1143, 'UNIVERSITY_ADMIN', 3, 'password_changes', 1, '2026-08-26 16:42:06'),
(1144, 'UNIVERSITY_ADMIN', 3, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1145, 'UNIVERSITY_ADMIN', 3, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1146, 'UNIVERSITY_ADMIN', 3, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1147, 'UNIVERSITY_ADMIN', 3, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(1148, 'SYSTEM_ADMIN', 1, 'master_notifications', 1, '2026-08-26 16:42:06'),
(1149, 'SYSTEM_ADMIN', 1, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(1150, 'SYSTEM_ADMIN', 1, 'email_notifications', 1, '2026-08-26 16:42:06'),
(1151, 'SYSTEM_ADMIN', 1, 'security_alerts', 1, '2026-08-26 16:42:06'),
(1152, 'SYSTEM_ADMIN', 1, 'password_changes', 1, '2026-08-26 16:42:06'),
(1153, 'SYSTEM_ADMIN', 1, 'suspicious_logins', 1, '2026-08-26 16:42:06'),
(1154, 'SYSTEM_ADMIN', 1, 'profile_updates', 1, '2026-08-26 16:42:06'),
(1155, 'SYSTEM_ADMIN', 1, 'service_announcements', 1, '2026-08-26 16:42:06'),
(1156, 'SYSTEM_ADMIN', 1, 'platform_maintenance', 1, '2026-08-26 16:42:06'),
(2048, 'PASSENGER', 1, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2049, 'PASSENGER', 2, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2050, 'PASSENGER', 3, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2051, 'PASSENGER', 4, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2052, 'PASSENGER', 5, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2053, 'PASSENGER', 6, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2054, 'PASSENGER', 7, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2055, 'PASSENGER', 8, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2056, 'PASSENGER', 9, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2057, 'PASSENGER', 10, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2058, 'PASSENGER', 11, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2059, 'PASSENGER', 12, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2060, 'PASSENGER', 13, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2061, 'PASSENGER', 14, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2062, 'PASSENGER', 15, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2063, 'PASSENGER', 16, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2064, 'PASSENGER', 17, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2065, 'PASSENGER', 18, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2066, 'PASSENGER', 19, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2067, 'PASSENGER', 20, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2068, 'PASSENGER', 21, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2069, 'PASSENGER', 22, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2070, 'PASSENGER', 23, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2071, 'PASSENGER', 24, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2072, 'PASSENGER', 25, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2073, 'PASSENGER', 26, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2074, 'PASSENGER', 27, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2075, 'PASSENGER', 28, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2076, 'PASSENGER', 29, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2077, 'PASSENGER', 30, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2078, 'PASSENGER', 31, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2079, 'PASSENGER', 32, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2080, 'PASSENGER', 33, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2081, 'PASSENGER', 34, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2082, 'PASSENGER', 35, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2083, 'PASSENGER', 36, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2084, 'PASSENGER', 37, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2085, 'PASSENGER', 38, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2086, 'PASSENGER', 39, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2087, 'PASSENGER', 40, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2088, 'PASSENGER', 41, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2089, 'PASSENGER', 42, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2090, 'PASSENGER', 43, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2091, 'PASSENGER', 44, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2092, 'PASSENGER', 45, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2093, 'PASSENGER', 46, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2094, 'PASSENGER', 47, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2095, 'PASSENGER', 48, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2096, 'PASSENGER', 49, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2097, 'PASSENGER', 50, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2098, 'PASSENGER', 51, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2099, 'PASSENGER', 52, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2100, 'PASSENGER', 53, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2101, 'PASSENGER', 54, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2102, 'PASSENGER', 55, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2103, 'PASSENGER', 56, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2104, 'PASSENGER', 57, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2105, 'PASSENGER', 58, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2106, 'PASSENGER', 59, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2107, 'PASSENGER', 60, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2108, 'PASSENGER', 61, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2109, 'PASSENGER', 62, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2110, 'PASSENGER', 63, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2111, 'PASSENGER', 64, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2112, 'PASSENGER', 65, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2113, 'PASSENGER', 66, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2114, 'PASSENGER', 67, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2115, 'PASSENGER', 68, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2116, 'PASSENGER', 69, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2117, 'PASSENGER', 70, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2118, 'PASSENGER', 71, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2119, 'PASSENGER', 72, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2120, 'PASSENGER', 73, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2121, 'PASSENGER', 74, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2122, 'PASSENGER', 75, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2123, 'PASSENGER', 76, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2124, 'PASSENGER', 77, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2125, 'PASSENGER', 78, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2126, 'PASSENGER', 79, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2127, 'PASSENGER', 80, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2128, 'PASSENGER', 81, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2129, 'PASSENGER', 82, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2130, 'PASSENGER', 83, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2131, 'PASSENGER', 84, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2132, 'PASSENGER', 85, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2133, 'PASSENGER', 86, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2134, 'PASSENGER', 87, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2135, 'PASSENGER', 88, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2136, 'PASSENGER', 89, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2137, 'PASSENGER', 90, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2138, 'PASSENGER', 91, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2139, 'PASSENGER', 92, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2140, 'PASSENGER', 93, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2141, 'PASSENGER', 94, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2142, 'PASSENGER', 95, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2143, 'PASSENGER', 96, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2144, 'PASSENGER', 97, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2145, 'PASSENGER', 98, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2146, 'PASSENGER', 99, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2147, 'PASSENGER', 100, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2148, 'PASSENGER', 101, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2149, 'PASSENGER', 102, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2150, 'PASSENGER', 103, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2151, 'PASSENGER', 104, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2152, 'PASSENGER', 105, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2153, 'PASSENGER', 106, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2154, 'PASSENGER', 107, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2155, 'PASSENGER', 108, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2156, 'PASSENGER', 109, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2157, 'PASSENGER', 110, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2158, 'PASSENGER', 111, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2159, 'PASSENGER', 112, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2160, 'PASSENGER', 113, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2161, 'PASSENGER', 114, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2162, 'PASSENGER', 115, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2163, 'PASSENGER', 116, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2164, 'PASSENGER', 117, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2165, 'PASSENGER', 118, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2166, 'PASSENGER', 119, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2167, 'PASSENGER', 120, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2168, 'PASSENGER', 121, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2169, 'PASSENGER', 122, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2170, 'PASSENGER', 123, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2171, 'PASSENGER', 124, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2172, 'PASSENGER', 125, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2173, 'PASSENGER', 126, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2174, 'PASSENGER', 127, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2175, 'PASSENGER', 128, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2176, 'PASSENGER', 129, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2177, 'PASSENGER', 130, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2178, 'PASSENGER', 131, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2179, 'PASSENGER', 132, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2180, 'PASSENGER', 133, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2181, 'PASSENGER', 134, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2182, 'PASSENGER', 135, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2183, 'PASSENGER', 136, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2184, 'PASSENGER', 137, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2185, 'PASSENGER', 138, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2186, 'PASSENGER', 139, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2187, 'PASSENGER', 140, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2188, 'PASSENGER', 141, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2189, 'PASSENGER', 142, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2190, 'PASSENGER', 143, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2191, 'PASSENGER', 144, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2192, 'PASSENGER', 145, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2193, 'PASSENGER', 146, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2194, 'PASSENGER', 147, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2195, 'PASSENGER', 148, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2196, 'PASSENGER', 149, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2197, 'PASSENGER', 150, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2198, 'PASSENGER', 151, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2199, 'PASSENGER', 152, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2200, 'PASSENGER', 153, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2201, 'PASSENGER', 154, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2202, 'PASSENGER', 155, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2203, 'PASSENGER', 156, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2204, 'PASSENGER', 157, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2205, 'PASSENGER', 158, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2206, 'PASSENGER', 159, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2207, 'PASSENGER', 160, 'dashboard_notifications', 1, '2026-08-26 16:42:06'),
(2303, 'PASSENGER', 1, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2304, 'PASSENGER', 2, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2305, 'PASSENGER', 3, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2306, 'PASSENGER', 4, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2307, 'PASSENGER', 5, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2308, 'PASSENGER', 6, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2309, 'PASSENGER', 7, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2310, 'PASSENGER', 8, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2311, 'PASSENGER', 9, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2312, 'PASSENGER', 10, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2313, 'PASSENGER', 11, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2314, 'PASSENGER', 12, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2315, 'PASSENGER', 13, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2316, 'PASSENGER', 14, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2317, 'PASSENGER', 15, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2318, 'PASSENGER', 16, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2319, 'PASSENGER', 17, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2320, 'PASSENGER', 18, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2321, 'PASSENGER', 19, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2322, 'PASSENGER', 20, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2323, 'PASSENGER', 21, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2324, 'PASSENGER', 22, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2325, 'PASSENGER', 23, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2326, 'PASSENGER', 24, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2327, 'PASSENGER', 25, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2328, 'PASSENGER', 26, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2329, 'PASSENGER', 27, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2330, 'PASSENGER', 28, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2331, 'PASSENGER', 29, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2332, 'PASSENGER', 30, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2333, 'PASSENGER', 31, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2334, 'PASSENGER', 32, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2335, 'PASSENGER', 33, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2336, 'PASSENGER', 34, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2337, 'PASSENGER', 35, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2338, 'PASSENGER', 36, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2339, 'PASSENGER', 37, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2340, 'PASSENGER', 38, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2341, 'PASSENGER', 39, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2342, 'PASSENGER', 40, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2343, 'PASSENGER', 41, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2344, 'PASSENGER', 42, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2345, 'PASSENGER', 43, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2346, 'PASSENGER', 44, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2347, 'PASSENGER', 45, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2348, 'PASSENGER', 46, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2349, 'PASSENGER', 47, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2350, 'PASSENGER', 48, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2351, 'PASSENGER', 49, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2352, 'PASSENGER', 50, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2353, 'PASSENGER', 51, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2354, 'PASSENGER', 52, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2355, 'PASSENGER', 53, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2356, 'PASSENGER', 54, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2357, 'PASSENGER', 55, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2358, 'PASSENGER', 56, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2359, 'PASSENGER', 57, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2360, 'PASSENGER', 58, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2361, 'PASSENGER', 59, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2362, 'PASSENGER', 60, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2363, 'PASSENGER', 61, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2364, 'PASSENGER', 62, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2365, 'PASSENGER', 63, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2366, 'PASSENGER', 64, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2367, 'PASSENGER', 65, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2368, 'PASSENGER', 66, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2369, 'PASSENGER', 67, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2370, 'PASSENGER', 68, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2371, 'PASSENGER', 69, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2372, 'PASSENGER', 70, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2373, 'PASSENGER', 71, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2374, 'PASSENGER', 72, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2375, 'PASSENGER', 73, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2376, 'PASSENGER', 74, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2377, 'PASSENGER', 75, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2378, 'PASSENGER', 76, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2379, 'PASSENGER', 77, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2380, 'PASSENGER', 78, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2381, 'PASSENGER', 79, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2382, 'PASSENGER', 80, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2383, 'PASSENGER', 81, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2384, 'PASSENGER', 82, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2385, 'PASSENGER', 83, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2386, 'PASSENGER', 84, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2387, 'PASSENGER', 85, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2388, 'PASSENGER', 86, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2389, 'PASSENGER', 87, 'email_notifications', 1, '2026-08-26 16:42:06');
INSERT INTO `user_notification_preferences` (`preference_id`, `user_type`, `user_id`, `preference_key`, `enabled`, `updated_at`) VALUES
(2390, 'PASSENGER', 88, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2391, 'PASSENGER', 89, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2392, 'PASSENGER', 90, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2393, 'PASSENGER', 91, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2394, 'PASSENGER', 92, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2395, 'PASSENGER', 93, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2396, 'PASSENGER', 94, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2397, 'PASSENGER', 95, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2398, 'PASSENGER', 96, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2399, 'PASSENGER', 97, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2400, 'PASSENGER', 98, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2401, 'PASSENGER', 99, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2402, 'PASSENGER', 100, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2403, 'PASSENGER', 101, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2404, 'PASSENGER', 102, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2405, 'PASSENGER', 103, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2406, 'PASSENGER', 104, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2407, 'PASSENGER', 105, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2408, 'PASSENGER', 106, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2409, 'PASSENGER', 107, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2410, 'PASSENGER', 108, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2411, 'PASSENGER', 109, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2412, 'PASSENGER', 110, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2413, 'PASSENGER', 111, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2414, 'PASSENGER', 112, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2415, 'PASSENGER', 113, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2416, 'PASSENGER', 114, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2417, 'PASSENGER', 115, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2418, 'PASSENGER', 116, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2419, 'PASSENGER', 117, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2420, 'PASSENGER', 118, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2421, 'PASSENGER', 119, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2422, 'PASSENGER', 120, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2423, 'PASSENGER', 121, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2424, 'PASSENGER', 122, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2425, 'PASSENGER', 123, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2426, 'PASSENGER', 124, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2427, 'PASSENGER', 125, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2428, 'PASSENGER', 126, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2429, 'PASSENGER', 127, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2430, 'PASSENGER', 128, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2431, 'PASSENGER', 129, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2432, 'PASSENGER', 130, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2433, 'PASSENGER', 131, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2434, 'PASSENGER', 132, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2435, 'PASSENGER', 133, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2436, 'PASSENGER', 134, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2437, 'PASSENGER', 135, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2438, 'PASSENGER', 136, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2439, 'PASSENGER', 137, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2440, 'PASSENGER', 138, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2441, 'PASSENGER', 139, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2442, 'PASSENGER', 140, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2443, 'PASSENGER', 141, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2444, 'PASSENGER', 142, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2445, 'PASSENGER', 143, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2446, 'PASSENGER', 144, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2447, 'PASSENGER', 145, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2448, 'PASSENGER', 146, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2449, 'PASSENGER', 147, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2450, 'PASSENGER', 148, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2451, 'PASSENGER', 149, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2452, 'PASSENGER', 150, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2453, 'PASSENGER', 151, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2454, 'PASSENGER', 152, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2455, 'PASSENGER', 153, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2456, 'PASSENGER', 154, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2457, 'PASSENGER', 155, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2458, 'PASSENGER', 156, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2459, 'PASSENGER', 157, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2460, 'PASSENGER', 158, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2461, 'PASSENGER', 159, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2462, 'PASSENGER', 160, 'email_notifications', 1, '2026-08-26 16:42:06'),
(2558, 'PASSENGER', 1, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2559, 'PASSENGER', 1, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2560, 'PASSENGER', 1, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2561, 'PASSENGER', 1, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2562, 'PASSENGER', 1, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2563, 'PASSENGER', 2, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2564, 'PASSENGER', 2, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2565, 'PASSENGER', 2, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2566, 'PASSENGER', 2, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2567, 'PASSENGER', 2, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2568, 'PASSENGER', 3, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2569, 'PASSENGER', 3, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2570, 'PASSENGER', 3, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2571, 'PASSENGER', 3, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2572, 'PASSENGER', 3, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2573, 'PASSENGER', 4, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2574, 'PASSENGER', 4, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2575, 'PASSENGER', 4, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2576, 'PASSENGER', 4, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2577, 'PASSENGER', 4, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2578, 'PASSENGER', 5, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2579, 'PASSENGER', 5, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2580, 'PASSENGER', 5, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2581, 'PASSENGER', 5, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2582, 'PASSENGER', 5, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2583, 'PASSENGER', 6, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2584, 'PASSENGER', 6, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2585, 'PASSENGER', 6, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2586, 'PASSENGER', 6, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2587, 'PASSENGER', 6, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2588, 'PASSENGER', 11, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2589, 'PASSENGER', 11, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2590, 'PASSENGER', 11, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2591, 'PASSENGER', 11, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2592, 'PASSENGER', 11, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2593, 'PASSENGER', 12, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2594, 'PASSENGER', 12, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2595, 'PASSENGER', 12, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2596, 'PASSENGER', 12, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2597, 'PASSENGER', 12, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2598, 'PASSENGER', 13, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2599, 'PASSENGER', 13, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2600, 'PASSENGER', 13, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2601, 'PASSENGER', 13, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2602, 'PASSENGER', 13, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2603, 'PASSENGER', 14, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2604, 'PASSENGER', 14, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2605, 'PASSENGER', 14, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2606, 'PASSENGER', 14, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2607, 'PASSENGER', 14, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2608, 'PASSENGER', 15, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2609, 'PASSENGER', 15, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2610, 'PASSENGER', 15, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2611, 'PASSENGER', 15, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2612, 'PASSENGER', 15, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2613, 'PASSENGER', 16, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2614, 'PASSENGER', 16, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2615, 'PASSENGER', 16, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2616, 'PASSENGER', 16, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2617, 'PASSENGER', 16, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2618, 'PASSENGER', 17, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2619, 'PASSENGER', 17, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2620, 'PASSENGER', 17, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2621, 'PASSENGER', 17, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2622, 'PASSENGER', 17, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2623, 'PASSENGER', 18, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2624, 'PASSENGER', 18, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2625, 'PASSENGER', 18, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2626, 'PASSENGER', 18, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2627, 'PASSENGER', 18, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2628, 'PASSENGER', 19, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2629, 'PASSENGER', 19, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2630, 'PASSENGER', 19, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2631, 'PASSENGER', 19, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2632, 'PASSENGER', 19, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2633, 'PASSENGER', 20, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2634, 'PASSENGER', 20, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2635, 'PASSENGER', 20, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2636, 'PASSENGER', 20, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2637, 'PASSENGER', 20, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2638, 'PASSENGER', 21, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2639, 'PASSENGER', 21, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2640, 'PASSENGER', 21, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2641, 'PASSENGER', 21, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2642, 'PASSENGER', 21, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2643, 'PASSENGER', 22, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2644, 'PASSENGER', 22, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2645, 'PASSENGER', 22, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2646, 'PASSENGER', 22, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2647, 'PASSENGER', 22, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2648, 'PASSENGER', 23, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2649, 'PASSENGER', 23, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2650, 'PASSENGER', 23, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2651, 'PASSENGER', 23, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2652, 'PASSENGER', 23, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2653, 'PASSENGER', 24, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2654, 'PASSENGER', 24, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2655, 'PASSENGER', 24, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2656, 'PASSENGER', 24, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2657, 'PASSENGER', 24, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2658, 'PASSENGER', 25, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2659, 'PASSENGER', 25, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2660, 'PASSENGER', 25, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2661, 'PASSENGER', 25, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2662, 'PASSENGER', 25, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2663, 'PASSENGER', 26, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2664, 'PASSENGER', 26, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2665, 'PASSENGER', 26, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2666, 'PASSENGER', 26, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2667, 'PASSENGER', 26, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2668, 'PASSENGER', 27, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2669, 'PASSENGER', 27, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2670, 'PASSENGER', 27, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2671, 'PASSENGER', 27, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2672, 'PASSENGER', 27, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2673, 'PASSENGER', 28, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2674, 'PASSENGER', 28, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2675, 'PASSENGER', 28, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2676, 'PASSENGER', 28, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2677, 'PASSENGER', 28, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2678, 'PASSENGER', 29, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2679, 'PASSENGER', 29, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2680, 'PASSENGER', 29, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2681, 'PASSENGER', 29, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2682, 'PASSENGER', 29, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2683, 'PASSENGER', 30, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2684, 'PASSENGER', 30, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2685, 'PASSENGER', 30, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2686, 'PASSENGER', 30, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2687, 'PASSENGER', 30, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2688, 'PASSENGER', 31, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2689, 'PASSENGER', 31, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2690, 'PASSENGER', 31, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2691, 'PASSENGER', 31, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2692, 'PASSENGER', 31, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2693, 'PASSENGER', 32, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2694, 'PASSENGER', 32, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2695, 'PASSENGER', 32, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2696, 'PASSENGER', 32, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2697, 'PASSENGER', 32, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2698, 'PASSENGER', 33, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2699, 'PASSENGER', 33, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2700, 'PASSENGER', 33, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2701, 'PASSENGER', 33, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2702, 'PASSENGER', 33, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2703, 'PASSENGER', 34, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2704, 'PASSENGER', 34, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2705, 'PASSENGER', 34, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2706, 'PASSENGER', 34, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2707, 'PASSENGER', 34, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2708, 'PASSENGER', 35, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2709, 'PASSENGER', 35, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2710, 'PASSENGER', 35, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2711, 'PASSENGER', 35, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2712, 'PASSENGER', 35, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2713, 'PASSENGER', 36, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2714, 'PASSENGER', 36, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2715, 'PASSENGER', 36, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2716, 'PASSENGER', 36, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2717, 'PASSENGER', 36, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2718, 'PASSENGER', 37, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2719, 'PASSENGER', 37, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2720, 'PASSENGER', 37, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2721, 'PASSENGER', 37, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2722, 'PASSENGER', 37, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2723, 'PASSENGER', 38, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2724, 'PASSENGER', 38, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2725, 'PASSENGER', 38, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2726, 'PASSENGER', 38, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2727, 'PASSENGER', 38, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2728, 'PASSENGER', 39, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2729, 'PASSENGER', 39, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2730, 'PASSENGER', 39, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2731, 'PASSENGER', 39, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2732, 'PASSENGER', 39, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2733, 'PASSENGER', 40, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2734, 'PASSENGER', 40, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2735, 'PASSENGER', 40, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2736, 'PASSENGER', 40, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2737, 'PASSENGER', 40, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2738, 'PASSENGER', 41, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2739, 'PASSENGER', 41, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2740, 'PASSENGER', 41, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2741, 'PASSENGER', 41, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2742, 'PASSENGER', 41, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2743, 'PASSENGER', 42, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2744, 'PASSENGER', 42, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2745, 'PASSENGER', 42, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2746, 'PASSENGER', 42, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2747, 'PASSENGER', 42, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2748, 'PASSENGER', 43, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2749, 'PASSENGER', 43, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2750, 'PASSENGER', 43, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2751, 'PASSENGER', 43, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2752, 'PASSENGER', 43, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2753, 'PASSENGER', 44, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2754, 'PASSENGER', 44, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2755, 'PASSENGER', 44, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2756, 'PASSENGER', 44, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2757, 'PASSENGER', 44, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2758, 'PASSENGER', 45, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2759, 'PASSENGER', 45, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2760, 'PASSENGER', 45, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2761, 'PASSENGER', 45, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2762, 'PASSENGER', 45, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2763, 'PASSENGER', 46, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2764, 'PASSENGER', 46, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2765, 'PASSENGER', 46, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2766, 'PASSENGER', 46, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2767, 'PASSENGER', 46, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2768, 'PASSENGER', 47, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2769, 'PASSENGER', 47, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2770, 'PASSENGER', 47, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2771, 'PASSENGER', 47, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2772, 'PASSENGER', 47, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2773, 'PASSENGER', 48, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2774, 'PASSENGER', 48, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2775, 'PASSENGER', 48, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2776, 'PASSENGER', 48, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2777, 'PASSENGER', 48, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2778, 'PASSENGER', 49, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2779, 'PASSENGER', 49, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2780, 'PASSENGER', 49, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2781, 'PASSENGER', 49, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2782, 'PASSENGER', 49, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2783, 'PASSENGER', 50, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2784, 'PASSENGER', 50, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2785, 'PASSENGER', 50, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2786, 'PASSENGER', 50, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2787, 'PASSENGER', 50, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2788, 'PASSENGER', 51, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2789, 'PASSENGER', 51, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2790, 'PASSENGER', 51, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2791, 'PASSENGER', 51, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2792, 'PASSENGER', 51, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2793, 'PASSENGER', 52, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2794, 'PASSENGER', 52, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2795, 'PASSENGER', 52, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2796, 'PASSENGER', 52, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2797, 'PASSENGER', 52, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2798, 'PASSENGER', 53, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2799, 'PASSENGER', 53, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2800, 'PASSENGER', 53, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2801, 'PASSENGER', 53, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2802, 'PASSENGER', 53, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2803, 'PASSENGER', 54, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2804, 'PASSENGER', 54, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2805, 'PASSENGER', 54, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2806, 'PASSENGER', 54, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2807, 'PASSENGER', 54, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2808, 'PASSENGER', 55, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2809, 'PASSENGER', 55, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2810, 'PASSENGER', 55, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2811, 'PASSENGER', 55, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2812, 'PASSENGER', 55, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2813, 'PASSENGER', 56, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2814, 'PASSENGER', 56, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2815, 'PASSENGER', 56, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2816, 'PASSENGER', 56, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2817, 'PASSENGER', 56, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2818, 'PASSENGER', 57, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2819, 'PASSENGER', 57, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2820, 'PASSENGER', 57, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2821, 'PASSENGER', 57, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2822, 'PASSENGER', 57, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2823, 'PASSENGER', 58, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2824, 'PASSENGER', 58, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2825, 'PASSENGER', 58, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2826, 'PASSENGER', 58, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2827, 'PASSENGER', 58, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2828, 'PASSENGER', 59, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2829, 'PASSENGER', 59, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2830, 'PASSENGER', 59, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2831, 'PASSENGER', 59, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2832, 'PASSENGER', 59, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2833, 'PASSENGER', 60, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2834, 'PASSENGER', 60, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2835, 'PASSENGER', 60, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2836, 'PASSENGER', 60, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2837, 'PASSENGER', 60, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2838, 'PASSENGER', 7, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2839, 'PASSENGER', 7, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2840, 'PASSENGER', 7, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2841, 'PASSENGER', 7, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2842, 'PASSENGER', 7, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2843, 'PASSENGER', 8, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2844, 'PASSENGER', 8, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2845, 'PASSENGER', 8, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2846, 'PASSENGER', 8, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2847, 'PASSENGER', 8, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2848, 'PASSENGER', 61, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2849, 'PASSENGER', 61, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2850, 'PASSENGER', 61, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2851, 'PASSENGER', 61, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2852, 'PASSENGER', 61, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2853, 'PASSENGER', 62, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2854, 'PASSENGER', 62, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2855, 'PASSENGER', 62, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2856, 'PASSENGER', 62, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2857, 'PASSENGER', 62, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2858, 'PASSENGER', 63, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2859, 'PASSENGER', 63, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2860, 'PASSENGER', 63, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2861, 'PASSENGER', 63, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2862, 'PASSENGER', 63, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2863, 'PASSENGER', 64, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2864, 'PASSENGER', 64, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2865, 'PASSENGER', 64, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2866, 'PASSENGER', 64, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2867, 'PASSENGER', 64, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2868, 'PASSENGER', 65, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2869, 'PASSENGER', 65, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2870, 'PASSENGER', 65, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2871, 'PASSENGER', 65, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2872, 'PASSENGER', 65, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2873, 'PASSENGER', 66, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2874, 'PASSENGER', 66, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2875, 'PASSENGER', 66, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2876, 'PASSENGER', 66, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2877, 'PASSENGER', 66, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2878, 'PASSENGER', 67, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2879, 'PASSENGER', 67, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2880, 'PASSENGER', 67, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2881, 'PASSENGER', 67, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2882, 'PASSENGER', 67, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2883, 'PASSENGER', 68, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2884, 'PASSENGER', 68, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2885, 'PASSENGER', 68, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2886, 'PASSENGER', 68, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2887, 'PASSENGER', 68, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2888, 'PASSENGER', 69, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2889, 'PASSENGER', 69, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2890, 'PASSENGER', 69, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2891, 'PASSENGER', 69, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2892, 'PASSENGER', 69, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2893, 'PASSENGER', 70, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2894, 'PASSENGER', 70, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2895, 'PASSENGER', 70, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2896, 'PASSENGER', 70, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2897, 'PASSENGER', 70, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2898, 'PASSENGER', 71, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2899, 'PASSENGER', 71, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2900, 'PASSENGER', 71, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2901, 'PASSENGER', 71, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2902, 'PASSENGER', 71, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2903, 'PASSENGER', 72, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2904, 'PASSENGER', 72, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2905, 'PASSENGER', 72, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2906, 'PASSENGER', 72, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2907, 'PASSENGER', 72, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2908, 'PASSENGER', 73, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2909, 'PASSENGER', 73, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2910, 'PASSENGER', 73, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2911, 'PASSENGER', 73, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2912, 'PASSENGER', 73, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2913, 'PASSENGER', 74, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2914, 'PASSENGER', 74, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2915, 'PASSENGER', 74, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2916, 'PASSENGER', 74, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2917, 'PASSENGER', 74, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2918, 'PASSENGER', 75, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2919, 'PASSENGER', 75, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2920, 'PASSENGER', 75, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2921, 'PASSENGER', 75, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2922, 'PASSENGER', 75, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2923, 'PASSENGER', 76, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2924, 'PASSENGER', 76, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2925, 'PASSENGER', 76, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2926, 'PASSENGER', 76, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2927, 'PASSENGER', 76, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2928, 'PASSENGER', 77, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2929, 'PASSENGER', 77, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2930, 'PASSENGER', 77, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2931, 'PASSENGER', 77, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2932, 'PASSENGER', 77, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2933, 'PASSENGER', 78, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2934, 'PASSENGER', 78, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2935, 'PASSENGER', 78, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2936, 'PASSENGER', 78, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2937, 'PASSENGER', 78, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2938, 'PASSENGER', 79, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2939, 'PASSENGER', 79, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2940, 'PASSENGER', 79, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2941, 'PASSENGER', 79, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2942, 'PASSENGER', 79, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2943, 'PASSENGER', 80, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2944, 'PASSENGER', 80, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2945, 'PASSENGER', 80, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2946, 'PASSENGER', 80, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2947, 'PASSENGER', 80, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2948, 'PASSENGER', 81, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2949, 'PASSENGER', 81, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2950, 'PASSENGER', 81, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2951, 'PASSENGER', 81, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2952, 'PASSENGER', 81, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2953, 'PASSENGER', 82, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2954, 'PASSENGER', 82, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2955, 'PASSENGER', 82, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2956, 'PASSENGER', 82, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2957, 'PASSENGER', 82, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2958, 'PASSENGER', 83, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2959, 'PASSENGER', 83, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2960, 'PASSENGER', 83, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2961, 'PASSENGER', 83, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2962, 'PASSENGER', 83, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2963, 'PASSENGER', 84, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2964, 'PASSENGER', 84, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2965, 'PASSENGER', 84, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2966, 'PASSENGER', 84, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2967, 'PASSENGER', 84, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2968, 'PASSENGER', 85, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2969, 'PASSENGER', 85, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2970, 'PASSENGER', 85, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2971, 'PASSENGER', 85, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2972, 'PASSENGER', 85, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2973, 'PASSENGER', 86, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2974, 'PASSENGER', 86, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2975, 'PASSENGER', 86, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2976, 'PASSENGER', 86, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2977, 'PASSENGER', 86, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2978, 'PASSENGER', 87, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2979, 'PASSENGER', 87, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2980, 'PASSENGER', 87, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2981, 'PASSENGER', 87, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2982, 'PASSENGER', 87, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2983, 'PASSENGER', 88, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2984, 'PASSENGER', 88, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2985, 'PASSENGER', 88, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2986, 'PASSENGER', 88, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2987, 'PASSENGER', 88, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2988, 'PASSENGER', 89, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2989, 'PASSENGER', 89, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2990, 'PASSENGER', 89, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2991, 'PASSENGER', 89, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2992, 'PASSENGER', 89, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2993, 'PASSENGER', 90, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2994, 'PASSENGER', 90, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(2995, 'PASSENGER', 90, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(2996, 'PASSENGER', 90, 'semester_billing', 1, '2026-08-26 16:42:06'),
(2997, 'PASSENGER', 90, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(2998, 'PASSENGER', 91, 'booking_updates', 1, '2026-08-26 16:42:06'),
(2999, 'PASSENGER', 91, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3000, 'PASSENGER', 91, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3001, 'PASSENGER', 91, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3002, 'PASSENGER', 91, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3003, 'PASSENGER', 92, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3004, 'PASSENGER', 92, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3005, 'PASSENGER', 92, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3006, 'PASSENGER', 92, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3007, 'PASSENGER', 92, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3008, 'PASSENGER', 93, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3009, 'PASSENGER', 93, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3010, 'PASSENGER', 93, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3011, 'PASSENGER', 93, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3012, 'PASSENGER', 93, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3013, 'PASSENGER', 94, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3014, 'PASSENGER', 94, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3015, 'PASSENGER', 94, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3016, 'PASSENGER', 94, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3017, 'PASSENGER', 94, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3018, 'PASSENGER', 95, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3019, 'PASSENGER', 95, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3020, 'PASSENGER', 95, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3021, 'PASSENGER', 95, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3022, 'PASSENGER', 95, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3023, 'PASSENGER', 96, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3024, 'PASSENGER', 96, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3025, 'PASSENGER', 96, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3026, 'PASSENGER', 96, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3027, 'PASSENGER', 96, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3028, 'PASSENGER', 97, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3029, 'PASSENGER', 97, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3030, 'PASSENGER', 97, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3031, 'PASSENGER', 97, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3032, 'PASSENGER', 97, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3033, 'PASSENGER', 98, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3034, 'PASSENGER', 98, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3035, 'PASSENGER', 98, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3036, 'PASSENGER', 98, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3037, 'PASSENGER', 98, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3038, 'PASSENGER', 99, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3039, 'PASSENGER', 99, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3040, 'PASSENGER', 99, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3041, 'PASSENGER', 99, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3042, 'PASSENGER', 99, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3043, 'PASSENGER', 100, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3044, 'PASSENGER', 100, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3045, 'PASSENGER', 100, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3046, 'PASSENGER', 100, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3047, 'PASSENGER', 100, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3048, 'PASSENGER', 101, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3049, 'PASSENGER', 101, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3050, 'PASSENGER', 101, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3051, 'PASSENGER', 101, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3052, 'PASSENGER', 101, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3053, 'PASSENGER', 102, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3054, 'PASSENGER', 102, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3055, 'PASSENGER', 102, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3056, 'PASSENGER', 102, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3057, 'PASSENGER', 102, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3058, 'PASSENGER', 103, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3059, 'PASSENGER', 103, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3060, 'PASSENGER', 103, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3061, 'PASSENGER', 103, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3062, 'PASSENGER', 103, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3063, 'PASSENGER', 104, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3064, 'PASSENGER', 104, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3065, 'PASSENGER', 104, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3066, 'PASSENGER', 104, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3067, 'PASSENGER', 104, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3068, 'PASSENGER', 105, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3069, 'PASSENGER', 105, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3070, 'PASSENGER', 105, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3071, 'PASSENGER', 105, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3072, 'PASSENGER', 105, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3073, 'PASSENGER', 106, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3074, 'PASSENGER', 106, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3075, 'PASSENGER', 106, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3076, 'PASSENGER', 106, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3077, 'PASSENGER', 106, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3078, 'PASSENGER', 107, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3079, 'PASSENGER', 107, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3080, 'PASSENGER', 107, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3081, 'PASSENGER', 107, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3082, 'PASSENGER', 107, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3083, 'PASSENGER', 108, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3084, 'PASSENGER', 108, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3085, 'PASSENGER', 108, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3086, 'PASSENGER', 108, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3087, 'PASSENGER', 108, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3088, 'PASSENGER', 109, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3089, 'PASSENGER', 109, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3090, 'PASSENGER', 109, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3091, 'PASSENGER', 109, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3092, 'PASSENGER', 109, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3093, 'PASSENGER', 110, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3094, 'PASSENGER', 110, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3095, 'PASSENGER', 110, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3096, 'PASSENGER', 110, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3097, 'PASSENGER', 110, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3098, 'PASSENGER', 9, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3099, 'PASSENGER', 9, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3100, 'PASSENGER', 9, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3101, 'PASSENGER', 9, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3102, 'PASSENGER', 9, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3103, 'PASSENGER', 10, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3104, 'PASSENGER', 10, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3105, 'PASSENGER', 10, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3106, 'PASSENGER', 10, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3107, 'PASSENGER', 10, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3108, 'PASSENGER', 111, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3109, 'PASSENGER', 111, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3110, 'PASSENGER', 111, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3111, 'PASSENGER', 111, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3112, 'PASSENGER', 111, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3113, 'PASSENGER', 112, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3114, 'PASSENGER', 112, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3115, 'PASSENGER', 112, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3116, 'PASSENGER', 112, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3117, 'PASSENGER', 112, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3118, 'PASSENGER', 113, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3119, 'PASSENGER', 113, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3120, 'PASSENGER', 113, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3121, 'PASSENGER', 113, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3122, 'PASSENGER', 113, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3123, 'PASSENGER', 114, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3124, 'PASSENGER', 114, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3125, 'PASSENGER', 114, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3126, 'PASSENGER', 114, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3127, 'PASSENGER', 114, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3128, 'PASSENGER', 115, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3129, 'PASSENGER', 115, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3130, 'PASSENGER', 115, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3131, 'PASSENGER', 115, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3132, 'PASSENGER', 115, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3133, 'PASSENGER', 116, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3134, 'PASSENGER', 116, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3135, 'PASSENGER', 116, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3136, 'PASSENGER', 116, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3137, 'PASSENGER', 116, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3138, 'PASSENGER', 117, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3139, 'PASSENGER', 117, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3140, 'PASSENGER', 117, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3141, 'PASSENGER', 117, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3142, 'PASSENGER', 117, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3143, 'PASSENGER', 118, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3144, 'PASSENGER', 118, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3145, 'PASSENGER', 118, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3146, 'PASSENGER', 118, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3147, 'PASSENGER', 118, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3148, 'PASSENGER', 119, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3149, 'PASSENGER', 119, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3150, 'PASSENGER', 119, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3151, 'PASSENGER', 119, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3152, 'PASSENGER', 119, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3153, 'PASSENGER', 120, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3154, 'PASSENGER', 120, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3155, 'PASSENGER', 120, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3156, 'PASSENGER', 120, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3157, 'PASSENGER', 120, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3158, 'PASSENGER', 121, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3159, 'PASSENGER', 121, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3160, 'PASSENGER', 121, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3161, 'PASSENGER', 121, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3162, 'PASSENGER', 121, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3163, 'PASSENGER', 122, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3164, 'PASSENGER', 122, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3165, 'PASSENGER', 122, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3166, 'PASSENGER', 122, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3167, 'PASSENGER', 122, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3168, 'PASSENGER', 123, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3169, 'PASSENGER', 123, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3170, 'PASSENGER', 123, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3171, 'PASSENGER', 123, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3172, 'PASSENGER', 123, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3173, 'PASSENGER', 124, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3174, 'PASSENGER', 124, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3175, 'PASSENGER', 124, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3176, 'PASSENGER', 124, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3177, 'PASSENGER', 124, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3178, 'PASSENGER', 125, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3179, 'PASSENGER', 125, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3180, 'PASSENGER', 125, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3181, 'PASSENGER', 125, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3182, 'PASSENGER', 125, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3183, 'PASSENGER', 126, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3184, 'PASSENGER', 126, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3185, 'PASSENGER', 126, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3186, 'PASSENGER', 126, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3187, 'PASSENGER', 126, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3188, 'PASSENGER', 127, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3189, 'PASSENGER', 127, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3190, 'PASSENGER', 127, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3191, 'PASSENGER', 127, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3192, 'PASSENGER', 127, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3193, 'PASSENGER', 128, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3194, 'PASSENGER', 128, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3195, 'PASSENGER', 128, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3196, 'PASSENGER', 128, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3197, 'PASSENGER', 128, 'complaint_responses', 1, '2026-08-26 16:42:06');
INSERT INTO `user_notification_preferences` (`preference_id`, `user_type`, `user_id`, `preference_key`, `enabled`, `updated_at`) VALUES
(3198, 'PASSENGER', 129, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3199, 'PASSENGER', 129, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3200, 'PASSENGER', 129, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3201, 'PASSENGER', 129, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3202, 'PASSENGER', 129, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3203, 'PASSENGER', 130, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3204, 'PASSENGER', 130, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3205, 'PASSENGER', 130, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3206, 'PASSENGER', 130, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3207, 'PASSENGER', 130, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3208, 'PASSENGER', 131, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3209, 'PASSENGER', 131, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3210, 'PASSENGER', 131, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3211, 'PASSENGER', 131, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3212, 'PASSENGER', 131, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3213, 'PASSENGER', 132, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3214, 'PASSENGER', 132, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3215, 'PASSENGER', 132, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3216, 'PASSENGER', 132, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3217, 'PASSENGER', 132, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3218, 'PASSENGER', 133, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3219, 'PASSENGER', 133, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3220, 'PASSENGER', 133, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3221, 'PASSENGER', 133, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3222, 'PASSENGER', 133, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3223, 'PASSENGER', 134, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3224, 'PASSENGER', 134, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3225, 'PASSENGER', 134, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3226, 'PASSENGER', 134, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3227, 'PASSENGER', 134, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3228, 'PASSENGER', 135, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3229, 'PASSENGER', 135, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3230, 'PASSENGER', 135, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3231, 'PASSENGER', 135, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3232, 'PASSENGER', 135, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3233, 'PASSENGER', 136, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3234, 'PASSENGER', 136, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3235, 'PASSENGER', 136, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3236, 'PASSENGER', 136, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3237, 'PASSENGER', 136, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3238, 'PASSENGER', 137, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3239, 'PASSENGER', 137, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3240, 'PASSENGER', 137, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3241, 'PASSENGER', 137, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3242, 'PASSENGER', 137, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3243, 'PASSENGER', 138, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3244, 'PASSENGER', 138, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3245, 'PASSENGER', 138, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3246, 'PASSENGER', 138, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3247, 'PASSENGER', 138, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3248, 'PASSENGER', 139, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3249, 'PASSENGER', 139, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3250, 'PASSENGER', 139, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3251, 'PASSENGER', 139, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3252, 'PASSENGER', 139, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3253, 'PASSENGER', 140, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3254, 'PASSENGER', 140, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3255, 'PASSENGER', 140, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3256, 'PASSENGER', 140, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3257, 'PASSENGER', 140, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3258, 'PASSENGER', 141, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3259, 'PASSENGER', 141, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3260, 'PASSENGER', 141, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3261, 'PASSENGER', 141, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3262, 'PASSENGER', 141, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3263, 'PASSENGER', 142, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3264, 'PASSENGER', 142, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3265, 'PASSENGER', 142, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3266, 'PASSENGER', 142, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3267, 'PASSENGER', 142, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3268, 'PASSENGER', 143, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3269, 'PASSENGER', 143, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3270, 'PASSENGER', 143, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3271, 'PASSENGER', 143, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3272, 'PASSENGER', 143, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3273, 'PASSENGER', 144, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3274, 'PASSENGER', 144, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3275, 'PASSENGER', 144, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3276, 'PASSENGER', 144, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3277, 'PASSENGER', 144, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3278, 'PASSENGER', 145, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3279, 'PASSENGER', 145, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3280, 'PASSENGER', 145, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3281, 'PASSENGER', 145, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3282, 'PASSENGER', 145, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3283, 'PASSENGER', 146, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3284, 'PASSENGER', 146, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3285, 'PASSENGER', 146, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3286, 'PASSENGER', 146, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3287, 'PASSENGER', 146, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3288, 'PASSENGER', 147, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3289, 'PASSENGER', 147, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3290, 'PASSENGER', 147, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3291, 'PASSENGER', 147, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3292, 'PASSENGER', 147, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3293, 'PASSENGER', 148, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3294, 'PASSENGER', 148, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3295, 'PASSENGER', 148, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3296, 'PASSENGER', 148, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3297, 'PASSENGER', 148, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3298, 'PASSENGER', 149, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3299, 'PASSENGER', 149, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3300, 'PASSENGER', 149, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3301, 'PASSENGER', 149, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3302, 'PASSENGER', 149, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3303, 'PASSENGER', 150, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3304, 'PASSENGER', 150, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3305, 'PASSENGER', 150, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3306, 'PASSENGER', 150, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3307, 'PASSENGER', 150, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3308, 'PASSENGER', 151, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3309, 'PASSENGER', 151, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3310, 'PASSENGER', 151, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3311, 'PASSENGER', 151, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3312, 'PASSENGER', 151, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3313, 'PASSENGER', 152, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3314, 'PASSENGER', 152, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3315, 'PASSENGER', 152, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3316, 'PASSENGER', 152, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3317, 'PASSENGER', 152, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3318, 'PASSENGER', 153, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3319, 'PASSENGER', 153, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3320, 'PASSENGER', 153, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3321, 'PASSENGER', 153, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3322, 'PASSENGER', 153, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3323, 'PASSENGER', 154, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3324, 'PASSENGER', 154, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3325, 'PASSENGER', 154, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3326, 'PASSENGER', 154, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3327, 'PASSENGER', 154, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3328, 'PASSENGER', 155, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3329, 'PASSENGER', 155, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3330, 'PASSENGER', 155, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3331, 'PASSENGER', 155, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3332, 'PASSENGER', 155, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3333, 'PASSENGER', 156, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3334, 'PASSENGER', 156, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3335, 'PASSENGER', 156, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3336, 'PASSENGER', 156, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3337, 'PASSENGER', 156, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3338, 'PASSENGER', 157, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3339, 'PASSENGER', 157, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3340, 'PASSENGER', 157, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3341, 'PASSENGER', 157, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3342, 'PASSENGER', 157, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3343, 'PASSENGER', 158, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3344, 'PASSENGER', 158, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3345, 'PASSENGER', 158, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3346, 'PASSENGER', 158, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3347, 'PASSENGER', 158, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3348, 'PASSENGER', 159, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3349, 'PASSENGER', 159, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3350, 'PASSENGER', 159, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3351, 'PASSENGER', 159, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3352, 'PASSENGER', 159, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3353, 'PASSENGER', 160, 'booking_updates', 1, '2026-08-26 16:42:06'),
(3354, 'PASSENGER', 160, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3355, 'PASSENGER', 160, 'ticket_transfers', 1, '2026-08-26 16:42:06'),
(3356, 'PASSENGER', 160, 'semester_billing', 1, '2026-08-26 16:42:06'),
(3357, 'PASSENGER', 160, 'complaint_responses', 1, '2026-08-26 16:42:06'),
(3581, 'UNIVERSITY_ADMIN', 1, 'passenger_registrations', 1, '2026-08-26 16:42:06'),
(3582, 'UNIVERSITY_ADMIN', 2, 'passenger_registrations', 1, '2026-08-26 16:42:06'),
(3583, 'UNIVERSITY_ADMIN', 3, 'passenger_registrations', 1, '2026-08-26 16:42:06'),
(3584, 'UNIVERSITY_ADMIN', 1, 'booking_activity', 1, '2026-08-26 16:42:06'),
(3585, 'UNIVERSITY_ADMIN', 2, 'booking_activity', 1, '2026-08-26 16:42:06'),
(3586, 'UNIVERSITY_ADMIN', 3, 'booking_activity', 1, '2026-08-26 16:42:06'),
(3587, 'UNIVERSITY_ADMIN', 1, 'capacity_warnings', 1, '2026-08-26 16:42:06'),
(3588, 'UNIVERSITY_ADMIN', 2, 'capacity_warnings', 1, '2026-08-26 16:42:06'),
(3589, 'UNIVERSITY_ADMIN', 3, 'capacity_warnings', 1, '2026-08-26 16:42:06'),
(3590, 'UNIVERSITY_ADMIN', 1, 'complaints', 1, '2026-08-26 16:42:06'),
(3591, 'UNIVERSITY_ADMIN', 2, 'complaints', 1, '2026-08-26 16:42:06'),
(3592, 'UNIVERSITY_ADMIN', 3, 'complaints', 1, '2026-08-26 16:42:06'),
(3593, 'UNIVERSITY_ADMIN', 1, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3594, 'UNIVERSITY_ADMIN', 2, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3595, 'UNIVERSITY_ADMIN', 3, 'schedule_changes', 1, '2026-08-26 16:42:06'),
(3596, 'UNIVERSITY_ADMIN', 1, 'fleet_route_changes', 1, '2026-08-26 16:42:06'),
(3597, 'UNIVERSITY_ADMIN', 2, 'fleet_route_changes', 1, '2026-08-26 16:42:06'),
(3598, 'UNIVERSITY_ADMIN', 3, 'fleet_route_changes', 1, '2026-08-26 16:42:06'),
(3599, 'UNIVERSITY_ADMIN', 1, 'announcement_activity', 1, '2026-08-26 16:42:06'),
(3600, 'UNIVERSITY_ADMIN', 2, 'announcement_activity', 1, '2026-08-26 16:42:06'),
(3601, 'UNIVERSITY_ADMIN', 3, 'announcement_activity', 1, '2026-08-26 16:42:06'),
(3602, 'UNIVERSITY_ADMIN', 1, 'verification_events', 1, '2026-08-26 16:42:06'),
(3603, 'UNIVERSITY_ADMIN', 2, 'verification_events', 1, '2026-08-26 16:42:06'),
(3604, 'UNIVERSITY_ADMIN', 3, 'verification_events', 1, '2026-08-26 16:42:06'),
(3605, 'UNIVERSITY_ADMIN', 1, 'transport_events', 1, '2026-08-26 16:42:06'),
(3606, 'UNIVERSITY_ADMIN', 2, 'transport_events', 1, '2026-08-26 16:42:06'),
(3607, 'UNIVERSITY_ADMIN', 3, 'transport_events', 1, '2026-08-26 16:42:06'),
(3612, 'SYSTEM_ADMIN', 1, 'university_created', 1, '2026-08-26 16:42:06'),
(3613, 'SYSTEM_ADMIN', 1, 'university_status', 1, '2026-08-26 16:42:06'),
(3614, 'SYSTEM_ADMIN', 1, 'admin_accounts', 1, '2026-08-26 16:42:06'),
(3615, 'SYSTEM_ADMIN', 1, 'account_suspensions', 1, '2026-08-26 16:42:06'),
(3616, 'SYSTEM_ADMIN', 1, 'failed_logins', 1, '2026-08-26 16:42:06'),
(3617, 'SYSTEM_ADMIN', 1, 'platform_activity', 1, '2026-08-26 16:42:06'),
(3618, 'SYSTEM_ADMIN', 1, 'database_warnings', 1, '2026-08-26 16:42:06');

-- --------------------------------------------------------

--
-- Table structure for table `user_profiles`
--

CREATE TABLE `user_profiles` (
  `profile_id` bigint(20) UNSIGNED NOT NULL,
  `user_type` enum('PASSENGER','UNIVERSITY_ADMIN','SYSTEM_ADMIN') NOT NULL,
  `user_id` int(11) NOT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `address` varchar(500) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `gender` varchar(30) DEFAULT NULL,
  `emergency_contact_name` varchar(200) DEFAULT NULL,
  `emergency_contact_phone` varchar(30) DEFAULT NULL,
  `profile_picture_path` varchar(500) DEFAULT NULL,
  `preferred_boarding_stop` varchar(200) DEFAULT NULL,
  `preferred_destination_stop` varchar(200) DEFAULT NULL,
  `seat_preference` enum('SEAT','STANDING','NO_PREFERENCE') NOT NULL DEFAULT 'NO_PREFERENCE',
  `job_title` varchar(150) DEFAULT NULL,
  `department` varchar(200) DEFAULT NULL,
  `office_phone` varchar(30) DEFAULT NULL,
  `office_location` varchar(250) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_profiles`
--

INSERT INTO `user_profiles` (`profile_id`, `user_type`, `user_id`, `phone`, `address`, `date_of_birth`, `gender`, `emergency_contact_name`, `emergency_contact_phone`, `profile_picture_path`, `preferred_boarding_stop`, `preferred_destination_stop`, `seat_preference`, `job_title`, `department`, `office_phone`, `office_location`, `created_at`, `updated_at`) VALUES
(1, 'PASSENGER', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(2, 'PASSENGER', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(3, 'PASSENGER', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(4, 'PASSENGER', 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(5, 'PASSENGER', 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(6, 'PASSENGER', 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(7, 'PASSENGER', 7, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(8, 'PASSENGER', 8, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(9, 'PASSENGER', 9, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(10, 'PASSENGER', 10, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(11, 'PASSENGER', 11, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(12, 'PASSENGER', 12, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(13, 'PASSENGER', 13, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(14, 'PASSENGER', 14, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(15, 'PASSENGER', 15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(16, 'PASSENGER', 16, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(17, 'PASSENGER', 17, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(18, 'PASSENGER', 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(19, 'PASSENGER', 19, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(20, 'PASSENGER', 20, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(21, 'PASSENGER', 21, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(22, 'PASSENGER', 22, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(23, 'PASSENGER', 23, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(24, 'PASSENGER', 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(25, 'PASSENGER', 25, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(26, 'PASSENGER', 26, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(27, 'PASSENGER', 27, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(28, 'PASSENGER', 28, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(29, 'PASSENGER', 29, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(30, 'PASSENGER', 30, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(31, 'PASSENGER', 31, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(32, 'PASSENGER', 32, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(33, 'PASSENGER', 33, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(34, 'PASSENGER', 34, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(35, 'PASSENGER', 35, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(36, 'PASSENGER', 36, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(37, 'PASSENGER', 37, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(38, 'PASSENGER', 38, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(39, 'PASSENGER', 39, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(40, 'PASSENGER', 40, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(41, 'PASSENGER', 41, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(42, 'PASSENGER', 42, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(43, 'PASSENGER', 43, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(44, 'PASSENGER', 44, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(45, 'PASSENGER', 45, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(46, 'PASSENGER', 46, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(47, 'PASSENGER', 47, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(48, 'PASSENGER', 48, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(49, 'PASSENGER', 49, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(50, 'PASSENGER', 50, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(51, 'PASSENGER', 51, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(52, 'PASSENGER', 52, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(53, 'PASSENGER', 53, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(54, 'PASSENGER', 54, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(55, 'PASSENGER', 55, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(56, 'PASSENGER', 56, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(57, 'PASSENGER', 57, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(58, 'PASSENGER', 58, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(59, 'PASSENGER', 59, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(60, 'PASSENGER', 60, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(61, 'PASSENGER', 61, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(62, 'PASSENGER', 62, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(63, 'PASSENGER', 63, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(64, 'PASSENGER', 64, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(65, 'PASSENGER', 65, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(66, 'PASSENGER', 66, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(67, 'PASSENGER', 67, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(68, 'PASSENGER', 68, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(69, 'PASSENGER', 69, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(70, 'PASSENGER', 70, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(71, 'PASSENGER', 71, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(72, 'PASSENGER', 72, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(73, 'PASSENGER', 73, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(74, 'PASSENGER', 74, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(75, 'PASSENGER', 75, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(76, 'PASSENGER', 76, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(77, 'PASSENGER', 77, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(78, 'PASSENGER', 78, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(79, 'PASSENGER', 79, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(80, 'PASSENGER', 80, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(81, 'PASSENGER', 81, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(82, 'PASSENGER', 82, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(83, 'PASSENGER', 83, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(84, 'PASSENGER', 84, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(85, 'PASSENGER', 85, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(86, 'PASSENGER', 86, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(87, 'PASSENGER', 87, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(88, 'PASSENGER', 88, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(89, 'PASSENGER', 89, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(90, 'PASSENGER', 90, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(91, 'PASSENGER', 91, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(92, 'PASSENGER', 92, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(93, 'PASSENGER', 93, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(94, 'PASSENGER', 94, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(95, 'PASSENGER', 95, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(96, 'PASSENGER', 96, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(97, 'PASSENGER', 97, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(98, 'PASSENGER', 98, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(99, 'PASSENGER', 99, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(100, 'PASSENGER', 100, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(101, 'PASSENGER', 101, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(102, 'PASSENGER', 102, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(103, 'PASSENGER', 103, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(104, 'PASSENGER', 104, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(105, 'PASSENGER', 105, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(106, 'PASSENGER', 106, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(107, 'PASSENGER', 107, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(108, 'PASSENGER', 108, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(109, 'PASSENGER', 109, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(110, 'PASSENGER', 110, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(111, 'PASSENGER', 111, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(112, 'PASSENGER', 112, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(113, 'PASSENGER', 113, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(114, 'PASSENGER', 114, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(115, 'PASSENGER', 115, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(116, 'PASSENGER', 116, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(117, 'PASSENGER', 117, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(118, 'PASSENGER', 118, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(119, 'PASSENGER', 119, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(120, 'PASSENGER', 120, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(121, 'PASSENGER', 121, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(122, 'PASSENGER', 122, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(123, 'PASSENGER', 123, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(124, 'PASSENGER', 124, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(125, 'PASSENGER', 125, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(126, 'PASSENGER', 126, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(127, 'PASSENGER', 127, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(128, 'PASSENGER', 128, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(129, 'PASSENGER', 129, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(130, 'PASSENGER', 130, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(131, 'PASSENGER', 131, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(132, 'PASSENGER', 132, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(133, 'PASSENGER', 133, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(134, 'PASSENGER', 134, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(135, 'PASSENGER', 135, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(136, 'PASSENGER', 136, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(137, 'PASSENGER', 137, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(138, 'PASSENGER', 138, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(139, 'PASSENGER', 139, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(140, 'PASSENGER', 140, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(141, 'PASSENGER', 141, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(142, 'PASSENGER', 142, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(143, 'PASSENGER', 143, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(144, 'PASSENGER', 144, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(145, 'PASSENGER', 145, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(146, 'PASSENGER', 146, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(147, 'PASSENGER', 147, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(148, 'PASSENGER', 148, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(149, 'PASSENGER', 149, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(150, 'PASSENGER', 150, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(151, 'PASSENGER', 151, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(152, 'PASSENGER', 152, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(153, 'PASSENGER', 153, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(154, 'PASSENGER', 154, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(155, 'PASSENGER', 155, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(156, 'PASSENGER', 156, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(157, 'PASSENGER', 157, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(158, 'PASSENGER', 158, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(159, 'PASSENGER', 159, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(160, 'PASSENGER', 160, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(256, 'UNIVERSITY_ADMIN', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(257, 'UNIVERSITY_ADMIN', 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(258, 'UNIVERSITY_ADMIN', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06'),
(259, 'SYSTEM_ADMIN', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'NO_PREFERENCE', NULL, NULL, NULL, NULL, '2026-08-26 16:42:06', '2026-08-26 16:42:06');

-- --------------------------------------------------------

--
-- Table structure for table `user_security_events`
--

CREATE TABLE `user_security_events` (
  `security_event_id` bigint(20) UNSIGNED NOT NULL,
  `user_type` enum('PASSENGER','UNIVERSITY_ADMIN','SYSTEM_ADMIN') NOT NULL,
  `user_id` int(11) NOT NULL,
  `event_type` varchar(80) NOT NULL,
  `event_description` varchar(500) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(500) DEFAULT NULL,
  `occurred_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_security_events`
--

INSERT INTO `user_security_events` (`security_event_id`, `user_type`, `user_id`, `event_type`, `event_description`, `ip_address`, `user_agent`, `occurred_at`) VALUES
(1, 'SYSTEM_ADMIN', 1, 'LOGIN_FAILED', 'An unsuccessful sign-in attempt was recorded.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:48:58'),
(2, 'SYSTEM_ADMIN', 1, 'LOGIN_FAILED', 'An unsuccessful sign-in attempt was recorded.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:49:04'),
(3, 'SYSTEM_ADMIN', 1, 'LOGIN_FAILED', 'An unsuccessful sign-in attempt was recorded.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:49:32'),
(4, 'SYSTEM_ADMIN', 1, 'LOGIN_FAILED', 'An unsuccessful sign-in attempt was recorded.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:50:00'),
(5, 'SYSTEM_ADMIN', 1, 'LOGIN_SUCCESS', 'A successful sign-in was recorded.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:50:27'),
(6, 'SYSTEM_ADMIN', 1, 'OTHER_SESSIONS_REVOKED', 'All other active sessions were signed out.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:52:20'),
(7, 'SYSTEM_ADMIN', 1, 'PASSWORD_CHANGED', 'The account password was changed securely.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:52:20'),
(8, 'SYSTEM_ADMIN', 1, 'LOGIN_SUCCESS', 'A successful sign-in was recorded.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:52:35'),
(9, 'SYSTEM_ADMIN', 1, 'LOGIN_FAILED', 'An unsuccessful sign-in attempt was recorded.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:52:46'),
(10, 'UNIVERSITY_ADMIN', 1, 'LOGIN_SUCCESS', 'A successful sign-in was recorded.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:53:17'),
(11, 'UNIVERSITY_ADMIN', 1, 'OTHER_SESSIONS_REVOKED', 'All other active sessions were signed out.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:54:57'),
(12, 'UNIVERSITY_ADMIN', 1, 'PASSWORD_CHANGED', 'The account password was changed securely.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:54:57'),
(13, 'UNIVERSITY_ADMIN', 1, 'LOGIN_FAILED', 'An unsuccessful sign-in attempt was recorded.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:55:11'),
(14, 'UNIVERSITY_ADMIN', 1, 'LOGIN_FAILED', 'An unsuccessful sign-in attempt was recorded.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:55:13'),
(15, 'UNIVERSITY_ADMIN', 1, 'LOGIN_SUCCESS', 'A successful sign-in was recorded.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:55:19'),
(16, 'SYSTEM_ADMIN', 1, 'LOGIN_SUCCESS', 'A successful sign-in was recorded.', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-26 16:59:38');

-- --------------------------------------------------------

--
-- Table structure for table `user_sessions`
--

CREATE TABLE `user_sessions` (
  `session_record_id` bigint(20) UNSIGNED NOT NULL,
  `user_type` enum('PASSENGER','UNIVERSITY_ADMIN','SYSTEM_ADMIN') NOT NULL,
  `user_id` int(11) NOT NULL,
  `session_token_hash` char(64) NOT NULL,
  `user_agent` varchar(500) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `logged_in_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_activity_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `revoked_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_sessions`
--

INSERT INTO `user_sessions` (`session_record_id`, `user_type`, `user_id`, `session_token_hash`, `user_agent`, `ip_address`, `logged_in_at`, `last_activity_at`, `revoked_at`) VALUES
(1, 'PASSENGER', 2, 'eb0df4a3e4fc2d9ca28c233f9ee59588b1272ba301ed657b45307f46f39a7f01', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '::1', '2026-08-26 16:42:11', '2026-08-26 16:42:11', '2026-08-26 16:43:16'),
(2, 'SYSTEM_ADMIN', 1, 'f0173412b672f2f76f6e664b4970182aa062220ac2d146170219f19e40c8f4b3', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '::1', '2026-08-26 16:50:27', '2026-08-26 16:51:28', '2026-08-26 16:52:20'),
(3, 'SYSTEM_ADMIN', 1, 'bf2414bff76640eab022e7e455b63b183bce125bd00f7ddcc6787c21cfbf824a', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '::1', '2026-08-26 16:52:20', '2026-08-26 16:52:20', '2026-08-26 16:52:23'),
(4, 'SYSTEM_ADMIN', 1, '4d1953f2e4e9a8e62ec19eb3fc1f129f5dae7ed434be395f72b541f6f1252414', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '::1', '2026-08-26 16:52:35', '2026-08-26 16:52:35', '2026-08-26 16:52:38'),
(5, 'UNIVERSITY_ADMIN', 1, '4cf596dae3ea15ac1887b692dbce36e30b2c0d52abab9e4ea80a07dba11420cb', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '::1', '2026-08-26 16:53:17', '2026-08-26 16:54:34', '2026-08-26 16:54:57'),
(6, 'UNIVERSITY_ADMIN', 1, 'b7aa08570d805afb04ec7f8223aeff0b3e8213f7571bd5100712173228cf51a0', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '::1', '2026-08-26 16:54:57', '2026-08-26 16:54:57', '2026-08-26 16:55:02'),
(7, 'UNIVERSITY_ADMIN', 1, '962509380b7bb4aee7afa3519d27a15c5c8aa7c8e627c90d5d55323e264d09ce', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '::1', '2026-08-26 16:55:19', '2026-08-26 16:55:19', '2026-08-26 16:55:21'),
(8, 'SYSTEM_ADMIN', 1, '04c3894c1c7a072feeaa028bf161fee6cb6e15e4fe371779fb915b8d58369493', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '::1', '2026-08-26 16:59:38', '2026-08-26 16:59:38', NULL);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_passenger_booking_history`
-- (See below for the actual view)
--
CREATE TABLE `v_passenger_booking_history` (
`booking_id` int(11)
,`booking_reference` varchar(20)
,`passenger_id` int(11)
,`schedule_id` int(11)
,`slot_type` enum('SEAT','STANDING')
,`seat_number` int(11)
,`standing_slot` int(11)
,`seat_label` varchar(20)
,`fare_charged` decimal(10,2)
,`qr_token` varchar(100)
,`status` enum('BOOKED','CONFIRMED','CANCELLED','COMPLETED','TRANSFER_PENDING')
,`hidden_from_passenger` tinyint(1)
,`booking_date` timestamp
,`schedule_date` date
,`departure_time` time
,`arrival_time` time
,`route_name` varchar(200)
,`start_location` varchar(200)
,`end_location` varchar(200)
,`registration_number` varchar(50)
,`bus_type` enum('STANDARD','STUDENT_ONLY','FACULTY_ONLY')
,`university_name` varchar(200)
,`university_id` int(11)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_schedule_availability`
-- (See below for the actual view)
--
CREATE TABLE `v_schedule_availability` (
`schedule_id` int(11)
,`schedule_date` date
,`departure_time` time
,`arrival_time` time
,`schedule_status` enum('SCHEDULED','IN_PROGRESS','COMPLETED','CANCELLED')
,`route_id` int(11)
,`route_code` varchar(20)
,`route_name` varchar(200)
,`start_location` varchar(200)
,`end_location` varchar(200)
,`fare` decimal(10,2)
,`university_id` int(11)
,`university_name` varchar(200)
,`bus_id` int(11)
,`registration_number` varchar(50)
,`bus_type` enum('STANDARD','STUDENT_ONLY','FACULTY_ONLY')
,`seat_capacity` int(11)
,`standing_capacity` int(11)
,`booked_seats` decimal(22,0)
,`available_seats` decimal(23,0)
,`booked_standing` decimal(22,0)
,`available_standing` decimal(23,0)
,`seated_occupancy_percent` decimal(27,1)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_semester_transport_charges`
-- (See below for the actual view)
--
CREATE TABLE `v_semester_transport_charges` (
`bill_id` int(11)
,`passenger_id` int(11)
,`semester_id` int(11)
,`semester_name` varchar(100)
,`start_date` date
,`end_date` date
,`is_active` tinyint(1)
,`total_charges` decimal(10,2)
,`total_credits` decimal(10,2)
,`net_balance` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_university_dashboard_stats`
-- (See below for the actual view)
--
CREATE TABLE `v_university_dashboard_stats` (
`university_id` int(11)
,`total_buses` bigint(21)
,`active_buses` bigint(21)
,`total_routes` bigint(21)
,`active_routes` bigint(21)
,`total_passengers` bigint(21)
,`total_students` bigint(21)
,`total_faculty` bigint(21)
,`total_bookings` bigint(21)
,`active_bookings` bigint(21)
,`pending_complaints` bigint(21)
);

-- --------------------------------------------------------

--
-- Structure for view `v_passenger_booking_history`
--
DROP TABLE IF EXISTS `v_passenger_booking_history`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY INVOKER VIEW `v_passenger_booking_history`  AS SELECT `bk`.`booking_id` AS `booking_id`, `bk`.`booking_reference` AS `booking_reference`, `bk`.`passenger_id` AS `passenger_id`, `bk`.`schedule_id` AS `schedule_id`, `bk`.`slot_type` AS `slot_type`, `bk`.`seat_number` AS `seat_number`, `bk`.`standing_slot` AS `standing_slot`, CASE WHEN `bk`.`slot_type` = 'STANDING' THEN concat('Standing ',`bk`.`standing_slot`) WHEN `bk`.`seat_number` is null THEN NULL ELSE concat('Seat ',`bk`.`seat_number`) END AS `seat_label`, `bk`.`fare_charged` AS `fare_charged`, `bk`.`qr_token` AS `qr_token`, `bk`.`status` AS `status`, `bk`.`hidden_from_passenger` AS `hidden_from_passenger`, `bk`.`booking_date` AS `booking_date`, `s`.`schedule_date` AS `schedule_date`, `s`.`departure_time` AS `departure_time`, `s`.`arrival_time` AS `arrival_time`, `r`.`route_name` AS `route_name`, `r`.`start_location` AS `start_location`, `r`.`end_location` AS `end_location`, `b`.`registration_number` AS `registration_number`, `b`.`bus_type` AS `bus_type`, `u`.`name` AS `university_name`, `u`.`university_id` AS `university_id` FROM ((((`bookings` `bk` join `schedules` `s` on(`s`.`schedule_id` = `bk`.`schedule_id`)) join `routes` `r` on(`r`.`route_id` = `s`.`route_id`)) join `buses` `b` on(`b`.`bus_id` = `s`.`bus_id`)) join `universities` `u` on(`u`.`university_id` = `r`.`university_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_schedule_availability`
--
DROP TABLE IF EXISTS `v_schedule_availability`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY INVOKER VIEW `v_schedule_availability`  AS SELECT `s`.`schedule_id` AS `schedule_id`, `s`.`schedule_date` AS `schedule_date`, `s`.`departure_time` AS `departure_time`, `s`.`arrival_time` AS `arrival_time`, `s`.`status` AS `schedule_status`, `r`.`route_id` AS `route_id`, `r`.`route_code` AS `route_code`, `r`.`route_name` AS `route_name`, `r`.`start_location` AS `start_location`, `r`.`end_location` AS `end_location`, `r`.`fare` AS `fare`, `u`.`university_id` AS `university_id`, `u`.`name` AS `university_name`, `b`.`bus_id` AS `bus_id`, `b`.`registration_number` AS `registration_number`, `b`.`bus_type` AS `bus_type`, `b`.`seat_capacity` AS `seat_capacity`, `b`.`standing_capacity` AS `standing_capacity`, sum(case when `bk`.`slot_type` = 'SEAT' and `bk`.`status` in ('BOOKED','CONFIRMED','TRANSFER_PENDING') then 1 else 0 end) AS `booked_seats`, greatest(`b`.`seat_capacity` - sum(case when `bk`.`slot_type` = 'SEAT' and `bk`.`status` in ('BOOKED','CONFIRMED','TRANSFER_PENDING') then 1 else 0 end),0) AS `available_seats`, sum(case when `bk`.`slot_type` = 'STANDING' and `bk`.`status` in ('BOOKED','CONFIRMED','TRANSFER_PENDING') then 1 else 0 end) AS `booked_standing`, greatest(`b`.`standing_capacity` - sum(case when `bk`.`slot_type` = 'STANDING' and `bk`.`status` in ('BOOKED','CONFIRMED','TRANSFER_PENDING') then 1 else 0 end),0) AS `available_standing`, round(100 * sum(case when `bk`.`slot_type` = 'SEAT' and `bk`.`status` in ('BOOKED','CONFIRMED','TRANSFER_PENDING') then 1 else 0 end) / nullif(`b`.`seat_capacity`,0),1) AS `seated_occupancy_percent` FROM ((((`schedules` `s` join `routes` `r` on(`r`.`route_id` = `s`.`route_id`)) join `buses` `b` on(`b`.`bus_id` = `s`.`bus_id`)) join `universities` `u` on(`u`.`university_id` = `r`.`university_id`)) left join `bookings` `bk` on(`bk`.`schedule_id` = `s`.`schedule_id`)) GROUP BY `s`.`schedule_id`, `s`.`schedule_date`, `s`.`departure_time`, `s`.`arrival_time`, `s`.`status`, `r`.`route_id`, `r`.`route_code`, `r`.`route_name`, `r`.`start_location`, `r`.`end_location`, `r`.`fare`, `u`.`university_id`, `u`.`name`, `b`.`bus_id`, `b`.`registration_number`, `b`.`bus_type`, `b`.`seat_capacity`, `b`.`standing_capacity` ;

-- --------------------------------------------------------

--
-- Structure for view `v_semester_transport_charges`
--
DROP TABLE IF EXISTS `v_semester_transport_charges`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY INVOKER VIEW `v_semester_transport_charges`  AS SELECT `sb`.`bill_id` AS `bill_id`, `sb`.`passenger_id` AS `passenger_id`, `sb`.`semester_id` AS `semester_id`, `sem`.`semester_name` AS `semester_name`, `sem`.`start_date` AS `start_date`, `sem`.`end_date` AS `end_date`, `sem`.`is_active` AS `is_active`, `sb`.`total_charges` AS `total_charges`, `sb`.`total_credits` AS `total_credits`, `sb`.`net_balance` AS `net_balance` FROM (`semester_bills` `sb` join `semesters` `sem` on(`sem`.`semester_id` = `sb`.`semester_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_university_dashboard_stats`
--
DROP TABLE IF EXISTS `v_university_dashboard_stats`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY INVOKER VIEW `v_university_dashboard_stats`  AS SELECT `u`.`university_id` AS `university_id`, (select count(0) from `buses` `b` where `b`.`university_id` = `u`.`university_id`) AS `total_buses`, (select count(0) from `buses` `b` where `b`.`university_id` = `u`.`university_id` and `b`.`status` = 'ACTIVE') AS `active_buses`, (select count(0) from `routes` `r` where `r`.`university_id` = `u`.`university_id`) AS `total_routes`, (select count(0) from `routes` `r` where `r`.`university_id` = `u`.`university_id` and `r`.`status` = 'ACTIVE') AS `active_routes`, (select count(0) from `passengers` `p` where `p`.`university_id` = `u`.`university_id`) AS `total_passengers`, (select count(0) from `passengers` `p` where `p`.`university_id` = `u`.`university_id` and `p`.`passenger_type` = 'STUDENT') AS `total_students`, (select count(0) from `passengers` `p` where `p`.`university_id` = `u`.`university_id` and `p`.`passenger_type` = 'FACULTY') AS `total_faculty`, (select count(0) from (`bookings` `bk` join `passengers` `p` on(`p`.`passenger_id` = `bk`.`passenger_id`)) where `p`.`university_id` = `u`.`university_id`) AS `total_bookings`, (select count(0) from (`bookings` `bk` join `passengers` `p` on(`p`.`passenger_id` = `bk`.`passenger_id`)) where `p`.`university_id` = `u`.`university_id` and `bk`.`status` in ('BOOKED','CONFIRMED','TRANSFER_PENDING')) AS `active_bookings`, (select count(0) from `complaints` `c` where `c`.`university_id` = `u`.`university_id` and `c`.`status` in ('OPEN','IN_PROGRESS')) AS `pending_complaints` FROM `universities` AS `u` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admins`
--
ALTER TABLE `admins`
  ADD PRIMARY KEY (`admin_id`),
  ADD UNIQUE KEY `uk_admin_email` (`email`);

--
-- Indexes for table `billing_transactions`
--
ALTER TABLE `billing_transactions`
  ADD PRIMARY KEY (`transaction_id`),
  ADD KEY `idx_billing_passenger` (`passenger_id`),
  ADD KEY `idx_billing_semester` (`semester_id`),
  ADD KEY `idx_billing_booking` (`booking_id`);

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`booking_id`),
  ADD UNIQUE KEY `uk_booking_reference` (`booking_reference`),
  ADD UNIQUE KEY `uk_booking_qr_token` (`qr_token`),
  ADD KEY `idx_booking_passenger` (`passenger_id`),
  ADD KEY `idx_booking_schedule` (`schedule_id`);

--
-- Indexes for table `booking_status_history`
--
ALTER TABLE `booking_status_history`
  ADD PRIMARY KEY (`history_id`),
  ADD KEY `idx_history_booking` (`booking_id`);

--
-- Indexes for table `buses`
--
ALTER TABLE `buses`
  ADD PRIMARY KEY (`bus_id`),
  ADD UNIQUE KEY `uk_bus_registration` (`university_id`,`registration_number`);

--
-- Indexes for table `bus_route_assignments`
--
ALTER TABLE `bus_route_assignments`
  ADD PRIMARY KEY (`assignment_id`),
  ADD UNIQUE KEY `uk_bus_route` (`bus_id`,`route_id`),
  ADD KEY `idx_assignment_route` (`route_id`);

--
-- Indexes for table `complaints`
--
ALTER TABLE `complaints`
  ADD PRIMARY KEY (`complaint_id`),
  ADD KEY `idx_complaint_passenger` (`passenger_id`),
  ADD KEY `idx_complaint_university` (`university_id`);

--
-- Indexes for table `faculty`
--
ALTER TABLE `faculty`
  ADD PRIMARY KEY (`faculty_id`),
  ADD UNIQUE KEY `uk_faculty_passenger` (`passenger_id`);

--
-- Indexes for table `favorite_routes`
--
ALTER TABLE `favorite_routes`
  ADD PRIMARY KEY (`favorite_id`),
  ADD UNIQUE KEY `uk_favorite_route` (`passenger_id`,`route_id`),
  ADD KEY `idx_favorite_route` (`route_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `idx_notification_passenger_read` (`passenger_id`,`is_read`);

--
-- Indexes for table `passengers`
--
ALTER TABLE `passengers`
  ADD PRIMARY KEY (`passenger_id`),
  ADD UNIQUE KEY `uk_passenger_email` (`email`),
  ADD KEY `idx_passenger_university` (`university_id`);

--
-- Indexes for table `routes`
--
ALTER TABLE `routes`
  ADD PRIMARY KEY (`route_id`),
  ADD UNIQUE KEY `uk_route_code` (`university_id`,`route_code`);

--
-- Indexes for table `schedules`
--
ALTER TABLE `schedules`
  ADD PRIMARY KEY (`schedule_id`),
  ADD KEY `idx_schedule_date_time` (`schedule_date`,`departure_time`),
  ADD KEY `idx_schedule_route` (`route_id`),
  ADD KEY `idx_schedule_bus` (`bus_id`);

--
-- Indexes for table `semesters`
--
ALTER TABLE `semesters`
  ADD PRIMARY KEY (`semester_id`);

--
-- Indexes for table `semester_bills`
--
ALTER TABLE `semester_bills`
  ADD PRIMARY KEY (`bill_id`),
  ADD UNIQUE KEY `uk_passenger_semester` (`passenger_id`,`semester_id`),
  ADD KEY `idx_bill_semester` (`semester_id`);

--
-- Indexes for table `students`
--
ALTER TABLE `students`
  ADD PRIMARY KEY (`student_id`),
  ADD UNIQUE KEY `uk_student_passenger` (`passenger_id`);

--
-- Indexes for table `universities`
--
ALTER TABLE `universities`
  ADD PRIMARY KEY (`university_id`),
  ADD UNIQUE KEY `uk_university_code` (`code`);

--
-- Indexes for table `university_users`
--
ALTER TABLE `university_users`
  ADD PRIMARY KEY (`university_user_id`),
  ADD UNIQUE KEY `uk_university_user_email` (`email`),
  ADD KEY `idx_university_user_university` (`university_id`);

--
-- Indexes for table `user_notification_preferences`
--
ALTER TABLE `user_notification_preferences`
  ADD PRIMARY KEY (`preference_id`),
  ADD UNIQUE KEY `uq_notification_preference` (`user_type`,`user_id`,`preference_key`),
  ADD KEY `idx_notification_identity` (`user_type`,`user_id`);

--
-- Indexes for table `user_profiles`
--
ALTER TABLE `user_profiles`
  ADD PRIMARY KEY (`profile_id`),
  ADD UNIQUE KEY `uq_user_profiles_identity` (`user_type`,`user_id`),
  ADD KEY `idx_user_profiles_updated` (`updated_at`);

--
-- Indexes for table `user_security_events`
--
ALTER TABLE `user_security_events`
  ADD PRIMARY KEY (`security_event_id`),
  ADD KEY `idx_security_identity_time` (`user_type`,`user_id`,`occurred_at`),
  ADD KEY `idx_security_event_time` (`event_type`,`occurred_at`);

--
-- Indexes for table `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD PRIMARY KEY (`session_record_id`),
  ADD UNIQUE KEY `uq_session_token_hash` (`session_token_hash`),
  ADD KEY `idx_session_identity_active` (`user_type`,`user_id`,`revoked_at`),
  ADD KEY `idx_session_activity` (`last_activity_at`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admins`
--
ALTER TABLE `admins`
  MODIFY `admin_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `billing_transactions`
--
ALTER TABLE `billing_transactions`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `booking_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=81;

--
-- AUTO_INCREMENT for table `booking_status_history`
--
ALTER TABLE `booking_status_history`
  MODIFY `history_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT for table `buses`
--
ALTER TABLE `buses`
  MODIFY `bus_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `bus_route_assignments`
--
ALTER TABLE `bus_route_assignments`
  MODIFY `assignment_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `complaints`
--
ALTER TABLE `complaints`
  MODIFY `complaint_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `faculty`
--
ALTER TABLE `faculty`
  MODIFY `faculty_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `favorite_routes`
--
ALTER TABLE `favorite_routes`
  MODIFY `favorite_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notification_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `passengers`
--
ALTER TABLE `passengers`
  MODIFY `passenger_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=161;

--
-- AUTO_INCREMENT for table `routes`
--
ALTER TABLE `routes`
  MODIFY `route_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `schedules`
--
ALTER TABLE `schedules`
  MODIFY `schedule_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `semesters`
--
ALTER TABLE `semesters`
  MODIFY `semester_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `semester_bills`
--
ALTER TABLE `semester_bills`
  MODIFY `bill_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `students`
--
ALTER TABLE `students`
  MODIFY `student_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=157;

--
-- AUTO_INCREMENT for table `universities`
--
ALTER TABLE `universities`
  MODIFY `university_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `university_users`
--
ALTER TABLE `university_users`
  MODIFY `university_user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `user_notification_preferences`
--
ALTER TABLE `user_notification_preferences`
  MODIFY `preference_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3619;

--
-- AUTO_INCREMENT for table `user_profiles`
--
ALTER TABLE `user_profiles`
  MODIFY `profile_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=268;

--
-- AUTO_INCREMENT for table `user_security_events`
--
ALTER TABLE `user_security_events`
  MODIFY `security_event_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `user_sessions`
--
ALTER TABLE `user_sessions`
  MODIFY `session_record_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `billing_transactions`
--
ALTER TABLE `billing_transactions`
  ADD CONSTRAINT `fk_billing_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_billing_passenger` FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_billing_semester` FOREIGN KEY (`semester_id`) REFERENCES `semesters` (`semester_id`) ON UPDATE CASCADE;

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `fk_booking_passenger` FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_booking_schedule` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`schedule_id`) ON UPDATE CASCADE;

--
-- Constraints for table `booking_status_history`
--
ALTER TABLE `booking_status_history`
  ADD CONSTRAINT `fk_history_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `buses`
--
ALTER TABLE `buses`
  ADD CONSTRAINT `fk_bus_university` FOREIGN KEY (`university_id`) REFERENCES `universities` (`university_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `bus_route_assignments`
--
ALTER TABLE `bus_route_assignments`
  ADD CONSTRAINT `fk_assignment_bus` FOREIGN KEY (`bus_id`) REFERENCES `buses` (`bus_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_assignment_route` FOREIGN KEY (`route_id`) REFERENCES `routes` (`route_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `complaints`
--
ALTER TABLE `complaints`
  ADD CONSTRAINT `fk_complaint_passenger` FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_complaint_university` FOREIGN KEY (`university_id`) REFERENCES `universities` (`university_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `faculty`
--
ALTER TABLE `faculty`
  ADD CONSTRAINT `fk_faculty_passenger` FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `favorite_routes`
--
ALTER TABLE `favorite_routes`
  ADD CONSTRAINT `fk_favorite_passenger` FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_favorite_route` FOREIGN KEY (`route_id`) REFERENCES `routes` (`route_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notification_passenger` FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `passengers`
--
ALTER TABLE `passengers`
  ADD CONSTRAINT `fk_passenger_university` FOREIGN KEY (`university_id`) REFERENCES `universities` (`university_id`) ON UPDATE CASCADE;

--
-- Constraints for table `routes`
--
ALTER TABLE `routes`
  ADD CONSTRAINT `fk_route_university` FOREIGN KEY (`university_id`) REFERENCES `universities` (`university_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `schedules`
--
ALTER TABLE `schedules`
  ADD CONSTRAINT `fk_schedule_bus` FOREIGN KEY (`bus_id`) REFERENCES `buses` (`bus_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_schedule_route` FOREIGN KEY (`route_id`) REFERENCES `routes` (`route_id`) ON UPDATE CASCADE;

--
-- Constraints for table `semester_bills`
--
ALTER TABLE `semester_bills`
  ADD CONSTRAINT `fk_bill_passenger` FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_bill_semester` FOREIGN KEY (`semester_id`) REFERENCES `semesters` (`semester_id`) ON UPDATE CASCADE;

--
-- Constraints for table `students`
--
ALTER TABLE `students`
  ADD CONSTRAINT `fk_student_passenger` FOREIGN KEY (`passenger_id`) REFERENCES `passengers` (`passenger_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `university_users`
--
ALTER TABLE `university_users`
  ADD CONSTRAINT `fk_university_user_university` FOREIGN KEY (`university_id`) REFERENCES `universities` (`university_id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
