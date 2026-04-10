-- ============================================================
-- Migration: Add is_blocked column to users table
-- ============================================================

USE visionfurnish;

ALTER TABLE users
  ADD COLUMN is_blocked BOOLEAN NOT NULL DEFAULT FALSE
  AFTER role;

CREATE INDEX idx_users_is_blocked ON users(is_blocked);
