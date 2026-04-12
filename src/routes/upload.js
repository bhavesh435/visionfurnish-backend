const express = require('express');
const multer  = require('multer');
const path    = require('path');
const fs      = require('fs');

const router = express.Router();

// ── Ensure upload directories exist ─────────────────────────
const MODEL_DIR = path.join(__dirname, '../../uploads/models');
const IMAGE_DIR = path.join(__dirname, '../../uploads/images');
if (!fs.existsSync(MODEL_DIR)) {
  fs.mkdirSync(MODEL_DIR, { recursive: true });
}
if (!fs.existsSync(IMAGE_DIR)) {
  fs.mkdirSync(IMAGE_DIR, { recursive: true });
}

// ── Helper: build public URL ────────────────────────────────
function buildPublicUrl(req, subPath) {
  const renderUrl = process.env.RENDER_EXTERNAL_URL; // e.g. "https://visionfurnish-api.onrender.com"
  if (renderUrl) {
    return `${renderUrl}/uploads/${subPath}`;
  }
  const host = req.get('host');
  const protocol = req.protocol;
  return `${protocol}://${host}/uploads/${subPath}`;
}

// ── Multer: 3D model storage (.glb / .gltf) ────────────────
const modelStorage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, MODEL_DIR),
  filename: (_req, file, cb) => {
    const safe = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
    cb(null, `${Date.now()}_${safe}`);
  },
});

const modelFilter = (_req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  if (ext === '.glb' || ext === '.gltf') {
    cb(null, true);
  } else {
    cb(new Error('Only .glb and .gltf 3D model files are allowed.'), false);
  }
};

const uploadModel = multer({
  storage: modelStorage,
  fileFilter: modelFilter,
  limits: { fileSize: 100 * 1024 * 1024 }, // 100 MB
});

// ── Multer: Product image storage (.png / .jpg / .jpeg / .webp) ─
const imageStorage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, IMAGE_DIR),
  filename: (_req, file, cb) => {
    const safe = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
    cb(null, `${Date.now()}_${safe}`);
  },
});

const imageFilter = (_req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  if (['.png', '.jpg', '.jpeg', '.webp', '.gif'].includes(ext)) {
    cb(null, true);
  } else {
    cb(new Error('Only image files (PNG, JPG, JPEG, WebP, GIF) are allowed.'), false);
  }
};

const uploadImage = multer({
  storage: imageStorage,
  fileFilter: imageFilter,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
});

// ── POST /api/upload/model ───────────────────────────────────
/**
 * Accepts a single `model` field multipart file.
 * Returns: { success: true, url: "http://host:5000/uploads/models/xxx.glb" }
 */
router.post('/model', uploadModel.single('model'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No file uploaded.' });
  }

  const publicUrl = buildPublicUrl(req, `models/${req.file.filename}`);

  return res.status(201).json({
    success: true,
    message: '3D model uploaded successfully.',
    url: publicUrl,
    filename: req.file.filename,
    size: req.file.size,
  });
});

// ── POST /api/upload/image ───────────────────────────────────
/**
 * Accepts a single `image` field multipart file (PNG, JPG, etc.).
 * Returns: { success: true, url: "https://host/uploads/images/xxx.png" }
 */
router.post('/image', uploadImage.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No image uploaded.' });
  }

  const publicUrl = buildPublicUrl(req, `images/${req.file.filename}`);

  return res.status(201).json({
    success: true,
    message: 'Image uploaded successfully.',
    url: publicUrl,
    filename: req.file.filename,
    size: req.file.size,
  });
});

// ── Multer error handler ─────────────────────────────────────
router.use((err, _req, res, _next) => {
  if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ success: false, message: 'File too large. Maximum allowed size exceeded.' });
  }
  return res.status(400).json({ success: false, message: err.message || 'Upload failed.' });
});

module.exports = router;
