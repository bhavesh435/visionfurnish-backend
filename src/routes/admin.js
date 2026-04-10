const router = require('express').Router();
const { authenticate, authorize } = require('../middleware/auth');
const ctrl = require('../controllers/adminController');

// All routes require admin role
router.use(authenticate, authorize('admin'));

router.get('/dashboard', ctrl.getDashboardStats);
router.get('/users', ctrl.getAllUsers);
router.put('/users/:id/block', ctrl.toggleBlockUser);
router.delete('/users/:id', ctrl.deleteUser);

module.exports = router;
