USE currensee;

ALTER TABLE users
  ADD COLUMN is_primary_admin BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN primary_admin_slot TINYINT
    GENERATED ALWAYS AS (IF(is_primary_admin, 1, NULL)) STORED,
  ADD UNIQUE KEY uq_single_primary_admin (primary_admin_slot);
