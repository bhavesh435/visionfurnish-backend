// ============================================================
// VisionFurnish — AI Chat Service
// Cost-efficient: regex intent parsing + PostgreSQL filtering + gpt-4o-mini
// ============================================================

const OpenAI = require('openai');
const db = require('../config/db');

// ── OpenAI client (lazy init) ───────────────────────────────
let openai = null;
function getOpenAI() {
  if (!openai) {
    openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  }
  return openai;
}

// ── Category keyword map ────────────────────────────────────
const CATEGORY_KEYWORDS = {
  sofas: ['sofa', 'couch', 'sectional', 'loveseat', 'recliner', 'settee'],
  beds: ['bed', 'mattress', 'cot', 'bunk', 'platform bed', 'canopy'],
  tables: ['table', 'dining table', 'coffee table', 'center table', 'side table'],
  chairs: ['chair', 'stool', 'armchair', 'wingback', 'rocking chair', 'office chair', 'bar stool'],
  wardrobes: ['wardrobe', 'almirah', 'closet', 'cupboard', 'chest', 'drawer'],
  bookshelves: ['bookshelf', 'shelf', 'bookcase', 'rack', 'display unit'],
  desks: ['desk', 'study table', 'computer table', 'writing desk', 'laptop table', 'standing desk'],
  'tv-units': ['tv unit', 'tv stand', 'tv console', 'entertainment', 'media unit'],
  outdoor: ['outdoor', 'garden', 'patio', 'swing', 'bench', 'lounger'],
  lighting: ['lamp', 'light', 'chandelier', 'pendant', 'led strip', 'bulb'],
};

// ── Style / material keywords ───────────────────────────────
const STYLE_KEYWORDS = ['modern', 'rustic', 'industrial', 'minimalist', 'scandinavian', 'classic', 'luxury', 'premium', 'elegant', 'vintage'];
const MATERIAL_KEYWORDS = ['wood', 'wooden', 'metal', 'glass', 'marble', 'leather', 'fabric', 'velvet', 'rattan', 'bamboo', 'teak', 'oak', 'mdf'];
const COLOR_KEYWORDS = ['white', 'black', 'brown', 'grey', 'gray', 'blue', 'green', 'red', 'gold', 'beige', 'cream', 'pink', 'walnut', 'natural'];

// ══════════════════════════════════════════════════════════════
// 1. PARSE INTENT — No AI call, pure regex
// ══════════════════════════════════════════════════════════════
function parseIntent(message) {
  const lower = message.toLowerCase().trim();
  const intent = {
    category: null,
    minPrice: null,
    maxPrice: null,
    material: null,
    color: null,
    style: null,
    featured: null,
    searchTerms: [],
    isProductQuery: false,
  };

  // ── Category detection ──
  for (const [slug, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
    for (const kw of keywords) {
      if (lower.includes(kw)) {
        intent.category = slug;
        intent.isProductQuery = true;
        break;
      }
    }
    if (intent.category) break;
  }

  // ── Price extraction ──
  // "under 50000", "below 30k", "less than 20000"
  const underMatch = lower.match(/(?:under|below|less than|upto|up to|max|within)\s*(?:rs\.?|₹|inr)?\s*([\d,]+)\s*k?/i);
  if (underMatch) {
    let val = parseInt(underMatch[1].replace(/,/g, ''), 10);
    if (lower.includes('k') && val < 1000) val *= 1000;
    intent.maxPrice = val;
    intent.isProductQuery = true;
  }

  // "above 10000", "over 5000", "more than 20000"
  const aboveMatch = lower.match(/(?:above|over|more than|min|starting|from)\s*(?:rs\.?|₹|inr)?\s*([\d,]+)\s*k?/i);
  if (aboveMatch) {
    let val = parseInt(aboveMatch[1].replace(/,/g, ''), 10);
    if (lower.includes('k') && val < 1000) val *= 1000;
    intent.minPrice = val;
    intent.isProductQuery = true;
  }

  // "between 10000 and 50000", "10000-50000"
  const rangeMatch = lower.match(/(?:between|from)?\s*(?:rs\.?|₹|inr)?\s*([\d,]+)\s*(?:to|-|and)\s*(?:rs\.?|₹|inr)?\s*([\d,]+)/i);
  if (rangeMatch && !intent.maxPrice && !intent.minPrice) {
    intent.minPrice = parseInt(rangeMatch[1].replace(/,/g, ''), 10);
    intent.maxPrice = parseInt(rangeMatch[2].replace(/,/g, ''), 10);
    intent.isProductQuery = true;
  }

  // ── Material ──
  for (const mat of MATERIAL_KEYWORDS) {
    if (lower.includes(mat)) {
      intent.material = mat;
      intent.isProductQuery = true;
      break;
    }
  }

  // ── Color ──
  for (const col of COLOR_KEYWORDS) {
    if (lower.includes(col)) {
      intent.color = col;
      intent.isProductQuery = true;
      break;
    }
  }

  // ── Style ──
  for (const sty of STYLE_KEYWORDS) {
    if (lower.includes(sty)) {
      intent.style = sty;
      intent.isProductQuery = true;
      break;
    }
  }

  // ── Featured ──
  if (lower.includes('featured') || lower.includes('best') || lower.includes('popular') || lower.includes('top')) {
    intent.featured = true;
    intent.isProductQuery = true;
  }

  // General product-related words
  const productWords = ['show', 'find', 'search', 'suggest', 'recommend', 'buy', 'want', 'need', 'looking', 'price', 'cheap', 'expensive', 'budget', 'affordable'];
  for (const pw of productWords) {
    if (lower.includes(pw)) {
      intent.isProductQuery = true;
      break;
    }
  }

  return intent;
}

// ══════════════════════════════════════════════════════════════
// 2. QUERY PRODUCTS — PostgreSQL with dynamic WHERE
// ══════════════════════════════════════════════════════════════
async function queryProducts(intent) {
  if (!intent.isProductQuery) return [];

  let sql = `
    SELECT p.id, p.name, p.price, p.discount_price, p.stock, p.image_url,
           p.material, p.color, p.dimensions, p.description, p.is_featured,
           c.name AS category_name, c.slug AS category_slug
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    WHERE 1=1
  `;
  const params = [];
  let pIdx = 0;

  if (intent.category) {
    sql += ` AND c.slug = $${++pIdx}`;
    params.push(intent.category);
  }

  if (intent.maxPrice) {
    sql += ` AND p.price <= $${++pIdx}`;
    params.push(intent.maxPrice);
  }

  if (intent.minPrice) {
    sql += ` AND p.price >= $${++pIdx}`;
    params.push(intent.minPrice);
  }

  if (intent.material) {
    // ILIKE = case-insensitive LIKE in PostgreSQL
    sql += ` AND p.material ILIKE $${++pIdx}`;
    params.push(`%${intent.material}%`);
  }

  if (intent.color) {
    sql += ` AND p.color ILIKE $${++pIdx}`;
    params.push(`%${intent.color}%`);
  }

  if (intent.style) {
    sql += ` AND (p.name ILIKE $${++pIdx} OR p.description ILIKE $${pIdx + 1})`;
    pIdx++;
    params.push(`%${intent.style}%`, `%${intent.style}%`);
  }

  if (intent.featured) {
    sql += ` AND p.is_featured = true`;
  }

  sql += ' AND p.stock > 0';
  sql += ' ORDER BY p.is_featured DESC, p.price ASC';
  sql += ' LIMIT 8';

  const { rows } = await db.query(sql, params);
  return rows;
}

// ══════════════════════════════════════════════════════════════
// 3. SMART LOCAL RESPONSE — No AI needed
// ══════════════════════════════════════════════════════════════

// Complementary product suggestions
const COMPLEMENTARY = {
  sofas: ['coffee tables', 'cushions', 'rugs', 'floor lamps'],
  beds: ['bedside tables', 'wardrobes', 'mattresses', 'table lamps'],
  tables: ['chairs', 'table runners', 'pendant lights'],
  chairs: ['desks', 'cushions', 'side tables'],
  wardrobes: ['mirrors', 'chest of drawers', 'shoe racks'],
  bookshelves: ['desk lamps', 'decor items', 'study desks'],
  desks: ['office chairs', 'table lamps', 'bookshelves'],
  'tv-units': ['sofas', 'LED strip lights', 'wall shelves'],
  outdoor: ['planters', 'outdoor lighting', 'garden decor'],
  lighting: ['smart switches', 'home decor', 'wall art'],
};

// Greeting detection
const GREETINGS = ['hi', 'hello', 'hey', 'good morning', 'good evening', 'good afternoon', 'namaste', 'hii', 'hiii'];
const THANKS = ['thank', 'thanks', 'thankyou', 'thank you', 'thx'];
const HELP_WORDS = ['help', 'what can you do', 'how to', 'guide'];

function generateLocalResponse(message, products, intent) {
  const lower = message.toLowerCase().trim();

  // ── Greetings ──
  for (const g of GREETINGS) {
    if (lower.startsWith(g) || lower === g) {
      return '👋 Hello! Welcome to VisionFurnish! I can help you find the perfect furniture. Try asking me:\n\n• "Show me sofas under ₹50,000"\n• "Modern wooden chairs"\n• "Best featured products"\n• "Beds between ₹30,000 and ₹60,000"\n\nWhat are you looking for today?';
    }
  }

  // ── Thanks ──
  for (const t of THANKS) {
    if (lower.includes(t)) {
      return '😊 You\'re welcome! Happy to help. Let me know if you need anything else — I\'m here to find the perfect furniture for you!';
    }
  }

  // ── Help ──
  for (const h of HELP_WORDS) {
    if (lower.includes(h)) {
      return '🛋️ I\'m your VisionFurnish assistant! Here\'s what I can do:\n\n• 🔍 **Search products** — "sofas under 50000"\n• 🎨 **Filter by style** — "modern chairs", "rustic tables"\n• 🪵 **Filter by material** — "wooden beds", "leather sofas"\n• 🎯 **Featured picks** — "show best products"\n• 💰 **Price ranges** — "tables between 10000 and 30000"\n\nJust type what you\'re looking for!';
    }
  }

  // ── Product results ──
  if (products.length > 0) {
    const fmt = (n) => '₹' + Number(n).toLocaleString('en-IN');
    const catName = intent.category ? intent.category.charAt(0).toUpperCase() + intent.category.slice(1) : 'products';

    // Highlight top 3
    const topPicks = products.slice(0, 3);
    let reply = `🛋️ Great news! I found ${products.length} ${catName}`;
    if (intent.maxPrice) reply += ` under ${fmt(intent.maxPrice)}`;
    if (intent.minPrice && intent.maxPrice) reply = `🛋️ I found ${products.length} ${catName} between ${fmt(intent.minPrice)} and ${fmt(intent.maxPrice)}`;
    if (intent.material) reply += ` in ${intent.material}`;
    if (intent.color) reply += ` (${intent.color})`;
    reply += ' for you!\n\n';

    // Top picks with details
    reply += '⭐ **Top Picks:**\n';
    topPicks.forEach((p, i) => {
      const price = p.discount_price ? `~~${fmt(p.price)}~~ ${fmt(p.discount_price)}` : fmt(p.price);
      const save = p.discount_price ? ` (Save ${fmt(p.price - p.discount_price)}!)` : '';
      reply += `${i + 1}. **${p.name}** — ${price}${save}\n`;
      if (p.material) reply += `   Material: ${p.material}`;
      if (p.color) reply += ` | Color: ${p.color}`;
      reply += '\n';
    });

    if (products.length > 3) {
      reply += `\n...and ${products.length - 3} more options! Scroll through the cards below 👇`;
    }

    // Complementary suggestions
    if (intent.category && COMPLEMENTARY[intent.category]) {
      const suggestions = COMPLEMENTARY[intent.category].slice(0, 2).join(' or ');
      reply += `\n\n💡 **Tip:** These would pair great with ${suggestions}! Want me to find some?`;
    }

    return reply;
  }

  // ── No products found ──
  if (intent.isProductQuery && products.length === 0) {
    let reply = '😔 I couldn\'t find exact matches for your request.';
    if (intent.maxPrice && intent.maxPrice < 5000) {
      reply += ' The price range might be too low for furniture.';
    }
    reply += '\n\n**Try these tips:**\n';
    reply += '• Broaden your price range\n';
    reply += '• Try a different category (sofas, beds, tables, chairs, desks)\n';
    reply += '• Remove material/color filters\n';
    reply += '\n**Example:** "Show me all sofas" or "chairs under ₹30,000"';
    return reply;
  }

  // ── General / unknown ──
  return '🛋️ I\'m your VisionFurnish furniture assistant! I can help you find sofas, beds, tables, chairs, wardrobes, desks, lighting, and more.\n\nTry: "Show me modern sofas under ₹50,000" or "wooden beds"';
}

// ══════════════════════════════════════════════════════════════
// 4. GENERATE RESPONSE — Try OpenAI, fallback to local
// ══════════════════════════════════════════════════════════════
const SYSTEM_PROMPT = `You are VisionFurnish AI — a helpful furniture shopping assistant.

Rules:
- Be friendly, concise (2-4 sentences max)
- If products are provided, highlight top 2-3 picks with name and price
- Suggest complementary items when relevant (e.g., sofa → coffee table)
- For non-product questions, answer briefly about furniture/decor
- Use ₹ for prices
- Never invent products — only reference the provided data
- If no products match, suggest broadening the search`;

async function generateResponse(message, products, intent, history = []) {
  // Check if OpenAI key is valid
  const apiKey = process.env.OPENAI_API_KEY || '';
  if (!apiKey || apiKey === 'your_openai_api_key_here' || apiKey.length < 20) {
    return generateLocalResponse(message, products, intent);
  }

  const ai = getOpenAI();

  // Build messages array
  const messages = [{ role: 'system', content: SYSTEM_PROMPT }];

  // Add last 4 messages of history (cost control)
  const recentHistory = history.slice(-4);
  for (const h of recentHistory) {
    messages.push({ role: h.role, content: h.content });
  }

  // Build user message with product context
  let userContent = message;
  if (products.length > 0) {
    const productSummary = products.map((p, i) =>
      `${i + 1}. ${p.name} — ₹${Number(p.price).toLocaleString('en-IN')}${p.discount_price ? ` (sale: ₹${Number(p.discount_price).toLocaleString('en-IN')})` : ''} | ${p.category_name} | ${p.material || 'N/A'} | Stock: ${p.stock}`
    ).join('\n');
    userContent += `\n\n[MATCHING PRODUCTS]\n${productSummary}`;
  } else if (intent.isProductQuery) {
    userContent += '\n\n[NO MATCHING PRODUCTS FOUND]';
  }

  messages.push({ role: 'user', content: userContent });

  try {
    const completion = await ai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages,
      max_tokens: 500,
      temperature: 0.7,
    });

    return completion.choices[0].message.content;
  } catch (err) {
    console.error('OpenAI API Error:', err.message);
    // Graceful fallback to local response
    return generateLocalResponse(message, products, intent);
  }
}

// ══════════════════════════════════════════════════════════════
// 5. MAIN CHAT HANDLER
// ══════════════════════════════════════════════════════════════
async function chat(message, history = []) {
  // Step 1: Parse intent (free — no API call)
  const intent = parseIntent(message);

  // Step 2: Query DB if product-related (free — just PostgreSQL)
  const products = await queryProducts(intent);

  // Step 3: Generate response (OpenAI if available, else smart local)
  const reply = await generateResponse(message, intent.isProductQuery ? products : [], intent, history);

  // Step 4: Format products for frontend
  const formattedProducts = products.map(p => ({
    id: p.id,
    name: p.name,
    price: p.price,
    discountPrice: p.discount_price,
    image: p.image_url,
    category: p.category_name,
    material: p.material,
    color: p.color,
    stock: p.stock,
    isFeatured: !!p.is_featured,
  }));

  return {
    reply,
    products: formattedProducts,
    intent: {
      category: intent.category,
      priceRange: intent.minPrice || intent.maxPrice ? { min: intent.minPrice, max: intent.maxPrice } : null,
      isProductQuery: intent.isProductQuery,
    },
  };
}

module.exports = { chat, parseIntent, queryProducts };

