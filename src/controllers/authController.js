const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body } = require('express-validator');
const db = require('../config/db');
const { success, error } = require('../utils/response');
const { generateOTP, verifyOTP } = require('../utils/otp');

// ── Validation Rules ────────────────────────────────────────

const strongPasswordMsg =
  'Password must be at least 8 characters and include an uppercase letter, lowercase letter, number, and special character.';

const strongPassword = body('password')
  .isLength({ min: 8 })
  .withMessage('Password must be at least 8 characters.')
  .matches(/[A-Z]/)
  .withMessage('Password must contain at least one uppercase letter.')
  .matches(/[a-z]/)
  .withMessage('Password must contain at least one lowercase letter.')
  .matches(/[0-9]/)
  .withMessage('Password must contain at least one number.')
  .matches(/[!@#%^&*()\'\-_=+\[\]{};:,.<>?\/\\|]/ )
  .withMessage('Password must contain at least one special character.');

const registerRules = [
  body('name').trim().notEmpty().withMessage('Name is required.'),
  body('email').isEmail().withMessage('Valid email is required.'),
  strongPassword,
  body('phone').optional().isMobilePhone().withMessage('Invalid phone number.'),
];

const loginRules = [
  body('email').isEmail().withMessage('Valid email is required.'),
  body('password').notEmpty().withMessage('Password is required.'),
];

const forgotPasswordRules = [
  body('email').isEmail().withMessage('Valid email is required.'),
];

const verifyOtpRules = [
  body('email').isEmail().withMessage('Valid email is required.'),
  body('otp').isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits.'),
];

const resetPasswordRules = [
  body('email').isEmail().withMessage('Valid email is required.'),
  body('otp').isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits.'),
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('New password must be at least 8 characters.')
    .matches(/[A-Z]/)
    .withMessage('New password must contain at least one uppercase letter.')
    .matches(/[a-z]/)
    .withMessage('New password must contain at least one lowercase letter.')
    .matches(/[0-9]/)
    .withMessage('New password must contain at least one number.')
    .matches(/[!@#%^&*()\'\-_=+\[\]{};:,.<>?\/\\|]/)
    .withMessage('New password must contain at least one special character.'),
];

// ── Helpers ─────────────────────────────────────────────────

const signToken = (user) =>
  jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );

// ── Controllers ─────────────────────────────────────────────

/**
 * POST /api/auth/register
 */
const register = async (req, res, next) => {
  try {
    const { name, email, password, phone } = req.body;

    // Check duplicate email
    const { rows: existing } = await db.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );
    if (existing.length > 0) {
      return error(res, 'Email is already registered.', 409);
    }

    const hashedPassword = await bcrypt.hash(password, 12);

    // RETURNING id — replaces MySQL insertId
    const { rows } = await db.query(
      'INSERT INTO users (name, email, password, phone) VALUES ($1, $2, $3, $4) RETURNING id',
      [name, email, hashedPassword, phone || null]
    );
    const newId = rows[0].id;

    const token = signToken({ id: newId, email, role: 'user' });

    return success(
      res,
      { user: { id: newId, name, email, phone: phone || null, role: 'user' }, token },
      'Registration successful.',
      201
    );
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/auth/login
 */
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    const { rows } = await db.query(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );
    if (rows.length === 0) {
      return error(res, 'Invalid email or password.', 401);
    }

    const user = rows[0];
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return error(res, 'Invalid email or password.', 401);
    }

    if (user.is_blocked) {
      return error(res, 'Your account has been blocked. Please contact support.', 403);
    }

    const token = signToken(user);

    return success(
      res,
      { user: { id: user.id, name: user.name, email: user.email, phone: user.phone, role: user.role }, token },
      'Login successful.'
    );
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/auth/forgot-password
 */
const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;

    const { rows } = await db.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );
    if (rows.length === 0) {
      return error(res, 'No account found with this email.', 404);
    }

    const otp = generateOTP(email);

    return success(
      res,
      { otp: process.env.NODE_ENV !== 'production' ? otp : undefined },
      'OTP sent successfully. Please check your email.'
    );
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/auth/verify-otp
 */
const verifyOtp = async (req, res, next) => {
  try {
    const { email, otp } = req.body;

    const isValid = verifyOTP(email, otp);
    if (!isValid) {
      return error(res, 'Invalid or expired OTP.', 400);
    }

    const newOtp = generateOTP(email);

    return success(
      res,
      { resetToken: newOtp },
      'OTP verified successfully. Use the resetToken to set a new password.'
    );
  } catch (err) {
    next(err);
  }
};

/**
 * POST /api/auth/reset-password
 */
const resetPassword = async (req, res, next) => {
  try {
    const { email, otp, newPassword } = req.body;

    const isValid = verifyOTP(email, otp);
    if (!isValid) {
      return error(res, 'Invalid or expired OTP.', 400);
    }

    const hashedPassword = await bcrypt.hash(newPassword, 12);
    await db.query(
      'UPDATE users SET password = $1 WHERE email = $2',
      [hashedPassword, email]
    );

    return success(res, null, 'Password reset successful. Please login with your new password.');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/auth/profile
 */
const getProfile = async (req, res, next) => {
  try {
    const { rows } = await db.query(
      'SELECT id, name, email, phone, role, avatar_url, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (rows.length === 0) {
      return error(res, 'User not found.', 404);
    }

    return success(res, { user: rows[0] });
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/auth/profile
 */
const updateProfile = async (req, res, next) => {
  try {
    const { name, phone } = req.body;
    if (!name || name.trim().length === 0) {
      return error(res, 'Name is required.', 400);
    }
    await db.query(
      'UPDATE users SET name = $1, phone = $2 WHERE id = $3',
      [name.trim(), phone || null, req.user.id]
    );
    const { rows } = await db.query(
      'SELECT id, name, email, phone, role, avatar_url, created_at FROM users WHERE id = $1',
      [req.user.id]
    );
    return success(res, { user: rows[0] }, 'Profile updated successfully.');
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/auth/site-settings
 */
const getSiteSettings = async (req, res, next) => {
  try {
    const { rows } = await db.query('SELECT key, value FROM site_settings');
    const settings = {};
    for (const row of rows) {
      settings[row.key] = row.value;
    }
    return success(res, { settings });
  } catch (err) {
    next(err);
  }
};

/**
 * PUT /api/auth/site-settings  (Admin)
 */
const updateSiteSettings = async (req, res, next) => {
  try {
    const { settings } = req.body;
    if (!settings || typeof settings !== 'object') {
      return error(res, 'Settings object is required.', 400);
    }
    for (const [key, value] of Object.entries(settings)) {
      await db.query(
        `INSERT INTO site_settings (key, value) VALUES ($1, $2)
         ON CONFLICT (key) DO UPDATE SET value = $2`,
        [key, value]
      );
    }
    return success(res, null, 'Settings updated successfully.');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  register,
  login,
  forgotPassword,
  verifyOtp,
  resetPassword,
  getProfile,
  updateProfile,
  getSiteSettings,
  updateSiteSettings,
  registerRules,
  loginRules,
  forgotPasswordRules,
  verifyOtpRules,
  resetPasswordRules,
};
