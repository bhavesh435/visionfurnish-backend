const { body, param } = require('express-validator');
const db = require('../config/db');
const { success, error } = require('../utils/response');

// ── Validation Rules ────────────────────────────────────────

const addToCartRules = [
  body('product_id').isInt().withMessage('Valid product ID is required.'),
  body('quantity').optional().isInt({ min: 1 }).withMessage('Quantity must be at least 1.'),
];

const updateCartRules = [
  param('id').isInt().withMessage('Valid cart item ID is required.'),
  body('quantity').isInt({ min: 1 }).withMessage('Quantity must be at least 1.'),
];

// ── Controllers ─────────────────────────────────────────────

/**
 * GET /api/cart
 */
const getCart = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT c.id, c.quantity, c.created_at,
              p.id AS product_id, p.name, p.slug, p.price, p.discount_price,
              p.image_url, p.stock
       FROM cart c
       JOIN products p ON c.product_id = p.id
       WHERE c.user_id = $1
       ORDER BY c.created_at DESC`,
      [req.user.id]
    );

    let subtotal = 0;
    const items = rows.map((item) => {
      const effectivePrice = parseFloat(item.discount_price || item.price);
      const itemTotal = effectivePrice * item.quantity;
      subtotal += itemTotal;
      return {
        ...item,
        effective_price: effectivePrice,
        item_total: parseFloat(itemTotal.toFixed(2)),
      };
    });

    return success(res, {
      items,
      summary: {
        item_count: items.length,
        subtotal: parseFloat(subtotal.toFixed(2)),
      },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/cart
 */
const addToCart = async (req, res, next) => {
  try {
    const { product_id, quantity = 1 } = req.body;

    // Verify product exists and has stock
    const { rows: products } = await db.query(
      'SELECT id, stock FROM products WHERE id = $1',
      [product_id]
    );
    if (products.length === 0) {
      return error(res, 'Product not found.', 404);
    }
    if (products[0].stock < quantity) {
      return error(res, 'Insufficient stock.', 400);
    }

    // Check if already in cart
    const { rows: existing } = await db.query(
      'SELECT id, quantity FROM cart WHERE user_id = $1 AND product_id = $2',
      [req.user.id, product_id]
    );

    if (existing.length > 0) {
      const newQty = existing[0].quantity + quantity;
      if (newQty > products[0].stock) {
        return error(res, 'Quantity exceeds available stock.', 400);
      }
      await db.query('UPDATE cart SET quantity = $1 WHERE id = $2', [newQty, existing[0].id]);
      return success(res, { id: existing[0].id, quantity: newQty }, 'Cart updated.');
    }

    // Insert new cart item
    const { rows } = await db.query(
      'INSERT INTO cart (user_id, product_id, quantity) VALUES ($1, $2, $3) RETURNING id',
      [req.user.id, product_id, quantity]
    );

    return success(res, { id: rows[0].id }, 'Product added to cart.', 201);
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/cart/:id
 */
const updateQuantity = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { quantity } = req.body;

    // Verify ownership and check stock
    const { rows: items } = await db.query(
      `SELECT c.id, c.product_id, p.stock
       FROM cart c
       JOIN products p ON c.product_id = p.id
       WHERE c.id = $1 AND c.user_id = $2`,
      [id, req.user.id]
    );
    if (items.length === 0) {
      return error(res, 'Cart item not found.', 404);
    }
    if (quantity > items[0].stock) {
      return error(res, 'Quantity exceeds available stock.', 400);
    }

    await db.query('UPDATE cart SET quantity = $1 WHERE id = $2', [quantity, id]);

    return success(res, null, 'Cart item updated.');
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/cart/:id
 */
const removeItem = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await db.query(
      'DELETE FROM cart WHERE id = $1 AND user_id = $2',
      [id, req.user.id]
    );
    if (result.rowCount === 0) {
      return error(res, 'Cart item not found.', 404);
    }

    return success(res, null, 'Item removed from cart.');
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/cart   (clear entire cart)
 */
const clearCart = async (req, res, next) => {
  try {
    await db.query('DELETE FROM cart WHERE user_id = $1', [req.user.id]);
    return success(res, null, 'Cart cleared.');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getCart, addToCart, updateQuantity, removeItem, clearCart,
  addToCartRules, updateCartRules,
};
