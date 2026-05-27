const jwt = require('jsonwebtoken');
const env = require('../config/env');

const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, env.JWT_SECRET);
    req.userId = decoded.id;
    req.userMobile = decoded.mobile;
    req.isAdmin = decoded.isAdmin;
    req.permissions = decoded.permissions || {};
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};

const verifyAdmin = (req, res, next) => {
  verifyToken(req, res, () => {
    if (!req.isAdmin) {
      return res.status(403).json({ error: 'Admin access required' });
    }
    next();
  });
};

const verifySuperUser = (req, res, next) => {
  verifyToken(req, res, () => {
    // ONLY THIS NUMBER HAS SUPER ACCESS
    if (req.userMobile !== env.SUPER_USER_MOBILE) {
      return res.status(403).json({ error: 'Super User access required' });
    }
    next();
  });
};

module.exports = {
  verifyToken,
  verifyAdmin,
  verifySuperUser,
};
