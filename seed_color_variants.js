/**
 * Seeds realistic color variants for all products.
 * Each furniture category gets appropriate color options.
 *
 * Run: node seed_color_variants.js
 */

require('dotenv').config();
const { Client } = require('pg');

// ── Color Palettes per category ──────────────────────────────
const PALETTES = {
  sofa: [
    { name: 'Charcoal Grey', hex: '#4A4A4A' },
    { name: 'Warm Beige',    hex: '#C9B99A' },
    { name: 'Navy Blue',     hex: '#1B2A4A' },
    { name: 'Olive Green',   hex: '#5C6B3A' },
    { name: 'Terracotta',    hex: '#C1632F' },
  ],
  chair: [
    { name: 'Walnut Brown',  hex: '#6B3F22' },
    { name: 'Ash Grey',      hex: '#8A8A8A' },
    { name: 'Forest Green',  hex: '#2D5A27' },
    { name: 'Slate Blue',    hex: '#4A6FA5' },
    { name: 'Ivory',         hex: '#F5F0E8' },
  ],
  table: [
    { name: 'Oak Natural',   hex: '#C8A96E' },
    { name: 'Walnut Dark',   hex: '#5C3D1E' },
    { name: 'Matte White',   hex: '#F2F2F2' },
    { name: 'Jet Black',     hex: '#1A1A1A' },
    { name: 'Marble White',  hex: '#E8E4DC' },
  ],
  bed: [
    { name: 'Walnut',        hex: '#6B3F22' },
    { name: 'Pearl White',   hex: '#F0EDE8' },
    { name: 'Charcoal',      hex: '#333333' },
    { name: 'Ash Grey',      hex: '#8A8A8A' },
    { name: 'Teak Brown',    hex: '#8B5E3C' },
  ],
  shelf: [
    { name: 'Natural Oak',   hex: '#C8A96E' },
    { name: 'White',         hex: '#F5F5F5' },
    { name: 'Black Metal',   hex: '#1A1A1A' },
    { name: 'Walnut',        hex: '#5C3D1E' },
  ],
  wardrobe: [
    { name: 'Pearl White',   hex: '#F0EDE8' },
    { name: 'Walnut',        hex: '#6B3F22' },
    { name: 'Light Grey',    hex: '#C8C8C8' },
    { name: 'Midnight Black', hex: '#1A1A1A' },
  ],
  desk: [
    { name: 'Black',         hex: '#1A1A1A' },
    { name: 'White',         hex: '#F5F5F5' },
    { name: 'Oak',           hex: '#C8A96E' },
    { name: 'Walnut',        hex: '#5C3D1E' },
  ],
  tv: [
    { name: 'Walnut',        hex: '#6B3F22' },
    { name: 'White Gloss',   hex: '#F5F5F5' },
    { name: 'Dark Wenge',    hex: '#2D1B0E' },
    { name: 'Grey Oak',      hex: '#8A8070' },
  ],
  lamp: [
    { name: 'Gold',          hex: '#C9A96E' },
    { name: 'Black',         hex: '#1A1A1A' },
    { name: 'Chrome Silver', hex: '#C0C0C0' },
    { name: 'Brushed Bronze', hex: '#8B6914' },
  ],
  outdoor: [
    { name: 'Teak Natural',  hex: '#8B5E3C' },
    { name: 'Graphite',      hex: '#3D3D3D' },
    { name: 'Rust Orange',   hex: '#C04B1E' },
    { name: 'Olive',         hex: '#5C6B3A' },
  ],
};

// ── Keyword → palette mapping ────────────────────────────────
function getPalette(name, category) {
  const text = `${name} ${category}`.toLowerCase();
  if (/sofa|couch|sectional|loveseat|futon|recliner/.test(text)) return PALETTES.sofa;
  if (/chair|stool|seat|armchair|wingback|rocking|bar/.test(text)) return PALETTES.chair;
  if (/table|coffee|dining|console|nested|marble|center/.test(text)) return PALETTES.table;
  if (/bed|mattress|bunk|daybed|headboard|canopy|hydraulic/.test(text)) return PALETTES.bed;
  if (/shelf|shelves|bookcase|bookshelf|rack|display|ladder/.test(text)) return PALETTES.shelf;
  if (/wardrobe|closet|dresser|armoire|drawer|cabinet|almirah/.test(text)) return PALETTES.wardrobe;
  if (/desk|workstation|bureau|writing|study|standing|laptop/.test(text)) return PALETTES.desk;
  if (/tv|television|entertainment|media|console/.test(text)) return PALETTES.tv;
  if (/lamp|light|chandelier|pendant|sconce|led/.test(text)) return PALETTES.lamp;
  if (/outdoor|garden|patio|bench|lounger|swing/.test(text)) return PALETTES.outdoor;
  // Default: mix
  return PALETTES.sofa;
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
    `SELECT p.id, p.name, c.name AS category_name
     FROM products p
     LEFT JOIN categories c ON p.category_id = c.id
     ORDER BY p.id`
  );

  console.log(`🎨 Seeding color variants for ${products.length} products...\n`);

  for (const p of products) {
    const palette = getPalette(p.name, p.category_name || '');
    const variants = JSON.stringify(palette.map(c => ({
      name:   c.name,
      hex:    c.hex,
      images: [],          // admin can add specific images later
    })));

    await client.query(
      'UPDATE products SET color_variants = $1::jsonb WHERE id = $2',
      [variants, p.id]
    );

    const names = palette.map(c => c.name).join(', ');
    console.log(`  ✓ [#${p.id}] ${p.name}`);
    console.log(`       Colors: ${names}\n`);
  }

  console.log(`🎉 Done! ${products.length} products now have color variants.`);
  console.log('\n📱 Open mobile app → View any product AR → Color swatches will appear!\n');

  await client.end();
}

run().catch(err => {
  console.error('\n❌ Failed:', err.message);
  process.exit(1);
});
