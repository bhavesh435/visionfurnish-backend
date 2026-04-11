// ── Self-hosted AR furniture GLB models ──────────────────────
// Hosted on our own Render server for Android Scene Viewer compatibility.
// These are REAL furniture models from KhronosGroup/glTF-Sample-Assets.
//   • chair.glb  = SheenChair (fabric director's chair, Wayfair CC0)
//   • sofa.glb   = GlamVelvetSofa (velvet sofa, Wayfair CC BY 4.0)
//   • table.glb  = SheenWoodLeatherSofa (wood/leather sofa, CC0)
//   • lamp.glb   = AnisotropyBarnLamp (barn lamp, Wayfair CC BY 4.0)

const db = require('../config/db');

const BASE = 'https://visionfurnish-api.onrender.com/models';

const FURNITURE_MODELS = [
  {
    keywords: ['sofa', 'couch', 'sectional', 'loveseat', 'settee', 'divan', 'futon', 'chesterfield'],
    label: 'Velvet Sofa',
    url: `${BASE}/sofa.glb`,
  },
  {
    keywords: ['chair', 'armchair', 'accent', 'stool', 'seat', 'wingback', 'rocking', 'bar stool', 'ergonomic', 'mesh', 'office'],
    label: 'Fabric Chair',
    url: `${BASE}/chair.glb`,
  },
  {
    keywords: ['table', 'coffee', 'dining', 'side', 'console', 'nested', 'marble', 'round'],
    label: 'Wood Table / Sofa',
    url: `${BASE}/table.glb`,
  },
  {
    keywords: ['bed', 'mattress', 'bunk', 'daybed', 'headboard', 'platform', 'canopy', 'hydraulic', 'king', 'queen'],
    label: 'Bed Frame',
    url: `${BASE}/sofa.glb`,
  },
  {
    keywords: ['shelf', 'shelves', 'bookcase', 'bookshelf', 'rack', 'display', 'ladder', 'industrial'],
    label: 'Bookshelf',
    url: `${BASE}/table.glb`,
  },
  {
    keywords: ['wardrobe', 'closet', 'dresser', 'armoire', 'drawer', 'cabinet', 'cupboard', 'almirah', 'mirror'],
    label: 'Wardrobe',
    url: `${BASE}/table.glb`,
  },
  {
    keywords: ['desk', 'workstation', 'bureau', 'writing', 'study', 'standing', 'laptop', 'computer', 'height'],
    label: 'Standing Desk',
    url: `${BASE}/table.glb`,
  },
  {
    keywords: ['tv', 'television', 'entertainment', 'console', 'unit', 'media', 'rustic'],
    label: 'TV Unit',
    url: `${BASE}/table.glb`,
  },
  {
    keywords: ['lamp', 'light', 'chandelier', 'pendant', 'sconce', 'strip', 'led', 'crystal', 'bulb', 'floor'],
    label: 'Barn Lamp',
    url: `${BASE}/lamp.glb`,
  },
  {
    keywords: ['outdoor', 'garden', 'patio', 'bench', 'lounger', 'swing', 'hammock'],
    label: 'Garden Chair',
    url: `${BASE}/chair.glb`,
  },
];

const FALLBACK_URL = `${BASE}/chair.glb`;

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
    const { rows } = await db.query(
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
    await db.query(
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

    await db.query(
      'UPDATE products SET ar_model = $1, updated_at = NOW() WHERE id = $2',
      [glbUrl, productId]
    );

    return res.json({ success: true, message: 'AR model saved' });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};
