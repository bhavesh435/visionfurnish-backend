// ============================================================
// VisionFurnish — Chat Controller
// POST /api/chat
// ============================================================

const { body, validationResult } = require('express-validator');
const { success, error } = require('../utils/response');
const chatService = require('../services/chatService');

// ── Validation rules ────────────────────────────────────────
const chatValidation = [
  body('message')
    .trim()
    .notEmpty().withMessage('Message is required.')
    .isLength({ max: 500 }).withMessage('Message must be under 500 characters.'),
  body('history')
    .optional()
    .isArray({ max: 10 }).withMessage('History must be an array (max 10 items).'),
];

// ── Handler ─────────────────────────────────────────────────
const handleChat = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return error(res, errors.array()[0].msg, 400);
    }

    const { message, history = [] } = req.body;

    // Sanitize history — only keep role and content
    const sanitizedHistory = history
      .filter(h => h.role && h.content)
      .map(h => ({
        role: h.role === 'user' ? 'user' : 'assistant',
        content: String(h.content).slice(0, 500),
      }))
      .slice(-4); // Keep only last 4 messages

    const result = await chatService.chat(message, sanitizedHistory);

    return success(res, result, 'Chat response generated.');
  } catch (err) {
    next(err);
  }
};

module.exports = { chatValidation, handleChat };
