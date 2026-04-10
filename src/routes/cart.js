const router = require('express').Router();
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const ctrl = require('../controllers/cartController');

// All routes require authentication
router.use(authenticate);

router.get('/', ctrl.getCart);
router.post('/', ctrl.addToCartRules, validate, ctrl.addToCart);
router.put('/:id', ctrl.updateCartRules, validate, ctrl.updateQuantity);
router.delete('/:id', ctrl.removeItem);
router.delete('/', ctrl.clearCart);

module.exports = router;
