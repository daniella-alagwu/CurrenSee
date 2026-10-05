USE currensee;

INSERT INTO currencies (code, name, symbol)
VALUES ('NGN', 'Nigerian Naira', '₦')
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  symbol = VALUES(symbol),
  is_active = TRUE;
