-- ============================================================
-- Migration: Add 360° images, color variants, AR model
-- Run once against the visionfurnish database
-- ============================================================

USE visionfurnish;

ALTER TABLE products
  ADD COLUMN IF NOT EXISTS images_360     JSON         DEFAULT NULL COMMENT 'Array of 360° image URLs',
  ADD COLUMN IF NOT EXISTS color_variants JSON         DEFAULT NULL COMMENT 'Array of {name, hex, images:[]} objects',
  ADD COLUMN IF NOT EXISTS ar_model       VARCHAR(500) DEFAULT NULL COMMENT 'URL to .glb AR model file';
