const router = require('express').Router();
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const ctrl = require('../controllers/wishlistController');

// All routes require authentication
router.use(authenticate);

router.get('/', ctrl.getWishlist);
router.post('/', ctrl.addWishlistRules, validate, ctrl.addToWishlist);
router.delete('/:productId', ctrl.removeFromWishlist);

module.exports = router;
