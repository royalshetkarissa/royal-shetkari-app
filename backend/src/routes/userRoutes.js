const express = require('express');
const router = express.Router();
const pool = require('../config/db');

// @route   GET /api/users
// @desc    Get users summary / success check
// @access  Public
router.get('/', async (req, res, next) => {
  try {
    const result = await pool.query('SELECT COUNT(*) FROM users');
    const userCount = parseInt(result.rows[0].count, 10);

    res.json({
      status: 'success',
      message: 'Users API is fully functional!',
      totalUsers: userCount,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(503).json({
      status: 'fail',
      message: 'Users API is currently degraded (Database is offline or unreachable)!',
      timestamp: new Date().toISOString(),
    });
  }
});

module.exports = router;
