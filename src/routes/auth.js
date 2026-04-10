const router = require('express').Router();
const validate = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const ctrl = require('../controllers/authController');

// Public
router.post('/register', ctrl.registerRules, validate, ctrl.register);
router.post('/login', ctrl.loginRules, validate, ctrl.login);
router.post('/forgot-password', ctrl.forgotPasswordRules, validate, ctrl.forgotPassword);
router.post('/verify-otp', ctrl.verifyOtpRules, validate, ctrl.verifyOtp);
router.post('/reset-password', ctrl.resetPasswordRules, validate, ctrl.resetPassword);

// Protected
router.get('/profile', authenticate, ctrl.getProfile);

module.exports = router;
