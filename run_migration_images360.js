/**
 * Migration script: Add images_360, color_variants, ar_model columns
 * to the products table (PostgreSQL version).
 *
 * Run once: node run_migration_images360.js
 * (These columns are already in schema_pg.sql — only needed if upgrading
 *  an existing PostgreSQL DB that's missing them.)
 */
require('dotenv').config();
const { Client } = require('pg');

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
  console.log('✅ Connected to PostgreSQL database.');

  // PostgreSQL system catalog: check which columns already exist
  // (replaces MySQL's INFORMATION_SCHEMA.COLUMNS query)
  const { rows: cols } = await client.query(
    `SELECT column_name
     FROM information_schema.columns
     WHERE table_schema = 'public'
       AND table_name   = 'products'`,
    []
  );
  const existing = cols.map(c => c.column_name);
  console.log('Existing product columns:', existing.join(', '));

  const migrations = [];

  if (!existing.includes('images_360')) {
    // PostgreSQL: JSONB instead of JSON, no COMMENT syntax
    migrations.push(
      client.query(`ALTER TABLE products ADD COLUMN IF NOT EXISTS images_360 JSONB DEFAULT NULL`)
    );
    console.log('  + Adding images_360 column...');
  }

  if (!existing.includes('color_variants')) {
    migrations.push(
      client.query(`ALTER TABLE products ADD COLUMN IF NOT EXISTS color_variants JSONB DEFAULT NULL`)
    );
    console.log('  + Adding color_variants column...');
  }

  if (!existing.includes('ar_model')) {
    migrations.push(
      client.query(`ALTER TABLE products ADD COLUMN IF NOT EXISTS ar_model VARCHAR(500) DEFAULT NULL`)
    );
    console.log('  + Adding ar_model column...');
  }

  if (migrations.length === 0) {
    console.log('\n✅ All columns already exist. Nothing to do.');
  } else {
    await Promise.all(migrations);
    console.log(`\n✅ Successfully added ${migrations.length} column(s).`);
  }

  await client.end();
  console.log('Done.');
}

run().catch(err => {
  console.error('❌ Migration failed:', err.message);
  process.exit(1);
});
