// ============================================================
// VisionFurnish — Chat Routes
// ============================================================

const router = require('express').Router();
const { chatValidation, handleChat } = require('../controllers/chatController');

// POST /api/chat — public endpoint (no auth required)
router.post('/', chatValidation, handleChat);

module.exports = router;
