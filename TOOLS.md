TOOLS
=====

search-index
------------

This repository generates a search index (`search-index.json`) from HTML files using the Node script `tools/build-search-index.js`.

Regenerate locally

1. Install dependencies (dev):

```bash
npm ci
```

2. Run the index builder:

```bash
npm run build-index
# produces: search-index.json in repository root
```

CI behavior

- The GitHub Actions workflow `.github/workflows/build-search-index-artifact.yml` will run on pushes affecting HTML files or the `tools/` folder and will upload the generated `search-index.json` as a workflow artifact named `search-index`.
- The artifact can be downloaded from the workflow run and used in deploy pipelines.

Notes

- `search-index.json` is intentionally git-ignored to avoid committing generated artifacts. If you need the index in the deployed site, update your deployment step to include the artifact or run the builder as part of the deployment job.
- The builder uses a lightweight HTML extraction to avoid heavy runtime dependencies in CI.
