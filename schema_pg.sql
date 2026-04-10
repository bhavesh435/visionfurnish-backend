-- ============================================================
-- VisionFurnish — PostgreSQL Schema
-- Migrated from MySQL (XAMPP) to PostgreSQL
-- ============================================================

-- Run this file in psql or pgAdmin:
--   psql -U postgres -d visionfurnish -f schema_pg.sql
--
-- Or create the DB first:
--   CREATE DATABASE visionfurnish;
--   \c visionfurnish
--   \i schema_pg.sql

-- ============================================================
-- ENUM Types (replaces MySQL ENUM columns)
-- ============================================================
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('user', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE order_status AS ENUM (
    'pending', 'confirmed', 'processing',
    'shipped', 'delivered', 'cancelled'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- Trigger function for auto-updating updated_at
-- (Replaces MySQL's ON UPDATE CURRENT_TIMESTAMP)
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 1. USERS
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id          SERIAL        PRIMARY KEY,
  name        VARCHAR(100)  NOT NULL,
  email       VARCHAR(255)  NOT NULL UNIQUE,
  password    VARCHAR(255)  NOT NULL,
  phone       VARCHAR(20)   DEFAULT NULL,
  role        user_role     NOT NULL DEFAULT 'user',
  avatar_url  VARCHAR(500)  DEFAULT NULL,
  is_blocked  BOOLEAN       NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_users_role  ON users (role);

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 2. CATEGORIES
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
  id          SERIAL        PRIMARY KEY,
  name        VARCHAR(100)  NOT NULL,
  slug        VARCHAR(120)  NOT NULL UNIQUE,
  description TEXT          DEFAULT NULL,
  image_url   VARCHAR(500)  DEFAULT NULL,
  parent_id   INT           DEFAULT NULL,
  created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_categories_parent
    FOREIGN KEY (parent_id) REFERENCES categories(id)
    ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_categories_slug      ON categories (slug);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories (parent_id);

DROP TRIGGER IF EXISTS trg_categories_updated_at ON categories;
CREATE TRIGGER trg_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 3. PRODUCTS
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
  id              SERIAL          PRIMARY KEY,
  name            VARCHAR(255)    NOT NULL,
  slug            VARCHAR(280)    NOT NULL UNIQUE,
  description     TEXT            DEFAULT NULL,
  price           NUMERIC(10,2)   NOT NULL,
  discount_price  NUMERIC(10,2)   DEFAULT NULL,
  stock           INT             NOT NULL DEFAULT 0,
  category_id     INT             DEFAULT NULL,
  image_url       VARCHAR(500)    DEFAULT NULL,
  images          JSONB           DEFAULT NULL,   -- array of image URLs
  material        VARCHAR(100)    DEFAULT NULL,
  dimensions      VARCHAR(100)    DEFAULT NULL,   -- e.g. "120x60x75 cm"
  color           VARCHAR(50)     DEFAULT NULL,
  is_featured     BOOLEAN         NOT NULL DEFAULT FALSE,
  images_360      JSONB           DEFAULT NULL,   -- array of 360° image URLs
  color_variants  JSONB           DEFAULT NULL,   -- array of {name,hex,images} objects
  ar_model        VARCHAR(500)    DEFAULT NULL,   -- URL to .glb model file
  created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES categories(id)
    ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_products_slug        ON products (slug);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products (category_id);
CREATE INDEX IF NOT EXISTS idx_products_price       ON products (price);
CREATE INDEX IF NOT EXISTS idx_products_is_featured ON products (is_featured);

-- Full-text search (replaces MySQL FULLTEXT INDEX)
CREATE INDEX IF NOT EXISTS idx_products_fts ON products
  USING GIN (to_tsvector('english',
    name || ' ' || COALESCE(description, '')
  ));

DROP TRIGGER IF EXISTS trg_products_updated_at ON products;
CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 4. REVIEWS
-- ============================================================
CREATE TABLE IF NOT EXISTS reviews (
  id          SERIAL    PRIMARY KEY,
  user_id     INT       NOT NULL,
  product_id  INT       NOT NULL,
  rating      SMALLINT  NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment     TEXT      DEFAULT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  UNIQUE (user_id, product_id),   -- one review per user per product

  CONSTRAINT fk_reviews_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_reviews_product
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews (product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id    ON reviews (user_id);

DROP TRIGGER IF EXISTS trg_reviews_updated_at ON reviews;
CREATE TRIGGER trg_reviews_updated_at
  BEFORE UPDATE ON reviews
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 5. CART
-- ============================================================
CREATE TABLE IF NOT EXISTS cart (
  id          SERIAL    PRIMARY KEY,
  user_id     INT       NOT NULL,
  product_id  INT       NOT NULL,
  quantity    INT       NOT NULL DEFAULT 1,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  UNIQUE (user_id, product_id),

  CONSTRAINT fk_cart_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_cart_product
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_cart_user_id ON cart (user_id);

DROP TRIGGER IF EXISTS trg_cart_updated_at ON cart;
CREATE TRIGGER trg_cart_updated_at
  BEFORE UPDATE ON cart
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 6. WISHLIST
-- ============================================================
CREATE TABLE IF NOT EXISTS wishlist (
  id          SERIAL    PRIMARY KEY,
  user_id     INT       NOT NULL,
  product_id  INT       NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  UNIQUE (user_id, product_id),

  CONSTRAINT fk_wishlist_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_wishlist_product
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_wishlist_user_id ON wishlist (user_id);

-- ============================================================
-- 7. ORDERS
-- ============================================================
CREATE TABLE IF NOT EXISTS orders (
  id                SERIAL          PRIMARY KEY,
  user_id           INT             NOT NULL,
  total             NUMERIC(12,2)   NOT NULL,
  status            order_status    NOT NULL DEFAULT 'pending',
  shipping_address  TEXT            NOT NULL,
  city              VARCHAR(100)    DEFAULT NULL,
  state             VARCHAR(100)    DEFAULT NULL,
  zip_code          VARCHAR(20)     DEFAULT NULL,
  phone             VARCHAR(20)     NOT NULL,
  payment_method    VARCHAR(50)     DEFAULT 'cod',
  notes             TEXT            DEFAULT NULL,
  created_at        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders (user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status  ON orders (status);

DROP TRIGGER IF EXISTS trg_orders_updated_at ON orders;
CREATE TRIGGER trg_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 8. ORDER ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS order_items (
  id          SERIAL        PRIMARY KEY,
  order_id    INT           NOT NULL,
  product_id  INT           NOT NULL,
  quantity    INT           NOT NULL DEFAULT 1,
  unit_price  NUMERIC(10,2) NOT NULL,
  created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id   ON order_items (order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items (product_id);

-- ============================================================
-- Done!
-- ============================================================
