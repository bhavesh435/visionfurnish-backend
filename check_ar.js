require('dotenv').config();
const { Client } = require('pg');
const c = new Client({
  host: process.env.DB_HOST, port: process.env.DB_PORT,
  user: process.env.DB_USER, password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
});
c.connect().then(() =>
  c.query('SELECT id, name, ar_model FROM products WHERE ar_model IS NOT NULL LIMIT 8')
).then(r => {
  console.log('✅ Products with AR models in DB:\n');
  r.rows.forEach(p => console.log(`  #${p.id}  ${p.name}\n       → ${(p.ar_model||'').split('/').pop()}\n`));
  c.end();
}).catch(e => { console.error(e.message); c.end(); });
