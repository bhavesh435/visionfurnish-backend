const { body, param } = require('express-validator');
const db = require('../config/db');
const { success, error } = require('../utils/response');

// ── Validation Rules ────────────────────────────────────────

const placeOrderRules = [
  body('shipping_address').trim().notEmpty().withMessage('Shipping address is required.'),
  body('phone').trim().notEmpty().withMessage('Phone number is required.'),
  body('city').optional().trim(),
  body('state').optional().trim(),
  body('zip_code').optional().trim(),
  body('payment_method').optional().trim(),
  body('notes').optional().trim(),
];

const updateStatusRules = [
  param('id').isInt().withMessage('Valid order ID is required.'),
  body('status')
    .isIn(['pending', 'confirmed', 'processing', 'packed', 'shipped', 'delivered', 'cancelled'])
    .withMessage('Status must be one of: pending, confirmed, processing, packed, shipped, delivered, cancelled.'),
];

// ── Controllers ─────────────────────────────────────────────

/**
 * POST /api/orders
 * Creates an order from the user's current cart, inside a transaction.
 */
const placeOrder = async (req, res, next) => {
  // In pg, transactions require a dedicated client from the pool
  const client = await db.connect();
  try {
    await client.query('BEGIN');

    const userId = req.user.id;

    // 1. Fetch cart items
    const { rows: cartItems } = await client.query(
      `SELECT c.product_id, c.quantity,
              p.price, p.discount_price, p.stock, p.name
       FROM cart c
       JOIN products p ON c.product_id = p.id
       WHERE c.user_id = $1`,
      [userId]
    );

    if (cartItems.length === 0) {
      await client.query('ROLLBACK');
      return error(res, 'Your cart is empty.', 400);
    }

    // 2. Validate stock & calculate total
    let total = 0;
    for (const item of cartItems) {
      if (item.quantity > item.stock) {
        await client.query('ROLLBACK');
        return error(
          res,
          `Insufficient stock for "${item.name}". Available: ${item.stock}.`,
          400
        );
      }
      const effectivePrice = parseFloat(item.discount_price || item.price);
      total += effectivePrice * item.quantity;
    }

    const { shipping_address, phone, city, state, zip_code, payment_method, notes } = req.body;

    // 3. Create order — RETURNING id instead of insertId
    const { rows: orderRows } = await client.query(
      `INSERT INTO orders
         (user_id, total, shipping_address, phone, city, state, zip_code, payment_method, notes)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       RETURNING id`,
      [
        userId, total.toFixed(2), shipping_address, phone,
        city || null, state || null, zip_code || null,
        payment_method || 'cod', notes || null,
      ]
    );
    const orderId = orderRows[0].id;

    // 4. Insert order items & reduce stock
    for (const item of cartItems) {
      const unitPrice = parseFloat(item.discount_price || item.price);
      await client.query(
        `INSERT INTO order_items (order_id, product_id, quantity, unit_price)
         VALUES ($1, $2, $3, $4)`,
        [orderId, item.product_id, item.quantity, unitPrice]
      );
      await client.query(
        'UPDATE products SET stock = stock - $1 WHERE id = $2',
        [item.quantity, item.product_id]
      );
    }

    // 5. Clear cart
    await client.query('DELETE FROM cart WHERE user_id = $1', [userId]);

    await client.query('COMMIT');

    return success(
      res,
      { order_id: orderId, total: parseFloat(total.toFixed(2)) },
      'Order placed successfully.',
      201
    );
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release(); // always return client to pool
  }
};

/**
 * GET /api/orders
 */
const getUserOrders = async (req, res, next) => {
  try {
    const page   = Math.max(parseInt(req.query.page,  10) || 1,  1);
    const limit  = Math.min(Math.max(parseInt(req.query.limit, 10) || 10, 1), 50);
    const offset = (page - 1) * limit;

    const { rows: countRows } = await db.query(
      'SELECT COUNT(*) AS total FROM orders WHERE user_id = $1',
      [req.user.id]
    );
    const total = parseInt(countRows[0].total, 10);

    const { rows: orders } = await db.query(
      `SELECT * FROM orders WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [req.user.id, limit, offset]
    );

    return success(res, {
      orders,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/orders/:id
 */
const getOrderById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const { rows: orders } = await db.query(
      'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
      [id, req.user.id]
    );
    if (orders.length === 0) {
      return error(res, 'Order not found.', 404);
    }

    const { rows: items } = await db.query(
      `SELECT oi.*, p.name, p.slug, p.image_url
       FROM order_items oi
       JOIN products p ON oi.product_id = p.id
       WHERE oi.order_id = $1`,
      [id]
    );

    return success(res, { order: orders[0], items });
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/orders/:id/status   (Admin)
 */
const updateStatus = async (req, res, next) => {
  try {
    const { id }     = req.params;
    const { status } = req.body;

    const result = await db.query(
      'UPDATE orders SET status = $1 WHERE id = $2',
      [status, id]
    );
    if (result.rowCount === 0) {
      return error(res, 'Order not found.', 404);
    }

    return success(res, null, `Order status updated to "${status}".`);
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/orders/all   (Admin)
 */
const getAllOrders = async (req, res, next) => {
  try {
    const page   = Math.max(parseInt(req.query.page,  10) || 1,   1);
    const limit  = Math.min(Math.max(parseInt(req.query.limit, 10) || 20, 1), 100);
    const offset = (page - 1) * limit;

    const statusFilter = req.query.status;
    let where = '';
    const params = [];
    let pIdx = 0;

    if (statusFilter) {
      where = `WHERE o.status = $${++pIdx}`;
      params.push(statusFilter);
    }

    const { rows: countRows } = await db.query(
      `SELECT COUNT(*) AS total FROM orders o ${where}`,
      params
    );
    const total = parseInt(countRows[0].total, 10);

    const { rows: orders } = await db.query(
      `SELECT o.*, u.name AS user_name, u.email AS user_email
       FROM orders o
       JOIN users u ON o.user_id = u.id
       ${where}
       ORDER BY o.created_at DESC
       LIMIT $${pIdx + 1} OFFSET $${pIdx + 2}`,
      [...params, limit, offset]
    );

    return success(res, {
      orders,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  placeOrder, getUserOrders, getOrderById, updateStatus, getAllOrders,
  placeOrderRules, updateStatusRules,
};
