const express = require('express');
const cors = require('cors');
const path = require('path');
const morgan = require('morgan');
const pool = require('./config/db');
const { connection: redis } = require('./config/redis');
const logger = require('./utils/logger');
const AppError = require('./utils/AppError');

// Import routes
const authRoutes = require('./routes/v1/authRoutes');
const postRoutes = require('./routes/v1/postRoutes');
const adminRoutes = require('./routes/v1/adminRoutes');
const bookingRoutes = require('./routes/v1/bookingRoutes');
const diseaseRoutes = require('./routes/v1/diseaseRoutes');
const marketRoutes = require('./routes/v1/marketRoutes');
const timetableRoutes = require('./routes/v1/timetableRoutes');
const shopRoutes = require('./routes/v1/shopRoutes');
const hospitalRoutes = require('./routes/v1/hospitalRoutes');
const analyticsRoutes = require('./routes/v1/analyticsRoutes');
const userRoutes = require('./routes/userRoutes');

const { securityHeaders, apiLimiter, authLimiter } = require('./middleware/security');

const requestId = require('./middleware/requestId');
const errorMiddleware = require('./middleware/errorMiddleware');

const app = express();

// 1. Global Middlewares
app.use(requestId);

const allowedOrigins = process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['http://localhost:3000', 'http://localhost:5000'];

app.use(cors({
  origin: function (origin, callback) {
    // allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) !== -1 || process.env.NODE_ENV === 'development') {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Idempotency-Key']
}));
app.use(securityHeaders);
app.use('/api', apiLimiter);
app.use(express.json());
app.use(morgan('dev'));

// 2. Static Files
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// 3. Health Routes
app.get('/', (req, res) => {
  res.json({
    status: 'success',
    message: 'Welcome to the Royal Shetkari API!',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', async (req, res) => {
  try {
    const dbStatus = await pool.query('SELECT 1');
    res.json({
      status: 'ok',
      requestId: req.id,
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      database: dbStatus ? 'connected' : 'disconnected',
      redis: redis.status === 'ready' ? 'connected' : 'disconnected',
      version: '1.0.0-prod'
    });
  } catch (err) {
    logger.error('Health check failed', { error: err.message, requestId: req.id });
    res.status(503).json({ status: 'error', database: 'unavailable', requestId: req.id });
  }
});

app.get('/ready', (req, res) => {
  res.json({ status: 'ready', requestId: req.id });
});

app.use('/api/auth', authRoutes);
app.use('/api/v1', authRoutes);
app.use('/api/v1/posts', postRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/bookings', bookingRoutes);
app.use('/api/v1/disease', diseaseRoutes);
app.use('/api/v1/market', marketRoutes);
app.use('/api/v1/timetable', timetableRoutes);
app.use('/api/v1/shops', shopRoutes);
app.use('/api/v1/hospitals', hospitalRoutes);
app.use('/api/v1/analytics', analyticsRoutes);
app.use('/api/users', userRoutes);

// 4. Unhandled Routes
app.all('*', (req, res, next) => {
  next(new AppError(`Can't find ${req.originalUrl} on this server!`, 404));
});

// 5. Global Error Handler
app.use(errorMiddleware);

module.exports = app;
