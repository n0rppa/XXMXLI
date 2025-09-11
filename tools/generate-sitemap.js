const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '..');
const files = fs.readdirSync(ROOT).filter(f=>f.endsWith('.html'));
const urls = files.map(f=>`https://n0rppa.github.io/XXMXLI/${f}`);
const xml = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls.map(u=>`<url><loc>${u}</loc></url>`).join('\n')}\n</urlset>`;
fs.writeFileSync(path.join(ROOT,'sitemap.xml'),xml);
console.log('sitemap.xml written');
