const express = require('express');
const multer  = require('multer');
const path    = require('path');
const fs      = require('fs');

const router = express.Router();

// ── Ensure upload directory exists ───────────────────────────
const MODEL_DIR = path.join(__dirname, '../../uploads/models');
if (!fs.existsSync(MODEL_DIR)) {
  fs.mkdirSync(MODEL_DIR, { recursive: true });
}

// ── Multer storage config ────────────────────────────────────
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, MODEL_DIR),
  filename: (_req, file, cb) => {
    // Sanitize original name and prefix with timestamp to avoid clashes
    const safe = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
    cb(null, `${Date.now()}_${safe}`);
  },
});

// Only allow .glb and .gltf files (≤ 100 MB)
const fileFilter = (_req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  if (ext === '.glb' || ext === '.gltf') {
    cb(null, true);
  } else {
    cb(new Error('Only .glb and .gltf 3D model files are allowed.'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 100 * 1024 * 1024 }, // 100 MB
});

// ── POST /api/upload/model ───────────────────────────────────
/**
 * Accepts a single `model` field multipart file.
 * Returns: { success: true, url: "http://host:5000/uploads/models/xxx.glb" }
 */
router.post('/model', upload.single('model'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No file uploaded.' });
  }

  // Build public URL from Host header (works for both LAN and ADB forwarding)
  const host = req.get('host'); // e.g. "192.168.1.5:5000" or "localhost:5000"
  const protocol = req.protocol; // "http" or "https"
  const publicUrl = `${protocol}://${host}/uploads/models/${req.file.filename}`;

  return res.status(201).json({
    success: true,
    message: '3D model uploaded successfully.',
    url: publicUrl,
    filename: req.file.filename,
    size: req.file.size,
  });
});

// ── Multer error handler ─────────────────────────────────────
router.use((err, _req, res, _next) => {
  if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ success: false, message: 'File too large. Maximum size is 100 MB.' });
  }
  return res.status(400).json({ success: false, message: err.message || 'Upload failed.' });
});

module.exports = router;
