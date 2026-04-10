const { param, body } = require('express-validator');
const db = require('../config/db');
const { success, error } = require('../utils/response');

// ── Controllers ─────────────────────────────────────────────

/**
 * GET /api/admin/dashboard
 */
const getDashboardStats = async (req, res, next) => {
  try {
    // PostgreSQL: single-quotes for strings, no double-quotes
    const { rows: [userCount] } = await db.query(
      `SELECT COUNT(*) AS total FROM users WHERE role = 'user'`
    );
    const { rows: [productCount] } = await db.query(
      'SELECT COUNT(*) AS total FROM products'
    );
    const { rows: [orderStats] } = await db.query(
      'SELECT COUNT(*) AS total_orders, COALESCE(SUM(total), 0) AS total_revenue FROM orders'
    );
    const { rows: [pendingOrders] } = await db.query(
      `SELECT COUNT(*) AS total FROM orders WHERE status = 'pending'`
    );

    // Monthly revenue — TO_CHAR replaces MySQL DATE_FORMAT
    // CURRENT_DATE - INTERVAL replaces DATE_SUB / DATE_ADD
    const { rows: monthlyRevenue } = await db.query(
      `SELECT
         TO_CHAR(created_at, 'YYYY-MM') AS month,
         COALESCE(SUM(total), 0)::numeric(12,2) AS revenue,
         COUNT(*)::int AS orders
       FROM orders
       WHERE created_at >= CURRENT_DATE - INTERVAL '6 months'
       GROUP BY TO_CHAR(created_at, 'YYYY-MM')
       ORDER BY month ASC`
    );

    // Recent 5 orders
    const { rows: recentOrders } = await db.query(
      `SELECT o.id, o.total, o.status, o.created_at,
              u.name AS user_name, u.email AS user_email
       FROM orders o
       JOIN users u ON o.user_id = u.id
       ORDER BY o.created_at DESC
       LIMIT 5`
    );

    return success(res, {
      total_users:     parseInt(userCount.total, 10),
      total_products:  parseInt(productCount.total, 10),
      total_orders:    parseInt(orderStats.total_orders, 10),
      total_revenue:   parseFloat(orderStats.total_revenue),
      pending_orders:  parseInt(pendingOrders.total, 10),
      monthly_revenue: monthlyRevenue,
      recent_orders:   recentOrders,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/admin/users
 */
const getAllUsers = async (req, res, next) => {
  try {
    const page   = Math.max(parseInt(req.query.page,  10) || 1,   1);
    const limit  = Math.min(Math.max(parseInt(req.query.limit, 10) || 20, 1), 100);
    const offset = (page - 1) * limit;

    const search = req.query.search;
    let where = 'WHERE 1=1';
    const params = [];
    let pIdx = 0;

    if (search) {
      // ILIKE = case-insensitive LIKE in PostgreSQL
      where += ` AND (name ILIKE $${++pIdx} OR email ILIKE $${++pIdx})`;
      const term = `%${search}%`;
      params.push(term, term);
    }

    const { rows: countRows } = await db.query(
      `SELECT COUNT(*) AS total FROM users ${where}`,
      params
    );
    const total = parseInt(countRows[0].total, 10);

    const { rows } = await db.query(
      `SELECT id, name, email, phone, role, is_blocked, avatar_url, created_at, updated_at
       FROM users ${where}
       ORDER BY created_at DESC
       LIMIT $${pIdx + 1} OFFSET $${pIdx + 2}`,
      [...params, limit, offset]
    );

    return success(res, {
      users: rows,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/admin/users/:id/block
 */
const toggleBlockUser = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (parseInt(id, 10) === req.user.id) {
      return error(res, 'You cannot block yourself.', 400);
    }

    const { rows } = await db.query(
      'SELECT id, is_blocked FROM users WHERE id = $1',
      [id]
    );
    if (rows.length === 0) {
      return error(res, 'User not found.', 404);
    }

    const newStatus = !rows[0].is_blocked;
    await db.query('UPDATE users SET is_blocked = $1 WHERE id = $2', [newStatus, id]);

    return success(
      res,
      { is_blocked: newStatus },
      newStatus ? 'User blocked successfully.' : 'User unblocked successfully.'
    );
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/admin/users/:id
 */
const deleteUser = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (parseInt(id, 10) === req.user.id) {
      return error(res, 'You cannot delete yourself.', 400);
    }

    const result = await db.query('DELETE FROM users WHERE id = $1', [id]);
    if (result.rowCount === 0) {
      return error(res, 'User not found.', 404);
    }

    return success(res, null, 'User deleted successfully.');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getDashboardStats,
  getAllUsers,
  toggleBlockUser,
  deleteUser,
};
