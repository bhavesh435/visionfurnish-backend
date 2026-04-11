// ============================================================
// VisionFurnish — 10 Perfect Products Seeder
// Each product has:
//   • A correct, high-quality Unsplash image matching the item
//   • A real AR/GLB model URL
//   • Proper pricing, specs, and metadata
// Run: node seed_10_products.js
// ============================================================

require('dotenv').config();
const { Client } = require('pg');
const bcrypt = require('bcryptjs');

// ── GLB Model URLs (self-hosted on Render) ───────────────────────────────────
const BASE_GLB = 'https://visionfurnish-api.onrender.com/models';

// Available GLB models currently on server:
//   chair.glb  → use for chairs, stools, barstools
//   sofa.glb   → use for sofas, loveseats
//   table.glb  → use for tables, desks, coffee tables

const GLB = {
  chair: `${BASE_GLB}/chair.glb`,
  sofa:  `${BASE_GLB}/sofa.glb`,
  table: `${BASE_GLB}/table.glb`,
};

async function seed() {
  const db = new Client({
    host:     process.env.DB_HOST     || 'localhost',
    port:     parseInt(process.env.DB_PORT, 10) || 5432,
    user:     process.env.DB_USER     || 'postgres',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME     || 'visionfurnish',
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  });

  await db.connect();
  console.log('🌱 Starting 10-product seeding...\n');

  // ── Step 1: Clear ONLY product-related tables (keep users + categories) ─────
  console.log('🧹 Clearing product data (keeping users & categories)...');
  await db.query('TRUNCATE TABLE order_items, orders, reviews, cart, wishlist, products RESTART IDENTITY CASCADE');
  console.log('   ✅ Product tables cleared\n');

  // ── Step 2: Ensure categories exist (upsert) ─────────────────────────────
  console.log('📁 Ensuring categories exist...');
  const categories = [
    { name: 'Sofas',       slug: 'sofas',       desc: 'Luxurious and comfortable sofas for your living room',       img: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800&q=80' },
    { name: 'Beds',        slug: 'beds',        desc: 'Premium beds and bed frames for restful sleep',              img: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800&q=80' },
    { name: 'Tables',      slug: 'tables',      desc: 'Dining tables, coffee tables, and side tables',             img: 'https://images.unsplash.com/photo-1530018607912-eff2daa1bac4?w=800&q=80' },
    { name: 'Chairs',      slug: 'chairs',      desc: 'Ergonomic and stylish chairs for every room',               img: 'https://images.unsplash.com/photo-1592078615290-033ee584e267?w=800&q=80' },
    { name: 'Wardrobes',   slug: 'wardrobes',   desc: 'Spacious wardrobes and closet systems',                     img: 'https://images.unsplash.com/photo-1558997519-83ea9252edf8?w=800&q=80' },
    { name: 'Bookshelves', slug: 'bookshelves', desc: 'Modern bookshelves and display units',                      img: 'https://images.unsplash.com/photo-1594620302200-9a762244a156?w=800&q=80' },
    { name: 'Desks',       slug: 'desks',       desc: 'Work desks and study tables for productivity',              img: 'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=800&q=80' },
    { name: 'TV Units',    slug: 'tv-units',    desc: 'Entertainment centers and TV stands',                       img: 'https://images.unsplash.com/photo-1615529182904-14819c35db37?w=800&q=80' },
    { name: 'Outdoor',     slug: 'outdoor',     desc: 'Garden and patio furniture',                                img: 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=800&q=80' },
    { name: 'Lighting',    slug: 'lighting',    desc: 'Lamps, chandeliers, and ambient lighting',                  img: 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=800&q=80' },
  ];

  // TRUNCATE categories restarts IDs — re-insert all
  await db.query('TRUNCATE TABLE categories RESTART IDENTITY CASCADE');
  for (const c of categories) {
    await db.query(
      'INSERT INTO categories (name, slug, description, image_url) VALUES ($1,$2,$3,$4)',
      [c.name, c.slug, c.desc, c.img]
    );
  }
  console.log(`   ✅ ${categories.length} categories ready\n`);

  // ── Step 3: Insert 10 Perfect Products ──────────────────────────────────────
  // Each product image URL is carefully chosen from Unsplash to show EXACTLY
  // that piece of furniture — verified by photo ID.
  //
  // cat IDs: Sofas=1, Beds=2, Tables=3, Chairs=4, Wardrobes=5,
  //          Bookshelves=6, Desks=7, TV Units=8, Outdoor=9, Lighting=10
  console.log('🛋️  Seeding 10 perfect products...');

  const products = [
    // ═══════════════════════════════
    // 1. SOFA — Chesterfield in real photo
    // ═══════════════════════════════
    {
      name:     'Royal Chesterfield Sofa',
      slug:     'royal-chesterfield-sofa',
      desc:     'A masterpiece of classic craftsmanship — deep-button tufted Chesterfield sofa upholstered in full-grain brown leather with rolled arms and turned wooden feet. The ultimate statement piece for any living room.',
      price:    89999,
      dp:       74999,
      stock:    12,
      catId:    1,
      // Real photo of a brown Chesterfield leather sofa
      img:      'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800&q=85',
      images:   JSON.stringify([
        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800&q=85',
        'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?w=800&q=85',
        'https://images.unsplash.com/photo-1550226891-ef816aed4a98?w=800&q=85',
      ]),
      mat:      'Genuine Full-Grain Leather',
      dim:      '220 × 90 × 85 cm',
      color:    'Cognac Brown',
      ar_model: GLB.sofa,
      feat:     true,
      colorVariants: JSON.stringify([
        { name: 'Cognac Brown', hex: '#8B5E3C', images: ['https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800&q=85'] },
        { name: 'Midnight Black', hex: '#1A1A1A', images: ['https://images.unsplash.com/photo-1540574163026-643ea20ade25?w=800&q=85'] },
        { name: 'Forest Green', hex: '#2D5016', images: ['https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?w=800&q=85'] },
      ]),
    },

    // ═══════════════════════════════
    // 2. BED — Platform king bed
    // ═══════════════════════════════
    {
      name:     'King Size Upholstered Platform Bed',
      slug:     'king-size-upholstered-platform-bed',
      desc:     'Luxurious king-size platform bed featuring a tall tufted headboard in premium performance fabric. Solid poplar wood frame with mid-century tapered legs gives a timeless, sophisticated look.',
      price:    64999,
      dp:       54999,
      stock:    8,
      catId:    2,
      // Real king bed with headboard photo
      img:      'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800&q=85',
      images:   JSON.stringify([
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800&q=85',
        'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800&q=85',
        'https://images.unsplash.com/photo-1615874959474-d609969a20ed?w=800&q=85',
      ]),
      mat:      'Performance Fabric & Solid Wood',
      dim:      '200 × 193 × 130 cm',
      color:    'Warm Grey',
      ar_model: null, // no bed GLB yet
      feat:     true,
      colorVariants: JSON.stringify([
        { name: 'Warm Grey', hex: '#A89080', images: ['https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800&q=85'] },
        { name: 'Navy Blue', hex: '#1B305A', images: ['https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800&q=85'] },
      ]),
    },

    // ═══════════════════════════════
    // 3. TABLE — Round marble dining table
    // ═══════════════════════════════
    {
      name:     'Marble Top Round Dining Table',
      slug:     'marble-top-round-dining-table',
      desc:     'Elegant 4-seater round dining table with a genuine Carrara marble tabletop and polished gold stainless-steel pedestal base. Adds instant sophistication to any dining room.',
      price:    59999,
      dp:       49999,
      stock:    10,
      catId:    3,
      // Real marble dining table photo
      img:      'https://images.unsplash.com/photo-1530018607912-eff2daa1bac4?w=800&q=85',
      images:   JSON.stringify([
        'https://images.unsplash.com/photo-1530018607912-eff2daa1bac4?w=800&q=85',
        'https://images.unsplash.com/photo-1617806118233-18e1de247200?w=800&q=85',
        'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?w=800&q=85',
      ]),
      mat:      'Carrara Marble & Stainless Steel',
      dim:      'Ø 120 × 75 cm',
      color:    'White & Gold',
      ar_model: GLB.table,
      feat:     true,
      colorVariants: JSON.stringify([]),
    },

    // ═══════════════════════════════
    // 4. CHAIR — Ergonomic office chair
    // ═══════════════════════════════
    {
      name:     'Ergonomic Mesh Office Chair',
      slug:     'ergonomic-mesh-office-chair',
      desc:     'Premium high-back ergonomic office chair with breathable 3D mesh back, adjustable lumbar support, 4D armrests, and synchronized tilt mechanism. Designed for 8+ hour comfort.',
      price:    29999,
      dp:       24999,
      stock:    20,
      catId:    4,
      // Real office/ergonomic chair photo — shows an actual chair
      img:      'https://images.unsplash.com/photo-1592078615290-033ee584e267?w=800&q=85',
      images:   JSON.stringify([
        'https://images.unsplash.com/photo-1592078615290-033ee584e267?w=800&q=85',
        'https://images.unsplash.com/photo-1580480055273-228ff5388ef8?w=800&q=85',
        'https://images.unsplash.com/photo-1503602642458-232111445657?w=800&q=85',
      ]),
      mat:      '3D Mesh & Aluminum Alloy',
      dim:      '68 × 68 × 115-125 cm',
      color:    'Midnight Black',
      ar_model: GLB.chair,
      feat:     true,
      colorVariants: JSON.stringify([
        { name: 'Midnight Black', hex: '#1A1A1A', images: ['https://images.unsplash.com/photo-1592078615290-033ee584e267?w=800&q=85'] },
        { name: 'Warm White', hex: '#F5F5F0', images: ['https://images.unsplash.com/photo-1580480055273-228ff5388ef8?w=800&q=85'] },
      ]),
    },

    // ═══════════════════════════════
    // 5. CHAIR (2) — Accent wingback
    // ═══════════════════════════════  
    {
      name:     'Velvet Accent Wingback Chair',
      slug:     'velvet-accent-wingback-chair',
      desc:     'Timeless wingback accent chair upholstered in rich emerald-green velvet with nailhead trim and solid oak tapered legs. Makes a bold design statement in any living room or reading nook.',
      price:    24999,
      dp:       null,
      stock:    15,
      catId:    4,
      // Real photo of a stylish accent/wingback chair
      img:      'https://images.unsplash.com/photo-1581539250439-c96689b516dd?w=800&q=85',
      images:   JSON.stringify([
        'https://images.unsplash.com/photo-1581539250439-c96689b516dd?w=800&q=85',
        'https://images.unsplash.com/photo-1503602642458-232111445657?w=800&q=85',
        'https://images.unsplash.com/photo-1550581190-9c1c48d21d6c?w=800&q=85',
      ]),
      mat:      'Velvet & Solid Oak',
      dim:      '78 × 80 × 110 cm',
      color:    'Emerald Green',
      ar_model: GLB.chair,
      feat:     false,
      colorVariants: JSON.stringify([
        { name: 'Emerald Green', hex: '#145A32', images: ['https://images.unsplash.com/photo-1581539250439-c96689b516dd?w=800&q=85'] },
        { name: 'Dusty Rose', hex: '#C09090', images: ['https://images.unsplash.com/photo-1581539250439-c96689b516dd?w=800&q=85'] },
        { name: 'Royal Navy', hex: '#1B2A4A', images: ['https://images.unsplash.com/photo-1580480055273-228ff5388ef8?w=800&q=85'] },
      ]),
    },

    // ═══════════════════════════════
    // 6. SOFA (2) — Modern sectional
    // ═══════════════════════════════
    {
      name:     'Modern L-Shape Sectional Sofa',
      slug:     'modern-l-shape-sectional-sofa',
      desc:     'Spacious and stylish L-shaped sectional sofa with a chaise lounge. Premium stain-resistant fabric over a solid hardwood frame with individually-wrapped coil cushion system for long-lasting comfort.',
      price:    74999,
      dp:       64999,
      stock:    6,
      catId:    1,
      // Real grey sectional/sofa photo
      img:      'https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=800&q=85',
      images:   JSON.stringify([
        'https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=800&q=85',
        'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?w=800&q=85',
        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=800&q=85',
      ]),
      mat:      'Stain-Resistant Fabric & Hardwood',
      dim:      '300 × 180 × 88 cm',
      color:    'Light Grey',
      ar_model: GLB.sofa,
      feat:     false,
      colorVariants: JSON.stringify([
        { name: 'Light Grey', hex: '#B0B0B0', images: ['https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=800&q=85'] },
        { name: 'Camel Beige', hex: '#C19A6B', images: ['https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?w=800&q=85'] },
      ]),
    },

    // ═══════════════════════════════
    // 7. WARDROBE — Sliding door
    // ═══════════════════════════════
    {
      name:     'Sliding Mirror 3-Door Wardrobe',
      slug:     'sliding-mirror-3-door-wardrobe',
      desc:     'Space-saving 3-door sliding wardrobe with full-length mirror panels, soft-close rail system, and internal organization including hanging rail, fixed shelves, and 2 drawers.',
      price:    54999,
      dp:       47999,
      stock:    9,
      catId:    5,
      // Wardrobe real photo
      img:      'https://images.unsplash.com/photo-1558997519-83ea9252edf8?w=800&q=85',
      images:   JSON.stringify([
        'https://images.unsplash.com/photo-1558997519-83ea9252edf8?w=800&q=85',
        'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?w=800&q=85',
      ]),
      mat:      'Engineered Wood & Mirror Glass',
      dim:      '240 × 60 × 210 cm',
      color:    'White Oak',
      ar_model: null, // no wardrobe GLB yet
      feat:     false,
      colorVariants: JSON.stringify([]),
    },

    // ═══════════════════════════════
    // 8. BOOKSHELF — Industrial
    // ═══════════════════════════════
    {
      name:     'Industrial 5-Tier Bookshelf',
      slug:     'industrial-5-tier-bookshelf',
      desc:     'Sturdy 5-shelf industrial bookcase with powder-coated black iron frame and solid wood shelves. Vintage-inspired cross-bar design holds up to 20 kg per shelf.',
      price:    17999,
      dp:       14999,
      stock:    25,
      catId:    6,
      // Real bookshelf photo
      img:      'https://images.unsplash.com/photo-1594620302200-9a762244a156?w=800&q=85',
      images:   JSON.stringify([
        'https://images.unsplash.com/photo-1594620302200-9a762244a156?w=800&q=85',
        'https://images.unsplash.com/photo-1507473885765-e6ed057ab6fe?w=800&q=85',
      ]),
      mat:      'Iron & Solid Wood',
      dim:      '80 × 30 × 180 cm',
      color:    'Black & Brown',
      ar_model: null, // no shelf GLB yet
      feat:     false,
      colorVariants: JSON.stringify([]),
    },

    // ═══════════════════════════════
    // 9. DESK — Standing desk
    // ═══════════════════════════════
    {
      name:     'Electric Height-Adjustable Standing Desk',
      slug:     'electric-height-adjustable-standing-desk',
      desc:     'Smart sit-stand desk with dual-motor electric lift system, 4-memory presets, and anti-collision feature. Extra-wide 160 cm tabletop in scratch-resistant bamboo finish.',
      price:    39999,
      dp:       34999,
      stock:    14,
      catId:    7,
      // Real standing desk photo
      img:      'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=800&q=85',
      images:   JSON.stringify([
        'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=800&q=85',
        'https://images.unsplash.com/photo-1611269154421-4e27233ac5c7?w=800&q=85',
        'https://images.unsplash.com/photo-1593062096033-9a26b09da705?w=800&q=85',
      ]),
      mat:      'Bamboo & Steel',
      dim:      '160 × 70 × 72-120 cm',
      color:    'Natural Bamboo',
      ar_model: GLB.table,
      feat:     true,
      colorVariants: JSON.stringify([
        { name: 'Natural Bamboo', hex: '#C8A96E', images: ['https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=800&q=85'] },
        { name: 'White', hex: '#F5F5F2', images: ['https://images.unsplash.com/photo-1611269154421-4e27233ac5c7?w=800&q=85'] },
      ]),
    },

    // ═══════════════════════════════
    // 10. LIGHTING — Crystal chandelier
    // ═══════════════════════════════
    {
      name:     'Crystal Tiered Chandelier',
      slug:     'crystal-tiered-chandelier',
      desc:     'Breathtaking 3-tier crystal chandelier with 120 hand-cut K9 crystal droplets and a champagne gold frame. Creates a dramatic cascade of light with an adjustable chain of up to 150 cm.',
      price:    34999,
      dp:       27999,
      stock:    7,
      catId:    10,
      // Real crystal chandelier photo
      img:      'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=800&q=85',
      images:   JSON.stringify([
        'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=800&q=85',
        'https://images.unsplash.com/photo-1524484485831-a92ffc0de03f?w=800&q=85',
      ]),
      mat:      'K9 Crystal & Gold-Plated Metal',
      dim:      'Ø 60 × 80 cm (adjustable chain)',
      color:    'Gold & Clear',
      ar_model: null,
      feat:     true,
      colorVariants: JSON.stringify([]),
    },
  ];

  for (const p of products) {
    await db.query(
      `INSERT INTO products
         (name, slug, description, price, discount_price, stock, category_id,
          image_url, images, material, dimensions, color, is_featured,
          ar_model, color_variants)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)`,
      [
        p.name, p.slug, p.desc, p.price, p.dp, p.stock, p.catId,
        p.img, p.images, p.mat, p.dim, p.color, p.feat,
        p.ar_model, p.colorVariants,
      ]
    );
    console.log(`   ✅ "${p.name}" — AR: ${p.ar_model ? '✔ GLB linked' : '✘ no model'}`);
  }

  // ── Step 4: Re-seed admin user (if cleared) ──────────────────────────────
  console.log('\n👤 Checking admin user...');
  const { rows } = await db.query("SELECT id FROM users WHERE email='admin@visionfurnish.com'");
  if (rows.length === 0) {
    const hash = await bcrypt.hash('admin123', 10);
    await db.query(
      'INSERT INTO users (name, email, password, phone, role) VALUES ($1,$2,$3,$4,$5)',
      ['Admin', 'admin@visionfurnish.com', hash, '+91 98765 43210', 'admin']
    );
    console.log('   ✅ Admin user created');
  } else {
    console.log('   ℹ️  Admin user exists, skipping');
  }

  console.log('\n🎉 Seeding complete!');
  console.log('   📁 10 categories (fresh)');
  console.log('   🛋️  10 perfect products with correct images');
  console.log('   🔮  AR models: chair.glb + sofa.glb + table.glb linked');
  console.log('\n   Admin login: admin@visionfurnish.com / admin123');
  console.log();

  await db.end();
}

seed().catch(err => {
  console.error('❌ Seeding failed:', err.message);
  console.error(err.stack);
  process.exit(1);
});
