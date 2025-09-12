Security headers and testing

This repository includes a Netlify-style `/_headers` file that configures security headers. The CSP is currently set in Report-Only mode to avoid blocking legitimate content during rollout.

Headers included (report-only CSP):
- Content-Security-Policy-Report-Only
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- Referrer-Policy: strict-origin-when-cross-origin
- Feature-Policy: geolocation 'none'; microphone 'none'; camera 'none'
- Strict-Transport-Security

Testing steps:
1. Deploy to a staging site (Netlify recommended) or enable the `_headers` file in your hosting.
2. Open the browser DevTools Console and Network tab to look for CSP violations reported. Since CSP is Report-Only, violations will be logged but not blocked.
3. Tweak the CSP `script-src`, `style-src`, and `connect-src` directives as needed to add trusted CDNs or endpoints.
4. Once satisfied, change `Content-Security-Policy-Report-Only` to `Content-Security-Policy` in `/_headers` to enforce.

Notes:
- GitHub Pages cannot set arbitrary headers. Use Netlify, Cloudflare, or a reverse proxy to apply headers on GitHub Pages sites.
- Keep third-party origins minimal in CSP to maintain security.
