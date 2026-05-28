const http = require('https');

const url = 'https://royal-shetkari-app-production.up.railway.app/api/image/posts/1779924109715-efkv9tsu-1779924108537-843135290-1000472092.jpg';

http.get(url, (res) => {
  console.log('Status Code:', res.statusCode);
  console.log('Headers:', res.headers);
  if (res.headers.location) {
    console.log('Redirecting to:', res.headers.location);
  }
}).on('error', (e) => {
  console.error(e);
});
