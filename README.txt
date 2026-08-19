UNIRIDE2 WEBSITE FILES
======================

Copy this folder to:

C:\xampp\htdocs\uniride\

Main folder layout:

uniride\
│
├── css\
│   └── style.css
│
├── img\
│   └── logo.svg
│
├── js\
│   └── app.js
│
├── config\
│   └── database.php
│
├── includes\
│   └── auth.php
│
├── database\
│   └── password_reset_tokens.sql
│
├── index.php
├── signin.php
├── dashboard.php
├── forgot-password.php
├── reset-password.php
├── logout.php
└── README.txt

DATABASE
--------
The PHP connection uses:

Database: uniride2
Host: 127.0.0.1
Port: 3306
User: root
Password: empty

If your local MySQL root user has a password,
edit config/database.php.

PASSWORD RESET
--------------
In phpMyAdmin:

1. Select uniride2.
2. Import:
   database/password_reset_tokens.sql

START
-----
Start Apache and MySQL in XAMPP.

Then open:

http://localhost/uniride/

LOGIN TYPES
-----------
Passenger:
  students + faculty
  table: passengers
  password column: password_hash

Uni Admin:
  table: university_users
  password column: password_hash

Sys Admin:
  table: admins
  password column: password

The website does not hard-code demo accounts.
