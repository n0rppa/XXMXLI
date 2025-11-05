# w (blacklist sources)

This directory contains raw blacklist sources and datasets that are ingested by the processing tools.

- Input: text lists under various subfolders (e.g., `BLKLST`, `BlokeD`, and standalone files).
- Processor: run `process_w_blacklists.py` to aggregate, deduplicate, and generate deployable outputs.
- Outputs: written to `assets/security/` (e.g., `blocked_ips.json`, `blocked_ips.js`, `blacklist_stats.json`).

Guidelines:
- Avoid committing very large files when possible; prefer curated subsets.
- Keep upstream licenses/READMEs if present in submodules or source drops.
- New lists can be added under subfolders; the processor is resilient to nested structures.