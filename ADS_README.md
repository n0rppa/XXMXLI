Ads & Monetization Guide for XXMXLI
=================================

This file explains simple, privacy-conscious ways to add ads and affiliate links to the site.

1) Affiliate Links
- Use affiliate links on blog posts, product recommendations, or resource pages.
- Always disclose affiliate relationships clearly (we added `affiliate-disclosure.html`).

2) Hosted Checkout / Donations
- Use Coinbase Commerce or BTCPay Server for crypto donations.
- Use Stripe Checkout for one-off payments or subscriptions.

3) Ad Networks
- Google AdSense: easiest, but adds tracking and personalization.
- Privacy-first alternatives: Carbon Ads, EthicalAds, AdThrive (higher CPM but stricter requirements).
- Self-hosted sponsorship banners: add simple `<div id="ad-placeholder">` and replace with sponsor HTML.

4) Privacy & Consent
- Add a clear disclosure and provide an opt-out for tracking.
- Use server-side or first-party analytics (Plausible, Matomo) if privacy matters.

5) Implementation Notes
- Place ad units in `index.html` footer or inside `grid-item` sections for higher visibility.
- Use responsive ad units and lazy-load ad scripts.

6) Next Steps
- I can add example AdSense snippet, or add a privacy-friendly ad example (EthicalAds). Tell me which ad provider you prefer and whether you want affiliate link templates added to `donate.html` or `projects.html`.
