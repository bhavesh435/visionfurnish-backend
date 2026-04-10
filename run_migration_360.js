/**
 * run_migration_360.js
 * Adds images_360, color_variants, ar_model columns to products table.
 * Usage: node run_migration_360.js
 */
require('dotenv').config();
const db = require('./src/config/db');

async function migrate() {
  try {
    console.log('Running migration...');

    // Add images_360 column
    await db.query(`
      ALTER TABLE products
        ADD COLUMN IF NOT EXISTS images_360 JSON DEFAULT NULL
    `).catch(() => {
      // Fallback if IF NOT EXISTS not supported
      return db.query(`ALTER TABLE products ADD COLUMN images_360 JSON DEFAULT NULL`)
        .catch(e => { if (!e.message.includes('Duplicate column')) throw e; });
    });

    // Add color_variants column
    await db.query(`
      ALTER TABLE products
        ADD COLUMN IF NOT EXISTS color_variants JSON DEFAULT NULL
    `).catch(() => {
      return db.query(`ALTER TABLE products ADD COLUMN color_variants JSON DEFAULT NULL`)
        .catch(e => { if (!e.message.includes('Duplicate column')) throw e; });
    });

    // Add ar_model column
    await db.query(`
      ALTER TABLE products
        ADD COLUMN IF NOT EXISTS ar_model VARCHAR(500) DEFAULT NULL
    `).catch(() => {
      return db.query(`ALTER TABLE products ADD COLUMN ar_model VARCHAR(500) DEFAULT NULL`)
        .catch(e => { if (!e.message.includes('Duplicate column')) throw e; });
    });

    console.log('✅ Migration complete! New columns: images_360, color_variants, ar_model');

    // Verify
    const [cols] = await db.query(`SHOW COLUMNS FROM products LIKE 'images_360'`);
    if (cols.length > 0) {
      console.log('✅ Verified: images_360 column exists');
    }
    const [cols2] = await db.query(`SHOW COLUMNS FROM products LIKE 'color_variants'`);
    if (cols2.length > 0) {
      console.log('✅ Verified: color_variants column exists');
    }
    const [cols3] = await db.query(`SHOW COLUMNS FROM products LIKE 'ar_model'`);
    if (cols3.length > 0) {
      console.log('✅ Verified: ar_model column exists');
    }

    process.exit(0);
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  }
}

migrate();
