const fs = require('fs');
const path = require('path');
// simple recursive HTML file walker - avoids external glob dependency
// avoid heavy DOM libs to keep script portable

const repoRoot = path.resolve(__dirname, '..');
const outFile = path.join(repoRoot, 'search-index.json');

function cleanText(s) {
  if (!s) return '';
  return s.replace(/\s+/g, ' ').replace(/[\u0000-\u001f]+/g, '').trim();
}

function extractBodyText(html) {
  const bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
  let body = bodyMatch ? bodyMatch[1] : html;
  body = body.replace(/<script[\s\S]*?>[\s\S]*?<\/script>/gi, '');
  body = body.replace(/<style[\s\S]*?>[\s\S]*?<\/style>/gi, '');
  body = body.replace(/<[^>]+>/g, ' ');
  body = body.replace(/&nbsp;/g, ' ');
  body = body.replace(/&amp;/g, '&');
  body = body.replace(/&lt;/g, '<');
  body = body.replace(/&gt;/g, '>');
  return cleanText(body);
}

function walkHtmlFiles(dir) {
  const results = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const name = entry.name;
    if (name === 'node_modules' || name === '.git' || name === '.github' || name === 'node_modules') continue;
    const full = path.join(dir, name);
    if (entry.isDirectory()) {
      results.push(...walkHtmlFiles(full));
    } else if (entry.isFile() && name.endsWith('.html') && name !== 'search-index.json') {
      results.push(path.relative(repoRoot, full));
    }
  }
  return results;
}

const files = walkHtmlFiles(repoRoot);

const index = [];
files.forEach((filePath) => {
  try {
    const abs = path.resolve(repoRoot, filePath);
    const html = fs.readFileSync(abs, 'utf8');
    const titleMatch = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
    const h1Match = html.match(/<h1[^>]*>([\s\S]*?)<\/h1>/i);
    const title = cleanText((titleMatch && titleMatch[1]) || (h1Match && h1Match[1]) || '');
    let content = extractBodyText(html) || '';
    content = cleanText(content).slice(0, 100000);

    if (!title && content.length < 30) return;

    const url = filePath.replace(/\\/g, '/');
    index.push({ id: index.length + 1, title: title || path.basename(filePath), content, url });
  } catch (e) {
    console.warn('skipping', filePath, e.message);
  }
});

fs.writeFileSync(outFile, JSON.stringify(index, null, 2), 'utf8');
console.log(`Wrote ${index.length} entries to ${outFile}`);
