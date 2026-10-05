USE currensee;


ALTER TABLE users ADD COLUMN avatar MEDIUMTEXT NULL;

CREATE TABLE support_messages (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  sender ENUM('USER','ADMIN') NOT NULL,
  body VARCHAR(1000) NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_thread (user_id, id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

INSERT IGNORE INTO currencies (code, name, symbol) VALUES
('CHF', 'Swiss Franc', 'CHF'),
('CNY', 'Chinese Yuan', '¥'),
('SGD', 'Singapore Dollar', '$'),
('ZAR', 'South African Rand', 'R'),
('MXN', 'Mexican Peso', '$'),
('BRL', 'Brazilian Real', 'R$'),
('NZD', 'New Zealand Dollar', '$'),
('SEK', 'Swedish Krona', 'kr'),
('NOK', 'Norwegian Krone', 'kr'),
('HKD', 'Hong Kong Dollar', '$'),
('KRW', 'South Korean Won', '₩');

UPDATE user_preferences
SET default_target_currency = 'USD'
WHERE default_base_currency <> 'USD' AND default_target_currency = 'EUR';
