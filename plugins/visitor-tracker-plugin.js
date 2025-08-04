/**
 * XXMXLI Visitor Tracker Plugin
 * A lightweight, self-contained visitor tracking solution
 * Works on any website - just include this script!
 * 
 * Features:
 * - Real-time visitor tracking
 * - IP detection and geolocation
 * - Browser fingerprinting
 * - Threat assessment
 * - Local storage fallback
 * - Admin dashboard
 * - Export/import data
 * 
 * Usage: <script src="visitor-tracker-plugin.js"></script>
 */

(function() {
    'use strict';
    
    class XXMXLIVisitorTracker {
        constructor(options = {}) {
            this.options = {
                apiKey: options.apiKey || 'xxmxli-tracker',
                enableConsoleLog: options.enableConsoleLog !== false,
                enableNotifications: options.enableNotifications === true,
                storageKey: options.storageKey || 'xxmxli_visitors',
                maxStoredVisits: options.maxStoredVisits || 100,
                autoTrack: options.autoTrack !== false,
                dashboardEnabled: options.dashboardEnabled !== false,
                theme: options.theme || 'cyberpunk',
                ...options
            };
            
            this.sessionId = this.generateSessionId();
            this.visitorData = null;
            this.isTracking = false;
            
            if (this.options.autoTrack) {
                this.init();
            }
        }
        
        async init() {
            if (this.isTracking) return;
            this.isTracking = true;
            
            try {
                await this.collectVisitorData();
                await this.processVisitor();
                this.setupDashboard();
                
                if (this.options.enableConsoleLog) {
                    console.log('🔍 XXMXLI Visitor Tracker initialized', this.visitorData);
                }
            } catch (error) {
                console.error('Failed to initialize visitor tracker:', error);
            }
        }
        
        generateSessionId() {
            return 'xxmxli_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
        }
        
        async collectVisitorData() {
            const data = {
                sessionId: this.sessionId,
                timestamp: new Date().toISOString(),
                url: window.location.href,
                referrer: document.referrer || 'Direct',
                userAgent: navigator.userAgent,
                language: navigator.language,
                platform: navigator.platform,
                cookiesEnabled: navigator.cookieEnabled,
                screenResolution: `${screen.width}x${screen.height}`,
                viewport: `${window.innerWidth}x${window.innerHeight}`,
                timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                battery: null,
                connection: null,
                plugins: [],
                fingerprint: null
            };
            
            // Enhanced data collection
            try {
                // Battery API
                if ('getBattery' in navigator) {
                    const battery = await navigator.getBattery();
                    data.battery = {
                        level: Math.round(battery.level * 100),
                        charging: battery.charging
                    };
                }
            } catch (e) {}
            
            // Connection API
            if ('connection' in navigator) {
                data.connection = {
                    effectiveType: navigator.connection.effectiveType,
                    downlink: navigator.connection.downlink
                };
            }
            
            // Plugins
            data.plugins = Array.from(navigator.plugins).map(p => p.name);
            
            // Browser fingerprint
            data.fingerprint = this.generateFingerprint();
            
            // Browser detection
            data.browser = this.detectBrowser();
            
            // IP and location (external service)
            try {
                const ipData = await this.getLocationData();
                data.ip = ipData.ip;
                data.location = ipData;
            } catch (e) {
                data.ip = 'Unknown';
                data.location = { country: 'Unknown', city: 'Unknown', isp: 'Unknown' };
            }
            
            // Threat assessment
            data.threatLevel = this.assessThreat(data);
            
            this.visitorData = data;
            return data;
        }
        
        generateFingerprint() {
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            ctx.textBaseline = 'top';
            ctx.font = '14px Arial';
            ctx.fillText('XXMXLI Fingerprint', 2, 2);
            
            const fingerprint = [
                navigator.userAgent,
                navigator.language,
                screen.width + 'x' + screen.height,
                new Date().getTimezoneOffset(),
                canvas.toDataURL()
            ].join('|');
            
            return this.hashCode(fingerprint);
        }
        
        hashCode(str) {
            let hash = 0;
            for (let i = 0; i < str.length; i++) {
                const char = str.charCodeAt(i);
                hash = ((hash << 5) - hash) + char;
                hash = hash & hash;
            }
            return Math.abs(hash).toString(36);
        }
        
        detectBrowser() {
            const ua = navigator.userAgent;
            let browser = { name: 'Unknown', version: 'Unknown' };
            
            if (ua.includes('Chrome') && !ua.includes('Edg')) {
                browser.name = 'Chrome';
                browser.version = ua.match(/Chrome\/(\d+)/)?.[1] || 'Unknown';
            } else if (ua.includes('Firefox')) {
                browser.name = 'Firefox';
                browser.version = ua.match(/Firefox\/(\d+)/)?.[1] || 'Unknown';
            } else if (ua.includes('Safari') && !ua.includes('Chrome')) {
                browser.name = 'Safari';
                browser.version = ua.match(/Version\/(\d+)/)?.[1] || 'Unknown';
            } else if (ua.includes('Edg')) {
                browser.name = 'Edge';
                browser.version = ua.match(/Edg\/(\d+)/)?.[1] || 'Unknown';
            }
            
            return browser;
        }
        
        async getLocationData() {
            // Try multiple IP services
            const services = [
                'https://ipapi.co/json/',
                'https://ipinfo.io/json',
                'https://api.ipify.org?format=json'
            ];
            
            for (const service of services) {
                try {
                    const response = await fetch(service);
                    const data = await response.json();
                    
                    return {
                        ip: data.ip || data.query,
                        country: data.country_name || data.country,
                        city: data.city,
                        region: data.region,
                        isp: data.org || data.isp,
                        lat: data.latitude || data.lat,
                        lon: data.longitude || data.lon
                    };
                } catch (e) {
                    continue;
                }
            }
            
            throw new Error('All IP services failed');
        }
        
        assessThreat(data) {
            let threatScore = 0;
            
            // Check for suspicious patterns
            if (data.userAgent.includes('bot') || data.userAgent.includes('crawler')) {
                threatScore += 30;
            }
            
            if (data.plugins.length === 0) {
                threatScore += 10;
            }
            
            if (data.referrer === '') {
                threatScore += 5;
            }
            
            if (data.language && !data.language.startsWith('en') && !data.language.startsWith('fi')) {
                threatScore += 5;
            }
            
            // Determine threat level
            if (threatScore >= 50) return 'HIGH';
            if (threatScore >= 25) return 'MEDIUM';
            if (threatScore >= 10) return 'LOW';
            return 'NONE';
        }
        
        async processVisitor() {
            // Store locally
            this.storeLocally();
            
            // Try to send to server if available
            try {
                await this.sendToServer();
            } catch (e) {
                if (this.options.enableConsoleLog) {
                    console.log('📱 Server not available, using local storage');
                }
            }
        }
        
        storeLocally() {
            try {
                const stored = JSON.parse(localStorage.getItem(this.options.storageKey) || '[]');
                stored.push(this.visitorData);
                
                // Keep only recent visits
                if (stored.length > this.options.maxStoredVisits) {
                    stored.splice(0, stored.length - this.options.maxStoredVisits);
                }
                
                localStorage.setItem(this.options.storageKey, JSON.stringify(stored));
            } catch (error) {
                console.error('Failed to store visitor data locally:', error);
            }
        }
        
        async sendToServer() {
            // This would attempt to send to a server endpoint
            // For now, just simulate the attempt
            return new Promise((resolve, reject) => {
                setTimeout(() => reject(new Error('No server configured')), 100);
            });
        }
        
        setupDashboard() {
            if (!this.options.dashboardEnabled) return;
            
            // Add keyboard shortcut (Ctrl+Shift+V) to open dashboard
            document.addEventListener('keydown', (e) => {
                if (e.ctrlKey && e.shiftKey && e.key === 'V') {
                    this.openDashboard();
                }
            });
            
            // Add to window for manual access
            window.xxmxliTracker = this;
        }
        
        openDashboard() {
            const dashboard = this.createDashboard();
            document.body.appendChild(dashboard);
        }
        
        createDashboard() {
            const stored = JSON.parse(localStorage.getItem(this.options.storageKey) || '[]');
            const stats = this.calculateStats(stored);
            
            const modal = document.createElement('div');
            modal.innerHTML = `
                <div style="
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background: rgba(0, 0, 0, 0.9);
                    z-index: 999999;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-family: 'Courier New', monospace;
                ">
                    <div style="
                        background: #0a0a0a;
                        border: 2px solid #00ff00;
                        border-radius: 8px;
                        padding: 20px;
                        max-width: 800px;
                        max-height: 80vh;
                        overflow-y: auto;
                        color: #00ff00;
                        box-shadow: 0 0 30px #00ff00;
                    ">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                            <h2 style="margin: 0; text-shadow: 0 0 10px #00ff00;">🔍 XXMXLI Visitor Tracker</h2>
                            <button onclick="this.closest('[style*=\"position: fixed\"]').remove()" style="
                                background: #ff0040;
                                border: 1px solid #ff0040;
                                color: white;
                                padding: 5px 10px;
                                border-radius: 4px;
                                cursor: pointer;
                            ">✕</button>
                        </div>
                        
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 20px;">
                            <div style="background: rgba(0, 255, 0, 0.1); padding: 15px; border-radius: 4px; border: 1px solid #00ff00;">
                                <div style="font-size: 24px; font-weight: bold;">${stats.total}</div>
                                <div style="font-size: 12px; opacity: 0.8;">TOTAL VISITORS</div>
                            </div>
                            <div style="background: rgba(0, 255, 0, 0.1); padding: 15px; border-radius: 4px; border: 1px solid #00ff00;">
                                <div style="font-size: 24px; font-weight: bold;">${stats.unique}</div>
                                <div style="font-size: 12px; opacity: 0.8;">UNIQUE IPS</div>
                            </div>
                            <div style="background: rgba(0, 255, 0, 0.1); padding: 15px; border-radius: 4px; border: 1px solid #00ff00;">
                                <div style="font-size: 24px; font-weight: bold;">${stats.today}</div>
                                <div style="font-size: 12px; opacity: 0.8;">TODAY</div>
                            </div>
                            <div style="background: rgba(0, 255, 0, 0.1); padding: 15px; border-radius: 4px; border: 1px solid #00ff00;">
                                <div style="font-size: 24px; font-weight: bold;">${stats.topCountry}</div>
                                <div style="font-size: 12px; opacity: 0.8;">TOP COUNTRY</div>
                            </div>
                        </div>
                        
                        <div style="margin-bottom: 20px;">
                            <button onclick="window.xxmxliTracker.exportData()" style="
                                background: #0080ff;
                                border: 1px solid #0080ff;
                                color: white;
                                padding: 8px 15px;
                                margin-right: 10px;
                                border-radius: 4px;
                                cursor: pointer;
                            ">📥 Export Data</button>
                            
                            <button onclick="window.xxmxliTracker.clearData()" style="
                                background: #ff4000;
                                border: 1px solid #ff4000;
                                color: white;
                                padding: 8px 15px;
                                border-radius: 4px;
                                cursor: pointer;
                            ">🗑️ Clear Data</button>
                        </div>
                        
                        <div style="max-height: 300px; overflow-y: auto;">
                            <h3 style="margin: 0 0 10px 0;">Recent Visitors</h3>
                            ${this.renderVisitorTable(stored.slice(-20).reverse())}
                        </div>
                    </div>
                </div>
            `;
            
            return modal;
        }
        
        calculateStats(visitors) {
            const today = new Date().toDateString();
            const uniqueIps = new Set(visitors.map(v => v.ip).filter(Boolean));
            const countries = visitors.map(v => v.location?.country).filter(Boolean);
            const topCountry = this.getMostFrequent(countries) || 'Unknown';
            
            return {
                total: visitors.length,
                unique: uniqueIps.size,
                today: visitors.filter(v => new Date(v.timestamp).toDateString() === today).length,
                topCountry: topCountry
            };
        }
        
        getMostFrequent(arr) {
            const frequency = {};
            arr.forEach(item => frequency[item] = (frequency[item] || 0) + 1);
            return Object.keys(frequency).reduce((a, b) => frequency[a] > frequency[b] ? a : b, null);
        }
        
        renderVisitorTable(visitors) {
            if (visitors.length === 0) {
                return '<div style="text-align: center; opacity: 0.6;">No visitors tracked yet</div>';
            }
            
            return `
                <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
                    <thead>
                        <tr style="border-bottom: 1px solid #00ff00;">
                            <th style="padding: 8px; text-align: left;">Time</th>
                            <th style="padding: 8px; text-align: left;">IP</th>
                            <th style="padding: 8px; text-align: left;">Location</th>
                            <th style="padding: 8px; text-align: left;">Browser</th>
                            <th style="padding: 8px; text-align: left;">Threat</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${visitors.map(visitor => `
                            <tr style="border-bottom: 1px solid rgba(0, 255, 0, 0.2);">
                                <td style="padding: 8px;">${new Date(visitor.timestamp).toLocaleTimeString()}</td>
                                <td style="padding: 8px;">${visitor.ip || 'Unknown'}</td>
                                <td style="padding: 8px;">${visitor.location?.city || 'Unknown'}, ${visitor.location?.country || 'Unknown'}</td>
                                <td style="padding: 8px;">${visitor.browser?.name || 'Unknown'}</td>
                                <td style="padding: 8px;">
                                    <span style="
                                        color: ${visitor.threatLevel === 'HIGH' ? '#ff0040' : 
                                               visitor.threatLevel === 'MEDIUM' ? '#ff8000' :
                                               visitor.threatLevel === 'LOW' ? '#ffff00' : '#00ff00'};
                                    ">${visitor.threatLevel}</span>
                                </td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            `;
        }
        
        exportData() {
            const data = localStorage.getItem(this.options.storageKey) || '[]';
            const blob = new Blob([data], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            
            const a = document.createElement('a');
            a.href = url;
            a.download = `xxmxli-visitors-${new Date().toISOString().split('T')[0]}.json`;
            a.click();
            
            URL.revokeObjectURL(url);
        }
        
        clearData() {
            if (confirm('Are you sure you want to clear all visitor data?')) {
                localStorage.removeItem(this.options.storageKey);
                alert('Visitor data cleared!');
            }
        }
        
        // Public API methods
        getStats() {
            const stored = JSON.parse(localStorage.getItem(this.options.storageKey) || '[]');
            return this.calculateStats(stored);
        }
        
        getVisitors() {
            return JSON.parse(localStorage.getItem(this.options.storageKey) || '[]');
        }
        
        trackVisit() {
            return this.init();
        }
    }
    
    // Auto-initialize if not disabled
    if (typeof window !== 'undefined') {
        // Check for configuration in script tag
        const script = document.querySelector('script[src*="visitor-tracker-plugin"]');
        const config = script?.dataset ? Object.fromEntries(
            Object.entries(script.dataset).map(([k, v]) => [k, v === 'true' ? true : v === 'false' ? false : v])
        ) : {};
        
        // Initialize tracker
        window.XXMXLITracker = new XXMXLIVisitorTracker(config);
        
        // Add CSS for better styling
        const style = document.createElement('style');
        style.textContent = `
            .xxmxli-tracker-notification {
                position: fixed;
                top: 20px;
                right: 20px;
                background: rgba(0, 255, 0, 0.1);
                border: 1px solid #00ff00;
                color: #00ff00;
                padding: 10px 15px;
                border-radius: 4px;
                font-family: 'Courier New', monospace;
                font-size: 12px;
                z-index: 10000;
                animation: xxmxliSlideIn 0.3s ease-out;
            }
            
            @keyframes xxmxliSlideIn {
                from { transform: translateX(100%); opacity: 0; }
                to { transform: translateX(0); opacity: 1; }
            }
        `;
        document.head.appendChild(style);
        
        console.log('🔍 XXMXLI Visitor Tracker Plugin loaded! Press Ctrl+Shift+V to open dashboard.');
    }
    
    // Export for module systems
    if (typeof module !== 'undefined' && module.exports) {
        module.exports = XXMXLIVisitorTracker;
    }
    
})();
