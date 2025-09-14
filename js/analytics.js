// XXMXLI Analytics Tracker
// Sends visitor data to analytics endpoint

(function() {
  'use strict';
  
  // Generate session ID (persists for session)
  function getSessionId() {
    let sessionId = sessionStorage.getItem('xxmxli_session_id');
    if (!sessionId) {
      sessionId = Date.now().toString(36) + Math.random().toString(36).substr(2);
      sessionStorage.setItem('xxmxli_session_id', sessionId);
    }
    return sessionId;
  }
  
  // Collect visitor data
  function collectVisitorData() {
    return {
      page: window.location.href,
      sessionId: getSessionId(),
      viewport: window.innerWidth + 'x' + window.innerHeight,
      language: navigator.language || 'unknown',
      platform: navigator.platform || 'unknown',
      timestamp: Date.now()
    };
  }
  
  // Send analytics data
  function sendAnalytics() {
    try {
      const data = collectVisitorData();
      
      fetch('/netlify/functions/analytics', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
      }).catch(err => {
        // Silently fail - don't break site if analytics fails
        console.debug('Analytics tracking failed:', err);
      });
    } catch (error) {
      console.debug('Analytics error:', error);
    }
  }
  
  // Track page view on load
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', sendAnalytics);
  } else {
    sendAnalytics();
  }
  
  // Track page changes for SPAs (if needed)
  let currentPath = window.location.pathname;
  setInterval(() => {
    if (window.location.pathname !== currentPath) {
      currentPath = window.location.pathname;
      sendAnalytics();
    }
  }, 1000);
  
})();