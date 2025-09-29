// XXMXLI Analytics Tracker
// GDPR-aware analytics with custom event API and enhanced device info
(function() {
  'use strict';

  // --- Consent ---
  function hasAnalyticsConsent() {
    try {
      const consent = localStorage.getItem('xxmxli_gdpr_consent');
      if (!consent) return false;
      const parsed = JSON.parse(consent);
      return parsed.analytics === true;
    } catch (e) { return false; }
  }

  // --- Session ---
  function getSessionId() {
    let sessionId = sessionStorage.getItem('xxmxli_session_id');
    if (!sessionId) {
      sessionId = Date.now().toString(36) + Math.random().toString(36).slice(2);
      sessionStorage.setItem('xxmxli_session_id', sessionId);
    }
    return sessionId;
  }

  // --- Device & browser info ---
  function parseUA(ua) {
    ua = ua || navigator.userAgent;
    const out = { browser: 'unknown', os: 'unknown', device: 'desktop' };
    // Browser
    if (/Firefox\//.test(ua)) out.browser = 'Firefox';
    else if (/Edg\//.test(ua)) out.browser = 'Edge';
    else if (/Chrome\//.test(ua)) out.browser = 'Chrome';
    else if (/Safari\//.test(ua)) out.browser = 'Safari';
    // OS
    if (/Windows/i.test(ua)) out.os = 'Windows';
    else if (/Mac OS X|Macintosh/i.test(ua)) out.os = 'macOS';
    else if (/Android/i.test(ua)) out.os = 'Android';
    else if (/iPhone|iPad|iPod/i.test(ua)) out.os = 'iOS';
    else if (/Linux/i.test(ua)) out.os = 'Linux';
    // Device type
    if (/Mobi|Android|iPhone|iPad|iPod/i.test(ua)) out.device = 'mobile';
    return out;
  }

  function getDeviceInfo() {
    const nav = navigator || {};
    const scr = window.screen || {};
    const conn = nav.connection || nav.mozConnection || nav.webkitConnection;
    const tz = (Intl.DateTimeFormat && Intl.DateTimeFormat().resolvedOptions().timeZone) || '';
    const uaParsed = parseUA(nav.userAgent || '');
    return {
      userAgent: nav.userAgent || 'unknown',
      languages: nav.languages || [nav.language || 'unknown'],
      platform: nav.platform || 'unknown',
      vendor: nav.vendor || '',
      hardwareConcurrency: nav.hardwareConcurrency || null,
      deviceMemory: nav.deviceMemory || null,
      touch: ('ontouchstart' in window) || (nav.maxTouchPoints > 0) || false,
      screen: {
        width: scr.width || null,
        height: scr.height || null,
        availWidth: scr.availWidth || null,
        availHeight: scr.availHeight || null,
        colorDepth: scr.colorDepth || null,
        pixelRatio: window.devicePixelRatio || 1
      },
      viewport: { w: window.innerWidth, h: window.innerHeight },
      timezone: tz,
      tzOffset: new Date().getTimezoneOffset(),
      network: conn ? {
        effectiveType: conn.effectiveType,
        rtt: conn.rtt,
        downlink: conn.downlink,
        saveData: conn.saveData
      } : null,
      parsed: uaParsed
    };
  }

  // --- Transport helpers ---
  const ENDPOINTS = ['/.netlify/functions/analytics', '/netlify/functions/analytics'];

  async function postJSON(url, payload, useBeacon) {
    try {
      const body = JSON.stringify(payload);
      if (useBeacon && navigator.sendBeacon) {
        const ok = navigator.sendBeacon(url, body);
        if (ok) return { ok: true };
        // fallback to fetch if beacon fails
      }
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body
      });
      return res;
    } catch (e) {
      return { ok: false, error: e };
    }
  }

  async function send(payload, opts) {
    const useBeacon = !!(opts && opts.beacon);
    for (const url of ENDPOINTS) {
      const res = await postJSON(url, payload, useBeacon);
      if (res && res.ok) return true;
    }
    return false;
  }

  // --- Public API ---
  const api = {
    track: function(eventName, data) {
      const consent = hasAnalyticsConsent();
      if (!consent) { return false; }
      const payload = {
        kind: 'event',
        name: String(eventName || '').toLowerCase(),
        data: data || {},
        page: window.location.href,
        sessionId: getSessionId(),
        ts: Date.now(),
        device: getDeviceInfo(),
        visibility: document.visibilityState
      };
      return send(payload, { beacon: false });
    }
  };
  // Always expose API (no-op if no consent)
  window.xxmxliAnalytics = api;

  // --- Page view tracking ---
  function sendPageView() {
    if (!hasAnalyticsConsent()) return;
    const payload = {
      kind: 'pageview',
      page: window.location.href,
      path: window.location.pathname,
      referrer: document.referrer || '',
      sessionId: getSessionId(),
      ts: Date.now(),
      device: getDeviceInfo()
    };
    send(payload, { beacon: false });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', sendPageView);
  } else {
    sendPageView();
  }

  // Simple SPA path watcher
  let currentPath = window.location.pathname;
  setInterval(() => {
    if (window.location.pathname !== currentPath) {
      currentPath = window.location.pathname;
      sendPageView();
    }
  }, 1000);

  // --- Auto-triggers ---
  // sleep/wake on tab visibility
  document.addEventListener('visibilitychange', () => {
    if (!hasAnalyticsConsent()) return;
    const name = document.visibilityState === 'hidden' ? 'sleep' : 'wake';
    api.track(name, {});
  });

  // drop on pagehide/beforeunload (use Beacon)
  const dropHandler = () => {
    if (!hasAnalyticsConsent()) return;
    const payload = {
      kind: 'event',
      name: 'drop',
      data: {},
      page: window.location.href,
      sessionId: getSessionId(),
      ts: Date.now(),
      device: getDeviceInfo(),
      visibility: document.visibilityState
    };
    // fire-and-forget beacon
    send(payload, { beacon: true });
  };
  window.addEventListener('pagehide', dropHandler);
  window.addEventListener('beforeunload', dropHandler);

  // data-analytics-trigger hooks (e.g., obey)
  document.addEventListener('click', (e) => {
    let el = e.target;
    while (el && el !== document.body) {
      const trig = el.getAttribute && el.getAttribute('data-analytics-trigger');
      if (trig) {
        const meta = el.getAttribute('data-analytics-meta');
        let data = {};
        if (meta) {
          try { data = JSON.parse(meta); } catch(_) { data = { meta }; }
        }
        data.text = (el.innerText || el.value || '').slice(0, 100);
        data.id = el.id || '';
        data.href = el.href || '';
        api.track(trig, data);
        break;
      }
      el = el.parentElement;
    }
  }, true);
})();