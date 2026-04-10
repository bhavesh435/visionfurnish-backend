const router = require('express').Router();
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const ctrl = require('../controllers/reviewController');

// Public
router.get('/product/:productId', ctrl.getProductReviews);

// Authenticated
router.post('/', authenticate, ctrl.createReviewRules, validate, ctrl.createReview);
router.put('/:id', authenticate, ctrl.updateReviewRules, validate, ctrl.updateReview);
router.delete('/:id', authenticate, ctrl.deleteReview);

module.exports = router;
