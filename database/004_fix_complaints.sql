-- Fix complaint ID generation
USE uniride2;

ALTER TABLE complaints
MODIFY complaint_id INT(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE complaints
ADD PRIMARY KEY (complaint_id);
