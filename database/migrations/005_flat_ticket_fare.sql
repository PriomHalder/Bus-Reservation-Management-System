-- UniRide flat Passenger ticket fare
-- Optional for an existing database: the application already displays and
-- charges BDT 110.00. Import this once to align stored route fares as well.

USE `uniride2`;

UPDATE `routes`
SET `fare` = 110.00
WHERE `fare` <> 110.00;
