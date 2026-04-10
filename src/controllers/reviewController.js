const { body, param } = require('express-validator');
const db = require('../config/db');
const { success, error } = require('../utils/response');

// ── Validation Rules ────────────────────────────────────────

const createReviewRules = [
  body('product_id').isInt().withMessage('Valid product ID is required.'),
  body('rating').isInt({ min: 1, max: 5 }).withMessage('Rating must be between 1 and 5.'),
  body('comment').optional().trim(),
];

const updateReviewRules = [
  param('id').isInt().withMessage('Valid review ID is required.'),
  body('rating').optional().isInt({ min: 1, max: 5 }).withMessage('Rating must be between 1 and 5.'),
  body('comment').optional().trim(),
];

// ── Controllers ─────────────────────────────────────────────

/**
 * GET /api/reviews/product/:productId
 */
const getProductReviews = async (req, res, next) => {
  try {
    const { productId } = req.params;
    const page   = Math.max(parseInt(req.query.page,  10) || 1,  1);
    const limit  = Math.min(Math.max(parseInt(req.query.limit, 10) || 10, 1), 50);
    const offset = (page - 1) * limit;

    const { rows: countRows } = await db.query(
      'SELECT COUNT(*) AS total FROM reviews WHERE product_id = $1',
      [productId]
    );
    const total = parseInt(countRows[0].total, 10);

    const { rows } = await db.query(
      `SELECT r.*, u.name AS user_name, u.avatar_url
       FROM reviews r
       JOIN users u ON r.user_id = u.id
       WHERE r.product_id = $1
       ORDER BY r.created_at DESC
       LIMIT $2 OFFSET $3`,
      [productId, limit, offset]
    );

    const { rows: avgRows } = await db.query(
      'SELECT AVG(rating) AS avg_rating FROM reviews WHERE product_id = $1',
      [productId]
    );

    return success(res, {
      reviews: rows,
      avg_rating: avgRows[0].avg_rating
        ? parseFloat(avgRows[0].avg_rating).toFixed(1)
        : null,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/reviews
 */
const createReview = async (req, res, next) => {
  try {
    const { product_id, rating, comment } = req.body;

    // Verify product exists
    const { rows: products } = await db.query(
      'SELECT id FROM products WHERE id = $1',
      [product_id]
    );
    if (products.length === 0) {
      return error(res, 'Product not found.', 404);
    }

    // One review per user per product
    const { rows: existing } = await db.query(
      'SELECT id FROM reviews WHERE user_id = $1 AND product_id = $2',
      [req.user.id, product_id]
    );
    if (existing.length > 0) {
      return error(res, 'You have already reviewed this product.', 409);
    }

    const { rows } = await db.query(
      'INSERT INTO reviews (user_id, product_id, rating, comment) VALUES ($1,$2,$3,$4) RETURNING id',
      [req.user.id, product_id, rating, comment || null]
    );

    return success(res, { id: rows[0].id }, 'Review submitted successfully.', 201);
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/reviews/:id
 */
const updateReview = async (req, res, next) => {
  try {
    const { id } = req.params;

    const { rows: reviews } = await db.query(
      'SELECT id FROM reviews WHERE id = $1 AND user_id = $2',
      [id, req.user.id]
    );
    if (reviews.length === 0) {
      return error(res, 'Review not found or not yours.', 404);
    }

    const setClauses = [];
    const values     = [];
    let pIdx = 0;

    if (req.body.rating !== undefined) {
      setClauses.push(`rating = $${++pIdx}`);
      values.push(req.body.rating);
    }
    if (req.body.comment !== undefined) {
      setClauses.push(`comment = $${++pIdx}`);
      values.push(req.body.comment);
    }

    if (setClauses.length === 0) {
      return error(res, 'No fields to update.', 400);
    }

    values.push(id);
    await db.query(
      `UPDATE reviews SET ${setClauses.join(', ')} WHERE id = $${++pIdx}`,
      values
    );

    return success(res, null, 'Review updated successfully.');
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/reviews/:id  (Owner or Admin)
 */
const deleteReview = async (req, res, next) => {
  try {
    const { id } = req.params;

    let queryText = 'DELETE FROM reviews WHERE id = $1';
    const params  = [id];

    if (req.user.role !== 'admin') {
      queryText += ' AND user_id = $2';
      params.push(req.user.id);
    }

    const result = await db.query(queryText, params);
    if (result.rowCount === 0) {
      return error(res, 'Review not found.', 404);
    }

    return success(res, null, 'Review deleted successfully.');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getProductReviews, createReview, updateReview, deleteReview,
  createReviewRules, updateReviewRules,
};
