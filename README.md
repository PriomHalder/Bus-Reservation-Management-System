# UniRide — Multi-University Bus Ticket Management System

A complete PHP/MySQL web application for university bus seat booking, schedule management, and transport administration, built for local deployment on XAMPP.

---

## Features

- **Multi-University Support**: Multi-tenant data isolation for BRAC University (BRACU), North South University (NSU), and American International University-Bangladesh (AIUB).
- **Professional Academic Email Architecture**:
  - Students: `firstname.lastname@g.universityinitial.ac.bd`
  - Faculty: `firstname.lastname@g.universityinitial.ac.bd`
  - University Transport Admins: `<university>.transport@gmail.com`
  - Central System Admin: `uniride.admin@gmail.com`
- **3-Role Authentication**: System Admin, University Admin, Passenger (Student & Faculty superclass model).
- **Interactive 40-Seat Bus Map**: Real-time availability with 10 rows × 4 columns (`A1`–`J4`) coordinate system.
- **Standing Slot Booking**: 10 standing slots (`ST1`–`ST10`) automatically unlocked when all seated spots are booked.
- **Digital Boarding Pass with QR Codes**: Live QR generation from `qr_token` with 1-click PNG download.
- **Student Ticket Transfer & Sale**: Peer-to-peer sharing and credit sale via stored procedures with account balance adjustments.
- **Semester Transport Billing**: Automatic charge/credit tracking per booking linked with academic terms.
- **Support & Complaint System**: Passenger dispute filing with university admin responses and auto-notifications.
- **Real-Time Notification Center**: Bell popover with 30-second AJAX polling and bulk mark-as-read.
- **Favorite Routes**: Priority route pinning on passenger dashboard.
- **Automated Academic Email Suggestion**: Auto-formats `@g.<domain>.ac.bd` addresses when admins register new passengers.
- **Security**: Strict CSRF protection, PDO prepared statements, and bcrypt password hashing.

---

## How to Run & Verify

1. **Start Apache and MySQL** in XAMPP.

2. **Copy the `uniride` folder** to:
   ```
   C:\xampp\htdocs\uniride
   ```

3. **Open phpMyAdmin**:
   ```
   http://localhost/phpmyadmin/
   ```

4. **Import the database**:
   - Click the **Import** tab
   - Choose file: `database/uniride_complete_phpmyadmin.sql`
   - Click **Go**

5. **Access the application**:
   ```
   http://localhost/uniride/
   ```

---

## Demo Login Accounts

All demonstration accounts use the password: **`password`**

| Role / University | Name | Email Address | Password |
|---|---|---|---|
| **System Admin** | UniRide System Admin | `uniride.admin@gmail.com` | `password` |
| **BRACU University Admin** | BRACU Transport Admin | `bracu.transport@gmail.com` | `password` |
| **NSU University Admin** | NSU Transport Admin | `nsu.transport@gmail.com` | `password` |
| **AIUB University Admin** | AIUB Transport Admin | `aiub.transport@gmail.com` | `password` |
| **Student — BRACU** | Samiha Tasnim | `samiha.tasnim@g.bracu.ac.bd` | `password` |
| **Student — BRACU** | Samir Hossain | `samir.hossain@g.bracu.ac.bd` | `password` |
| **Faculty — BRACU** | Dr. Kamal Uddin | `kamal.uddin@g.bracu.ac.bd` | `password` |
| **Student — NSU** | Rafi Hasan | `rafi.hasan@g.nsu.ac.bd` | `password` |
| **Faculty — NSU** | Dr. Samira Ahmed | `samira.ahmed@g.nsu.ac.bd` | `password` |
| **Student — AIUB** | Tahmid Islam | `tahmid.islam@g.aiub.ac.bd` | `password` |
| **Faculty — AIUB** | Farhana Noor | `farhana.noor@g.aiub.ac.bd` | `password` |

---

## Project Structure

```
uniride/
├── database/
│   └── uniride_complete_phpmyadmin.sql   # Complete DB schema + seed data (19 tables, 4 views, 6 SPs, 1 fn)
├── config/
│   ├── database.php                       # UTF-8 (utf8mb4) PDO connection
│   ├── session.php                        # Secure session + CSRF token generation
│   └── functions.php                      # CSRF verification, email validation, role guards
├── includes/
│   ├── header.php                         # Role-aware sidebar navigation + notification bell
│   └── footer.php                         # Global scripts, CSRF injection, and footer
├── auth/
│   ├── login.php                          # Multi-role login with quick-fill demo pills
│   └── logout.php                         # Session destruction
├── passenger/
│   ├── dashboard.php                      # Schedules, occupancy bar, favorites priority
│   ├── book-seat.php                      # Interactive 40-seat coach map & standing slots
│   ├── booking-confirmation.php           # Boarding pass with QR code generation & download
│   ├── my-bookings.php                    # Active bookings, ticket cancellation & history
│   ├── transfer-ticket.php                # Student-to-student free share or balance sale
│   ├── pending-transfers.php              # Accept/reject incoming transfer requests
│   ├── complaints.php                     # Passenger complaints & university replies
│   ├── notifications.php                  # Notification center with mark-all-read
│   ├── billing.php                        # Semester charges & itemized transaction ledger
│   └── profile.php                        # Personal info, avatar upload, password reset
├── university/
│   ├── dashboard.php                      # Stats from v_university_dashboard_stats
│   ├── buses.php                          # Bus fleet CRUD with university isolation
│   ├── routes.php                         # Route catalog CRUD with university isolation
│   ├── bus-routes.php                     # Bus-to-route assignment management
│   ├── schedules.php                      # Scheduled trips CRUD
│   ├── passengers.php                     # Passenger roster & academic email auto-suggest
│   ├── complaints.php                     # Manage & respond to student complaints
│   └── bookings.php                       # Comprehensive bookings ledger
├── admin/
│   ├── dashboard.php                      # Global system overview across all universities
│   ├── universities.php                   # University tenant management (with academic domains)
│   ├── university-users.php               # University transport administrator credentials
│   └── semesters.php                      # Academic semester management & term activation
├── api/
│   ├── get-schedules.php                  # Schedule list (JSON)
│   ├── get-seat-availability.php          # Real-time booked seat matrix (JSON)
│   ├── create-booking.php                 # Calls sp_create_booking()
│   ├── cancel-booking.php                 # Calls sp_cancel_booking()
│   ├── toggle-favorite.php                # Add/remove favorite route
│   ├── get-notifications.php              # Notification list & unread count
│   ├── mark-notification-read.php         # Calls sp_mark_all_notifications_read()
│   ├── request-transfer.php               # Calls sp_request_ticket_transfer()
│   ├── respond-transfer.php               # Calls sp_respond_ticket_transfer()
│   └── archive-booking.php                # Calls sp_archive_booking_history()
├── assets/
│   ├── css/style.css                      # Design system (Deep Blue #00308F, Tuscan #D4A27A)
│   ├── js/app.js                          # Fetch wrapper with CSRF injection & toast system
│   ├── js/seat-map.js                     # 40-seat interactive grid & standing slots logic
│   ├── js/notifications.js                # Notification bell with 30s AJAX polling
│   └── uploads/avatars/                   # Avatar file storage
├── index.php                              # Entry router based on session role
├── .htaccess                              # Access security rules
└── README.md                              # Installation guide & demo credentials
```

---

## Database Architecture (`uniride_db`)

### Stored Procedures
| Procedure | Description |
|---|---|
| `sp_create_booking()` | Handles atomic seat/standing reservation, bus restrictions, billing charges, and notification. |
| `sp_cancel_booking()` | Handles ticket cancellation, seat release, cancellation credit, and notification. |
| `sp_archive_booking_history()` | Soft-hides completed/cancelled trips from passenger view. |
| `sp_request_ticket_transfer()` | Initiates same-university, same-role ticket transfers. |
| `sp_respond_ticket_transfer()` | Reassigns ticket ownership, processes balance transactions for sales, or rejects. |
| `sp_mark_all_notifications_read()` | Marks unread notifications as read in bulk. |

### Database Views
| View | Description |
|---|---|
| `v_schedule_availability` | Calculates booked/available seats, standing slots, and occupancy percentage. |
| `v_passenger_booking_history` | Joins bookings with schedules, routes, buses, and computed seat labels. |
| `v_university_dashboard_stats` | Real-time aggregated university metrics (buses, routes, passengers, bookings). |
| `v_semester_transport_charges` | Computes semester charges, credits, and net balances. |

### SQL Function
| Function | Description |
|---|---|
| `fn_seat_label(seat_number)` | Converts numeric index `1`–`40` to coach coordinates (`A1`–`J4`). |

---

## Technology Stack

- **Backend**: PHP 8.x with PDO (Prepared Statements, Transactions)
- **Database**: MySQL 8.x / MariaDB (`utf8mb4_unicode_ci` charset)
- **Frontend**: Vanilla HTML5, CSS3, JavaScript (Fetch API)
- **Design System**: Space Grotesk + PT Sans typography, Responsive Grid
- **Web Server**: Apache on XAMPP
- **QR Code Library**: qrcode.js
