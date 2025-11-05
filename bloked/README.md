# bloked

This folder is intentionally tracked so it always ships with the blacklist database.

Purpose:
- Store curated, exported, or temporary blacklist datasets used alongside the main sources in `w/`.
- Keep small auxiliary artifacts (e.g., subsets, review lists) that complement `assets/security/blocked_ips.*` outputs.

Notes:
- The primary source lists live under `w/` and are processed by `process_w_blacklists.py`.
- Public outputs are written to `assets/security/`.
- If this directory is empty, the `.gitkeep` file ensures it remains in the repository.