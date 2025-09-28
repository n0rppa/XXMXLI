Image manifest guide

- Gallery on `photography.html` is driven by `assets/images/filelist.json`.
- To regenerate the manifest from files in `assets/images/` run:

  npm run generate:images

- The generator skips derivative files like `*-400.webp`, `*-800.webp`, `*-1200.webp` and includes base images: jpg/jpeg/png/webp.
- After adding new photos, re-run the command and refresh the page.
