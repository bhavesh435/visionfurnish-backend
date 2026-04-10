/**
 * Replaces ALL 2D product images with 3D model render screenshots,
 * and ensures every product has its AR (.glb) model set.
 *
 * Images are render previews from KhronosGroup glTF-Sample-Assets (MIT licensed).
 * Run: node update_3d_images.js
 */

require('dotenv').config();
const { Client } = require('pg');

// ── 3D model packs ────────────────────────────────────────────
// Each pack has: a screenshot (used as product image_url) + a .glb (ar_model)
// All hosted via jsDelivr CDN — fast, no auth required.

const PACKS = {
  sofa: {
    img: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/screenshot/screenshot.jpg',
    glb: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
  },
  chair: {
    img: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/AntiqueChair/screenshot/screenshot.jpg',
    glb: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/AntiqueChair/glTF-Binary/AntiqueChair.glb',
  },
  // Fallback packs — alternate between the two real models
  pack_a: {
    img: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/screenshot/screenshot.jpg',
    glb: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
  },
  pack_b: {
    img: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/AntiqueChair/screenshot/screenshot.jpg',
    glb: 'https://cdn.jsdelivr.net/gh/KhronosGroup/glTF-Sample-Models@master/2.0/AntiqueChair/glTF-Binary/AntiqueChair.glb',
  },
};

// ── Keyword → pack mapping ────────────────────────────────────
const KEYWORD_MAP = [
  { pack: 'sofa',    words: ['sofa', 'couch', 'sectional', 'loveseat', 'settee', 'divan', 'futon', 'recliner'] },
  { pack: 'chair',   words: ['chair', 'stool', 'seat', 'armchair', 'wingback', 'rocking', 'bar stool', 'barstool'] },
  { pack: 'pack_a',  words: ['bed', 'mattress', 'cot', 'bunk', 'daybed', 'headboard', 'canopy'] },
  { pack: 'pack_b',  words: ['table', 'dining', 'coffee table', 'console', 'side table', 'nested', 'marble'] },
  { pack: 'sofa',    words: ['wardrobe', 'closet', 'almirah', 'dresser', 'drawer', 'armoire', 'chest'] },
  { pack: 'chair',   words: ['shelf', 'shelve', 'bookcase', 'bookshelf', 'rack', 'ladder', 'display'] },
  { pack: 'pack_a',  words: ['desk', 'writing', 'study', 'laptop', 'workstation', 'bureau', 'standing'] },
  { pack: 'pack_b',  words: ['tv', 'entertainment', 'console', 'floating', 'wall unit'] },
  { pack: 'sofa',    words: ['garden', 'outdoor', 'patio', 'lounger', 'swing', 'bench'] },
  { pack: 'chair',   words: ['lamp', 'light', 'chandelier', 'pendant', 'led', 'arc', 'sconce', 'crystal'] },
];

function getPack(name, index) {
  const lower = name.toLowerCase();
  for (const { pack, words } of KEYWORD_MAP) {
    if (words.some(w => lower.includes(w))) return PACKS[pack];
  }
  // Round-robin fallback
  return index % 2 === 0 ? PACKS.pack_a : PACKS.pack_b;
}

// ── Main ──────────────────────────────────────────────────────
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
    'SELECT id, name FROM products ORDER BY id'
  );

  if (products.length === 0) {
    console.log('⚠️  No products found. Run node seed_data.js first.');
    await client.end();
    return;
  }

  console.log(`🖼️  Replacing 2D images with 3D renders for ${products.length} products...\n`);

  for (let i = 0; i < products.length; i++) {
    const p = products[i];
    const pack = getPack(p.name, i);

    await client.query(
      `UPDATE products
       SET image_url = $1,
           ar_model  = $2,
           images    = '{}',
           images_360= '{}'
       WHERE id = $3`,
      [pack.img, pack.glb, p.id]
    );

    const imgFile = pack.img.split('/').pop();
    const glbFile = pack.glb.split('/').pop();
    console.log(`  ✓ [#${p.id}] ${p.name}`);
    console.log(`      🖼  Image  → ${imgFile}`);
    console.log(`      🧊  AR GLB → ${glbFile}\n`);
  }

  console.log(`\n🎉 Done! All ${products.length} products now have:`);
  console.log('   ✅ 3D render screenshots as product images');
  console.log('   ✅ Real .glb AR models for AR view');
  console.log('\n📱 Restart the app → Pull to refresh → Tap product → "View in AR"\n');

  await client.end();
}

run().catch(err => {
  console.error('\n❌ Failed:', err.message);
  process.exit(1);
});
