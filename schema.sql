-- ============================================================
-- VisionFurnish — MySQL Database Schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS visionfurnish
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE visionfurnish;

-- ============================================================
-- 1. USERS
-- ============================================================
CREATE TABLE users (
  id          INT           AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100)  NOT NULL,
  email       VARCHAR(255)  NOT NULL UNIQUE,
  password    VARCHAR(255)  NOT NULL,
  phone       VARCHAR(20)   DEFAULT NULL,
  role        ENUM('user', 'admin') NOT NULL DEFAULT 'user',
  avatar_url  VARCHAR(500)  DEFAULT NULL,
  is_blocked  BOOLEAN       NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_users_email (email),
  INDEX idx_users_role  (role)
) ENGINE=InnoDB;

-- ============================================================
-- 2. CATEGORIES
-- ============================================================
CREATE TABLE categories (
  id          INT           AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100)  NOT NULL,
  slug        VARCHAR(120)  NOT NULL UNIQUE,
  description TEXT          DEFAULT NULL,
  image_url   VARCHAR(500)  DEFAULT NULL,
  parent_id   INT           DEFAULT NULL,
  created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_categories_slug      (slug),
  INDEX idx_categories_parent_id (parent_id),

  CONSTRAINT fk_categories_parent
    FOREIGN KEY (parent_id) REFERENCES categories(id)
    ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- 3. PRODUCTS
-- ============================================================
CREATE TABLE products (
  id              INT           AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(255)  NOT NULL,
  slug            VARCHAR(280)  NOT NULL UNIQUE,
  description     TEXT          DEFAULT NULL,
  price           DECIMAL(10,2) NOT NULL,
  discount_price  DECIMAL(10,2) DEFAULT NULL,
  stock           INT           NOT NULL DEFAULT 0,
  category_id     INT           DEFAULT NULL,
  image_url       VARCHAR(500)  DEFAULT NULL,
  images          JSON          DEFAULT NULL,          -- array of image URLs
  material        VARCHAR(100)  DEFAULT NULL,
  dimensions      VARCHAR(100)  DEFAULT NULL,          -- e.g. "120x60x75 cm"
  color           VARCHAR(50)   DEFAULT NULL,
  is_featured     BOOLEAN       NOT NULL DEFAULT FALSE,
  images_360      JSON          DEFAULT NULL,          -- array of 360° image URLs
  color_variants  JSON          DEFAULT NULL,          -- array of {name, hex, images:[]} objects
  ar_model        VARCHAR(500)  DEFAULT NULL,          -- URL to .glb AR model file
  created_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_products_slug        (slug),
  INDEX idx_products_category_id (category_id),
  INDEX idx_products_price       (price),
  INDEX idx_products_is_featured (is_featured),
  FULLTEXT INDEX ft_products_name_desc (name, description),

  CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES categories(id)
    ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- 4. REVIEWS
-- ============================================================
CREATE TABLE reviews (
  id          INT       AUTO_INCREMENT PRIMARY KEY,
  user_id     INT       NOT NULL,
  product_id  INT       NOT NULL,
  rating      TINYINT   NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment     TEXT      DEFAULT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_reviews_product_id (product_id),
  INDEX idx_reviews_user_id    (user_id),

  UNIQUE KEY uq_user_product (user_id, product_id),  -- one review per user per product

  CONSTRAINT fk_reviews_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_reviews_product
    FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 5. CART
-- ============================================================
CREATE TABLE cart (
  id          INT       AUTO_INCREMENT PRIMARY KEY,
  user_id     INT       NOT NULL,
  product_id  INT       NOT NULL,
  quantity    INT       NOT NULL DEFAULT 1,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uq_cart_user_product (user_id, product_id),

  INDEX idx_cart_user_id (user_id),

  CONSTRAINT fk_cart_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_cart_product
    FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 6. WISHLIST
-- ============================================================
CREATE TABLE wishlist (
  id          INT       AUTO_INCREMENT PRIMARY KEY,
  user_id     INT       NOT NULL,
  product_id  INT       NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  UNIQUE KEY uq_wishlist_user_product (user_id, product_id),

  INDEX idx_wishlist_user_id (user_id),

  CONSTRAINT fk_wishlist_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_wishlist_product
    FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 7. ORDERS
-- ============================================================
CREATE TABLE orders (
  id                INT            AUTO_INCREMENT PRIMARY KEY,
  user_id           INT            NOT NULL,
  total             DECIMAL(12,2)  NOT NULL,
  status            ENUM('pending','confirmed','processing','shipped','delivered','cancelled')
                                   NOT NULL DEFAULT 'pending',
  shipping_address  TEXT           NOT NULL,
  city              VARCHAR(100)   DEFAULT NULL,
  state             VARCHAR(100)   DEFAULT NULL,
  zip_code          VARCHAR(20)    DEFAULT NULL,
  phone             VARCHAR(20)    NOT NULL,
  payment_method    VARCHAR(50)    DEFAULT 'cod',
  notes             TEXT           DEFAULT NULL,
  created_at        TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_orders_user_id (user_id),
  INDEX idx_orders_status  (status),

  CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 8. ORDER ITEMS
-- ============================================================
CREATE TABLE order_items (
  id          INT           AUTO_INCREMENT PRIMARY KEY,
  order_id    INT           NOT NULL,
  product_id  INT           NOT NULL,
  quantity    INT           NOT NULL DEFAULT 1,
  unit_price  DECIMAL(10,2) NOT NULL,
  created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_order_items_order_id   (order_id),
  INDEX idx_order_items_product_id (product_id),

  CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id) REFERENCES products(id)
    ON DELETE RESTRICT
) ENGINE=InnoDB;
