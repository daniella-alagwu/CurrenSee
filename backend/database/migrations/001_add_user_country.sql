
ALTER TABLE users
  ADD COLUMN country_code CHAR(2) NULL,
  ADD COLUMN country_name VARCHAR(100) NULL;
