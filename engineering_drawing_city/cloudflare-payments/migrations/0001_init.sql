CREATE TABLE IF NOT EXISTS payments (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  provider_ref TEXT NOT NULL UNIQUE,
  phone_last4 TEXT NOT NULL,
  request_id TEXT NOT NULL,
  status TEXT NOT NULL,
  provider_status TEXT NOT NULL,
  created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS payments_user_status ON payments(user_id, status);
CREATE TABLE IF NOT EXISTS user_locks (
  user_id TEXT PRIMARY KEY,
  payment_id TEXT NOT NULL UNIQUE
);