/**
 * Run the site_settings migration against the database.
 * Usage:  node run_migration_site_settings.js
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT, 10) || 5432,
  user:     process.env.DB_USER     || 'postgres',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME     || 'visionfurnish',
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
});

async function run() {
  const sql = fs.readFileSync(path.join(__dirname, 'migration_site_settings.sql'), 'utf-8');
  try {
    await pool.query(sql);
    console.log('✅  site_settings migration applied successfully!');
  } catch (err) {
    console.error('❌  Migration error:', err.message);
  } finally {
    await pool.end();
  }
}

run();
