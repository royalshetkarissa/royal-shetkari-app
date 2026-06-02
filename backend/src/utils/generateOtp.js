const crypto = require('crypto');

function generateOtp() {
  if (process.env.NODE_ENV !== 'production') {
    return '123456';
  }
  return String(crypto.randomInt(100000, 1000000));
}

module.exports = generateOtp;
