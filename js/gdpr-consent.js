// GDPR Consent Manager for XXMXLI
(function() {
    'use strict';
    
    const CONSENT_KEY = 'xxmxli_gdpr_consent';
    const CONSENT_VERSION = '1.0';
    
    // Check if user has given consent
    function hasConsent() {
        try {
            const consent = localStorage.getItem(CONSENT_KEY);
            if (!consent) return false;
            
            const parsed = JSON.parse(consent);
            return parsed.analytics === true && parsed.version === CONSENT_VERSION;
        } catch (e) {
            return false;
        }
    }
    
    // Save consent preferences
    function saveConsent(analytics = false) {
        const consent = {
            analytics: analytics,
            timestamp: new Date().toISOString(),
            version: CONSENT_VERSION
        };
        localStorage.setItem(CONSENT_KEY, JSON.stringify(consent));
    }
    
    // Show GDPR consent banner
    function showConsentBanner() {
        if (hasConsent() || document.getElementById('gdpr-banner')) return;
        
        const banner = document.createElement('div');
        banner.id = 'gdpr-banner';
        banner.innerHTML = `
            <div style="
                position: fixed;
                bottom: 0;
                left: 0;
                right: 0;
                background: #001100;
                border-top: 2px solid #00ff00;
                padding: 1rem;
                z-index: 10000;
                font-family: 'Courier New', monospace;
                color: #00ff00;
                box-shadow: 0 -2px 10px rgba(0,255,0,0.3);
            ">
                <div style="max-width: 1200px; margin: 0 auto; display: flex; align-items: center; gap: 1rem; flex-wrap: wrap;">
                    <div style="flex: 1; min-width: 300px;">
                        <strong>🍪 Cookie Notice</strong><br>
                        We use cookies and analytics to improve your experience. We collect visitor statistics including IP addresses for security and analytics purposes. 
                        <a href="/privacy-policy.html" style="color: #00cc00; text-decoration: underline;">Privacy Policy</a>
                    </div>
                    <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                        <button onclick="GDPR.acceptAll()" style="
                            background: #00ff00;
                            color: #000;
                            border: none;
                            padding: 0.5rem 1rem;
                            cursor: pointer;
                            font-family: 'Courier New', monospace;
                            font-weight: bold;
                        ">Accept All</button>
                        <button onclick="GDPR.acceptNecessary()" style="
                            background: transparent;
                            color: #00ff00;
                            border: 1px solid #00ff00;
                            padding: 0.5rem 1rem;
                            cursor: pointer;
                            font-family: 'Courier New', monospace;
                        ">Necessary Only</button>
                        <button onclick="GDPR.showSettings()" style="
                            background: transparent;
                            color: #00cc00;
                            border: 1px solid #00cc00;
                            padding: 0.5rem 1rem;
                            cursor: pointer;
                            font-family: 'Courier New', monospace;
                        ">Settings</button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(banner);
    }
    
    // Show detailed consent settings
    function showConsentSettings() {
        const existing = document.getElementById('gdpr-settings');
        if (existing) existing.remove();
        
        const modal = document.createElement('div');
        modal.id = 'gdpr-settings';
        modal.innerHTML = `
            <div style="
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0,0,0,0.8);
                z-index: 20000;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 1rem;
            ">
                <div style="
                    background: #001100;
                    border: 2px solid #00ff00;
                    padding: 2rem;
                    max-width: 600px;
                    width: 100%;
                    font-family: 'Courier New', monospace;
                    color: #00ff00;
                    border-radius: 4px;
                ">
                    <h2 style="margin-bottom: 1rem; color: #00ff00;">Privacy Settings</h2>
                    
                    <div style="margin-bottom: 1.5rem;">
                        <h3 style="color: #00cc00; margin-bottom: 0.5rem;">Necessary Cookies</h3>
                        <p style="font-size: 0.9rem; margin-bottom: 0.5rem;">Required for basic site functionality</p>
                        <label style="display: flex; align-items: center; gap: 0.5rem;">
                            <input type="checkbox" checked disabled style="accent-color: #00ff00;">
                            Always Active (Required)
                        </label>
                    </div>
                    
                    <div style="margin-bottom: 1.5rem;">
                        <h3 style="color: #00cc00; margin-bottom: 0.5rem;">Analytics Cookies</h3>
                        <p style="font-size: 0.9rem; margin-bottom: 0.5rem;">Help us understand how visitors use our site. Includes IP address logging for security.</p>
                        <label style="display: flex; align-items: center; gap: 0.5rem;">
                            <input type="checkbox" id="analytics-consent" style="accent-color: #00ff00;" ${hasConsent() ? 'checked' : ''}>
                            Enable Analytics
                        </label>
                    </div>
                    
                    <div style="border-top: 1px solid #003300; padding-top: 1rem;">
                        <h4 style="color: #00cc00; margin-bottom: 0.5rem;">Data We Collect:</h4>
                        <ul style="font-size: 0.9rem; margin-left: 1rem;">
                            <li>IP address (for security and geolocation)</li>
                            <li>Browser type and version</li>
                            <li>Pages visited and time spent</li>
                            <li>Screen resolution and device type</li>
                            <li>Referrer information</li>
                        </ul>
                    </div>
                    
                    <div style="display: flex; gap: 1rem; margin-top: 2rem; justify-content: flex-end;">
                        <button onclick="GDPR.saveSettings()" style="
                            background: #00ff00;
                            color: #000;
                            border: none;
                            padding: 0.5rem 1rem;
                            cursor: pointer;
                            font-family: 'Courier New', monospace;
                            font-weight: bold;
                        ">Save Settings</button>
                        <button onclick="GDPR.closeSettings()" style="
                            background: transparent;
                            color: #00ff00;
                            border: 1px solid #00ff00;
                            padding: 0.5rem 1rem;
                            cursor: pointer;
                            font-family: 'Courier New', monospace;
                        ">Cancel</button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
    }
    
    // Remove banner
    function hideBanner() {
        const banner = document.getElementById('gdpr-banner');
        if (banner) banner.remove();
    }
    
    // Global GDPR object
    window.GDPR = {
        hasConsent: hasConsent,
        
        acceptAll: function() {
            saveConsent(true);
            hideBanner();
            // Reload analytics if consent given
            if (window.location.reload) {
                setTimeout(() => window.location.reload(), 500);
            }
        },
        
        acceptNecessary: function() {
            saveConsent(false);
            hideBanner();
        },
        
        showSettings: function() {
            showConsentSettings();
        },
        
        closeSettings: function() {
            const modal = document.getElementById('gdpr-settings');
            if (modal) modal.remove();
        },
        
        saveSettings: function() {
            const analyticsCheckbox = document.getElementById('analytics-consent');
            const analyticsConsent = analyticsCheckbox ? analyticsCheckbox.checked : false;
            
            saveConsent(analyticsConsent);
            this.closeSettings();
            hideBanner();
            
            // Reload if consent changed
            setTimeout(() => window.location.reload(), 500);
        },
        
        revokeConsent: function() {
            localStorage.removeItem(CONSENT_KEY);
            showConsentBanner();
        }
    };
    
    // Show banner on page load if no consent
    document.addEventListener('DOMContentLoaded', function() {
        if (!hasConsent()) {
            showConsentBanner();
        }
    });
    
})();