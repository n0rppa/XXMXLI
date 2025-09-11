const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const IMAGES_DIR = path.join(__dirname,'..','assets','images');
if (!fs.existsSync(IMAGES_DIR)) { console.log('No images dir, skipping'); process.exit(0); }

const sizes = [400,800,1200];
fs.readdirSync(IMAGES_DIR).forEach(file=>{
  const ext = path.extname(file).toLowerCase();
  if (!['.jpg','.jpeg','.png'].includes(ext)) return;
  const base = path.basename(file,ext);
  sizes.forEach(sz=>{
    const out = path.join(IMAGES_DIR, base + '-' + sz + '.webp');
    sharp(path.join(IMAGES_DIR,file)).resize(sz).webp({quality:80}).toFile(out).then(()=>console.log('wrote',out)).catch(console.error);
  });
});
