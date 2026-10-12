ALTER TABLE support_messages
  ADD COLUMN tag VARCHAR(40) NULL AFTER body,
  ADD INDEX idx_support_tag (tag);