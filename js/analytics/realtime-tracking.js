/**
 * XXMXLI Real-time Visitor Tracking Module
 * Live visitor counter, WebSocket integration, geographic distribution
 */

class RealtimeTrackingModule {
    constructor(core) {
        this.core = core;
        this.config = {
            websocketEnabled: true,
            websocketUrl: 'ws://localhost:8080',
            updateInterval: 5000, // 5 seconds for fallback polling
            geoEnabled: true
        };
        
        this.websocket = null;
        this.fallbackTimer = null;
        this.currentVisitors = 0;
        this.visitorLocations = new Map();
        this.isConnected = false;
    }

    async init() {
        await this.initWebSocket();
        this.bindEvents();
        this.startTracking();
        this.updateGeolocation();
        
        if (this.core.config.debug) {
            console.log('🌐 Real-time tracking module initialized');
        }
    }

    async initWebSocket() {
        if (!this.config.websocketEnabled) {
            this.startFallbackPolling();
            return;
        }

        try {
            this.websocket = new WebSocket(this.config.websocketUrl);
            
            this.websocket.onopen = () => {
                this.isConnected = true;
                this.sendVisitorInfo();
                if (this.core.config.debug) {
                    console.log('🔌 WebSocket connected');
                }
            };

            this.websocket.onmessage = (event) => {
                this.handleWebSocketMessage(event);
            };

            this.websocket.onclose = () => {
                this.isConnected = false;
                if (this.core.config.debug) {
                    console.log('🔌 WebSocket disconnected, falling back to polling');
                }
                this.startFallbackPolling();
            };

            this.websocket.onerror = (error) => {
                console.error('❌ WebSocket error:', error);
                this.startFallbackPolling();
            };

        } catch (error) {
            console.error('❌ WebSocket initialization failed:', error);
            this.startFallbackPolling();
        }
    }

    startFallbackPolling() {
        if (this.fallbackTimer) return;
        
        this.fallbackTimer = setInterval(() => {
            this.updateVisitorCount();
        }, this.config.updateInterval);
    }

    bindEvents() {
        // Track page changes
        this.core.on('page_view', (data) => {
            this.sendPageView(data);
        });

        // Track when user becomes active/inactive
        document.addEventListener('visibilitychange', () => {
            if (document.visibilityState === 'visible') {
                this.sendVisitorInfo();
            } else {
                this.sendVisitorLeave();
            }
        });

        // Send heartbeat every 30 seconds
        setInterval(() => {
            this.sendHeartbeat();
        }, 30000);
    }

    startTracking() {
        // Send initial visitor info
        this.sendVisitorInfo();
        
        // Track current page
        this.trackCurrentPage();
    }

    async updateGeolocation() {
        if (!this.config.geoEnabled) return;

        try {
            // Try to get more accurate location from IP
            const response = await fetch('https://api.ipify.org?format=json');
            const ipData = await response.json();
            
            if (ipData.ip) {
                const geoResponse = await fetch(`http://ip-api.com/json/${ipData.ip}`);
                const geoData = await geoResponse.json();
                
                if (geoData.status === 'success') {
                    this.sendLocationUpdate(geoData);
                }
            }
        } catch (error) {
            if (this.core.config.debug) {
                console.log('📍 Geolocation not available:', error);
            }
        }
    }

    sendVisitorInfo() {
        const visitorInfo = {
            type: 'visitor_join',
            sessionId: this.core.sessionId,
            userId: this.core.userId,
            timestamp: Date.now(),
            page: window.location.pathname,
            title: document.title,
            referrer: document.referrer,
            userAgent: navigator.userAgent,
            language: navigator.language,
            screen: {
                width: screen.width,
                height: screen.height
            },
            viewport: {
                width: window.innerWidth,
                height: window.innerHeight
            }
        };

        this.sendRealtimeMessage(visitorInfo);
        this.core.sendEvent('realtime_visitor_join', visitorInfo);
    }

    sendVisitorLeave() {
        const leaveInfo = {
            type: 'visitor_leave',
            sessionId: this.core.sessionId,
            userId: this.core.userId,
            timestamp: Date.now()
        };

        this.sendRealtimeMessage(leaveInfo);
        this.core.sendEvent('realtime_visitor_leave', leaveInfo);
    }

    sendPageView(data) {
        const pageViewInfo = {
            type: 'page_view',
            sessionId: this.core.sessionId,
            userId: this.core.userId,
            timestamp: Date.now(),
            page: data.page,
            url: data.url
        };

        this.sendRealtimeMessage(pageViewInfo);
    }

    sendHeartbeat() {
        const heartbeat = {
            type: 'heartbeat',
            sessionId: this.core.sessionId,
            userId: this.core.userId,
            timestamp: Date.now(),
            page: window.location.pathname
        };

        this.sendRealtimeMessage(heartbeat);
    }

    sendLocationUpdate(geoData) {
        const locationInfo = {
            type: 'location_update',
            sessionId: this.core.sessionId,
            userId: this.core.userId,
            timestamp: Date.now(),
            location: {
                country: geoData.country,
                region: geoData.regionName,
                city: geoData.city,
                lat: geoData.lat,
                lon: geoData.lon,
                isp: geoData.isp
            }
        };

        this.sendRealtimeMessage(locationInfo);
        this.core.sendEvent('visitor_location', locationInfo);
    }

    sendRealtimeMessage(message) {
        if (this.websocket && this.isConnected) {
            this.websocket.send(JSON.stringify(message));
        }
    }

    handleWebSocketMessage(event) {
        try {
            const data = JSON.parse(event.data);
            
            switch (data.type) {
                case 'visitor_count':
                    this.updateVisitorCountDisplay(data.count);
                    break;
                    
                case 'visitor_list':
                    this.updateVisitorList(data.visitors);
                    break;
                    
                case 'visitor_join':
                    this.handleVisitorJoin(data);
                    break;
                    
                case 'visitor_leave':
                    this.handleVisitorLeave(data);
                    break;
                    
                case 'location_update':
                    this.updateVisitorLocation(data);
                    break;
            }
        } catch (error) {
            console.error('❌ Error handling WebSocket message:', error);
        }
    }

    async updateVisitorCount() {
        try {
            const response = await fetch(`${this.core.config.endpoint}realtime-visitors.php`);
            const data = await response.json();
            
            if (data.status === 'success') {
                this.updateVisitorCountDisplay(data.count);
                this.updateVisitorList(data.visitors);
                this.updateGeographicDistribution(data.locations);
            }
        } catch (error) {
            console.error('❌ Failed to update visitor count:', error);
        }
    }

    updateVisitorCountDisplay(count) {
        this.currentVisitors = count;
        
        // Update any live counter elements
        const counters = document.querySelectorAll('.live-visitor-count');
        counters.forEach(counter => {
            counter.textContent = count.toLocaleString();
            
            // Add pulse animation for changes
            counter.classList.add('pulse');
            setTimeout(() => counter.classList.remove('pulse'), 1000);
        });

        // Update title with visitor count
        const baseTitle = document.title.split(' | ')[0];
        document.title = `${baseTitle} | ${count} online`;
    }

    updateVisitorList(visitors) {
        const listElement = document.getElementById('realtime-visitor-list');
        if (!listElement) return;

        listElement.innerHTML = '';
        
        visitors.forEach(visitor => {
            const visitorElement = document.createElement('div');
            visitorElement.className = 'visitor-item';
            visitorElement.innerHTML = `
                <div class="visitor-info">
                    <div class="visitor-location">${visitor.country || 'Unknown'}</div>
                    <div class="visitor-page">${visitor.page || '/'}</div>
                    <div class="visitor-time">${this.formatTimeAgo(visitor.lastSeen)}</div>
                </div>
                <div class="visitor-status ${visitor.isActive ? 'active' : 'idle'}"></div>
            `;
            listElement.appendChild(visitorElement);
        });
    }

    updateGeographicDistribution(locations) {
        const mapElement = document.getElementById('visitor-map');
        if (!mapElement) return;

        // Simple geographic distribution display
        const distributionElement = document.getElementById('geographic-distribution');
        if (distributionElement) {
            const countryStats = {};
            
            locations.forEach(location => {
                const country = location.country || 'Unknown';
                countryStats[country] = (countryStats[country] || 0) + 1;
            });

            const sortedCountries = Object.entries(countryStats)
                .sort((a, b) => b[1] - a[1])
                .slice(0, 10);

            distributionElement.innerHTML = sortedCountries.map(([country, count]) => `
                <div class="country-stat">
                    <span class="country-name">${country}</span>
                    <span class="country-count">${count}</span>
                    <div class="country-bar" style="width: ${(count / Math.max(...Object.values(countryStats))) * 100}%"></div>
                </div>
            `).join('');
        }
    }

    handleVisitorJoin(data) {
        // Show notification for new visitor
        this.showVisitorNotification(`👤 New visitor from ${data.location?.country || 'Unknown'}`);
    }

    handleVisitorLeave(data) {
        // Optional: Show leave notification
        if (this.core.config.debug) {
            console.log('👋 Visitor left:', data.sessionId);
        }
    }

    updateVisitorLocation(data) {
        this.visitorLocations.set(data.sessionId, data.location);
        this.updateGeographicDistribution(Array.from(this.visitorLocations.values()));
    }

    showVisitorNotification(message) {
        const notificationElement = document.getElementById('visitor-notifications');
        if (!notificationElement) return;

        const notification = document.createElement('div');
        notification.className = 'visitor-notification';
        notification.innerHTML = `
            <span class="notification-message">${message}</span>
            <span class="notification-time">${new Date().toLocaleTimeString()}</span>
        `;

        notificationElement.insertBefore(notification, notificationElement.firstChild);

        // Remove after 5 seconds
        setTimeout(() => {
            notification.remove();
        }, 5000);

        // Keep only last 10 notifications
        while (notificationElement.children.length > 10) {
            notificationElement.removeChild(notificationElement.lastChild);
        }
    }

    trackCurrentPage() {
        // Send current page tracking
        this.core.sendEvent('page_tracking', {
            page: window.location.pathname,
            title: document.title,
            timestamp: Date.now()
        });
    }

    createRealtimeWidget(containerId) {
        const container = document.getElementById(containerId);
        if (!container) return;

        container.innerHTML = `
            <div class="realtime-widget">
                <div class="widget-header">
                    <h3><i class="fas fa-wifi"></i> Live Visitors</h3>
                    <div class="live-indicator"></div>
                </div>
                
                <div class="visitor-counter">
                    <div class="counter-number live-visitor-count">0</div>
                    <div class="counter-label">Active Now</div>
                </div>

                <div class="visitor-details">
                    <div class="detail-section">
                        <h4>Geographic Distribution</h4>
                        <div id="geographic-distribution"></div>
                    </div>

                    <div class="detail-section">
                        <h4>Recent Activity</h4>
                        <div id="visitor-notifications"></div>
                    </div>

                    <div class="detail-section">
                        <h4>Active Visitors</h4>
                        <div id="realtime-visitor-list"></div>
                    </div>
                </div>
            </div>
        `;

        this.updateVisitorCount();
    }

    formatTimeAgo(timestamp) {
        const seconds = Math.floor((Date.now() - timestamp) / 1000);
        
        if (seconds < 60) return `${seconds}s ago`;
        if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
        if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
        return `${Math.floor(seconds / 86400)}d ago`;
    }

    destroy() {
        if (this.websocket) {
            this.websocket.close();
        }
        
        if (this.fallbackTimer) {
            clearInterval(this.fallbackTimer);
        }
    }
}

// Register module
if (typeof window !== 'undefined') {
    window.RealtimeTrackingModule = RealtimeTrackingModule;
}