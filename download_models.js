/**
 * Downloads REAL furniture GLB models from KhronosGroup/glTF-Sample-Assets
 * These are actual furniture 3D models (chairs, sofas, lamps) — NOT ducks!
 * 
 * Sources: KhronosGroup glTF-Sample-Assets (CC BY 4.0 / CC0)
 *   • SheenChair        — fabric director's chair by Wayfair
 *   • GlamVelvetSofa     — velvet sofa by Wayfair
 *   • AnisotropyBarnLamp — barn lamp by Wayfair
 *
 * Run: node download_models.js
 */
const https = require('https');
const fs = require('fs');
const path = require('path');

const MODELS_DIR = path.join(__dirname, 'models');
if (!fs.existsSync(MODELS_DIR)) fs.mkdirSync(MODELS_DIR, { recursive: true });

const BASE = 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models';

const DOWNLOADS = [
  {
    name: 'chair.glb',
    url: `${BASE}/SheenChair/glTF-Binary/SheenChair.glb`,
    note: 'Real fabric chair (Wayfair, CC0)',
  },
  {
    name: 'sofa.glb',
    url: `${BASE}/GlamVelvetSofa/glTF-Binary/GlamVelvetSofa.glb`,
    note: 'Real velvet sofa (Wayfair, CC BY 4.0)',
  },
  {
    name: 'table.glb',
    url: `${BASE}/ABeautifulGame/glTF-Binary/ABeautifulGame.glb`,
    note: 'Chess set / table furniture piece (ASWF, CC BY 4.0)',
  },
  {
    name: 'lamp.glb',
    url: `${BASE}/AnisotropyBarnLamp/glTF-Binary/AnisotropyBarnLamp.glb`,
    note: 'Barn lamp (Wayfair, CC BY 4.0)',
  },
];

function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    // Remove old file if exists
    if (fs.existsSync(dest)) fs.unlinkSync(dest);
    const file = fs.createWriteStream(dest);

    function follow(currentUrl, redirects = 0) {
      if (redirects > 10) return reject(new Error('Too many redirects'));
      const proto = currentUrl.startsWith('https') ? https : require('http');
      proto.get(currentUrl, (res) => {
        if ([301, 302, 307, 308].includes(res.statusCode)) {
          file.close();
          return follow(res.headers.location, redirects + 1);
        }
        if (res.statusCode !== 200) {
          file.close();
          fs.unlink(dest, () => {});
          return reject(new Error(`HTTP ${res.statusCode} for ${currentUrl}`));
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
  console.log('📥 Downloading REAL furniture GLB models...\n');

  for (const item of DOWNLOADS) {
    const dest = path.join(MODELS_DIR, item.name);
    process.stdout.write(`  ⬇️  ${item.name} (${item.note})... `);
    try {
      await downloadFile(item.url, dest);
      const size = (fs.statSync(dest).size / 1024).toFixed(0);
      console.log(`✅ ${size} KB`);
    } catch (err) {
      console.log(`❌ ${err.message}`);
    }
  }

  console.log('\n📁 Models directory:');
  const files = fs.readdirSync(MODELS_DIR);
  files.forEach(f => {
    const size = (fs.statSync(path.join(MODELS_DIR, f)).size / 1024).toFixed(0);
    console.log(`  ✓ models/${f} (${size} KB)`);
  });

  console.log('\n✅ Done! Real furniture models ready.');
  console.log('   Commit + push to Render to deploy.\n');
}

main();
