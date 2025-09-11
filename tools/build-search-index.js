const fs = require('fs');
const path = require('path');
const cheerio = require('cheerio');

const ROOT = path.resolve(__dirname, '..');

function listHtmlFiles(dir) {
  return fs.readdirSync(dir).filter(f => f.endsWith('.html'));
}

const files = listHtmlFiles(ROOT);
const index = files.map(file => {
  const full = path.join(ROOT, file);
  const html = fs.readFileSync(full,'utf8');
  const $ = cheerio.load(html);
  const title = $('title').text() || file;
  const body = $('body').text().replace(/\s+/g,' ').trim();
  return { id: file, title, body: body.slice(0, 5000) };
});

fs.writeFileSync(path.join(ROOT,'search-index.json'), JSON.stringify(index,null,2));
console.log('search-index.json written with', index.length, 'items');
