const http = require('https');

const url = 'https://t3.storageapi.dev/royal-bucket-nc-3ok4qwlzr/posts/1779924109715-efkv9tsu-1779924108537-843135290-1000472092.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Credential=tid_SqtvfZKVdgwXfFHfYwvZOBaCLWgQgU_WOxBaQpOtXkkVcNBHoR%2F20260528%2Feu-central-003%2Fs3%2Faws4_request&X-Amz-Date=20260528T020831Z&X-Amz-Expires=3600&X-Amz-Signature=9a387d52be7f9b8b526c035d38fd81f1f36821a2ec9490187c36a594d7cb800c&X-Amz-SignedHeaders=host&x-amz-checksum-mode=ENABLED&x-id=GetObject';

http.get(url, (res) => {
  console.log('Status Code:', res.statusCode);
  console.log('Headers:', res.headers);
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  res.on('end', () => {
    console.log('Body length:', data.length);
    console.log('Body start:', data.substring(0, 1000));
  });
}).on('error', (e) => {
  console.error(e);
});
