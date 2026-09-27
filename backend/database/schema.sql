CREATE DATABASE IF NOT EXISTS currensee CHARACTER SET utf8mb4;
USE currensee;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  firebase_uid VARCHAR(255) UNIQUE NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(100),
  country_code CHAR(2),
  country_name VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- New: backs the email-code alternative to the verification link.
-- One row per user; resending overwrites it (ON DUPLICATE KEY in the
-- controller), so a stale code can never be reused after a fresh send.
CREATE TABLE email_otp_codes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  firebase_uid VARCHAR(255) NOT NULL UNIQUE,
  code_hash VARCHAR(255) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  attempts INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE currencies (
  code CHAR(3) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  symbol VARCHAR(10),
  is_active BOOLEAN DEFAULT TRUE
);
INSERT INTO currencies (code, name, symbol) VALUES
('USD', 'US Dollar', '$'),
('EUR', 'Euro', '€'),
('GBP', 'British Pound', '£'),
('JPY', 'Japanese Yen', '¥'),
('CAD', 'Canadian Dollar', '$'),
('AUD', 'Australian Dollar', '$'),
('INR', 'Indian Rupee', '₹');

CREATE TABLE user_preferences (
  user_id INT PRIMARY KEY,
  default_base_currency CHAR(3) DEFAULT 'USD',
  default_target_currency CHAR(3) DEFAULT 'EUR',
  push_enabled BOOLEAN DEFAULT TRUE,
  alert_notifications_enabled BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (default_base_currency) REFERENCES currencies(code),
  FOREIGN KEY (default_target_currency) REFERENCES currencies(code)
);

CREATE TABLE device_tokens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  fcm_token VARCHAR(512) NOT NULL UNIQUE,
  platform ENUM('android','ios') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE exchange_rates (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  base_code CHAR(3) NOT NULL,
  target_code CHAR(3) NOT NULL,
  rate DECIMAL(18,8) NOT NULL,
  rate_date DATE NOT NULL,
  fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_pair_day (base_code, target_code, rate_date),
  FOREIGN KEY (base_code) REFERENCES currencies(code),
  FOREIGN KEY (target_code) REFERENCES currencies(code)
);

CREATE TABLE conversion_history (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  from_code CHAR(3) NOT NULL,
  to_code CHAR(3) NOT NULL,
  amount DECIMAL(18,4) NOT NULL,
  rate_used DECIMAL(18,8) NOT NULL,
  result DECIMAL(18,4) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_time (user_id, created_at),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (from_code) REFERENCES currencies(code),
  FOREIGN KEY (to_code) REFERENCES currencies(code)
);

CREATE TABLE rate_alerts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  base_code CHAR(3) NOT NULL,
  target_code CHAR(3) NOT NULL,
  threshold DECIMAL(18,8) NOT NULL,
  direction ENUM('ABOVE','BELOW') NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  triggered_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_active (is_active),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (base_code) REFERENCES currencies(code),
  FOREIGN KEY (target_code) REFERENCES currencies(code)
);

CREATE TABLE notifications (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(150) NOT NULL,
  body VARCHAR(500) NOT NULL,
  type ENUM('ALERT','SYSTEM') DEFAULT 'SYSTEM',
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_time (user_id, created_at),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE news_articles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  summary TEXT,
  url VARCHAR(500),
  source VARCHAR(100),
  published_at DATETIME
);

CREATE TABLE faqs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  category VARCHAR(50),
  question VARCHAR(255) NOT NULL,
  answer TEXT NOT NULL,
  sort_order INT DEFAULT 0
);

CREATE TABLE support_tickets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  subject VARCHAR(150) NOT NULL,
  message TEXT NOT NULL,
  status ENUM('OPEN','IN_PROGRESS','CLOSED') DEFAULT 'OPEN',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE feedback (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  type ENUM('FEEDBACK','BUG') NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
