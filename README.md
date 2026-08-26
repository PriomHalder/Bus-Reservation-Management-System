# UniRide — Multi-University Bus Ticket Booking System

UniRide is a full-stack, database-driven university transport management and bus ticket booking system built as a university database course project.

The platform is designed as a **multi-university system**, where a central System Administrator can manage participating universities, while each university manages its own buses, routes, schedules, passengers, complaints, and transport operations.

The current project is configured to use the MySQL database:

```text
uniride2
```

---

## Project Overview

UniRide provides a single platform for university transport systems.

The system supports three major user roles:

- **Passenger**
  - Student
  - Faculty
- **University Administrator**
- **System Administrator**

Students and Faculty share the Passenger login system, while their passenger type is stored separately in the database.

Each passenger belongs to exactly one university, and universities manage their own transport-related data.

---

## Main Features

### Passenger Features

Passengers can:

- Log in using their academic account
- View available university bus routes
- Search and filter routes
- View route schedules
- View bus and trip information
- Book bus tickets
- Select available seats
- View booking history
- Receive booking-related notifications
- Mark favorite routes
- Submit complaints
- Transfer or share eligible tickets
- Cancel eligible bookings
- View semester transport billing
- Reset forgotten passwords

Passenger accounts are divided into:

```text
STUDENT
FACULTY
```

A Passenger can only belong to one subtype.

---

### University Administrator Features

Each participating university has its own transport administrator.

University Administrators can manage data belonging only to their university, including:

- Passengers
- Students
- Faculty
- Buses
- Routes
- Route stops
- Bus-route assignments
- Schedules
- Complaints
- Transport-related records

The application keeps university data isolated using `university_id`.

---

### System Administrator Features

The central System Administrator controls the overall UniRide platform.

The System Administrator can:

- Manage participating universities
- Add universities to the platform
- Remove or deactivate universities
- View platform-wide information
- Monitor university records
- Access system-level statistics

Universities are added to UniRide only after being approved by the central administrator.

---

## Database Design

UniRide is designed to demonstrate important DBMS concepts.

### Main Entities

```text
admins
universities
university_users

passengers
students
faculty

buses
routes
route_stops
bus_route_assignments

schedules

bookings
booking_status_history

favorite_routes
complaints
ticket_transfers
notifications

semesters
semester_bills
billing_transactions

password_reset_tokens
```

The exact table set may evolve as the project is extended.

---

## Important Database Relationships

### University — Passenger

```text
University 1 ───── N Passenger
```

Each Passenger belongs to exactly one university.

---

### University — Bus

```text
University 1 ───── N Bus
```

A university can own multiple buses.

A bus belongs to one university.

---

### Passenger Superclass

```text
              Passenger
              /       \
         Student     Faculty
```

Passenger is implemented as a superclass.

Student and Faculty are **disjoint subtypes**.

A passenger cannot be both Student and Faculty.

---

### University — Route

```text
University 1 ───── N Route
```

Each university manages its own transport routes.

---

### Route — Schedule

```text
Route 1 ───── N Schedule
```

One route can have multiple schedules.

---

### Schedule — Booking

```text
Schedule 1 ───── N Booking
```

A schedule can contain many passenger bookings.

---

### Passenger — Favorite Route

```text
Passenger N ───── M Route
```

Passengers can favorite multiple routes, and a route can be favorited by multiple passengers.

This relationship is implemented using a junction table.

---

### Passenger — Complaint

```text
Passenger 1 ───── N Complaint
```

One passenger can submit multiple complaints.

Complaints are also associated with the passenger's university.

---

## Technology Stack

### Frontend

- HTML5
- CSS3
- Vanilla JavaScript

### Backend

- PHP
- PHP Sessions
- PDO

### Database

- MySQL / MariaDB
- phpMyAdmin

### Local Development

- XAMPP
- Apache
- MySQL / MariaDB

---

## UI Design

The UniRide interface uses a minimal, modern visual style with:

- Large editorial-style headings
- Generous whitespace
- Soft neutral backgrounds
- Compact navigation
- Rounded route and feature cards
- Light borders
- Minimal shadows
- Responsive layouts
- Search and filter controls

The design is intended to stay simple while keeping the transport information easy to scan.

---

## Project Folder Structure

A typical project structure is:

```text
uniride/
│
├── css/
│   └── style.css
│
├── img/
│   └── logo.svg
│
├── js/
│   └── app.js
│
├── config/
│   └── database.php
│
├── includes/
│   └── auth.php
│
├── database/
│   └── password_reset_tokens.sql
│
├── index.php
├── signin.php
├── dashboard.php
├── forgot-password.php
├── reset-password.php
├── logout.php
└── README.md
```

Additional booking, schedule, route, passenger, university-admin, and system-admin modules can be organized into separate folders as the project grows.

---

## Database Configuration

The current project uses:

```text
Database Name: uniride2
Host: 127.0.0.1
Port: 3306
```

Default XAMPP configuration:

```text
Username: root
Password: empty
```

Database settings can be changed in:

```text
config/database.php
```

Example:

```php
$dbHost = '127.0.0.1';
$dbPort = '3306';
$dbName = 'uniride2';
$dbUser = 'root';
$dbPass = '';
```

Do not commit real production database passwords to GitHub.

---

## Installation

### 1. Install XAMPP

Install XAMPP and make sure the following services are available:

```text
Apache
MySQL
```

---

### 2. Clone the Repository

```bash
git clone <your-repository-url>
```

Move or clone the repository into:

```text
C:\xampp\htdocs\uniride
```

---

### 3. Start XAMPP

Open the XAMPP Control Panel and start:

```text
Apache
MySQL
```

---

### 4. Create the Database

Open phpMyAdmin:

```text
http://localhost/phpmyadmin
```

Create or import the project database as:

```text
uniride2
```

Make sure all UniRide tables are inside this database.

---

### 5. Import Password Reset Support

Select the `uniride2` database in phpMyAdmin and import:

```text
database/password_reset_tokens.sql
```

This creates the table required for password reset functionality.

---

### 6. Configure the Database Connection

Open:

```text
config/database.php
```

Confirm that the connection points to:

```text
uniride2
```

---

### 7. Run the Website

Open:

```text
http://localhost/uniride/
```

---

## Authentication System

UniRide uses database-backed authentication.

There are no hard-coded login accounts in the PHP login logic.

### Passenger Login

Passenger authentication uses:

```text
passengers
```

Password field:

```text
password_hash
```

Both Students and Faculty log in using the Passenger tab.

---

### University Admin Login

University Administrator authentication uses:

```text
university_users
```

Password field:

```text
password_hash
```

---

### System Admin Login

System Administrator authentication uses:

```text
admins
```

In the current database schema, the hashed password is stored in:

```text
password
```

---

## Password Security

Passwords are never intended to be stored as plain text.

PHP password hashing is used:

```php
password_hash($password, PASSWORD_DEFAULT);
```

Authentication uses:

```php
password_verify($password, $storedHash);
```

The login system also uses:

- PDO prepared statements
- PHP sessions
- Session regeneration after login
- CSRF tokens
- Role-based authentication
- Generic invalid-login messages

---

## Forgot Password / Reset Password

UniRide includes a password reset workflow.

The application uses:

```text
password_reset_tokens
```

Reset tokens are:

- Cryptographically generated
- Stored as hashes
- Time-limited
- Single-use

For local XAMPP development, the reset URL can be displayed directly after a valid reset request.

In a production deployment, the reset URL should instead be delivered through a configured email service.

---

## Multi-University Data Isolation

University-specific users must only be able to access data belonging to their own university.

For example:

```sql
SELECT *
FROM buses
WHERE university_id = ?;
```

The university identifier should come from the authenticated PHP session rather than from an untrusted URL parameter.

This isolation should be applied to:

- Buses
- Routes
- Schedules
- Passengers
- Complaints
- Bookings
- Billing
- Other university-owned records

---

## Bus Information

Each bus belongs to a university.

Bus information may include:

- Registration Number
- Tax Number
- Seat Capacity
- Standing Capacity
- Bus Type
- Status

Bus type can be used to control passenger eligibility.

Examples:

```text
STUDENT_ONLY
FACULTY_ONLY
STANDARD
```

---

## Booking System

A booking connects a Passenger with a particular Schedule.

Typical booking information includes:

- Booking ID
- Passenger ID
- Schedule ID
- Booking Date
- Seat Number
- Status
- Fare
- QR token/reference

Booking status can be used for states such as:

```text
BOOKED
CONFIRMED
CANCELLED
TRANSFER_PENDING
```

The exact values should match the database schema used by the application.

---

## Semester Billing

Valid transport bookings can contribute to a passenger's semester transport bill.

Relevant data can include:

```text
semesters
semester_bills
billing_transactions
```

This allows UniRide to keep transport charges connected to the passenger and academic semester.

---

## Ticket Transfer

Passengers can transfer eligible tickets to another compatible passenger.

Important checks include:

- Same university
- Eligible passenger type
- Valid booking
- Valid schedule
- Transfer status
- No conflicting active ticket

Transfer records are stored in:

```text
ticket_transfers
```

---

## Complaints

Passengers can submit complaints related to transport services.

A complaint is associated with:

- Passenger
- University
- Subject
- Description
- Status

Example statuses:

```text
OPEN
IN_PROGRESS
RESOLVED
```

---

## Favorite Routes

Passengers can save frequently used routes.

The many-to-many relationship between Passenger and Route is stored using:

```text
favorite_routes
```

---

## Notifications

The application can generate notifications for events such as:

- Successful booking
- Booking cancellation
- Ticket transfer
- Complaint update
- Schedule change
- System message

Notifications should be stored in the database rather than being hard-coded in JavaScript.

---

## Sample / Seed Data

The development database contains synthetic sample information used to demonstrate the system.

This can include:

- BRAC University students
- North South University students
- AIUB students
- Faculty accounts
- University administrators
- System administrator
- Buses
- Routes
- Schedules
- Complaints
- Favorites
- Other demo records

The sample student and faculty records are intended for academic demonstration only.

They should not be treated as real university user records.

---

## Universities Included in the Demo

The current demo project includes:

```text
BRAC University
North South University
American International University-Bangladesh (AIUB)
```

The architecture is designed so additional universities can be added later.

---

## Course Concepts Demonstrated

This project demonstrates concepts such as:

- Entity-Relationship Modeling
- Strong and Weak Entities
- Composite Attributes
- Superclass / Subclass
- Disjoint Specialization
- One-to-Many Relationships
- Many-to-Many Relationships
- Junction Tables
- Primary Keys
- Foreign Keys
- Unique Constraints
- Referential Integrity
- Normalization
- Transactions
- Stored Procedures / Triggers where applicable
- Authentication
- Role-Based Access Control
- Database-backed CRUD operations

---

## Future Improvements

Possible future improvements include:

- Full online payment integration
- Real email password-reset delivery
- University onboarding workflow
- Live bus GPS tracking
- Push notifications
- QR validation by transport staff
- Dynamic seat-map layouts
- Mobile application
- Advanced transport analytics
- University branding customization
- Route maps
- Real-time delay updates
- Automated schedule generation
- Driver and transport-staff accounts

---

## Academic Purpose

UniRide was developed as a database course project to demonstrate how a relational database can support a real-world multi-user transportation platform.

The project focuses on combining:

```text
Database Design
+
Backend Logic
+
Authentication
+
Role-Based Access
+
Transport Management
+
Ticket Booking
```

into one integrated system.

---

## Security Notice

This repository is intended for development and academic demonstration.

Before deploying publicly:

- Replace all development credentials
- Configure a dedicated MySQL user
- Disable local reset-link display
- Configure SMTP/email delivery
- Use HTTPS
- Secure PHP session cookies
- Remove diagnostic/development files
- Disable PHP error display
- Store secrets outside the repository
- Review authorization rules
- Back up the database

---

## License

This project is intended primarily for academic and educational use.

Add the license required by your university, course, or repository before public distribution.

---

## Author

Developed as a university database course project.

Project:

```text
UniRide
Multi-University Bus Ticket Booking & Transport Management System
```
