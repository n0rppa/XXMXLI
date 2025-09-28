const fs = require('fs');
const path = require('path');

exports.handler = async function(event) {
  // CORS preflight
  const CORS_HEADERS = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type' };
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers: CORS_HEADERS, body: '' };
  }
  if (event.httpMethod !== 'POST') return { statusCode: 405, headers: CORS_HEADERS, body: 'Method not allowed' };
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

    // Verify Turnstile (or hCaptcha if configured)
    const token = formData?.turnstile_token || formData?.['cf-turnstile-response'] || '';
    const secret = process.env.TURNSTILE_SECRET || process.env.HCAPTCHA_SECRET || '';
    if (!secret) {
      // If no secret configured, reject to avoid spam; change to allow if you prefer
      return { statusCode: 500, headers: CORS_HEADERS, body: 'Captcha not configured' };
    }
    const verifyParams = new URLSearchParams();
    verifyParams.append('secret', secret);
    verifyParams.append('response', token);
    const ip = event.headers['client-ip'] || event.headers['x-forwarded-for'] || '';
    if (ip) verifyParams.append('remoteip', Array.isArray(ip) ? ip[0] : ip);
    const verifyResp = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
      method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: verifyParams.toString()
    });
    const verifyJson = await verifyResp.json().catch(()=>({success:false}));
    if (!verifyJson.success) return { statusCode: 400, headers: CORS_HEADERS, body: 'Captcha failed' };

    // Persist submission server-side for auditing (best-effort; may fail on read-only FS)
    try {
      const submissionsDir = path.join(__dirname, '..', '..', 'data', 'form-submissions');
      if (!fs.existsSync(submissionsDir)) fs.mkdirSync(submissionsDir, { recursive: true });
      const filename = 'submission-' + Date.now() + '-' + Math.floor(Math.random()*10000) + '.json';
      const fp = path.join(submissionsDir, filename);
      fs.writeFileSync(fp, JSON.stringify({ headers: event.headers, form: formData }, null, 2));
    } catch (e) {
      console.warn('Skipping submission persistence (likely read-only FS):', e.message);
    }

    // Forward to Formspree endpoint server-side as application/x-www-form-urlencoded
    const FORMSPREE_ENDPOINT = 'https://formspree.io/f/mvgqqyqr';
    let bodyForForward;
    if (formData === null) {
      // multipart/raw body: forward as-is
      bodyForForward = event.body;
    } else {
      const params = new URLSearchParams();
      for (const k of Object.keys(formData)) params.append(k, formData[k]);
      bodyForForward = params.toString();
    }

  // Use native fetch available in Netlify Functions runtime
  const forwardResp = await fetch(FORMSPREE_ENDPOINT, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: bodyForForward });

    if (!forwardResp.ok && forwardResp.status !== 200 && forwardResp.status !== 204) {
      return { statusCode: 502, headers: CORS_HEADERS, body: 'Forwarding to Formspree failed' };
    }

    return { statusCode: 200, headers: CORS_HEADERS, body: '' };
  } catch (err) {
    console.error('submit-form error', err);
    return { statusCode: 500, headers: CORS_HEADERS, body: 'Internal Server Error' };
  }
};
