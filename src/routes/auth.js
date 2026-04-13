const router = require('express').Router();
const validate = require('../middleware/validate');
const { authenticate, authorize } = require('../middleware/auth');
const ctrl = require('../controllers/authController');

// Public
router.post('/register', ctrl.registerRules, validate, ctrl.register);
router.post('/login', ctrl.loginRules, validate, ctrl.login);
router.post('/forgot-password', ctrl.forgotPasswordRules, validate, ctrl.forgotPassword);
router.post('/verify-otp', ctrl.verifyOtpRules, validate, ctrl.verifyOtp);
router.post('/reset-password', ctrl.resetPasswordRules, validate, ctrl.resetPassword);

// Protected
router.get('/profile', authenticate, ctrl.getProfile);
router.put('/profile', authenticate, ctrl.updateProfile);

// Site settings (public read, admin write)
router.get('/site-settings', ctrl.getSiteSettings);
router.put('/site-settings', authenticate, authorize('admin'), ctrl.updateSiteSettings);

module.exports = router;
