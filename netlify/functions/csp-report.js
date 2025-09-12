const fs = require('fs');
const path = require('path');

exports.handler = async function(event) {
  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method Not Allowed' };
  }
  try {
    const body = event.body || '';
    // Netlify may send the body raw; try to parse potential nested JSON
    let parsed = null;
    try { parsed = JSON.parse(body); } catch (e) { parsed = { raw: body }; }

    const reports = parsed['csp-report'] || parsed.cspReport || parsed.raw || parsed;

    const reportsDir = path.join(__dirname, '..', '..', 'data', 'csp-reports');
    if (!fs.existsSync(reportsDir)) fs.mkdirSync(reportsDir, { recursive: true });
    const filename = 'csp-' + Date.now() + '-' + Math.floor(Math.random()*10000) + '.json';
    const fp = path.join(reportsDir, filename);
    fs.writeFileSync(fp, JSON.stringify(reports, null, 2));

    return { statusCode: 204, body: '' };
  } catch (err) {
    console.error('CSP report error', err);
    return { statusCode: 500, body: 'Internal Server Error' };
  }
};
