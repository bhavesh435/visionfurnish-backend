const router = require('express').Router();
const validate = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const ctrl = require('../controllers/categoryController');

// Public
router.get('/', ctrl.getAll);
router.get('/:id', ctrl.getById);

// Admin only
router.post('/', authenticate, authorize('admin'), ctrl.createCategoryRules, validate, ctrl.create);
router.put('/:id', authenticate, authorize('admin'), ctrl.updateCategoryRules, validate, ctrl.update);
router.delete('/:id', authenticate, authorize('admin'), ctrl.remove);

module.exports = router;
