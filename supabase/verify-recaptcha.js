// Example Supabase Edge Function (Node) to verify reCAPTCHA v3 token
// Deploy this to Supabase Functions and set RECAPTCHA_SECRET in environment variables
const fetch = require('node-fetch');

module.exports = async (req, res) => {
  try {
    const form = await req.formData();
    const token = form.get('g-recaptcha-response');
    if (!token) return res.status(400).json({ ok: false, error: 'No token' });

    const secret = process.env.RECAPTCHA_SECRET;
    const verify = await fetch(`https://www.google.com/recaptcha/api/siteverify?secret=${encodeURIComponent(secret)}&response=${encodeURIComponent(token)}`, { method: 'POST' });
    const json = await verify.json();
    if (!json.success || json.score < 0.3) return res.status(403).json({ ok: false, error: 'Low score', score: json.score });

    // token valid — process the form as needed (store in DB, send email, forward to Formspree, etc.)
    return res.json({ ok: true, score: json.score });
  } catch (err) {
    console.error(err); return res.status(500).json({ ok: false, error: err.message });
  }
};
