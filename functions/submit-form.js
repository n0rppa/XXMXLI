export async function onRequestPost(context) {
  const { request, env } = context;
  const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type' };
  try {
    const contentType = request.headers.get('content-type') || '';
    let form = {};
    if (contentType.includes('application/x-www-form-urlencoded')) {
      const text = await request.text();
      const params = new URLSearchParams(text);
      for (const [k, v] of params.entries()) form[k] = v;
    } else if (contentType.includes('application/json')) {
      form = await request.json();
    } else {
      const text = await request.text();
      const params = new URLSearchParams(text);
      for (const [k, v] of params.entries()) form[k] = v;
    }

    // Turnstile verification
    const token = form.turnstile_token || form['cf-turnstile-response'];
    const ip = request.headers.get('CF-Connecting-IP') || '';
    const secret = env.TURNSTILE_SECRET || env.HCAPTCHA_SECRET || '';
    if (!secret) return new Response('Captcha not configured', { status: 500, headers: cors });
    const verifyResp = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ secret, response: token || '', remoteip: ip })
    });
    const verify = await verifyResp.json();
    if (!verify.success) {
      return new Response('Captcha failed', { status: 400, headers: cors });
    }

    // Forward to Formspree
    const FORMSPREE_ENDPOINT = env.FORMSPREE_ENDPOINT || 'https://formspree.io/f/mvgqqyqr';
    const forward = new URLSearchParams();
    for (const k of Object.keys(form)) if (k !== 'turnstile_token' && k !== 'cf-turnstile-response') forward.append(k, form[k]);
    const fr = await fetch(FORMSPREE_ENDPOINT, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: forward.toString() });
    if (!fr.ok && fr.status !== 200 && fr.status !== 204) return new Response('Forward failed', { status: 502, headers: cors });
    return new Response('', { status: 200, headers: cors });
  } catch (e) {
    return new Response('Server error', { status: 500, headers: cors });
  }
}

export async function onRequestOptions() {
  return new Response('', { status: 204, headers: { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type' } });
}