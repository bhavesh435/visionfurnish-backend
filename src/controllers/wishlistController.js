const { body, param } = require('express-validator');
const db = require('../config/db');
const { success, error } = require('../utils/response');

// ── Validation Rules ────────────────────────────────────────

const addWishlistRules = [
  body('product_id').isInt().withMessage('Valid product ID is required.'),
];

// ── Controllers ─────────────────────────────────────────────

/**
 * GET /api/wishlist
 */
const getWishlist = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT w.id, w.created_at,
              p.id AS product_id, p.name, p.slug, p.price, p.discount_price,
              p.image_url, p.stock
       FROM wishlist w
       JOIN products p ON w.product_id = p.id
       WHERE w.user_id = $1
       ORDER BY w.created_at DESC`,
      [req.user.id]
    );

    return success(res, { items: rows });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/wishlist
 */
const addToWishlist = async (req, res, next) => {
  try {
    const { product_id } = req.body;

    const { rows: products } = await db.query(
      'SELECT id FROM products WHERE id = $1',
      [product_id]
    );
    if (products.length === 0) {
      return error(res, 'Product not found.', 404);
    }

    const { rows: existing } = await db.query(
      'SELECT id FROM wishlist WHERE user_id = $1 AND product_id = $2',
      [req.user.id, product_id]
    );
    if (existing.length > 0) {
      return error(res, 'Product already in wishlist.', 409);
    }

    const { rows } = await db.query(
      'INSERT INTO wishlist (user_id, product_id) VALUES ($1, $2) RETURNING id',
      [req.user.id, product_id]
    );

    return success(res, { id: rows[0].id }, 'Added to wishlist.', 201);
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/wishlist/:productId
 */
const removeFromWishlist = async (req, res, next) => {
  try {
    const { productId } = req.params;

    const result = await db.query(
      'DELETE FROM wishlist WHERE user_id = $1 AND product_id = $2',
      [req.user.id, productId]
    );
    if (result.rowCount === 0) {
      return error(res, 'Item not found in wishlist.', 404);
    }

    return success(res, null, 'Removed from wishlist.');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getWishlist, addToWishlist, removeFromWishlist,
  addWishlistRules,
};
