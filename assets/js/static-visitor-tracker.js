/**
 * XXMXLI Static Visitor Tracker
 * Client-side only tracking for GitHub Pages
 */
class StaticVisitorTracker {
    constructor() {
        this.storageKey = 'xxmxli_visitors';
        this.sessionKey = 'xxmxli_session';
        this.init();
    }

    init() {
        // Only track if not already tracked in this session
        if (!sessionStorage.getItem(this.sessionKey)) {
            this.trackVisit();
            sessionStorage.setItem(this.sessionKey, 'tracked');
        }
    }

    async trackVisit() {
        try {
            const visitorData = await this.gatherVisitorData();
            this.storeVisit(visitorData);
            
            // Optional: Send to webhook if configured
            if (window.XXMXLI_WEBHOOK_URL) {
                this.sendToWebhook(visitorData);
            }
            
            console.log('📊 Visitor tracked:', visitorData.ip);
        } catch (error) {
            console.warn('⚠️ Visitor tracking failed:', error);
        }
    }

    async gatherVisitorData() {
        const ip = await this.getPublicIP();
        const location = await this.getLocationData(ip);
        
        return {
            timestamp: new Date().toISOString(),
            sessionId: this.generateSessionId(),
            ip: ip,
            userAgent: navigator.userAgent,
            url: window.location.href,
            page: window.location.pathname,
            referrer: document.referrer || 'Direct',
            title: document.title,
            language: navigator.language,
            platform: navigator.platform,
            screenResolution: `${screen.width}x${screen.height}`,
            viewport: `${window.innerWidth}x${window.innerHeight}`,
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            location: location,
            loadTime: performance.now(),
            browser: this.getBrowserInfo(),
            isBot: this.detectBot(),
            blocked: false,
            suspicious: false
        };
    }

    async getPublicIP() {
        const services = [
            'https://api.ipify.org?format=json',
            'https://ipapi.co/json/',
            'https://api.my-ip.io/ip.json'
        ];

        for (const service of services) {
            try {
                const response = await fetch(service, { 
                    timeout: 3000,
                    signal: AbortSignal.timeout(3000)
                });
                const data = await response.json();
                const ip = data.ip || data.origin;
                if (ip) return ip;
            } catch (error) {
                continue;
            }
        }
        return 'Unknown';
    }

    async getLocationData(ip) {
        if (ip === 'Unknown') return { country: 'Unknown', city: 'Unknown' };
        
        try {
            const response = await fetch(`https://ipapi.co/${ip}/json/`, {
                timeout: 3000,
                signal: AbortSignal.timeout(3000)
            });
            const data = await response.json();
            
            return {
                country: data.country_name || 'Unknown',
                countryCode: data.country_code || 'XX',
                city: data.city || 'Unknown',
                region: data.region || 'Unknown',
                isp: data.org || 'Unknown'
            };
        } catch (error) {
            return { country: 'Unknown', city: 'Unknown' };
        }
    }

    getBrowserInfo() {
        const ua = navigator.userAgent;
        if (ua.includes('Chrome')) return { name: 'Chrome', version: this.extractVersion(ua, 'Chrome') };
        if (ua.includes('Firefox')) return { name: 'Firefox', version: this.extractVersion(ua, 'Firefox') };
        if (ua.includes('Safari') && !ua.includes('Chrome')) return { name: 'Safari', version: this.extractVersion(ua, 'Safari') };
        if (ua.includes('Edge')) return { name: 'Edge', version: this.extractVersion(ua, 'Edge') };
        if (ua.includes('Opera')) return { name: 'Opera', version: this.extractVersion(ua, 'Opera') };
        return { name: 'Unknown', version: 'Unknown' };
    }

    extractVersion(ua, browser) {
        const match = ua.match(new RegExp(`${browser}[\/]([\\d\\.]+)`));
        return match ? match[1] : 'Unknown';
    }

    detectBot() {
        const ua = navigator.userAgent.toLowerCase();
        const botPatterns = ['bot', 'crawler', 'spider', 'scraper'];
        return botPatterns.some(pattern => ua.includes(pattern));
    }

    generateSessionId() {
        return 'xxmxli_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    storeVisit(visitorData) {
        try {
            let visits = JSON.parse(localStorage.getItem(this.storageKey) || '[]');
            
            // Limit stored visits to prevent localStorage bloat
            if (visits.length >= 1000) {
                visits = visits.slice(-500); // Keep last 500
            }
            
            visits.push(visitorData);
            localStorage.setItem(this.storageKey, JSON.stringify(visits));
            
            // Update daily stats
            this.updateDailyStats(visitorData);
        } catch (error) {
            console.warn('Failed to store visit:', error);
        }
    }

    updateDailyStats(visitorData) {
        try {
            const today = new Date().toISOString().split('T')[0];
            let dailyStats = JSON.parse(localStorage.getItem('xxmxli_daily_stats') || '{}');
            
            if (!dailyStats[today]) {
                dailyStats[today] = {
                    visits: 0,
                    uniqueIPs: new Set(),
                    countries: {},
                    pages: {},
                    blocked: 0
                };
            }
            
            dailyStats[today].visits++;
            dailyStats[today].uniqueIPs.add(visitorData.ip);
            
            const country = visitorData.location?.country || 'Unknown';
            dailyStats[today].countries[country] = (dailyStats[today].countries[country] || 0) + 1;
            
            const page = visitorData.page;
            dailyStats[today].pages[page] = (dailyStats[today].pages[page] || 0) + 1;
            
            if (visitorData.blocked) {
                dailyStats[today].blocked++;
            }
            
            // Convert Set to Array for storage
            dailyStats[today].uniqueIPs = Array.from(dailyStats[today].uniqueIPs);
            
            // Clean old data (keep last 30 days)
            const cutoffDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
            Object.keys(dailyStats).forEach(date => {
                if (new Date(date) < cutoffDate) {
                    delete dailyStats[date];
                }
            });
            
            localStorage.setItem('xxmxli_daily_stats', JSON.stringify(dailyStats));
        } catch (error) {
            console.warn('Failed to update daily stats:', error);
        }
    }

    async sendToWebhook(visitorData) {
        try {
            await fetch(window.XXMXLI_WEBHOOK_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    type: 'visitor_track',
                    data: visitorData,
                    site: 'xxmxli.com'
                })
            });
        } catch (error) {
            console.warn('Failed to send to webhook:', error);
        }
    }

    // Static methods for dashboard access
    static getStoredVisits() {
        try {
            return JSON.parse(localStorage.getItem('xxmxli_visitors') || '[]');
        } catch {
            return [];
        }
    }

    static getDailyStats() {
        try {
            return JSON.parse(localStorage.getItem('xxmxli_daily_stats') || '{}');
        } catch {
            return {};
        }
    }

    static clearData() {
        localStorage.removeItem('xxmxli_visitors');
        localStorage.removeItem('xxmxli_daily_stats');
        sessionStorage.removeItem('xxmxli_session');
    }

    static exportData() {
        return {
            visits: StaticVisitorTracker.getStoredVisits(),
            dailyStats: StaticVisitorTracker.getDailyStats(),
            exportDate: new Date().toISOString()
        };
    }
}

// Auto-initialize if in browser
if (typeof window !== 'undefined' && typeof document !== 'undefined') {
    // Wait for page load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            new StaticVisitorTracker();
        });
    } else {
        new StaticVisitorTracker();
    }
}

// Make available globally
window.StaticVisitorTracker = StaticVisitorTracker;

// Convenience static wrapper: allow pages to call StaticVisitorTracker.trackVisit()
if (typeof StaticVisitorTracker.trackVisit !== 'function') {
    StaticVisitorTracker.trackVisit = function() {
        try {
            const inst = new StaticVisitorTracker();
            return inst.trackVisit();
        } catch (e) {
            console.warn('StaticVisitorTracker.trackVisit wrapper failed', e);
        }
    };
}
