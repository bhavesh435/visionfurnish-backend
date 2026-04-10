const router = require('express').Router();
const validate = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const ctrl = require('../controllers/productController');
const gen3d = require('../controllers/generate3dController');

// Public
router.get('/search', ctrl.search);
router.get('/', ctrl.getAll);
router.get('/:id', ctrl.getById);

// Admin only — CRUD
router.post('/', authenticate, authorize('admin'), ctrl.createProductRules, validate, ctrl.create);
router.put('/:id', authenticate, authorize('admin'), ctrl.updateProductRules, validate, ctrl.update);
router.delete('/:id', authenticate, authorize('admin'), ctrl.remove);

// Admin only — AI 2D → 3D Generation (Poly.pizza free search)
router.post('/:id/generate-3d', authenticate, authorize('admin'), gen3d.startGeneration);
router.get('/:id/generate-3d/:taskId', authenticate, authorize('admin'), gen3d.checkStatus);
router.post('/:id/ar-model', authenticate, authorize('admin'), gen3d.selectModel);


module.exports = router;

