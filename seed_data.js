// ============================================================
// VisionFurnish — PostgreSQL Data Seeder
// Seeds: 10 categories, 50 products, 15 users, 20 orders, 30 reviews
// Run: node seed_data.js
// ============================================================

require('dotenv').config();
const { Client } = require('pg');
const bcrypt = require('bcryptjs');

async function seed() {
  // Use a single Client (not pool) for seeding
  const db = new Client({
    host:     process.env.DB_HOST     || 'localhost',
    port:     parseInt(process.env.DB_PORT, 10) || 5432,
    user:     process.env.DB_USER     || 'postgres',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME     || 'visionfurnish',
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  });

  await db.connect();
  console.log('🌱 Starting data seeding...\n');

  // ── Clear existing data (PostgreSQL: TRUNCATE with CASCADE) ──
  console.log('🧹 Clearing old data...');
  await db.query('TRUNCATE TABLE order_items, orders, reviews, cart, wishlist, products, categories, users RESTART IDENTITY CASCADE');

  // ══════════════════════════════════════════════
  // 1. CATEGORIES (10)
  // ══════════════════════════════════════════════
  console.log('📁 Seeding categories...');
  const categories = [
    { name: 'Sofas',       slug: 'sofas',       desc: 'Luxurious and comfortable sofas for your living room',       img: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400' },
    { name: 'Beds',        slug: 'beds',        desc: 'Premium beds and bed frames for restful sleep',              img: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=400' },
    { name: 'Tables',      slug: 'tables',      desc: 'Dining tables, coffee tables, and side tables',             img: 'https://images.unsplash.com/photo-1530018607912-eff2daa1bac4?w=400' },
    { name: 'Chairs',      slug: 'chairs',      desc: 'Ergonomic and stylish chairs for every room',               img: 'https://images.unsplash.com/photo-1592078615290-033ee584e267?w=400' },
    { name: 'Wardrobes',   slug: 'wardrobes',   desc: 'Spacious wardrobes and closet systems',                     img: 'https://images.unsplash.com/photo-1558997519-83ea9252edf8?w=400' },
    { name: 'Bookshelves', slug: 'bookshelves', desc: 'Modern bookshelves and display units',                      img: 'https://images.unsplash.com/photo-1594620302200-9a762244a156?w=400' },
    { name: 'Desks',       slug: 'desks',       desc: 'Work desks and study tables for productivity',              img: 'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=400' },
    { name: 'TV Units',    slug: 'tv-units',    desc: 'Entertainment centers and TV stands',                       img: 'https://images.unsplash.com/photo-1615529182904-14819c35db37?w=400' },
    { name: 'Outdoor',     slug: 'outdoor',     desc: 'Garden and patio furniture',                                img: 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=400' },
    { name: 'Lighting',    slug: 'lighting',    desc: 'Lamps, chandeliers, and ambient lighting',                  img: 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=400' },
  ];

  for (const c of categories) {
    await db.query(
      'INSERT INTO categories (name, slug, description, image_url) VALUES ($1,$2,$3,$4)',
      [c.name, c.slug, c.desc, c.img]
    );
  }
  console.log(`   ✅ ${categories.length} categories added`);

  // ══════════════════════════════════════════════
  // 2. USERS (16 total: 1 admin + 15 customers)
  // ══════════════════════════════════════════════
  console.log('👥 Seeding users...');
  const hash     = await bcrypt.hash('admin123', 10);
  const userHash = await bcrypt.hash('user123',  10);

  await db.query(
    'INSERT INTO users (name, email, password, phone, role) VALUES ($1,$2,$3,$4,$5)',
    ['Admin', 'admin@visionfurnish.com', hash, '+91 98765 43210', 'admin']
  );

  const userNames = [
    { name: 'Rahul Sharma',    email: 'rahul.sharma@gmail.com',    phone: '+91 98001 10001' },
    { name: 'Priya Patel',     email: 'priya.patel@gmail.com',     phone: '+91 98001 10002' },
    { name: 'Amit Kumar',      email: 'amit.kumar@gmail.com',      phone: '+91 98001 10003' },
    { name: 'Sneha Reddy',     email: 'sneha.reddy@gmail.com',     phone: '+91 98001 10004' },
    { name: 'Vikram Singh',    email: 'vikram.singh@gmail.com',    phone: '+91 98001 10005' },
    { name: 'Anjali Gupta',    email: 'anjali.gupta@gmail.com',    phone: '+91 98001 10006' },
    { name: 'Rohit Joshi',     email: 'rohit.joshi@gmail.com',     phone: '+91 98001 10007' },
    { name: 'Kavita Menon',    email: 'kavita.menon@gmail.com',    phone: '+91 98001 10008' },
    { name: 'Suresh Nair',     email: 'suresh.nair@gmail.com',     phone: '+91 98001 10009' },
    { name: 'Deepa Iyer',      email: 'deepa.iyer@gmail.com',      phone: '+91 98001 10010' },
    { name: 'Arjun Mehta',     email: 'arjun.mehta@gmail.com',     phone: '+91 98001 10011' },
    { name: 'Neha Verma',      email: 'neha.verma@gmail.com',      phone: '+91 98001 10012' },
    { name: 'Karan Malhotra',  email: 'karan.malhotra@gmail.com',  phone: '+91 98001 10013' },
    { name: 'Pooja Desai',     email: 'pooja.desai@gmail.com',     phone: '+91 98001 10014' },
    { name: 'Manish Agarwal',  email: 'manish.agarwal@gmail.com',  phone: '+91 98001 10015' },
  ];

  for (const u of userNames) {
    await db.query(
      'INSERT INTO users (name, email, password, phone, role) VALUES ($1,$2,$3,$4,$5)',
      [u.name, u.email, userHash, u.phone, 'user']
    );
  }
  console.log(`   ✅ ${userNames.length + 1} users added`);

  // ══════════════════════════════════════════════
  // 3. PRODUCTS (50)
  // ══════════════════════════════════════════════
  console.log('🛋️  Seeding products...');
  const products = [
    // ── Sofas (cat 1) ──
    { name: 'Royal Chesterfield Sofa',    slug: 'royal-chesterfield-sofa',    desc: 'Classic tufted Chesterfield sofa with premium leather upholstery.',    price: 89999, dp: 79999, stock: 12, catId: 1, img: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400',    mat: 'Genuine Leather', dim: '220x90x85 cm',     color: 'Brown',       feat: true },
    { name: 'Modern L-Shape Sectional',   slug: 'modern-l-shape-sectional',   desc: 'Spacious L-shaped sectional sofa with chaise lounge.',                  price: 64999, dp: null,  stock: 8,  catId: 1, img: 'https://images.unsplash.com/photo-1550226891-ef816aed4a98?w=400',  mat: 'Fabric',          dim: '300x180x85 cm',  color: 'Grey',        feat: true },
    { name: 'Velvet 3-Seater Sofa',       slug: 'velvet-3-seater-sofa',       desc: 'Elegant velvet upholstered sofa with gold-tone legs.',                  price: 45999, dp: 39999, stock: 15, catId: 1, img: 'https://images.unsplash.com/photo-1493663284031-b7e3aefcae8e?w=400', mat: 'Velvet',          dim: '200x85x80 cm',   color: 'Navy Blue',   feat: false },
    { name: 'Scandinavian Loveseat',      slug: 'scandinavian-loveseat',      desc: 'Minimalist 2-seater loveseat with clean lines and wooden frame.',       price: 29999, dp: null,  stock: 20, catId: 1, img: 'https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=400', mat: 'Linen',           dim: '150x80x78 cm',   color: 'Beige',       feat: false },
    { name: 'Recliner Sofa Set',          slug: 'recliner-sofa-set',          desc: 'Power reclining sofa set with USB charging ports.',                     price: 119999, dp: 99999, stock: 5, catId: 1, img: 'https://images.unsplash.com/photo-1540574163026-643ea20ade25?w=400', mat: 'Leatherette',    dim: '250x95x100 cm',  color: 'Black',       feat: true },
    // ── Beds (cat 2) ──
    { name: 'King Size Platform Bed',     slug: 'king-size-platform-bed',     desc: 'Solid wood platform bed with upholstered headboard.',                   price: 54999, dp: 49999, stock: 10, catId: 2, img: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=400', mat: 'Sheesham Wood',  dim: '200x180x120 cm', color: 'Walnut',      feat: true },
    { name: 'Queen Upholstered Bed',      slug: 'queen-upholstered-bed',      desc: 'Luxurious queen bed with tufted velvet headboard.',                     price: 42999, dp: null,  stock: 14, catId: 2, img: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=400', mat: 'Engineered Wood', dim: '200x160x110 cm', color: 'Grey',        feat: false },
    { name: 'Storage Hydraulic Bed',      slug: 'storage-hydraulic-bed',      desc: 'Space-saving hydraulic storage bed with gas lift mechanism.',           price: 37999, dp: 34999, stock: 18, catId: 2, img: 'https://images.unsplash.com/photo-1588046130717-0eb0c9a3ba15?w=400', mat: 'MDF',            dim: '195x150x100 cm', color: 'White',       feat: false },
    { name: 'Four Poster Canopy Bed',     slug: 'four-poster-canopy-bed',     desc: 'Elegant four-poster bed with canopy frame and carved wood details.',    price: 78999, dp: null,  stock: 6,  catId: 2, img: 'https://images.unsplash.com/photo-1617325247661-675ab4b64ae2?w=400', mat: 'Teak Wood',      dim: '210x190x220 cm', color: 'Dark Brown',  feat: true },
    { name: 'Minimalist Wooden Bed',      slug: 'minimalist-wooden-bed',      desc: 'Japanese-inspired low platform bed with clean geometric design.',       price: 31999, dp: 27999, stock: 22, catId: 2, img: 'https://images.unsplash.com/photo-1615874959474-d609969a20ed?w=400', mat: 'Pine Wood',      dim: '200x150x45 cm',  color: 'Natural',     feat: false },
    // ── Tables (cat 3) ──
    { name: 'Marble Top Dining Table',   slug: 'marble-top-dining-table',   desc: '6-seater dining table with Italian marble top and gold metal base.', price: 69999, dp: 59999, stock: 8,  catId: 3, img: 'https://images.unsplash.com/photo-1530018607912-eff2daa1bac4?w=400', mat: 'Marble & Metal',  dim: '180x90x75 cm',  color: 'White & Gold', feat: true },
    { name: 'Rustic Wood Coffee Table',  slug: 'rustic-wood-coffee-table',  desc: 'Handcrafted solid wood coffee table with natural grain finish.',     price: 18999, dp: null,  stock: 25, catId: 3, img: 'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?w=400', mat: 'Mango Wood',      dim: '120x60x45 cm',  color: 'Natural',      feat: false },
    { name: 'Glass Center Table',        slug: 'glass-center-table',        desc: 'Contemporary tempered glass center table with chrome base.',         price: 15999, dp: 13999, stock: 30, catId: 3, img: 'https://images.unsplash.com/photo-1532372576444-dda954194ad0?w=400', mat: 'Glass & Chrome',  dim: '110x60x40 cm',  color: 'Clear',        feat: false },
    { name: 'Extendable Dining Table',   slug: 'extendable-dining-table',   desc: '4-to-8 seater extendable dining table with butterfly leaf.',        price: 44999, dp: null,  stock: 12, catId: 3, img: 'https://images.unsplash.com/photo-1617806118233-18e1de247200?w=400', mat: 'Sheesham Wood',   dim: '150-210x90x77', color: 'Honey',        feat: false },
    { name: 'Nested Side Tables Set',    slug: 'nested-side-tables-set',    desc: 'Set of 3 nesting side tables with brass finish frames.',            price: 12999, dp: 10999, stock: 35, catId: 3, img: 'https://images.unsplash.com/photo-1499933374294-4584851497cc?w=400', mat: 'Metal & Wood',    dim: '50x50x55 cm',   color: 'Gold & Walnut',feat: false },
    // ── Chairs (cat 4) ──
    { name: 'Ergonomic Office Chair',    slug: 'ergonomic-office-chair',    desc: 'High-back ergonomic mesh chair with lumbar support.',               price: 24999, dp: 21999, stock: 20, catId: 4, img: 'https://images.unsplash.com/photo-1592078615290-033ee584e267?w=400', mat: 'Mesh & Metal',   dim: '65x65x120 cm',  color: 'Black',        feat: true },
    { name: 'Accent Wingback Chair',     slug: 'accent-wingback-chair',     desc: 'Classic wingback accent chair with nailhead trim.',                 price: 19999, dp: null,  stock: 16, catId: 4, img: 'https://images.unsplash.com/photo-1580480055273-228ff5388ef8?w=400', mat: 'Fabric',         dim: '75x80x105 cm',  color: 'Emerald Green',feat: false },
    { name: 'Dining Chair Set (4)',      slug: 'dining-chair-set-4',        desc: 'Set of 4 upholstered dining chairs with solid wood legs.',          price: 22999, dp: 19999, stock: 18, catId: 4, img: 'https://images.unsplash.com/photo-1503602642458-232111445657?w=400', mat: 'Fabric & Wood',  dim: '45x50x90 cm',   color: 'Cream',        feat: false },
    { name: 'Rocking Chair',             slug: 'rocking-chair',             desc: 'Solid wood rocking chair with woven cane seat.',                    price: 16999, dp: null,  stock: 14, catId: 4, img: 'https://images.unsplash.com/photo-1581539250439-c96689b516dd?w=400', mat: 'Teak & Cane',    dim: '60x80x110 cm',  color: 'Natural',      feat: false },
    { name: 'Swivel Bar Stool Set (2)',  slug: 'swivel-bar-stool-set-2',    desc: 'Set of 2 adjustable height bar stools with velvet seat.',           price: 13999, dp: 11999, stock: 24, catId: 4, img: 'https://images.unsplash.com/photo-1550581190-9c1c48d21d6c?w=400', mat: 'Metal & Velvet', dim: '40x40x95 cm',   color: 'Blush Pink',   feat: false },
    // ── Wardrobes (cat 5) ──
    { name: 'Sliding Door Wardrobe',     slug: 'sliding-door-wardrobe',     desc: '3-door sliding wardrobe with mirror and internal drawers.',         price: 59999, dp: 54999, stock: 7,  catId: 5, img: 'https://images.unsplash.com/photo-1558997519-83ea9252edf8?w=400',  mat: 'Engineered Wood',dim: '240x60x210 cm', color: 'White & Oak',  feat: true },
    { name: 'Walk-in Closet System',     slug: 'walk-in-closet-system',     desc: 'Modular walk-in closet with adjustable shelves.',                   price: 89999, dp: null,  stock: 4,  catId: 5, img: 'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?w=400', mat: 'Plywood',        dim: '300x60x240 cm', color: 'Grey',         feat: false },
    { name: 'Single Door Almirah',       slug: 'single-door-almirah',       desc: 'Compact single-door almirah with locker.',                          price: 14999, dp: null,  stock: 30, catId: 5, img: 'https://images.unsplash.com/photo-1597072689227-8882273e8f6a?w=400', mat: 'Metal',          dim: '90x45x180 cm',  color: 'Ivory',        feat: false },
    { name: 'Chest of Drawers',          slug: 'chest-of-drawers',          desc: '6-drawer chest with soft-close mechanism and walnut finish.',       price: 24999, dp: 21999, stock: 15, catId: 5, img: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400',  mat: 'Solid Wood',     dim: '90x45x120 cm',  color: 'Walnut',       feat: false },
    { name: 'Kids Wardrobe',             slug: 'kids-wardrobe',             desc: 'Colorful kids wardrobe with fun handles.',                          price: 19999, dp: 17999, stock: 20, catId: 5, img: 'https://images.unsplash.com/photo-1616627547584-bf28cee262db?w=400', mat: 'MDF',            dim: '120x50x170 cm', color: 'Multi-Color',  feat: false },
    // ── Bookshelves (cat 6) ──
    { name: 'Industrial Bookshelf',      slug: 'industrial-bookshelf',      desc: '5-tier industrial style bookshelf with metal frame.',               price: 17999, dp: 15999, stock: 22, catId: 6, img: 'https://images.unsplash.com/photo-1594620302200-9a762244a156?w=400', mat: 'Metal & Wood',   dim: '80x30x180 cm',  color: 'Black & Brown',feat: true },
    { name: 'Wall Mounted Shelves',      slug: 'wall-mounted-shelves',      desc: 'Set of 3 floating wall shelves with invisible bracket.',            price: 4999,  dp: null,  stock: 50, catId: 6, img: 'https://images.unsplash.com/photo-1507473885765-e6ed057ab6fe?w=400', mat: 'MDF',            dim: '60x20x2 cm',    color: 'White',        feat: false },
    { name: 'Ladder Bookcase',           slug: 'ladder-bookcase',           desc: 'Leaning ladder bookcase with 4 open shelves.',                      price: 11999, dp: 9999,  stock: 28, catId: 6, img: 'https://images.unsplash.com/photo-1588628566587-dbd176de94b4?w=400', mat: 'Bamboo',         dim: '60x35x150 cm',  color: 'Natural',      feat: false },
    { name: 'Corner Display Unit',       slug: 'corner-display-unit',       desc: 'Space-saving corner display unit with glass doors and LED.',        price: 22999, dp: null,  stock: 10, catId: 6, img: 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?w=400', mat: 'Engineered Wood',dim: '60x60x180 cm',  color: 'Wenge',        feat: false },
    { name: 'Kids Book Organizer',       slug: 'kids-book-organizer',       desc: 'Child-friendly book organizer with sling pockets.',                 price: 7999,  dp: 6499,  stock: 35, catId: 6, img: 'https://images.unsplash.com/photo-1614624532983-4ce03382d63d?w=400', mat: 'Fabric & Wood',  dim: '70x30x80 cm',   color: 'Pastel',       feat: false },
    // ── Desks (cat 7) ──
    { name: 'Executive Writing Desk',    slug: 'executive-writing-desk',    desc: 'Premium executive desk with leather inlay top.',                    price: 44999, dp: 39999, stock: 9,  catId: 7, img: 'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=400', mat: 'Mahogany',       dim: '150x70x78 cm',  color: 'Dark Brown',   feat: true },
    { name: 'Standing Desk',             slug: 'standing-desk',             desc: 'Electric height-adjustable standing desk with memory presets.',     price: 34999, dp: null,  stock: 15, catId: 7, img: 'https://images.unsplash.com/photo-1611269154421-4e27233ac5c7?w=400', mat: 'MDF & Steel',    dim: '140x70x72-120', color: 'White & Black',feat: true },
    { name: 'Compact Study Table',       slug: 'compact-study-table',       desc: 'Space-efficient study table with bookshelf and drawer unit.',       price: 12999, dp: 10999, stock: 25, catId: 7, img: 'https://images.unsplash.com/photo-1593062096033-9a26b09da705?w=400', mat: 'Engineered Wood',dim: '100x50x75 cm',  color: 'Maple',        feat: false },
    { name: 'Computer Desk with Hutch',  slug: 'computer-desk-with-hutch',  desc: 'L-shaped computer desk with hutch and cable management.',           price: 27999, dp: null,  stock: 12, catId: 7, img: 'https://images.unsplash.com/photo-1616627561950-9f746e330187?w=400', mat: 'Particle Board', dim: '160x120x145 cm',color: 'Oak',          feat: false },
    { name: 'Folding Laptop Table',      slug: 'folding-laptop-table',      desc: 'Portable folding laptop table with adjustable tilt.',               price: 3499,  dp: 2999,  stock: 60, catId: 7, img: 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=400', mat: 'Aluminum & MDF', dim: '60x40x30 cm',   color: 'Silver',       feat: false },
    // ── TV Units (cat 8) ──
    { name: 'Floating TV Wall Unit',     slug: 'floating-tv-wall-unit',     desc: 'Wall-mounted TV unit with LED backlight.',                          price: 32999, dp: 28999, stock: 11, catId: 8, img: 'https://images.unsplash.com/photo-1615529182904-14819c35db37?w=400', mat: 'MDF',            dim: '180x40x45 cm',  color: 'Matte Black',  feat: true },
    { name: 'Rustic TV Console',         slug: 'rustic-tv-console',         desc: 'Reclaimed wood TV console with iron accents.',                      price: 24999, dp: null,  stock: 14, catId: 8, img: 'https://images.unsplash.com/photo-1600210492493-0946911123ea?w=400', mat: 'Reclaimed Wood', dim: '150x45x55 cm',  color: 'Distressed Brown',feat: false },
    { name: 'Modern TV Stand Storage',   slug: 'modern-tv-stand-storage',   desc: 'Sleek TV stand with push-to-open doors.',                           price: 19999, dp: 17999, stock: 18, catId: 8, img: 'https://images.unsplash.com/photo-1585412727339-54e4bae3bbf9?w=400', mat: 'Engineered Wood',dim: '160x40x50 cm',  color: 'White & Walnut',feat: false },
    { name: 'Entertainment Wall System', slug: 'entertainment-wall-system', desc: 'Full wall entertainment system with shelves and cabinets.',         price: 74999, dp: 64999, stock: 5,  catId: 8, img: 'https://images.unsplash.com/photo-1593784991095-a205069470b6?w=400', mat: 'Plywood & Veneer',dim: '300x40x210 cm', color: 'Teak',         feat: true },
    { name: 'Corner TV Unit',            slug: 'corner-tv-unit',            desc: 'Space-saving corner TV unit for compact living rooms.',             price: 14999, dp: null,  stock: 20, catId: 8, img: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400', mat: 'Particle Board', dim: '110x45x50 cm',  color: 'Sonoma Oak',   feat: false },
    // ── Outdoor (cat 9) ──
    { name: 'Garden Sofa Set',           slug: 'garden-sofa-set',           desc: 'Weather-resistant 5-piece garden sofa set with cushions.',         price: 56999, dp: 49999, stock: 8,  catId: 9, img: 'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=400', mat: 'Rattan & Metal', dim: '250x150x80 cm', color: 'Grey & White', feat: true },
    { name: 'Patio Dining Set',          slug: 'patio-dining-set',          desc: '6-seater outdoor dining set with umbrella hole.',                   price: 38999, dp: null,  stock: 10, catId: 9, img: 'https://images.unsplash.com/photo-1533044309907-0fa3413da946?w=400', mat: 'Teak Wood',      dim: '180x90x75 cm',  color: 'Natural Teak', feat: false },
    { name: 'Hanging Swing Chair',       slug: 'hanging-swing-chair',       desc: 'Boho-style hanging egg chair with stand and wide cushion.',         price: 22999, dp: 19999, stock: 15, catId: 9, img: 'https://images.unsplash.com/photo-1520950237264-40f632d3ff39?w=400', mat: 'PE Rattan',      dim: '105x105x195 cm',color: 'Brown',        feat: true },
    { name: 'Garden Bench',              slug: 'garden-bench',              desc: 'Cast iron and wood garden bench with curved armrests.',             price: 11999, dp: null,  stock: 20, catId: 9, img: 'https://images.unsplash.com/photo-1572025442646-866d16c84a54?w=400', mat: 'Cast Iron & Wood',dim: '130x55x80 cm',  color: 'Green & Brown',feat: false },
    { name: 'Outdoor Lounger',           slug: 'outdoor-lounger',           desc: 'Adjustable poolside sun lounger with headrest and wheels.',         price: 15999, dp: 13999, stock: 16, catId: 9, img: 'https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=400', mat: 'Aluminum',       dim: '190x65x35 cm',  color: 'Black',        feat: false },
    // ── Lighting (cat 10) ──
    { name: 'Crystal Chandelier',        slug: 'crystal-chandelier',        desc: 'Stunning multi-tier crystal chandelier for living rooms.',          price: 34999, dp: 29999, stock: 6,  catId:10, img: 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=400', mat: 'Crystal & Metal',dim: '60x60x70 cm',   color: 'Gold & Clear', feat: true },
    { name: 'Floor Arc Lamp',            slug: 'floor-arc-lamp',            desc: 'Modern arc floor lamp with marble base and adjustable shade.',     price: 12999, dp: null,  stock: 20, catId:10, img: 'https://images.unsplash.com/photo-1507473885765-e6ed057ab6fe?w=400', mat: 'Metal & Marble', dim: '35x35x180 cm',  color: 'Brass',        feat: false },
    { name: 'Table Lamp Set (2)',         slug: 'table-lamp-set-2',          desc: 'Set of 2 ceramic table lamps with linen drum shades.',             price: 6999,  dp: 5999,  stock: 40, catId:10, img: 'https://images.unsplash.com/photo-1543198126-a8ad8e39e6ae?w=400', mat: 'Ceramic & Linen',dim: '30x30x50 cm',   color: 'Navy & White', feat: false },
    { name: 'Pendant Cluster Light',     slug: 'pendant-cluster-light',     desc: '5-light pendant cluster with Edison bulbs.',                        price: 9999,  dp: 8499,  stock: 18, catId:10, img: 'https://images.unsplash.com/photo-1524484485831-a92ffc0de03f?w=400', mat: 'Metal & Glass',  dim: '50x50x100 cm',  color: 'Matte Black',  feat: false },
    { name: 'Smart LED Strip Kit',       slug: 'smart-led-strip-kit',       desc: 'WiFi-enabled RGB LED strip kit, 10m length, app-controlled.',       price: 2999,  dp: 2499,  stock: 80, catId:10, img: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=400', mat: 'Silicone & LED', dim: '10m strip',      color: 'RGB Multi',    feat: false },
  ];

  for (const p of products) {
    await db.query(
      `INSERT INTO products
         (name, slug, description, price, discount_price, stock, category_id,
          image_url, material, dimensions, color, is_featured)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
      [p.name, p.slug, p.desc, p.price, p.dp, p.stock, p.catId,
       p.img, p.mat, p.dim, p.color, p.feat]
    );
  }
  console.log(`   ✅ ${products.length} products added`);

  // ══════════════════════════════════════════════
  // 4. ORDERS (20) — spread across last 6 months
  // ══════════════════════════════════════════════
  console.log('📦 Seeding orders...');
  const statuses  = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];
  const cities    = ['Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai', 'Pune', 'Kolkata', 'Ahmedabad', 'Jaipur', 'Lucknow'];
  const states    = ['Maharashtra', 'Delhi', 'Karnataka', 'Telangana', 'Tamil Nadu', 'Maharashtra', 'West Bengal', 'Gujarat', 'Rajasthan', 'Uttar Pradesh'];
  const payments  = ['cod', 'upi', 'card', 'netbanking'];

  for (let i = 0; i < 20; i++) {
    const userId   = 2 + Math.floor(Math.random() * 15);
    const cityIdx  = Math.floor(Math.random() * cities.length);
    const status   = statuses[Math.floor(Math.random() * statuses.length)];
    const payment  = payments[Math.floor(Math.random() * payments.length)];
    const zip      = (400001 + Math.floor(Math.random() * 99999)).toString();

    const monthsAgo = Math.floor(Math.random() * 6);
    const daysAgo   = Math.floor(Math.random() * 28);
    const orderDate = new Date();
    orderDate.setMonth(orderDate.getMonth() - monthsAgo);
    orderDate.setDate(1 + daysAgo);

    const numItems = 1 + Math.floor(Math.random() * 4);
    const pickedProducts = [];
    const usedIds = new Set();
    for (let j = 0; j < numItems; j++) {
      let prodIdx;
      do { prodIdx = Math.floor(Math.random() * products.length); } while (usedIds.has(prodIdx));
      usedIds.add(prodIdx);
      const qty = 1 + Math.floor(Math.random() * 3);
      pickedProducts.push({ prodId: prodIdx + 1, qty, price: products[prodIdx].price });
    }
    const total = pickedProducts.reduce((sum, pp) => sum + pp.price * pp.qty, 0);

    // PostgreSQL: RETURNING id instead of insertId
    const { rows: [{ id: orderId }] } = await db.query(
      `INSERT INTO orders
         (user_id, total, status, shipping_address, city, state, zip_code, phone, payment_method, created_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
       RETURNING id`,
      [userId, total, status, `${100 + i} Main Street, Sector ${10 + i}`,
       cities[cityIdx], states[cityIdx], zip,
       `+91 9${String(8000100000 + i).slice(1)}`, payment, orderDate]
    );

    for (const item of pickedProducts) {
      await db.query(
        'INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES ($1,$2,$3,$4)',
        [orderId, item.prodId, item.qty, item.price]
      );
    }
  }
  console.log('   ✅ 20 orders added (spread across 6 months)');

  // ══════════════════════════════════════════════
  // 5. REVIEWS (30)
  // ══════════════════════════════════════════════
  console.log('⭐ Seeding reviews...');
  const comments = [
    'Excellent quality! Looks even better in person.',
    'Very comfortable and well-built. Highly recommend.',
    'Great value for money. Fast delivery too.',
    'Beautiful design, matches my living room perfectly.',
    'Sturdy construction, easy to assemble.',
    'Love the color and finish. Premium feel.',
    'Good product but delivery took longer than expected.',
    'Exactly as shown in the pictures. Very happy!',
    'Amazing craftsmanship. Worth every rupee.',
    'Decent quality for the price point.',
  ];

  const usedReviews = new Set();
  let reviewCount = 0;
  while (reviewCount < 30) {
    const userId    = 2 + Math.floor(Math.random() * 15);
    const productId = 1 + Math.floor(Math.random() * 50);
    const key = `${userId}-${productId}`;
    if (usedReviews.has(key)) continue;
    usedReviews.add(key);

    const rating  = 3 + Math.floor(Math.random() * 3);
    const comment = comments[Math.floor(Math.random() * comments.length)];

    await db.query(
      'INSERT INTO reviews (user_id, product_id, rating, comment) VALUES ($1,$2,$3,$4)',
      [userId, productId, rating, comment]
    );
    reviewCount++;
  }
  console.log('   ✅ 30 reviews added');

  // ══════════════════════════════════════════════
  console.log('\n🎉 Seeding complete!');
  console.log('   📁 10 categories');
  console.log('   👥 16 users (1 admin + 15 customers)');
  console.log('   🛋️  50 products');
  console.log('   📦 20 orders');
  console.log('   ⭐ 30 reviews');
  console.log('\n   Admin login: admin@visionfurnish.com / admin123');
  console.log('   User login:  rahul.sharma@gmail.com / user123\n');

  await db.end();
}

seed().catch(err => {
  console.error('❌ Seeding failed:', err.message);
  process.exit(1);
});
