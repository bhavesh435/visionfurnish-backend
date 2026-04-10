const jwt = require('jsonwebtoken');
const { error } = require('../utils/response');

/**
 * Verify JWT token from Authorization header.
 * Attaches decoded payload to `req.user`.
 */
const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return error(res, 'Access denied. No token provided.', 401);
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, email, role }
    next();
  } catch (err) {
    return error(res, 'Invalid or expired token.', 401);
  }
};

/**
 * Role-based authorization.
 * Usage: authorize('admin')  or  authorize('admin', 'user')
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return error(res, 'Authentication required.', 401);
    }
    if (!roles.includes(req.user.role)) {
      return error(res, 'Forbidden. Insufficient permissions.', 403);
    }
    next();
  };
};

module.exports = { authenticate, authorize };
