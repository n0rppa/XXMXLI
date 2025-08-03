/**
 * XXMXLI Visitor Tracking System
 * Complete visitor analytics and IP monitoring
 */
class VisitorTracker {
    constructor(options = {}) {
        this.config = {
            apiEndpoint: '/api/visitor-logger.php',
            trackingEnabled: true,
            showVisitorInfo: options.showInfo || false,
            logToConsole: options.debug || false,
            autoBlock: options.autoBlock || false,
            ...options
        };
        
        this.visitorData = {};
        this.sessionId = this.generateSessionId();
        this.startTime = performance.now();
    }

    async init() {
        if (!this.config.trackingEnabled) return;
        
        try {
            await this.gatherVisitorData();
            
            if (this.config.showVisitorInfo) {
                this.displayVisitorInfo();
            }
            
            await this.logVisit();
            
            if (this.config.logToConsole) {
                console.log('🔍 Visitor Data:', this.visitorData);
            }

            // Check if IP should be blocked
            if (this.visitorData.isBlocked && this.config.autoBlock) {
                this.handleBlockedVisitor();
            }
            
        } catch (error) {
            console.error('❌ Visitor tracking error:', error);
        }
    }

    async gatherVisitorData() {
        const ip = await this.getPublicIP();
        const location = await this.getLocationData(ip);
        const deviceInfo = this.getDeviceInfo();
        
        this.visitorData = {
            // Session Info
            sessionId: this.sessionId,
            timestamp: new Date().toISOString(),
            visitDuration: 0,
            
            // Network Info
            ip: ip,
            userAgent: navigator.userAgent,
            
            // Page Info
            url: window.location.href,
            page: window.location.pathname,
            referrer: document.referrer || 'Direct',
            title: document.title,
            
            // Browser Info
            browser: this.getBrowserInfo(),
            language: navigator.language,
            languages: navigator.languages,
            platform: navigator.platform,
            cookieEnabled: navigator.cookieEnabled,
            doNotTrack: navigator.doNotTrack,
            
            // Device Info
            ...deviceInfo,
            
            // System Info
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            timezoneOffset: new Date().getTimezoneOffset(),
            
            // Location (if available)
            location: location,
            
            // Performance
            loadTime: this.startTime,
            connectionType: this.getConnectionType(),
            
            // Security
            isBlocked: await this.checkIfBlocked(ip),
            threatLevel: this.calculateThreatLevel(ip),
            
            // Additional tracking
            plugins: this.getPlugins(),
            java: navigator.javaEnabled(),
            localStorage: this.testLocalStorage(),
            sessionStorage: this.testSessionStorage()
        };
    }

    async getPublicIP() {
        const services = [
            { url: 'https://api.ipify.org?format=json', key: 'ip' },
            { url: 'https://ipapi.co/json/', key: 'ip' },
            { url: 'https://api.my-ip.io/ip.json', key: 'ip' },
            { url: 'https://httpbin.org/ip', key: 'origin' }
        ];

        for (const service of services) {
            try {
                const controller = new AbortController();
                const timeoutId = setTimeout(() => controller.abort(), 5000);
                
                const response = await fetch(service.url, { 
                    signal: controller.signal 
                });
                clearTimeout(timeoutId);
                
                const data = await response.json();
                const ip = data[service.key];
                
                if (ip && this.isValidIP(ip)) {
                    return ip;
                }
            } catch (error) {
                console.warn(`IP service ${service.url} failed:`, error.message);
            }
        }
        return 'Unknown';
    }

    isValidIP(ip) {
        const ipv4Regex = /^(\d{1,3}\.){3}\d{1,3}$/;
        const ipv6Regex = /^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$/;
        return ipv4Regex.test(ip) || ipv6Regex.test(ip);
    }

    async getLocationData(ip) {
        if (ip === 'Unknown') return {};
        
        try {
            const response = await fetch(`https://ipapi.co/${ip}/json/`);
            const data = await response.json();
            
            return {
                country: data.country_name || 'Unknown',
                countryCode: data.country_code || 'XX',
                city: data.city || 'Unknown',
                region: data.region || 'Unknown',
                latitude: data.latitude || null,
                longitude: data.longitude || null,
                isp: data.org || 'Unknown',
                timezone: data.timezone || 'Unknown'
            };
        } catch (error) {
            console.warn('Location service failed:', error);
            return {};
        }
    }

    getDeviceInfo() {
        return {
            screenResolution: `${screen.width}x${screen.height}`,
            windowSize: `${window.innerWidth}x${window.innerHeight}`,
            colorDepth: screen.colorDepth,
            pixelRatio: window.devicePixelRatio || 1,
            touchSupport: 'ontouchstart' in window,
            orientation: screen.orientation ? screen.orientation.type : 'Unknown'
        };
    }

    getBrowserInfo() {
        const ua = navigator.userAgent;
        let browser = 'Unknown';
        let version = 'Unknown';

        if (ua.includes('Chrome')) {
            browser = 'Chrome';
            version = ua.match(/Chrome\/(\d+)/)?.[1] || 'Unknown';
        } else if (ua.includes('Firefox')) {
            browser = 'Firefox';
            version = ua.match(/Firefox\/(\d+)/)?.[1] || 'Unknown';
        } else if (ua.includes('Safari') && !ua.includes('Chrome')) {
            browser = 'Safari';
            version = ua.match(/Safari\/(\d+)/)?.[1] || 'Unknown';
        } else if (ua.includes('Edge')) {
            browser = 'Edge';
            version = ua.match(/Edge\/(\d+)/)?.[1] || 'Unknown';
        } else if (ua.includes('Opera')) {
            browser = 'Opera';
            version = ua.match(/Opera\/(\d+)/)?.[1] || 'Unknown';
        }

        return { name: browser, version: version };
    }

    getConnectionType() {
        const connection = navigator.connection || 
                          navigator.mozConnection || 
                          navigator.webkitConnection;
        
        if (connection) {
            return {
                effectiveType: connection.effectiveType || 'Unknown',
                downlink: connection.downlink || 'Unknown',
                rtt: connection.rtt || 'Unknown',
                saveData: connection.saveData || false
            };
        }
        return { effectiveType: 'Unknown' };
    }

    getPlugins() {
        const plugins = [];
        for (let i = 0; i < navigator.plugins.length; i++) {
            plugins.push(navigator.plugins[i].name);
        }
        return plugins.slice(0, 10); // Limit to first 10 plugins
    }

    testLocalStorage() {
        try {
            localStorage.setItem('test', 'test');
            localStorage.removeItem('test');
            return true;
        } catch (e) {
            return false;
        }
    }

    testSessionStorage() {
        try {
            sessionStorage.setItem('test', 'test');
            sessionStorage.removeItem('test');
            return true;
        } catch (e) {
            return false;
        }
    }

    async checkIfBlocked(ip) {
        try {
            const response = await fetch('/api/check-blacklist.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ ip: ip })
            });
            const result = await response.json();
            return result.blocked || false;
        } catch (error) {
            return false;
        }
    }

    calculateThreatLevel(ip) {
        // Simple threat calculation based on IP patterns
        if (ip === 'Unknown') return 'Unknown';
        
        const parts = ip.split('.');
        if (parts.length !== 4) return 'Low'; // IPv6 or invalid
        
        // Check for suspicious patterns
        const firstOctet = parseInt(parts[0]);
        
        // Known suspicious ranges
        if (firstOctet === 127) return 'Localhost';
        if (firstOctet >= 224) return 'Reserved';
        if ([10, 172, 192].includes(firstOctet)) return 'Private';
        
        return 'Low'; // Default for public IPs
    }

    generateSessionId() {
        return 'xxmxli_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    displayVisitorInfo() {
        // Remove existing container if present
        const existing = document.getElementById('visitor-info-container');
        if (existing) existing.remove();

        const container = document.createElement('div');
        container.id = 'visitor-info-container';
        container.className = 'visitor-info-container';
        
        container.innerHTML = `
            <div class="visitor-info-card">
                <div class="visitor-header">
                    <h3><i class="fas fa-eye"></i> Visitor Tracking</h3>
                    <button class="close-btn" onclick="this.closest('.visitor-info-container').remove()">×</button>
                </div>
                <div class="visitor-details">
                    <div class="info-section">
                        <div class="info-row">
                            <span class="label">IP Address:</span>
                            <span class="value">${this.visitorData.ip}</span>
                            <span class="status ${this.visitorData.isBlocked ? 'blocked' : 'allowed'}">
                                ${this.visitorData.isBlocked ? '🚫 BLOCKED' : '✅ ALLOWED'}
                            </span>
                        </div>
                        <div class="info-row">
                            <span class="label">Location:</span>
                            <span class="value">${this.visitorData.location.city || 'Unknown'}, ${this.visitorData.location.country || 'Unknown'}</span>
                        </div>
                        <div class="info-row">
                            <span class="label">ISP:</span>
                            <span class="value">${this.visitorData.location.isp || 'Unknown'}</span>
                        </div>
                        <div class="info-row">
                            <span class="label">Browser:</span>
                            <span class="value">${this.visitorData.browser.name} ${this.visitorData.browser.version}</span>
                        </div>
                        <div class="info-row">
                            <span class="label">Device:</span>
                            <span class="value">${this.visitorData.screenResolution} • ${this.visitorData.platform}</span>
                        </div>
                        <div class="info-row">
                            <span class="label">Time:</span>
                            <span class="value">${new Date(this.visitorData.timestamp).toLocaleString()}</span>
                        </div>
                        <div class="info-row">
                            <span class="label">Session:</span>
                            <span class="value session-id">${this.sessionId}</span>
                        </div>
                        <div class="info-row">
                            <span class="label">Threat Level:</span>
                            <span class="value threat-${this.visitorData.threatLevel.toLowerCase()}">${this.visitorData.threatLevel}</span>
                        </div>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(container);
        
        // Auto-hide after 10 seconds
        setTimeout(() => {
            if (container.parentNode) {
                container.remove();
            }
        }, 10000);
    }

    handleBlockedVisitor() {
        // Redirect blocked visitors
        const blockedPage = '/blocked.html';
        console.warn('🚫 Blocked visitor detected, redirecting...');
        
        // Show warning first
        if (confirm('Your IP address is on our security blacklist. Contact admin if this is an error.')) {
            window.location.href = blockedPage;
        }
    }

    async logVisit() {
        try {
            const response = await fetch(this.config.apiEndpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(this.visitorData)
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const result = await response.json();
            
            if (this.config.logToConsole) {
                console.log('✅ Visit logged successfully:', result);
            }

        } catch (error) {
            console.error('❌ Failed to log visit:', error);
            
            // Fallback: log to localStorage if server is down
            this.logToLocalStorage();
        }
    }

    logToLocalStorage() {
        try {
            const visits = JSON.parse(localStorage.getItem('xxmxli_visits') || '[]');
            visits.push({
                ...this.visitorData,
                storedLocally: true
            });
            
            // Keep only last 50 visits
            if (visits.length > 50) {
                visits.splice(0, visits.length - 50);
            }
            
            localStorage.setItem('xxmxli_visits', JSON.stringify(visits));
            console.log('📱 Visit logged to localStorage as fallback');
            
            // Also show notification to user
            this.showStorageNotification();
        } catch (error) {
            console.error('Failed to log to localStorage:', error);
        }
    }

    showStorageNotification() {
        // Create notification element
        const notification = document.createElement('div');
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            left: 20px;
            background: rgba(0, 255, 0, 0.1);
            border: 1px solid #00ff00;
            color: #00ff00;
            padding: 10px 15px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 12px;
            z-index: 10000;
            animation: fadeInOut 3s ease-in-out;
        `;
        notification.innerHTML = '📱 Visitor data stored locally (no server connection)';
        
        // Add fade animation
        const style = document.createElement('style');
        style.textContent = `
            @keyframes fadeInOut {
                0% { opacity: 0; transform: translateX(-20px); }
                20% { opacity: 1; transform: translateX(0); }
                80% { opacity: 1; transform: translateX(0); }
                100% { opacity: 0; transform: translateX(-20px); }
            }
        `;
        document.head.appendChild(style);
        
        document.body.appendChild(notification);
        
        // Remove after animation
        setTimeout(() => {
            if (notification.parentNode) {
                notification.remove();
            }
            if (style.parentNode) {
                style.remove();
            }
        }, 3000);
    }

    // Public methods for external use
    getVisitorData() {
        return this.visitorData;
    }

    updateVisitDuration() {
        this.visitorData.visitDuration = Math.round((performance.now() - this.startTime) / 1000);
    }

    trackPageView(page) {
        this.visitorData.page = page || window.location.pathname;
        this.logVisit();
    }
}

// Auto-initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    // Check if tracking is enabled
    const trackingEnabled = !localStorage.getItem('xxmxli_tracking_disabled');
    
    if (trackingEnabled) {
        window.xxmxliTracker = new VisitorTracker({
            showInfo: false, // Set to true to show visitor info card
            debug: false,    // Set to true for console logging
            autoBlock: false // Set to true to auto-redirect blocked IPs
        });
        
        window.xxmxliTracker.init();
        
        // Update visit duration every 30 seconds
        setInterval(() => {
            if (window.xxmxliTracker) {
                window.xxmxliTracker.updateVisitDuration();
            }
        }, 30000);
        
        // Track page unload
        window.addEventListener('beforeunload', () => {
            if (window.xxmxliTracker) {
                window.xxmxliTracker.updateVisitDuration();
                // Send final update (beacon)
                if (navigator.sendBeacon) {
                    navigator.sendBeacon(
                        '/api/visitor-logger.php',
                        JSON.stringify({
                            ...window.xxmxliTracker.getVisitorData(),
                            event: 'page_unload'
                        })
                    );
                }
            }
        });
    }
});

// Global functions for manual control
window.enableXXMXLITracking = function() {
    localStorage.removeItem('xxmxli_tracking_disabled');
    location.reload();
};

window.disableXXMXLITracking = function() {
    localStorage.setItem('xxmxli_tracking_disabled', 'true');
    if (window.xxmxliTracker) {
        window.xxmxliTracker.config.trackingEnabled = false;
    }
};

window.showVisitorInfo = function() {
    if (window.xxmxliTracker) {
        window.xxmxliTracker.displayVisitorInfo();
    }
};

// Add function to view stored visitors
window.viewStoredVisitors = function() {
    const visits = JSON.parse(localStorage.getItem('xxmxli_visits') || '[]');
    console.log('📊 Stored Visitors:', visits);
    
    if (visits.length === 0) {
        console.log('No visitors stored yet. Visit some pages to track data.');
        return;
    }
    
    // Create summary table
    console.table(visits.map(v => ({
        IP: v.ip,
        Country: v.location?.country || 'Unknown',
        Browser: v.browser?.name || 'Unknown',
        Time: new Date(v.timestamp).toLocaleString(),
        Page: v.page
    })));
    
    alert(`Found ${visits.length} stored visitors. Check console for details.`);
};

// Add function to open static dashboard
window.openStaticDashboard = function() {
    const dashboardUrl = window.location.origin + '/admin/visitor-static.html';
    window.open(dashboardUrl, '_blank');
};
