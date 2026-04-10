const router = require('express').Router();
const validate = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const ctrl = require('../controllers/orderController');

// Authenticated user routes
router.post('/', authenticate, ctrl.placeOrderRules, validate, ctrl.placeOrder);
router.get('/', authenticate, ctrl.getUserOrders);
router.get('/all', authenticate, authorize('admin'), ctrl.getAllOrders);  // Admin — must come before /:id
router.get('/:id', authenticate, ctrl.getOrderById);

// Admin only
router.put('/:id/status', authenticate, authorize('admin'), ctrl.updateStatusRules, validate, ctrl.updateStatus);

module.exports = router;
