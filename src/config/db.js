const { Pool } = require('pg');
require('dotenv').config();

// ── PostgreSQL connection pool ───────────────────────────────
const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT, 10) || 5432,
  user:     process.env.DB_USER     || 'postgres',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME     || 'visionfurnish',
  max:                 20,    // max pool connections
  idleTimeoutMillis:   30000, // close idle clients after 30s
  connectionTimeoutMillis: 3000,
  ssl: process.env.DB_SSL === 'true'
    ? { rejectUnauthorized: false }
    : false,
});

// Quick connectivity test (non-blocking)
pool.connect()
  .then((client) => {
    console.log('✅  PostgreSQL connected — database:', process.env.DB_NAME);
    client.release();
  })
  .catch((err) => {
    console.error('❌  PostgreSQL connection failed:', err.message);
  });

module.exports = pool;
