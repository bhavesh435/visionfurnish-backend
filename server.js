require('dotenv').config();
const express = require('express');
const path    = require('path');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const errorHandler = require('./src/middleware/errorHandler');

// ── Route imports ───────────────────────────────────────────
const authRoutes = require('./src/routes/auth');
const productRoutes = require('./src/routes/products');
const categoryRoutes = require('./src/routes/categories');
const cartRoutes = require('./src/routes/cart');
const orderRoutes = require('./src/routes/orders');
const wishlistRoutes = require('./src/routes/wishlist');
const reviewRoutes = require('./src/routes/reviews');
const adminRoutes  = require('./src/routes/admin');
const chatRoutes   = require('./src/routes/chat');
const uploadRoutes = require('./src/routes/upload');

// ── App init ────────────────────────────────────────────────
const app = express();
const PORT = process.env.PORT || 5000;

// ── Global middleware ───────────────────────────────────────
app.use(helmet({
  crossOriginResourcePolicy: false,
  crossOriginOpenerPolicy: false,
  crossOriginEmbedderPolicy: false,
}));
app.use(cors());
app.use(morgan('dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ── Serve uploaded 3D models as static files ───────────────
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ── Health check ────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'VisionFurnish API is running 🚀',
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString(),
  });
});

// ── API routes ──────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/wishlist', wishlistRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/upload', uploadRoutes);

// ── 404 handler ─────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.originalUrl} not found.`,
  });
});

// ── Global error handler ────────────────────────────────────
app.use(errorHandler);

// ── Start server ────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🛋️  VisionFurnish API`);
  console.log(`   Environment : ${process.env.NODE_ENV || 'development'}`);
  console.log(`   Port        : ${PORT}`);
  console.log(`   URL         : http://localhost:${PORT}\n`);
});

module.exports = app;
