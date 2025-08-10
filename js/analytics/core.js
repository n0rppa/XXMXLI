/**
 * XXMXLI Advanced Analytics Core Framework
 * Central analytics system with modular feature support
 */

class XXMXLIAnalytics {
    constructor(config = {}) {
        this.config = {
            endpoint: '/api/analytics/',
            debug: false,
            gdprCompliance: true,
            autoStart: true,
            features: {
                userAnalytics: true,
                realtimeTracking: true,
                conversionTracking: true,
                abTesting: true,
                performanceMonitoring: true,
                seoAnalytics: true,
                heatmaps: true,
                customEvents: true
            },
            ...config
        };

        this.modules = {};
        this.sessionId = this.generateSessionId();
        this.userId = this.getUserId();
        this.startTime = performance.now();
        this.isInitialized = false;
        this.gdprConsent = false;

        // Event system
        this.events = {};
        this.eventQueue = [];

        // Data collection
        this.userData = {};
        this.sessionData = {};
        this.performanceData = {};

        this.init();
    }

    async init() {
        try {
            await this.checkGDPRConsent();
            if (!this.gdprConsent && this.config.gdprCompliance) {
                this.showGDPRConsent();
                return;
            }

            await this.initializeModules();
            this.startSession();
            this.bindEvents();
            
            this.isInitialized = true;
            this.emit('initialized');
            
            if (this.config.debug) {
                console.log('🚀 XXMXLI Analytics initialized', this.config);
            }
        } catch (error) {
            console.error('❌ Analytics initialization failed:', error);
        }
    }

    async initializeModules() {
        const modulePromises = [];

        if (this.config.features.userAnalytics) {
            modulePromises.push(this.loadModule('user-analytics'));
        }
        if (this.config.features.realtimeTracking) {
            modulePromises.push(this.loadModule('realtime-tracking'));
        }
        if (this.config.features.conversionTracking) {
            modulePromises.push(this.loadModule('conversion-tracking'));
        }
        if (this.config.features.abTesting) {
            modulePromises.push(this.loadModule('ab-testing'));
        }
        if (this.config.features.performanceMonitoring) {
            modulePromises.push(this.loadModule('performance-monitoring'));
        }
        if (this.config.features.seoAnalytics) {
            modulePromises.push(this.loadModule('seo-analytics'));
        }
        if (this.config.features.heatmaps) {
            modulePromises.push(this.loadModule('heatmaps'));
        }
        if (this.config.features.customEvents) {
            modulePromises.push(this.loadModule('custom-events'));
        }

        await Promise.all(modulePromises);
    }

    async loadModule(moduleName) {
        try {
            const moduleUrl = `/js/analytics/${moduleName}.js`;
            await this.loadScript(moduleUrl);
            
            const moduleClass = window[this.getModuleClassName(moduleName)];
            if (moduleClass) {
                this.modules[moduleName] = new moduleClass(this);
                await this.modules[moduleName].init();
                
                if (this.config.debug) {
                    console.log(`✅ Loaded module: ${moduleName}`);
                }
            }
        } catch (error) {
            console.error(`❌ Failed to load module ${moduleName}:`, error);
        }
    }

    getModuleClassName(moduleName) {
        return moduleName.split('-').map(word => 
            word.charAt(0).toUpperCase() + word.slice(1)
        ).join('') + 'Module';
    }

    async loadScript(url) {
        return new Promise((resolve, reject) => {
            if (document.querySelector(`script[src="${url}"]`)) {
                resolve();
                return;
            }

            const script = document.createElement('script');
            script.src = url;
            script.onload = resolve;
            script.onerror = reject;
            document.head.appendChild(script);
        });
    }

    // Event system
    on(event, callback) {
        if (!this.events[event]) {
            this.events[event] = [];
        }
        this.events[event].push(callback);
    }

    emit(event, data = null) {
        if (this.events[event]) {
            this.events[event].forEach(callback => callback(data));
        }
    }

    // Session management
    generateSessionId() {
        return `xxmxli_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    getUserId() {
        let userId = localStorage.getItem('xxmxli_user_id');
        if (!userId) {
            userId = `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            localStorage.setItem('xxmxli_user_id', userId);
        }
        return userId;
    }

    startSession() {
        this.sessionData = {
            sessionId: this.sessionId,
            userId: this.userId,
            startTime: new Date().toISOString(),
            userAgent: navigator.userAgent,
            url: window.location.href,
            referrer: document.referrer,
            language: navigator.language,
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            screen: {
                width: screen.width,
                height: screen.height,
                colorDepth: screen.colorDepth
            },
            viewport: {
                width: window.innerWidth,
                height: window.innerHeight
            }
        };

        this.sendEvent('session_start', this.sessionData);
    }

    // Data collection and sending
    async sendEvent(eventType, data) {
        if (!this.gdprConsent && this.config.gdprCompliance) {
            this.eventQueue.push({ eventType, data, timestamp: Date.now() });
            return;
        }

        try {
            const eventData = {
                eventType,
                sessionId: this.sessionId,
                userId: this.userId,
                timestamp: new Date().toISOString(),
                url: window.location.href,
                data: data
            };

            const response = await fetch(`${this.config.endpoint}event-collector.php`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(eventData)
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            if (this.config.debug) {
                console.log('📊 Event sent:', eventType, data);
            }
        } catch (error) {
            console.error('❌ Failed to send event:', error);
        }
    }

    // GDPR Compliance
    async checkGDPRConsent() {
        const consent = localStorage.getItem('xxmxli_gdpr_consent');
        this.gdprConsent = consent === 'true';
        return this.gdprConsent;
    }

    showGDPRConsent() {
        if (document.getElementById('xxmxli-gdpr-banner')) {
            return; // Already showing
        }

        const banner = document.createElement('div');
        banner.id = 'xxmxli-gdpr-banner';
        banner.innerHTML = `
            <div class="gdpr-banner">
                <div class="gdpr-content">
                    <h3>🍪 Privacy & Analytics</h3>
                    <p>We use analytics to improve your experience. Your data is anonymized and GDPR compliant.</p>
                    <div class="gdpr-buttons">
                        <button id="gdpr-accept" class="btn-accept">Accept All</button>
                        <button id="gdpr-essential" class="btn-essential">Essential Only</button>
                        <button id="gdpr-customize" class="btn-customize">Customize</button>
                    </div>
                </div>
            </div>
        `;

        // Add cyberpunk styling
        const style = document.createElement('style');
        style.textContent = `
            .gdpr-banner {
                position: fixed;
                bottom: 0;
                left: 0;
                right: 0;
                background: rgba(0, 17, 0, 0.95);
                border-top: 2px solid #00ff00;
                color: #00ff00;
                font-family: 'Courier New', monospace;
                padding: 20px;
                z-index: 10000;
                box-shadow: 0 -5px 20px rgba(0, 255, 0, 0.3);
            }
            .gdpr-content h3 {
                margin: 0 0 10px 0;
                color: #00ff00;
            }
            .gdpr-content p {
                margin: 0 0 15px 0;
                color: #cccccc;
            }
            .gdpr-buttons {
                display: flex;
                gap: 10px;
                flex-wrap: wrap;
            }
            .gdpr-buttons button {
                background: transparent;
                border: 1px solid #00ff00;
                color: #00ff00;
                padding: 8px 16px;
                cursor: pointer;
                font-family: 'Courier New', monospace;
                transition: all 0.3s ease;
            }
            .gdpr-buttons button:hover {
                background: #00ff00;
                color: #000000;
                box-shadow: 0 0 10px #00ff00;
            }
            .btn-accept {
                background: #00ff00 !important;
                color: #000000 !important;
            }
        `;
        document.head.appendChild(style);
        document.body.appendChild(banner);

        // Event handlers
        document.getElementById('gdpr-accept').onclick = () => this.handleGDPRConsent(true);
        document.getElementById('gdpr-essential').onclick = () => this.handleGDPRConsent(false);
        document.getElementById('gdpr-customize').onclick = () => this.showGDPRCustomization();
    }

    handleGDPRConsent(fullConsent) {
        this.gdprConsent = fullConsent;
        localStorage.setItem('xxmxli_gdpr_consent', fullConsent.toString());
        localStorage.setItem('xxmxli_gdpr_timestamp', new Date().toISOString());

        // Remove banner
        const banner = document.getElementById('xxmxli-gdpr-banner');
        if (banner) {
            banner.remove();
        }

        if (fullConsent) {
            // Process queued events
            this.eventQueue.forEach(event => {
                this.sendEvent(event.eventType, event.data);
            });
            this.eventQueue = [];

            // Initialize analytics if not already done
            if (!this.isInitialized) {
                this.init();
            }
        }

        this.emit('gdpr_consent', { consent: fullConsent });
    }

    showGDPRCustomization() {
        // TODO: Implement detailed GDPR customization modal
        console.log('GDPR customization modal - to be implemented');
    }

    // Utility methods
    bindEvents() {
        // Page visibility change
        document.addEventListener('visibilitychange', () => {
            if (document.visibilityState === 'hidden') {
                this.sendEvent('page_blur', { timestamp: Date.now() });
            } else {
                this.sendEvent('page_focus', { timestamp: Date.now() });
            }
        });

        // Page unload
        window.addEventListener('beforeunload', () => {
            const sessionDuration = performance.now() - this.startTime;
            this.sendEvent('session_end', { 
                duration: sessionDuration,
                timestamp: Date.now()
            });
        });

        // Error tracking
        window.addEventListener('error', (event) => {
            this.sendEvent('error', {
                message: event.message,
                filename: event.filename,
                lineno: event.lineno,
                colno: event.colno,
                stack: event.error ? event.error.stack : null
            });
        });
    }

    // Public API methods
    track(eventType, data = {}) {
        this.sendEvent(eventType, data);
    }

    identify(userId, properties = {}) {
        this.userId = userId;
        localStorage.setItem('xxmxli_user_id', userId);
        this.sendEvent('user_identify', { userId, properties });
    }

    page(pageName = null, properties = {}) {
        const pageData = {
            page: pageName || document.title,
            url: window.location.href,
            referrer: document.referrer,
            ...properties
        };
        this.sendEvent('page_view', pageData);
    }

    getModule(moduleName) {
        return this.modules[moduleName];
    }

    // Debug methods
    getDebugInfo() {
        return {
            config: this.config,
            modules: Object.keys(this.modules),
            sessionId: this.sessionId,
            userId: this.userId,
            gdprConsent: this.gdprConsent,
            isInitialized: this.isInitialized
        };
    }
}

// Auto-initialize if not manually configured
if (typeof window !== 'undefined') {
    window.XXMXLIAnalytics = XXMXLIAnalytics;
    
    // Auto-start unless disabled
    if (!window.xxmxliAnalyticsManual) {
        window.xxmxliAnalytics = new XXMXLIAnalytics(window.xxmxliAnalyticsConfig || {});
    }
}