function isEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

function isMobile(value) {
  return /^\d{10,15}$/.test(value);
}

function normalizeEmail(value) {
  return String(value || '').trim().toLowerCase();
}

function normalizeMobile(value) {
  return String(value || '').trim();
}

function isStrongEnoughPassword(value) {
  return String(value || '').length >= 6;
}

module.exports = {
  isEmail,
  isMobile,
  normalizeEmail,
  normalizeMobile,
  isStrongEnoughPassword,
};
