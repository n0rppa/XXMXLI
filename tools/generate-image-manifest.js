#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const IMAGES_DIR = path.join(__dirname, '..', 'assets', 'images');
const OUT_FILE = path.join(IMAGES_DIR, 'filelist.json');

function isImage(file) {
  const ext = path.extname(file).toLowerCase();
  return ['.jpg', '.jpeg', '.png', '.webp'].includes(ext);
}

function isDerivative(file) {
  // Exclude common derivative patterns like name-400.webp, name-800.webp, name-1200.webp
  const base = path.basename(file);
  return /-\d+\.(webp)$/i.test(base);
}

function main() {
  if (!fs.existsSync(IMAGES_DIR)) {
    console.error('Images directory not found:', IMAGES_DIR);
    process.exit(1);
  }

  const files = fs.readdirSync(IMAGES_DIR)
    .filter(isImage)
    .filter(f => !isDerivative(f))
    .sort((a, b) => a.localeCompare(b, 'en', { numeric: true }));

  const manifest = files.map((filename, idx) => ({
    filename,
    title: path.parse(filename).name
  }));

  fs.writeFileSync(OUT_FILE, JSON.stringify(manifest, null, 2));
  console.log(`Wrote ${manifest.length} entries to`, OUT_FILE);
}

main();
