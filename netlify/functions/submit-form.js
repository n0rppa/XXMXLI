const fs = require('fs');
const path = require('path');
const fetch = require('node-fetch');

exports.handler = async function(event) {
  if (event.httpMethod !== 'POST') return { statusCode: 405, body: 'Method not allowed' };
  try {
    // event.body is URL-encoded form data when sent from fetch with FormData; Netlify provides raw body
    const contentType = event.headers['content-type'] || event.headers['Content-Type'] || '';
    let formData = {};
    if (contentType.includes('application/x-www-form-urlencoded')) {
      const params = new URLSearchParams(event.body);
      for (const [k,v] of params.entries()) formData[k]=v;
    } else if (contentType.includes('multipart/form-data')) {
      // For simplicity, accept raw body and forward as-is to Formspree via fetch with same body
      formData = null;
    } else {
      // Try to parse JSON
      try { formData = JSON.parse(event.body); } catch(e) { formData = { raw: event.body }; }
    }

    // Persist submission server-side for auditing
    const submissionsDir = path.join(__dirname, '..', '..', 'data', 'form-submissions');
    if (!fs.existsSync(submissionsDir)) fs.mkdirSync(submissionsDir, { recursive: true });
    const filename = 'submission-' + Date.now() + '-' + Math.floor(Math.random()*10000) + '.json';
    const fp = path.join(submissionsDir, filename);
    fs.writeFileSync(fp, JSON.stringify({ headers: event.headers, form: formData }, null, 2));

    // Forward to Formspree endpoint server-side
    const FORMSPREE_ENDPOINT = 'https://formspree.io/f/mvgqqyqr';
    let forwardResp;
    if (formData === null) {
      // Multipart: forward raw body
      forwardResp = await fetch(FORMSPREE_ENDPOINT, { method: 'POST', headers: { 'Content-Type': contentType }, body: event.body });
    } else {
      forwardResp = await fetch(FORMSPREE_ENDPOINT, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(formData) });
    }

    if (!forwardResp.ok && forwardResp.status !== 200 && forwardResp.status !== 204) {
      return { statusCode: 502, body: 'Forwarding to Formspree failed' };
    }

    return { statusCode: 200, body: '' };
  } catch (err) {
    console.error('submit-form error', err);
    return { statusCode: 500, body: 'Internal Server Error' };
  }
};
