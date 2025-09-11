Supabase reCAPTCHA verification setup

1. Create a new Supabase Edge Function (or use `supabase/functions`) and deploy `verify-recaptcha.js`.
2. Set environment variable `RECAPTCHA_SECRET` to your secret key (do NOT commit this to git).
3. In your contact form, POST to the function endpoint (e.g. `https://<project>.supabase.co/functions/v1/verify-recaptcha`).
4. The function validates the token and returns `{ok:true}` on success. On failure, handle appropriately on the client.

Plausible Installation notes
----------------------------
1. Create an account at plausible.io and add your site (domain).
2. Get your site ID (e.g. `example.com`) and add the snippet to your `<head>`:

   <script async defer data-domain="your-domain.com" src="https://plausible.io/js/plausible.js"></script>

3. Optionally enable custom event tracking with `window.plausible('eventName')`.
4. Plausible can be self-hosted if you prefer full control.
