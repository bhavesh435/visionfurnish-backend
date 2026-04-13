const { body, query, param } = require('express-validator');
const db = require('../config/db');
const { success, error } = require('../utils/response');

// ── Validation Rules ────────────────────────────────────────

const createProductRules = [
  body('name').trim().notEmpty().withMessage('Product name is required.'),
  body('price').notEmpty().withMessage('Price is required.').toFloat(),
  body('stock').optional({ values: 'null' }).toInt(),
  body('category_id').optional({ values: 'null' }).toInt(),
  body('discount_price').optional({ values: 'null' }).toFloat(),
];

const updateProductRules = [
  param('id').isInt().withMessage('Valid product ID is required.'),
  body('name').optional().trim().notEmpty().withMessage('Product name cannot be empty.'),
  body('price').optional().toFloat(),
  body('stock').optional().toInt(),
];

// ── Helpers ─────────────────────────────────────────────────

const slugify = (str) =>
  str.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');

// ── Controllers ─────────────────────────────────────────────

/**
 * GET /api/products
 * Supports: ?page, ?limit, ?sort, ?order, ?category_id, ?min_price, ?max_price, ?is_featured
 */
const getAll = async (req, res, next) => {
  try {
    const page   = Math.max(parseInt(req.query.page,  10) || 1,   1);
    const limit  = Math.min(Math.max(parseInt(req.query.limit, 10) || 12, 1), 100);
    const offset = (page - 1) * limit;

    const sortParam = req.query.sort;
    const isRandom = sortParam === 'random';
    const sort  = ['price', 'created_at', 'name'].includes(sortParam) ? sortParam : 'created_at';
    const order = req.query.order === 'asc' ? 'ASC' : 'DESC';

    let where = 'WHERE 1=1';
    const params = [];
    let pIdx = 0; // parameter counter

    if (req.query.category_id) {
      where += ` AND p.category_id = $${++pIdx}`;
      params.push(parseInt(req.query.category_id, 10));
    }
    if (req.query.min_price) {
      where += ` AND p.price >= $${++pIdx}`;
      params.push(parseFloat(req.query.min_price));
    }
    if (req.query.max_price) {
      where += ` AND p.price <= $${++pIdx}`;
      params.push(parseFloat(req.query.max_price));
    }
    if (req.query.is_featured !== undefined) {
      where += ` AND p.is_featured = $${++pIdx}`;
      params.push(req.query.is_featured === 'true');
    }

    // Count total matching rows
    const { rows: countRows } = await db.query(
      `SELECT COUNT(*) AS total FROM products p ${where}`,
      params
    );
    const total = parseInt(countRows[0].total, 10);

    const orderClause = isRandom ? 'RANDOM()' : `p.${sort} ${order}`;

    // Fetch page — append LIMIT / OFFSET as next params
    const { rows } = await db.query(
      `SELECT p.*, c.name AS category_name
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       ${where}
       ORDER BY ${orderClause}
       LIMIT $${pIdx + 1} OFFSET $${pIdx + 2}`,
      [...params, limit, offset]
    );

    return success(res, {
      products: rows,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/products/search?q=...
 * Uses PostgreSQL ILIKE for case-insensitive search.
 */
const search = async (req, res, next) => {
  try {
    const q = req.query.q;
    if (!q || q.trim().length === 0) {
      return error(res, 'Search query (q) is required.', 400);
    }

    const page   = Math.max(parseInt(req.query.page,  10) || 1,   1);
    const limit  = Math.min(Math.max(parseInt(req.query.limit, 10) || 12, 1), 100);
    const offset = (page - 1) * limit;

    const searchTerm = `%${q.trim()}%`;

    const { rows: countRows } = await db.query(
      `SELECT COUNT(*) AS total FROM products
       WHERE name ILIKE $1 OR description ILIKE $2`,
      [searchTerm, searchTerm]
    );
    const total = parseInt(countRows[0].total, 10);

    const { rows } = await db.query(
      `SELECT p.*, c.name AS category_name
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.name ILIKE $1 OR p.description ILIKE $2
       ORDER BY p.created_at DESC
       LIMIT $3 OFFSET $4`,
      [searchTerm, searchTerm, limit, offset]
    );

    return success(res, {
      products: rows,
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/products/:id
 */
const getById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const { rows } = await db.query(
      `SELECT p.*, c.name AS category_name
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.id = $1`,
      [id]
    );

    if (rows.length === 0) {
      return error(res, 'Product not found.', 404);
    }

    const { rows: ratingRows } = await db.query(
      `SELECT AVG(rating) AS avg_rating, COUNT(*) AS review_count
       FROM reviews WHERE product_id = $1`,
      [id]
    );

    const raw = rows[0];

    // PostgreSQL JSONB columns are already parsed — no JSON.parse needed
    const product = {
      ...raw,
      images:         Array.isArray(raw.images)         ? raw.images         : (raw.images         || []),
      images_360:     Array.isArray(raw.images_360)     ? raw.images_360     : (raw.images_360     || []),
      color_variants: Array.isArray(raw.color_variants) ? raw.color_variants : (raw.color_variants || []),
      avg_rating:     ratingRows[0].avg_rating
        ? parseFloat(ratingRows[0].avg_rating).toFixed(1)
        : null,
      review_count: parseInt(ratingRows[0].review_count, 10),
    };

    return success(res, { product });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/products  (Admin)
 */
const create = async (req, res, next) => {
  try {
    const {
      name, description, price, discount_price, stock,
      category_id, image_url, images, material, dimensions, color, is_featured,
    } = req.body;

    const slug = slugify(name) + '-' + Date.now();

    // RETURNING id replaces MySQL insertId
    const { rows } = await db.query(
      `INSERT INTO products
        (name, slug, description, price, discount_price, stock,
         category_id, image_url, images, material, dimensions, color, is_featured)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
       RETURNING id`,
      [
        name, slug, description || null, price, discount_price || null,
        stock || 0, category_id || null, image_url || null,
        images ? JSON.stringify(images) : null,
        material || null, dimensions || null, color || null,
        is_featured ? true : false,
      ]
    );

    return success(res, { id: rows[0].id, slug }, 'Product created successfully.', 201);
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/products/:id  (Admin)
 */
const update = async (req, res, next) => {
  try {
    const { id } = req.params;

    const { rows: existing } = await db.query(
      'SELECT id FROM products WHERE id = $1',
      [id]
    );
    if (existing.length === 0) {
      return error(res, 'Product not found.', 404);
    }

    const setClauses = [];
    const values     = [];
    let pIdx = 0;

    const allowedFields = [
      'name', 'description', 'price', 'discount_price', 'stock',
      'category_id', 'image_url', 'material', 'dimensions', 'color',
      'is_featured', 'ar_model',
    ];

    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        setClauses.push(`${field} = $${++pIdx}`);
        values.push(req.body[field]);
      }
    }

    // JSON fields
    if (req.body.images !== undefined) {
      setClauses.push(`images = $${++pIdx}`);
      values.push(JSON.stringify(req.body.images));
    }
    if (req.body.images_360 !== undefined) {
      setClauses.push(`images_360 = $${++pIdx}`);
      values.push(JSON.stringify(req.body.images_360));
    }
    if (req.body.color_variants !== undefined) {
      setClauses.push(`color_variants = $${++pIdx}`);
      values.push(JSON.stringify(req.body.color_variants));
    }

    // Auto-regenerate slug if name changed
    if (req.body.name) {
      setClauses.push(`slug = $${++pIdx}`);
      values.push(slugify(req.body.name) + '-' + Date.now());
    }

    if (setClauses.length === 0) {
      return error(res, 'No fields to update.', 400);
    }

    values.push(id);
    await db.query(
      `UPDATE products SET ${setClauses.join(', ')} WHERE id = $${++pIdx}`,
      values
    );

    return success(res, null, 'Product updated successfully.');
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/products/:id  (Admin)
 */
const remove = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await db.query('DELETE FROM products WHERE id = $1', [id]);
    if (result.rowCount === 0) {
      return error(res, 'Product not found.', 404);
    }

    return success(res, null, 'Product deleted successfully.');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getAll, search, getById, create, update, remove,
  createProductRules, updateProductRules,
};
