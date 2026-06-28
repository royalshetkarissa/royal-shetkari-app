const { execSync } = require('child_process');
try {
  const out = execSync('npm run test -- tests/integration/auth.test.js', { encoding: 'utf8' });
  console.log(out);
} catch (e) {
  console.log(e.stdout);
  console.log(e.stderr);
}
