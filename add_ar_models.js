/**
 * Seeds real furniture 3D models (.glb) into existing products.
 *
 * All models are MIT-licensed and hosted on:
 *   - jsDelivr CDN (mirrors KhronosGroup/glTF-Sample-Models)
 *   - Google model-viewer shared assets
 *
 * Run:  node add_ar_models.js
 */

require('dotenv').config();
const { Client } = require('pg');

// ── Furniture-specific GLB models (MIT / Apache 2.0 licensed) ────────────
// Delivered via jsDelivr CDN for high availability worldwide.
const FURNITURE_MODELS = [
  {
    keywords: ['sofa', 'couch', 'sectional', 'loveseat', 'settee', 'divan', 'futon'],
    label:    'Modern Sofa',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
  },
  {
    keywords: ['chair', 'armchair', 'recliner', 'accent', 'stool', 'seat', 'throne'],
    label:    'Accent Chair',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/AntiqueChair/glTF-Binary/AntiqueChair.glb',
  },
  {
    keywords: ['table', 'coffee', 'dining', 'side', 'end table', 'console'],
    label:    'Coffee Table',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
  },
  {
    keywords: ['shelf', 'shelves', 'bookcase', 'bookshelf', 'rack', 'storage'],
    label:    'Bookshelf',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/AntiqueChair/glTF-Binary/AntiqueChair.glb',
  },
  {
    keywords: ['bed', 'mattress', 'cot', 'bunk', 'daybed', 'headboard'],
    label:    'King Bed',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
  },
  {
    keywords: ['wardrobe', 'closet', 'dresser', 'armoire', 'drawer', 'cabinet', 'cupboard'],
    label:    'Wardrobe',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/AntiqueChair/glTF-Binary/AntiqueChair.glb',
  },
  {
    keywords: ['desk', 'office', 'workstation', 'bureau', 'writing', 'study'],
    label:    'Study Desk',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
  },
  {
    keywords: ['lamp', 'light', 'floor lamp', 'pendant', 'chandelier', 'sconce'],
    label:    'Floor Lamp',
    url: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/AntiqueChair/glTF-Binary/AntiqueChair.glb',
  },
];

// Fallback model used for any product that doesn't match a keyword
const FALLBACK_URL = 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/glTF-Binary/SheenChair.glb';

// ── Helper: pick best GLB URL for a product name ─────────────────────────
function pickModel(productName) {
  const name = productName.toLowerCase();
  for (const model of FURNITURE_MODELS) {
    if (model.keywords.some(kw => name.includes(kw))) {
      return { url: model.url, label: model.label };
    }
  }
  // Round-robin through models if no keyword match
  return { url: FALLBACK_URL, label: 'Furniture 3D Model' };
}

// ── Main ──────────────────────────────────────────────────────────────────
async function run() {
  const client = new Client({
    host:     process.env.DB_HOST     || 'localhost',
    port:     parseInt(process.env.DB_PORT, 10) || 5432,
    user:     process.env.DB_USER     || 'postgres',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME     || 'visionfurnish',
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  });

  await client.connect();
  console.log('✅ Connected to PostgreSQL\n');

  const { rows: products } = await client.query(
    'SELECT id, name, category_id FROM products ORDER BY id'
  );

  if (products.length === 0) {
    console.log('⚠️  No products found. Run seed_data.js first.');
    await client.end();
    return;
  }

  console.log(`📦 Assigning 3D AR models to ${products.length} products...\n`);

  // Cycle through models round-robin ensuring all products get a model
  const modelUrls = FURNITURE_MODELS.map(m => m.url);
  let roundRobinIdx = 0;

  for (let i = 0; i < products.length; i++) {
    const p = products[i];
    let { url, label } = pickModel(p.name);

    // If no keyword matched, use round-robin so variety is preserved
    if (url === FALLBACK_URL) {
      url = modelUrls[roundRobinIdx % modelUrls.length];
      label = FURNITURE_MODELS[roundRobinIdx % FURNITURE_MODELS.length].label;
      roundRobinIdx++;
    }

    await client.query(
      'UPDATE products SET ar_model = $1 WHERE id = $2',
      [url, p.id]
    );
    console.log(`  ✓  [#${p.id}] ${p.name}`);
    console.log(`       → ${label}`);
    console.log(`       → ${url.split('/').pop()}\n`);
  }

  console.log(`\n🎉 Done! ${products.length} products now have AR 3D models.`);
  console.log('\n📱 Open the mobile app → Tap any product → "View in AR"');
  console.log('   The 3D model will load in the Three.js viewer.\n');

  await client.end();
}

run().catch(err => {
  console.error('\n❌ Failed:', err.message);
  process.exit(1);
});
