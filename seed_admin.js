/**
 * seed_admin.js
 * Creates the admin user in the database.
 *
 * Usage:  node seed_admin.js
 */

require('dotenv').config();
const bcrypt = require('bcryptjs');
const db = require('./src/config/db');

const ADMIN = {
  name: 'Bhavesh',
  email: 'admin@bhavesh.com',
  password: 'admin123',
  role: 'admin',
};

async function seed() {
  try {
    // Check if admin already exists
    const [existing] = await db.query(
      'SELECT id FROM users WHERE email = ?',
      [ADMIN.email]
    );

    const hashedPassword = await bcrypt.hash(ADMIN.password, 12);

    if (existing.length > 0) {
      console.log('⚠️  Admin user already exists. Updating password and ensuring role is admin.');
      await db.query(
        'UPDATE users SET password = ?, role = "admin" WHERE email = ?',
        [hashedPassword, ADMIN.email]
      );
      console.log('✅  Admin user updated successfully!');
    } else {
      await db.query(
        'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
        [ADMIN.name, ADMIN.email, hashedPassword, ADMIN.role]
      );
      console.log('✅  Admin user created successfully!');
    }

    console.log(`   Email    : ${ADMIN.email}`);
    console.log(`   Password : ${ADMIN.password}`);
    process.exit(0);
  } catch (err) {
    console.error('❌  Seed failed:', err.message);
    process.exit(1);
  }
}

seed();
