# 🚀 SIVUSTON SUORITUSKYKYOPTIMOINTISUUNNITELMA

## 📈 NYKYTILANNE
- **Kuvatiedostot:** 22MB (25 kuvaa)
- **Suurin kuva:** 5.3MB (23.jpg)
- **Ulkoisia resursseja:** 8+ CDN-pyyntöä per sivu
- **CSS:** Inline 500+ riviä per sivu
- **JavaScript:** Inline + ulkoiset kirjastot

## 🎯 TAVOITTEET
- Sivun latausaika < 3 sekuntia
- Kuvakoko < 5MB kokonaisuudessaan
- Vähemmän ulkoisia pyyntöjä
- Parempi mobiilisuorituskyky

## 🔧 OPTIMOINTISUUNNITELMA

### 1. KUVAOPTIMIZATION (PRIORITEETTI: KORKEA ⭐⭐⭐)

#### A) WebP-konvertointi:
```bash
# Automaattinen optimointi kaikille kuville
for img in assets/images/*.jpg; do
    cwebp -q 85 "$img" -o "${img%.jpg}.webp"
done
```

#### B) Responsive kuvat:
```html
<!-- Ennen -->
<img src="assets/images/23.jpg" alt="kuva">

<!-- Jälkeen -->
<picture>
    <source srcset="assets/images/23-480w.webp 480w,
                    assets/images/23-800w.webp 800w" 
            type="image/webp">
    <img src="assets/images/23-800w.jpg" 
         alt="kuva" 
         loading="lazy">
</picture>
```

#### C) Lazy loading:
- ✅ Jo käytössä: `loading="lazy"`
- Lisää Intersection Observer paremmin kontrollia varten

### 2. CSS OPTIMOINTI (PRIORITEETTI: KESKITASO ⭐⭐)

#### A) Yhteinen tyylitiedosto:
```css
/* assets/css/main.css - yhteisiä tyylejä */
:root { /* CSS muuttujat */ }
.side-menu { /* Sivupalkki */ }
.grid-container { /* Grid layout */ }
```

#### B) Sivu-spesifiset tyylit:
```css
/* assets/css/photography.css - vain galleria-spesifiset */
.image-modal { /* Modal-tyylit */ }
.gallery-item { /* Galleria-kohtaiset */ }
```

### 3. JAVASCRIPT OPTIMOINTI (PRIORITEETTI: KESKITASO ⭐⭐)

#### A) Moduulijako:
```javascript
// assets/js/core.js - perusominaisuudet
// assets/js/gallery.js - galleria-toiminnot  
// assets/js/music-player.js - musiikkitoiminnot
```

#### B) Lazy loading JS:lle:
```javascript
// Lataa vain tarvittaessa
if (document.querySelector('.gallery')) {
    import('./gallery.js');
}
```

### 4. ULKOISTEN RESURSSIEN OPTIMOINTI (PRIORITEETTI: MATALA ⭐)

#### A) Font Awesome lokalisointi:
```bash
# Lataa vain tarvittavat ikonit
wget -O assets/css/fontawesome-minimal.css \
  "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css"
```

#### B) CDN-resurssien minimointi:
- Käytä vain tarvittavat Howler.js ominaisuudet
- Alpine.js vain projektisivulla

### 5. CACHING & COMPRESSION (PRIORITEETTI: MATALA ⭐)

#### A) Palvelimen asetukset:
```nginx
# Nginx esimerkki
location ~* \.(jpg|jpeg|png|webp|css|js)$ {
    expires 1M;
    add_header Cache-Control "public, immutable";
}

# Gzip compression
gzip on;
gzip_types text/css application/javascript image/svg+xml;
```

## 📊 ODOTETUT TULOKSET

### Ennen optimointia:
- **Sivun koko:** ~3-5MB
- **Latausaika:** 8-15s (hidas yhteys)
- **HTTP-pyynnöt:** 15-25 per sivu

### Optimoinnin jälkeen:
- **Sivun koko:** ~500KB-1MB (-80%)
- **Latausaika:** 2-4s (-70%)
- **HTTP-pyynnöt:** 5-10 per sivu (-60%)

## 🚀 TOTEUTUSJÄRJESTYS

1. **Viikko 1:** Kuvaoptimization (WebP + koon pienennys)
2. **Viikko 2:** CSS refaktorointi (erillinen tiedosto)
3. **Viikko 3:** JavaScript optimointi
4. **Viikko 4:** CDN-resurssien lokalisointi
5. **Viikko 5:** Palvelimen optimointi

## 🔍 MITTAUS & SEURANTA

### Työkalut:
- Google PageSpeed Insights
- GTmetrix
- Chrome DevTools Network tab
- WebPageTest.org

### Keskeiset mittarit:
- First Contentful Paint (FCP)
- Largest Contentful Paint (LCP)  
- Total Blocking Time (TBT)
- Cumulative Layout Shift (CLS)

## ⚡ PIKAKORJAUKSET (TOTEUTETTAVISSA NYTÄ)

1. **Pienennä suurimmat kuvat heti:**
```bash
# Pienennä 5.3MB kuva
mogrify -resize 1200x1200> -quality 85 assets/images/23.jpg
```

2. **Lisää preload kriittisille resursseille:**
```html
<link rel="preload" href="assets/css/main.css" as="style">
<link rel="preload" href="assets/fonts/fontawesome.woff2" as="font" type="font/woff2" crossorigin>
```

3. **Minimoi CSS välittömästi:**
```bash
# Poista turhat välilyönnit ja kommentit
csso assets/css/main.css --output assets/css/main.min.css
```

Tämä suunnitelma parantaa sivuston suorituskykyä merkittävästi!
