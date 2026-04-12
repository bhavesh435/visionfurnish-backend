/**
 * ═══════════════════════════════════════════════════════════════
 *  Download ALL Free Furniture GLB Models
 * ═══════════════════════════════════════════════════════════════
 * 
 * Source: KhronosGroup/glTF-Sample-Assets (CC0 / CC BY 4.0)
 * These are professional-quality, AR-ready 3D models.
 * 
 * Run:  node download_all_furniture.js
 * 
 * After downloading:
 *   1. git add models/
 *   2. git commit -m "Add new furniture GLB models"
 *   3. git push origin main
 *   4. Wait for Render to redeploy (~5 min)
 *   5. Update product ar_model URLs in admin panel
 * ═══════════════════════════════════════════════════════════════
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

const MODELS_DIR = path.join(__dirname, 'models');
if (!fs.existsSync(MODELS_DIR)) fs.mkdirSync(MODELS_DIR, { recursive: true });

const BASE = 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models';

// ══════════════════════════════════════════════════════════════
//  ALL FREE FURNITURE GLB MODELS (KhronosGroup)
// ══════════════════════════════════════════════════════════════

const ALL_MODELS = [
  // ── Chairs ────────────────────────────────────────────────
  {
    name: 'chair.glb',
    url: `${BASE}/SheenChair/glTF-Binary/SheenChair.glb`,
    category: '🪑 Chair',
    desc: 'Fabric director chair (Wayfair)',
    license: 'CC0',
  },
  {
    name: 'chair_damask.glb',
    url: `${BASE}/ChairDamaskPurplegold/glTF-Binary/ChairDamaskPurplegold.glb`,
    category: '🪑 Chair',
    desc: 'Luxury purple-gold damask accent chair (Wayfair)',
    license: 'CC BY 4.0',
  },

  // ── Sofas ─────────────────────────────────────────────────
  {
    name: 'sofa.glb',
    url: `${BASE}/GlamVelvetSofa/glTF-Binary/GlamVelvetSofa.glb`,
    category: '🛋️ Sofa',
    desc: 'Glamorous velvet sofa (Wayfair)',
    license: 'CC BY 4.0',
  },
  {
    name: 'sofa_leather.glb',
    url: `${BASE}/SheenWoodLeatherSofa/glTF-Binary/SheenWoodLeatherSofa.glb`,
    category: '🛋️ Sofa',
    desc: 'Wood & leather sofa with sheen',
    license: 'CC0 / CC BY 4.0',
  },

  // ── Tables / Furniture ────────────────────────────────────
  {
    name: 'pouf.glb',
    url: `${BASE}/SpecularSilkPouf/glTF-Binary/SpecularSilkPouf.glb`,
    category: '🪑 Ottoman',
    desc: 'Silk pouf / ottoman (Wayfair)',
    license: 'CC BY 4.0',
  },

  // ── Lamps / Lighting ──────────────────────────────────────
  {
    name: 'lamp.glb',
    url: `${BASE}/AnisotropyBarnLamp/glTF-Binary/AnisotropyBarnLamp.glb`,
    category: '💡 Lamp',
    desc: 'Barn lamp (Wayfair)',
    license: 'CC BY 4.0',
  },
  {
    name: 'lamp_iridescent.glb',
    url: `${BASE}/IridescenceLamp/glTF-Binary/IridescenceLamp.glb`,
    category: '💡 Lamp',
    desc: 'Iridescent glass lamp (Wayfair)',
    license: 'CC BY 4.0',
  },
  {
    name: 'lamp_desk.glb',
    url: `${BASE}/LightsPunctualLamp/glTF-Binary/LightsPunctualLamp.glb`,
    category: '💡 Lamp',
    desc: 'Desk/table punctual lamp',
    license: 'CC BY 4.0',
  },
  {
    name: 'lantern.glb',
    url: `${BASE}/Lantern/glTF-Binary/Lantern.glb`,
    category: '💡 Lamp',
    desc: 'Old wooden street lantern',
    license: 'CC0',
  },

  // ── Home Decor ────────────────────────────────────────────
  {
    name: 'candle_holder.glb',
    url: `${BASE}/GlassHurricaneCandleHolder/glTF-Binary/GlassHurricaneCandleHolder.glb`,
    category: '🕯️ Decor',
    desc: 'Glass hurricane candle holder (Wayfair)',
    license: 'CC BY 4.0',
  },
  {
    name: 'vase_flowers.glb',
    url: `${BASE}/GlassVaseFlowers/glTF-Binary/GlassVaseFlowers.glb`,
    category: '🌸 Decor',
    desc: 'Glass vase with flowers',
    license: 'CC0',
  },
  {
    name: 'plant.glb',
    url: `${BASE}/DiffuseTransmissionPlant/glTF-Binary/DiffuseTransmissionPlant.glb`,
    category: '🌿 Decor',
    desc: 'Potted plant with translucent leaves',
    license: 'CC BY 4.0',
  },
];

// ══════════════════════════════════════════════════════════════

function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    if (fs.existsSync(dest)) fs.unlinkSync(dest);
    const file = fs.createWriteStream(dest);

    function follow(currentUrl, redirects = 0) {
      if (redirects > 10) return reject(new Error('Too many redirects'));
      const proto = currentUrl.startsWith('https') ? https : require('http');
      proto.get(currentUrl, (res) => {
        if ([301, 302, 307, 308].includes(res.statusCode)) {
          return follow(res.headers.location, redirects + 1);
        }
        if (res.statusCode !== 200) {
          file.close();
          fs.unlink(dest, () => {});
          return reject(new Error(`HTTP ${res.statusCode}`));
        }
        res.pipe(file);
        file.on('finish', () => file.close(resolve));
      }).on('error', (err) => {
        file.close();
        fs.unlink(dest, () => {});
        reject(err);
      });
    }
    follow(url);
  });
}

async function main() {
  console.log('');
  console.log('═══════════════════════════════════════════════════════');
  console.log('  📥  Downloading FREE Furniture GLB Models');
  console.log('═══════════════════════════════════════════════════════');
  console.log('');

  let downloaded = 0;
  let skipped = 0;

  for (const item of ALL_MODELS) {
    const dest = path.join(MODELS_DIR, item.name);
    process.stdout.write(`  ${item.category}  ${item.name} ... `);
    
    // Skip if already exists and is valid
    if (fs.existsSync(dest) && fs.statSync(dest).size > 1000) {
      const size = (fs.statSync(dest).size / 1024).toFixed(0);
      console.log(`⏭️  already exists (${size} KB)`);
      skipped++;
      continue;
    }

    try {
      await downloadFile(item.url, dest);
      const size = (fs.statSync(dest).size / 1024).toFixed(0);
      console.log(`✅ ${size} KB`);
      downloaded++;
    } catch (err) {
      console.log(`❌ ${err.message}`);
    }
  }

  // Summary
  console.log('');
  console.log('═══════════════════════════════════════════════════════');
  console.log('  📁  Models Directory:');
  console.log('═══════════════════════════════════════════════════════');
  
  const files = fs.readdirSync(MODELS_DIR).filter(f => f.endsWith('.glb'));
  let totalSize = 0;
  files.forEach(f => {
    const size = fs.statSync(path.join(MODELS_DIR, f)).size;
    totalSize += size;
    console.log(`  ✓ ${f.padEnd(25)} ${(size / 1024).toFixed(0).padStart(6)} KB`);
  });

  console.log('  ─────────────────────────────────────────');
  console.log(`  Total: ${files.length} models, ${(totalSize / (1024 * 1024)).toFixed(1)} MB`);
  console.log('');
  console.log('  📌 Next steps:');
  console.log('     1. git add models/');
  console.log('     2. git commit -m "Add furniture GLB models"');
  console.log('     3. git push origin main');
  console.log('     4. Wait ~5 min for Render to redeploy');
  console.log('');
  console.log('  🔗 Use these URLs in your app:');
  files.forEach(f => {
    console.log(`     https://visionfurnish-api.onrender.com/models/${f}`);
  });
  console.log('');
}

main();
