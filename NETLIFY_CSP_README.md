This project includes a simple Netlify function to collect Content-Security-Policy reports.

Files:
- `netlify/functions/csp-report.js` — a small Node handler that stores incoming CSP reports to `data/csp-reports/` as JSON files.
- `_headers` — updated to point `report-uri` to `/netlify/functions/csp-report` and to apply a report-only CSP for `/contact.html`.

How to view reports locally after deploying to Netlify:
1. Deploy the site to Netlify (the function will be available at `/netlify/functions/csp-report`).
2. Trigger page loads or actions that produce CSP violations (open the browser console and watch for reports).
3. Reports will be written to `data/csp-reports/` (server-side storage in the deployed site build directory). Download them from your Netlify site's build artifacts or set up a remote logging endpoint if you prefer.

Note: This is a minimal collector for debugging. For production use, consider forwarding reports to a logging/alerting service (Sentry, Datadog, ELK) and implementing rate-limiting and auth.
