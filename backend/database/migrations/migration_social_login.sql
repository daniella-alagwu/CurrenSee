ALTER TABLE users
  ADD COLUMN auth_provider VARCHAR(30) NOT NULL DEFAULT 'password' AFTER email,
  ADD COLUMN photo_url VARCHAR(1024) NULL AFTER avatar;