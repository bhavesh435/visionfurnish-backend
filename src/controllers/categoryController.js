const { body, param } = require('express-validator');
const db = require('../config/db');
const { success, error } = require('../utils/response');

// ── Validation Rules ────────────────────────────────────────

const createCategoryRules = [
  body('name').trim().notEmpty().withMessage('Category name is required.'),
  body('parent_id').optional().isInt().withMessage('Parent ID must be an integer.'),
];

const updateCategoryRules = [
  param('id').isInt().withMessage('Valid category ID is required.'),
  body('name').optional().trim().notEmpty().withMessage('Category name cannot be empty.'),
];

// ── Helpers ─────────────────────────────────────────────────

const slugify = (str) =>
  str.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');

// ── Controllers ─────────────────────────────────────────────

/**
 * GET /api/categories
 */
const getAll = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      `SELECT c.*, COUNT(p.id)::int AS product_count
       FROM categories c
       LEFT JOIN products p ON p.category_id = c.id
       GROUP BY c.id
       ORDER BY c.name ASC`
    );

    return success(res, { categories: rows });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/categories/:id
 */
const getById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const { rows } = await db.query(
      'SELECT * FROM categories WHERE id = $1',
      [id]
    );
    if (rows.length === 0) {
      return error(res, 'Category not found.', 404);
    }

    const { rows: children } = await db.query(
      'SELECT * FROM categories WHERE parent_id = $1',
      [id]
    );

    return success(res, { category: rows[0], subcategories: children });
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/categories  (Admin)
 */
const create = async (req, res, next) => {
  try {
    const { name, description, image_url, parent_id } = req.body;
    const slug = slugify(name);

    const { rows: existing } = await db.query(
      'SELECT id FROM categories WHERE slug = $1',
      [slug]
    );
    if (existing.length > 0) {
      return error(res, 'A category with this name already exists.', 409);
    }

    const { rows } = await db.query(
      `INSERT INTO categories (name, slug, description, image_url, parent_id)
       VALUES ($1,$2,$3,$4,$5) RETURNING id`,
      [name, slug, description || null, image_url || null, parent_id || null]
    );

    return success(res, { id: rows[0].id, slug }, 'Category created successfully.', 201);
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/categories/:id  (Admin)
 */
const update = async (req, res, next) => {
  try {
    const { id } = req.params;

    const { rows: existing } = await db.query(
      'SELECT id FROM categories WHERE id = $1',
      [id]
    );
    if (existing.length === 0) {
      return error(res, 'Category not found.', 404);
    }

    const setClauses = [];
    const values     = [];
    let pIdx = 0;

    const allowedFields = ['name', 'description', 'image_url', 'parent_id'];
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        setClauses.push(`${field} = $${++pIdx}`);
        values.push(req.body[field]);
      }
    }

    if (req.body.name) {
      setClauses.push(`slug = $${++pIdx}`);
      values.push(slugify(req.body.name));
    }

    if (setClauses.length === 0) {
      return error(res, 'No fields to update.', 400);
    }

    values.push(id);
    await db.query(
      `UPDATE categories SET ${setClauses.join(', ')} WHERE id = $${++pIdx}`,
      values
    );

    return success(res, null, 'Category updated successfully.');
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/categories/:id  (Admin)
 */
const remove = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await db.query('DELETE FROM categories WHERE id = $1', [id]);
    if (result.rowCount === 0) {
      return error(res, 'Category not found.', 404);
    }

    return success(res, null, 'Category deleted successfully.');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getAll, getById, create, update, remove,
  createCategoryRules, updateCategoryRules,
};
