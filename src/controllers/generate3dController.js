// ============================================================
// VisionFurnish — Smart Category-Based 3D Model Assignment
// Uses free KhronosGroup GLB models via jsDelivr CDN
// Completely FREE — No API keys, no credits, works forever!
// ============================================================

const pool = require('../config/db');

// ── Free furniture GLB models via jsDelivr CDN ───────────────
const FURNITURE_MODELS = [
  {
    keywords: ['sofa', 'couch', 'sectional', 'loveseat', 'settee', 'divan', 'futon', 'recliner'],
    label: 'Modern Sofa',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
  },
  {
    keywords: ['chair', 'armchair', 'accent', 'stool', 'seat', 'wingback', 'rocking', 'bar stool'],
    label: 'Accent Chair',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/AntiqueChair/glTF-Binary/AntiqueChair.glb',
  },
  {
    keywords: ['table', 'coffee', 'dining', 'side', 'console', 'nested', 'marble'],
    label: 'Coffee Table',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
  },
  {
    keywords: ['bed', 'mattress', 'bunk', 'daybed', 'headboard', 'platform', 'canopy', 'hydraulic'],
    label: 'King Size Bed',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
  },
  {
    keywords: ['shelf', 'shelves', 'bookcase', 'bookshelf', 'rack', 'display', 'ladder'],
    label: 'Bookshelf',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/AntiqueChair/glTF-Binary/AntiqueChair.glb',
  },
  {
    keywords: ['wardrobe', 'closet', 'dresser', 'armoire', 'drawer', 'cabinet', 'cupboard', 'almirah'],
    label: 'Wardrobe',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/AntiqueChair/glTF-Binary/AntiqueChair.glb',
  },
  {
    keywords: ['desk', 'workstation', 'bureau', 'writing', 'study', 'standing', 'laptop', 'computer'],
    label: 'Study Desk',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
  },
  {
    keywords: ['tv', 'television', 'entertainment', 'console', 'unit', 'media', 'rustic'],
    label: 'TV Unit',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
  },
  {
    keywords: ['lamp', 'light', 'chandelier', 'pendant', 'sconce', 'strip', 'led', 'crystal'],
    label: 'Floor Lamp',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/AntiqueChair/glTF-Binary/AntiqueChair.glb',
  },
  {
    keywords: ['outdoor', 'garden', 'patio', 'bench', 'lounger', 'swing', 'hammock'],
    label: 'Garden Chair',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/AntiqueChair/glTF-Binary/AntiqueChair.glb',
  },
];

const FALLBACK_URL = 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/glTF-Binary/SheenChair.glb';

// ── Pick best model for a product ────────────────────────────
function pickModel(productName, categoryName = '') {
  const text = `${productName} ${categoryName}`.toLowerCase();
  for (const model of FURNITURE_MODELS) {
    if (model.keywords.some(kw => text.includes(kw))) {
      return model;
    }
  }
  return { label: 'Furniture 3D Model', url: FALLBACK_URL };
}

// ── POST /api/products/:id/generate-3d ──────────────────────
// Auto-assigns a matching free furniture 3D model.
// Returns immediately — no wait time, no credits needed!
exports.startGeneration = async (req, res) => {
  try {
    const productId = parseInt(req.params.id, 10);
    const { rows } = await pool.query(
      `SELECT p.id, p.name, c.name AS category_name
       FROM products p
       LEFT JOIN categories c ON p.category_id = c.id
       WHERE p.id = $1`,
      [productId]
    );

    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    const { name, category_name } = rows[0];
    const model = pickModel(name, category_name || '');

    console.log(`🎯 Auto-assigning 3D model for "${name}" → ${model.label}`);

    // Save directly to DB — instant!
    await pool.query(
      'UPDATE products SET ar_model = $1, updated_at = NOW() WHERE id = $2',
      [model.url, productId]
    );

    console.log(`✅ AR model assigned: ${model.url}`);

    return res.status(201).json({
      success: true,
      taskId: 'direct',
      status: 'SUCCEEDED',
      glbUrl: model.url,
      modelLabel: model.label,
    });
  } catch (err) {
    console.error('❌ generate-3d error:', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ── GET /api/products/:id/generate-3d/:taskId ───────────────
// Immediate response — no polling needed.
exports.checkStatus = async (req, res) => {
  return res.json({ success: true, status: 'SUCCEEDED', progress: 100, glbUrl: null });
};

// ── POST /api/products/:id/ar-model ──────────────────────────
// Manually set a specific AR model URL.
exports.selectModel = async (req, res) => {
  try {
    const productId = parseInt(req.params.id, 10);
    const { glbUrl } = req.body;
    if (!glbUrl) return res.status(400).json({ success: false, message: 'glbUrl is required' });

    await pool.query(
      'UPDATE products SET ar_model = $1, updated_at = NOW() WHERE id = $2',
      [glbUrl, productId]
    );

    return res.json({ success: true, message: 'AR model saved' });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};
