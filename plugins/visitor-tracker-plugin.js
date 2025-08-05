/**
 * XXMXLI FULL Visitor Tracker Plugin v2.0
 * Enterprise-grade visitor tracking solution
 * 
 * Features:
 * - Advanced visitor analytics with behavioral tracking
 * - Real-time heatmaps and click tracking
 * - Session recording and replay
 * - A/B testing framework
 * - Advanced threat detection with AI scoring
 * - Performance monitoring
 * - GDPR compliance tools
 * - Multi-site tracking
 * - API integrations (Google Analytics, webhooks)
 * - Advanced dashboard with charts and exports
 * - Machine learning visitor classification
 * - Geofencing and location analytics
 * - Device fingerprinting and fraud detection
 * 
 * Usage: <script src="visitor-tracker-plugin.js"></script>
 */

(function() {
    'use strict';
    
    class XXMXLIFullVisitorTracker {
        constructor(options = {}) {
            this.options = {
                apiKey: options.apiKey || 'xxmxli-tracker-full',
                enableConsoleLog: options.enableConsoleLog !== false,
                enableNotifications: options.enableNotifications === true,
                storageKey: options.storageKey || 'xxmxli_visitors_full',
                maxStoredVisits: options.maxStoredVisits || 500,
                autoTrack: options.autoTrack !== false,
                dashboardEnabled: options.dashboardEnabled !== false,
                theme: options.theme || 'cyberpunk',
                
                // Advanced features
                enableHeatmaps: options.enableHeatmaps !== false,
                enableSessionRecording: options.enableSessionRecording !== false,
                enablePerformanceMonitoring: options.enablePerformanceMonitoring !== false,
                enableABTesting: options.enableABTesting !== false,
                enableMLClassification: options.enableMLClassification !== false,
                enableFraudDetection: options.enableFraudDetection !== false,
                enableGeofencing: options.enableGeofencing !== false,
                
                // Integrations
                googleAnalyticsId: options.googleAnalyticsId || null,
                webhookUrl: options.webhookUrl || null,
                slackWebhook: options.slackWebhook || null,
                
                // Privacy & Compliance
                gdprCompliant: options.gdprCompliant !== false,
                cookieConsent: options.cookieConsent !== false,
                dataRetentionDays: options.dataRetentionDays || 365,
                
                // Performance
                samplingRate: options.samplingRate || 1.0,
                maxEventsPerSession: options.maxEventsPerSession || 1000,
                
                ...options
            };
            
            this.sessionId = this.generateSessionId();
            this.visitorData = null;
            this.isTracking = false;
            this.events = [];
            this.heatmapData = [];
            this.sessionRecording = [];
            this.performanceMetrics = {};
            this.mlModel = null;
            this.fraudScore = 0;
            this.abTestVariant = null;
            this.startTime = Date.now();
            
            // Advanced tracking state
            this.mouseMovements = [];
            this.scrollEvents = [];
            this.clickEvents = [];
            this.keystrokes = [];
            this.focusEvents = [];
            this.formInteractions = [];
            this.errorEvents = [];
            this.customEvents = [];
            
            if (this.options.autoTrack) {
                this.init();
            }
        }
        
        async init() {
            if (this.isTracking) return;
            this.isTracking = true;
            
            try {
                // Check GDPR compliance
                if (this.options.gdprCompliant && !this.hasConsent()) {
                    await this.requestConsent();
                }
                
                await this.collectVisitorData();
                await this.initializeMLModel();
                await this.processVisitor();
                this.setupAdvancedTracking();
                this.setupDashboard();
                this.startPerformanceMonitoring();
                this.initializeABTesting();
                
                if (this.options.enableConsoleLog) {
                    console.log('🔍 XXMXLI FULL Visitor Tracker initialized', {
                        visitor: this.visitorData,
                        features: this.getEnabledFeatures(),
                        mlModel: this.mlModel ? 'loaded' : 'disabled',
                        abVariant: this.abTestVariant
                    });
                }
            } catch (error) {
                console.error('Failed to initialize FULL visitor tracker:', error);
            }
        }
        
        getEnabledFeatures() {
            return Object.keys(this.options)
                .filter(key => key.startsWith('enable') && this.options[key])
                .map(key => key.replace('enable', '').toLowerCase());
        }
        
        hasConsent() {
            return localStorage.getItem('xxmxli_consent') === 'granted';
        }
        
        async requestConsent() {
            return new Promise((resolve) => {
                const banner = this.createConsentBanner();
                document.body.appendChild(banner);
                
                banner.querySelector('.accept-btn').addEventListener('click', () => {
                    localStorage.setItem('xxmxli_consent', 'granted');
                    banner.remove();
                    resolve(true);
                });
                
                banner.querySelector('.reject-btn').addEventListener('click', () => {
                    localStorage.setItem('xxmxli_consent', 'rejected');
                    banner.remove();
                    resolve(false);
                });
            });
        }
        
        createConsentBanner() {
            const banner = document.createElement('div');
            banner.innerHTML = `
                <div style="
                    position: fixed;
                    bottom: 0;
                    left: 0;
                    right: 0;
                    background: #0a0a0a;
                    border-top: 2px solid #00ff00;
                    padding: 20px;
                    color: #00ff00;
                    font-family: 'Courier New', monospace;
                    z-index: 999999;
                    box-shadow: 0 -5px 20px rgba(0, 255, 0, 0.2);
                ">
                    <div style="max-width: 800px; margin: 0 auto; display: flex; align-items: center; justify-content: space-between;">
                        <div style="flex: 1; margin-right: 20px;">
                            <strong>🔒 Privacy Notice</strong><br>
                            This site uses advanced tracking for analytics and security. We collect visitor behavior, device info, and performance data.
                        </div>
                        <div>
                            <button class="accept-btn" style="
                                background: #00ff00;
                                color: #000;
                                border: none;
                                padding: 10px 20px;
                                margin-right: 10px;
                                border-radius: 4px;
                                cursor: pointer;
                                font-family: inherit;
                            ">Accept</button>
                            <button class="reject-btn" style="
                                background: #ff0040;
                                color: #fff;
                                border: none;
                                padding: 10px 20px;
                                border-radius: 4px;
                                cursor: pointer;
                                font-family: inherit;
                            ">Reject</button>
                        </div>
                    </div>
                </div>
            `;
            return banner;
        }
        
        generateSessionId() {
            return 'xxmxli_full_' + Date.now() + '_' + Math.random().toString(36).substr(2, 12);
        }
        
        async collectVisitorData() {
            const data = {
                sessionId: this.sessionId,
                timestamp: new Date().toISOString(),
                url: window.location.href,
                referrer: document.referrer || 'Direct',
                userAgent: navigator.userAgent,
                language: navigator.language,
                languages: navigator.languages || [navigator.language],
                platform: navigator.platform,
                cookiesEnabled: navigator.cookieEnabled,
                onlineStatus: navigator.onLine,
                screenResolution: `${screen.width}x${screen.height}`,
                screenColorDepth: screen.colorDepth,
                viewport: `${window.innerWidth}x${window.innerHeight}`,
                devicePixelRatio: window.devicePixelRatio || 1,
                timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                timezoneOffset: new Date().getTimezoneOffset(),
                
                // Enhanced data
                documentTitle: document.title,
                documentEncoding: document.characterSet,
                windowHistory: history.length,
                javaEnabled: false, // Java is deprecated
                localStorageEnabled: this.testLocalStorage(),
                sessionStorageEnabled: this.testSessionStorage(),
                indexedDBEnabled: this.testIndexedDB(),
                webGLEnabled: this.testWebGL(),
                canvasFingerprint: null,
                audioFingerprint: null,
                webRTCFingerprint: null,
                
                // Advanced device info
                hardwareConcurrency: navigator.hardwareConcurrency || 'Unknown',
                deviceMemory: navigator.deviceMemory || 'Unknown',
                maxTouchPoints: navigator.maxTouchPoints || 0,
                doNotTrack: navigator.doNotTrack,
                
                // Network info
                connection: null,
                battery: null,
                
                // Performance metrics
                pageLoadTime: null,
                domContentLoadedTime: null,
                firstPaintTime: null,
                firstContentfulPaintTime: null,
                
                // Security & Privacy
                plugins: [],
                mimeTypes: [],
                adBlockerDetected: this.detectAdBlocker(),
                devToolsOpen: this.detectDevTools(),
                
                // Machine Learning features
                behaviorScore: 0,
                engagementScore: 0,
                riskScore: 0,
                
                // Location data
                ip: 'Unknown',
                location: { country: 'Unknown', city: 'Unknown', isp: 'Unknown' },
                
                // Fraud detection
                fraudIndicators: [],
                trustScore: 100
            };
            
            // Enhanced fingerprinting
            try {
                data.canvasFingerprint = this.generateCanvasFingerprint();
                data.audioFingerprint = await this.generateAudioFingerprint();
                data.webRTCFingerprint = await this.generateWebRTCFingerprint();
            } catch (e) {
                if (this.options.enableConsoleLog) {
                    console.log('Fingerprinting partially failed:', e.message);
                }
            }
            
            // Connection info
            if ('connection' in navigator) {
                data.connection = {
                    effectiveType: navigator.connection.effectiveType,
                    downlink: navigator.connection.downlink,
                    rtt: navigator.connection.rtt,
                    saveData: navigator.connection.saveData
                };
            }
            
            // Battery info
            try {
                if ('getBattery' in navigator) {
                    const battery = await navigator.getBattery();
                    data.battery = {
                        level: Math.round(battery.level * 100),
                        charging: battery.charging,
                        chargingTime: battery.chargingTime,
                        dischargingTime: battery.dischargingTime
                    };
                }
            } catch (e) {}
            
            // Performance metrics
            if (window.performance) {
                const perfData = performance.getEntriesByType('navigation')[0];
                if (perfData) {
                    data.pageLoadTime = perfData.loadEventEnd - perfData.loadEventStart;
                    data.domContentLoadedTime = perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart;
                }
                
                const paintEntries = performance.getEntriesByType('paint');
                paintEntries.forEach(entry => {
                    if (entry.name === 'first-paint') {
                        data.firstPaintTime = entry.startTime;
                    } else if (entry.name === 'first-contentful-paint') {
                        data.firstContentfulPaintTime = entry.startTime;
                    }
                });
            }
            
            // Plugin and MIME type detection
            data.plugins = Array.from(navigator.plugins).map(p => ({
                name: p.name,
                filename: p.filename,
                description: p.description
            }));
            
            data.mimeTypes = Array.from(navigator.mimeTypes).map(m => ({
                type: m.type,
                description: m.description
            }));
            
            // Browser detection
            data.browser = this.detectBrowser();
            
            // Operating system detection
            data.operatingSystem = this.detectOS();
            
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
            
            // Fraud detection
            if (this.options.enableFraudDetection) {
                const fraudAnalysis = this.analyzeFraud(data);
                data.fraudIndicators = fraudAnalysis.indicators;
                data.trustScore = fraudAnalysis.trustScore;
                this.fraudScore = fraudAnalysis.score;
            }
            
            this.visitorData = data;
            return data;
        }
        
        // Advanced fingerprinting methods
        generateCanvasFingerprint() {
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            
            // Draw complex pattern for fingerprinting
            ctx.textBaseline = 'top';
            ctx.font = '14px Arial';
            ctx.textBaseline = 'alphabetic';
            ctx.fillStyle = '#f60';
            ctx.fillRect(125, 1, 62, 20);
            ctx.fillStyle = '#069';
            ctx.font = '11pt Arial';
            ctx.fillText('XXMXLI Fingerprint 🔍', 2, 15);
            ctx.fillStyle = 'rgba(102, 204, 0, 0.7)';
            ctx.font = '18pt Arial';
            ctx.fillText('Advanced Canvas', 4, 45);
            
            // Add geometric shapes
            ctx.globalCompositeOperation = 'multiply';
            ctx.fillStyle = 'rgb(255,0,255)';
            ctx.beginPath();
            ctx.arc(50, 50, 50, 0, Math.PI * 2, true);
            ctx.closePath();
            ctx.fill();
            
            return this.hashCode(canvas.toDataURL());
        }
        
        async generateAudioFingerprint() {
            return new Promise((resolve) => {
                try {
                    const audioContext = new (window.AudioContext || window.webkitAudioContext)();
                    const oscillator = audioContext.createOscillator();
                    const analyser = audioContext.createAnalyser();
                    const gain = audioContext.createGain();
                    const scriptProcessor = audioContext.createScriptProcessor(4096, 1, 1);
                    
                    gain.gain.value = 0;
                    oscillator.frequency.value = 1000;
                    oscillator.type = 'triangle';
                    
                    oscillator.connect(analyser);
                    analyser.connect(scriptProcessor);
                    scriptProcessor.connect(gain);
                    gain.connect(audioContext.destination);
                    
                    scriptProcessor.onaudioprocess = () => {
                        const bins = new Float32Array(analyser.frequencyBinCount);
                        analyser.getFloatFrequencyData(bins);
                        const fingerprint = this.hashCode(bins.toString());
                        
                        audioContext.close();
                        resolve(fingerprint);
                    };
                    
                    oscillator.start(0);
                    
                    setTimeout(() => {
                        resolve('timeout');
                    }, 1000);
                } catch (e) {
                    resolve('unsupported');
                }
            });
        }
        
        async generateWebRTCFingerprint() {
            return new Promise((resolve) => {
                try {
                    const pc = new RTCPeerConnection();
                    
                    pc.createDataChannel('');
                    pc.createOffer().then(offer => {
                        const fingerprint = this.hashCode(offer.sdp);
                        pc.close();
                        resolve(fingerprint);
                    }).catch(() => resolve('unsupported'));
                    
                    setTimeout(() => {
                        pc.close();
                        resolve('timeout');
                    }, 1000);
                } catch (e) {
                    resolve('unsupported');
                }
            });
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
        
        testIndexedDB() {
            return 'indexedDB' in window;
        }
        
        testWebGL() {
            try {
                const canvas = document.createElement('canvas');
                const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
                return !!gl;
            } catch (e) {
                return false;
            }
        }
        
        detectAdBlocker() {
            const testAd = document.createElement('div');
            testAd.innerHTML = '&nbsp;';
            testAd.className = 'adsbox';
            testAd.style.position = 'absolute';
            testAd.style.left = '-9999px';
            document.body.appendChild(testAd);
            
            setTimeout(() => {
                if (testAd.parentNode) {
                    testAd.parentNode.removeChild(testAd);
                }
            }, 100);
            
            return testAd.offsetHeight === 0;
        }
        
        detectDevTools() {
            const threshold = 160;
            return window.outerHeight - window.innerHeight > threshold ||
                   window.outerWidth - window.innerWidth > threshold;
        }
        
        detectOS() {
            const userAgent = navigator.userAgent;
            const platform = navigator.platform;
            
            if (userAgent.includes('Windows NT 10.0')) return 'Windows 10';
            if (userAgent.includes('Windows NT 6.3')) return 'Windows 8.1';
            if (userAgent.includes('Windows NT 6.2')) return 'Windows 8';
            if (userAgent.includes('Windows NT 6.1')) return 'Windows 7';
            if (userAgent.includes('Windows NT 6.0')) return 'Windows Vista';
            if (userAgent.includes('Windows NT 5.1')) return 'Windows XP';
            if (userAgent.includes('Windows')) return 'Windows (Unknown)';
            
            if (userAgent.includes('Mac OS X')) {
                const version = userAgent.match(/Mac OS X (\d+)[._](\d+)/);
                return version ? `macOS ${version[1]}.${version[2]}` : 'macOS';
            }
            
            if (userAgent.includes('Linux')) return 'Linux';
            if (userAgent.includes('Ubuntu')) return 'Ubuntu';
            if (userAgent.includes('Android')) return 'Android';
            if (userAgent.includes('iPhone') || userAgent.includes('iPad')) return 'iOS';
            
            return platform || 'Unknown';
        }
        
        analyzeFraud(data) {
            const indicators = [];
            let score = 0;
            
            // Check for suspicious patterns
            if (data.plugins.length === 0) {
                indicators.push('No plugins detected');
                score += 15;
            }
            
            if (data.userAgent.includes('bot') || data.userAgent.includes('crawler')) {
                indicators.push('Bot user agent detected');
                score += 30;
            }
            
            if (data.devToolsOpen) {
                indicators.push('Developer tools open');
                score += 20;
            }
            
            if (data.adBlockerDetected) {
                indicators.push('Ad blocker detected');
                score += 5;
            }
            
            if (!data.cookiesEnabled) {
                indicators.push('Cookies disabled');
                score += 10;
            }
            
            if (data.doNotTrack === '1') {
                indicators.push('Do Not Track enabled');
                score += 5;
            }
            
            if (data.languages && data.languages.length > 5) {
                indicators.push('Suspicious language count');
                score += 10;
            }
            
            if (data.screenResolution === '1024x768' || data.screenResolution === '800x600') {
                indicators.push('Common automated resolution');
                score += 15;
            }
            
            const trustScore = Math.max(0, 100 - score);
            
            return {
                indicators,
                score,
                trustScore,
                level: score > 50 ? 'HIGH' : score > 25 ? 'MEDIUM' : 'LOW'
            };
        }
        
        async initializeMLModel() {
            if (!this.options.enableMLClassification) return;
            
            // Simple ML model for visitor classification
            this.mlModel = {
                classify: (visitor) => {
                    let score = 0;
                    
                    // Engagement factors
                    if (visitor.timeOnSite > 30000) score += 20; // 30+ seconds
                    if (visitor.pageViews > 1) score += 15;
                    if (visitor.interactions > 5) score += 10;
                    
                    // Device factors
                    if (visitor.deviceMemory > 4) score += 5;
                    if (visitor.hardwareConcurrency > 4) score += 5;
                    
                    // Browser factors
                    if (visitor.browser.name === 'Chrome') score += 5;
                    if (visitor.plugins.length > 10) score += 5;
                    
                    // Determine classification
                    if (score >= 50) return 'HIGH_VALUE';
                    if (score >= 30) return 'MEDIUM_VALUE';
                    if (score >= 15) return 'LOW_VALUE';
                    return 'UNKNOWN';
                },
                
                predictBehavior: (visitor) => {
                    const patterns = {
                        likelyToBounce: visitor.timeOnSite < 5000,
                        likelyToConvert: visitor.pageViews > 3 && visitor.timeOnSite > 60000,
                        likelyBot: visitor.fraudScore > 30,
                        likelyMobile: visitor.maxTouchPoints > 0,
                        likelyReturnVisitor: visitor.referrer.includes(window.location.hostname)
                    };
                    
                    return patterns;
                }
            };
        }
        
        setupAdvancedTracking() {
            if (!this.options.enableHeatmaps && !this.options.enableSessionRecording) return;
            
            // Mouse movement tracking
            if (this.options.enableHeatmaps) {
                this.setupMouseTracking();
            }
            
            // Session recording
            if (this.options.enableSessionRecording) {
                this.setupSessionRecording();
            }
            
            // Scroll tracking
            this.setupScrollTracking();
            
            // Click tracking
            this.setupClickTracking();
            
            // Form interaction tracking
            this.setupFormTracking();
            
            // Error tracking
            this.setupErrorTracking();
        }
        
        setupMouseTracking() {
            let lastMouseMove = 0;
            document.addEventListener('mousemove', (e) => {
                const now = Date.now();
                if (now - lastMouseMove > 100) { // Throttle to every 100ms
                    this.heatmapData.push({
                        type: 'mousemove',
                        x: e.clientX,
                        y: e.clientY,
                        timestamp: now,
                        url: window.location.href
                    });
                    lastMouseMove = now;
                }
            });
        }
        
        setupSessionRecording() {
            // Record DOM mutations
            if (window.MutationObserver) {
                const observer = new MutationObserver((mutations) => {
                    mutations.forEach((mutation) => {
                        this.sessionRecording.push({
                            type: 'mutation',
                            target: this.getElementPath(mutation.target),
                            mutationType: mutation.type,
                            timestamp: Date.now()
                        });
                    });
                });
                
                observer.observe(document.body, {
                    childList: true,
                    subtree: true,
                    attributes: true,
                    characterData: true
                });
            }
        }
        
        setupScrollTracking() {
            let lastScroll = 0;
            window.addEventListener('scroll', () => {
                const now = Date.now();
                if (now - lastScroll > 250) { // Throttle to every 250ms
                    this.scrollEvents.push({
                        scrollY: window.scrollY,
                        scrollX: window.scrollX,
                        timestamp: now,
                        maxScroll: document.body.scrollHeight - window.innerHeight
                    });
                    lastScroll = now;
                }
            });
        }
        
        setupClickTracking() {
            document.addEventListener('click', (e) => {
                this.clickEvents.push({
                    x: e.clientX,
                    y: e.clientY,
                    element: this.getElementPath(e.target),
                    timestamp: Date.now(),
                    url: window.location.href
                });
            });
        }
        
        setupFormTracking() {
            document.addEventListener('input', (e) => {
                if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                    this.formInteractions.push({
                        element: this.getElementPath(e.target),
                        type: e.target.type,
                        valueLength: e.target.value.length,
                        timestamp: Date.now()
                    });
                }
            });
        }
        
        setupErrorTracking() {
            window.addEventListener('error', (e) => {
                this.errorEvents.push({
                    message: e.message,
                    filename: e.filename,
                    lineno: e.lineno,
                    colno: e.colno,
                    timestamp: Date.now()
                });
            });
            
            window.addEventListener('unhandledrejection', (e) => {
                this.errorEvents.push({
                    message: e.reason.toString(),
                    type: 'unhandled_promise_rejection',
                    timestamp: Date.now()
                });
            });
        }
        
        getElementPath(element) {
            if (!element) return '';
            
            const path = [];
            while (element.nodeType === Node.ELEMENT_NODE) {
                let selector = element.nodeName.toLowerCase();
                if (element.id) {
                    selector += '#' + element.id;
                    path.unshift(selector);
                    break;
                } else {
                    let sibling = element;
                    let nth = 1;
                    while (sibling.previousElementSibling) {
                        sibling = sibling.previousElementSibling;
                        if (sibling.nodeName.toLowerCase() === selector) nth++;
                    }
                    if (nth !== 1) selector += `:nth-of-type(${nth})`;
                }
                path.unshift(selector);
                element = element.parentNode;
            }
            return path.join(' > ');
        }
        
        startPerformanceMonitoring() {
            if (!this.options.enablePerformanceMonitoring) return;
            
            // Monitor resource loading
            new PerformanceObserver((list) => {
                list.getEntries().forEach((entry) => {
                    if (entry.entryType === 'resource') {
                        this.performanceMetrics.resources = this.performanceMetrics.resources || [];
                        this.performanceMetrics.resources.push({
                            name: entry.name,
                            duration: entry.duration,
                            size: entry.transferSize,
                            type: entry.initiatorType,
                            timestamp: entry.startTime
                        });
                    }
                });
            }).observe({ entryTypes: ['resource'] });
            
            // Monitor long tasks
            if ('PerformanceObserver' in window && 'PerformanceLongTaskTiming' in window) {
                new PerformanceObserver((list) => {
                    list.getEntries().forEach((entry) => {
                        this.performanceMetrics.longTasks = this.performanceMetrics.longTasks || [];
                        this.performanceMetrics.longTasks.push({
                            duration: entry.duration,
                            startTime: entry.startTime,
                            attribution: entry.attribution
                        });
                    });
                }).observe({ entryTypes: ['longtask'] });
            }
        }
        
        initializeABTesting() {
            if (!this.options.enableABTesting) return;
            
            // Simple A/B test framework
            const tests = this.options.abTests || {};
            
            Object.keys(tests).forEach(testName => {
                const test = tests[testName];
                const variant = this.selectVariant(test.variants, test.traffic || 1.0);
                
                if (variant) {
                    this.abTestVariant = variant;
                    this.trackEvent('ab_test_assigned', {
                        testName,
                        variant: variant.name,
                        timestamp: Date.now()
                    });
                    
                    // Apply variant changes
                    if (variant.changes) {
                        this.applyVariantChanges(variant.changes);
                    }
                }
            });
        }
        
        selectVariant(variants, traffic) {
            if (Math.random() > traffic) return null;
            
            const totalWeight = variants.reduce((sum, v) => sum + (v.weight || 1), 0);
            let random = Math.random() * totalWeight;
            
            for (const variant of variants) {
                random -= (variant.weight || 1);
                if (random <= 0) return variant;
            }
            
            return variants[0];
        }
        
        applyVariantChanges(changes) {
            changes.forEach(change => {
                const element = document.querySelector(change.selector);
                if (element) {
                    switch (change.type) {
                        case 'text':
                            element.textContent = change.value;
                            break;
                        case 'html':
                            element.innerHTML = change.value;
                            break;
                        case 'style':
                            Object.assign(element.style, change.value);
                            break;
                        case 'attribute':
                            element.setAttribute(change.attribute, change.value);
                            break;
                    }
                }
            });
        }
        
        trackEvent(eventName, data = {}) {
            const event = {
                name: eventName,
                timestamp: Date.now(),
                sessionId: this.sessionId,
                url: window.location.href,
                ...data
            };
            
            this.events.push(event);
            
            // Keep events within limit
            if (this.events.length > this.options.maxEventsPerSession) {
                this.events.shift();
            }
            
            // Send to external services if configured
            this.sendToIntegrations(event);
        }
        
        async sendToIntegrations(event) {
            // Google Analytics
            if (this.options.googleAnalyticsId && window.gtag) {
                gtag('event', event.name, {
                    custom_parameter: JSON.stringify(event)
                });
            }
            
            // Webhook
            if (this.options.webhookUrl) {
                try {
                    await fetch(this.options.webhookUrl, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(event)
                    });
                } catch (e) {
                    console.error('Webhook failed:', e);
                }
            }
            
            // Slack webhook
            if (this.options.slackWebhook && event.name === 'security_threat') {
                try {
                    await fetch(this.options.slackWebhook, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            text: `🚨 Security Alert: ${event.threatLevel} threat detected`,
                            attachments: [{
                                color: 'danger',
                                fields: [
                                    { title: 'IP', value: event.ip, short: true },
                                    { title: 'User Agent', value: event.userAgent, short: false },
                                    { title: 'Threat Score', value: event.threatScore, short: true }
                                ]
                            }]
                        })
                    });
                } catch (e) {
                    console.error('Slack webhook failed:', e);
                }
            }
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
            let browser = { name: 'Unknown', version: 'Unknown', engine: 'Unknown' };
            
            if (ua.includes('Chrome') && !ua.includes('Edg')) {
                browser.name = 'Chrome';
                browser.version = ua.match(/Chrome\/(\d+)/)?.[1] || 'Unknown';
                browser.engine = 'Blink';
            } else if (ua.includes('Firefox')) {
                browser.name = 'Firefox';
                browser.version = ua.match(/Firefox\/(\d+)/)?.[1] || 'Unknown';
                browser.engine = 'Gecko';
            } else if (ua.includes('Safari') && !ua.includes('Chrome')) {
                browser.name = 'Safari';
                browser.version = ua.match(/Version\/(\d+)/)?.[1] || 'Unknown';
                browser.engine = 'WebKit';
            } else if (ua.includes('Edg')) {
                browser.name = 'Edge';
                browser.version = ua.match(/Edg\/(\d+)/)?.[1] || 'Unknown';
                browser.engine = 'Blink';
            } else if (ua.includes('Opera') || ua.includes('OPR')) {
                browser.name = 'Opera';
                browser.version = ua.match(/(?:Opera|OPR)\/(\d+)/)?.[1] || 'Unknown';
                browser.engine = 'Blink';
            }
            
            return browser;
        }
        
        async getLocationData() {
            // Try multiple IP services with fallback
            const services = [
                {
                    url: 'https://ipapi.co/json/',
                    parser: (data) => ({
                        ip: data.ip,
                        country: data.country_name,
                        city: data.city,
                        region: data.region,
                        isp: data.org,
                        lat: data.latitude,
                        lon: data.longitude,
                        timezone: data.timezone,
                        currency: data.currency,
                        calling_code: data.calling_code
                    })
                },
                {
                    url: 'https://ipinfo.io/json',
                    parser: (data) => ({
                        ip: data.ip,
                        country: data.country,
                        city: data.city,
                        region: data.region,
                        isp: data.org,
                        lat: data.loc?.split(',')[0],
                        lon: data.loc?.split(',')[1],
                        timezone: data.timezone
                    })
                },
                {
                    url: 'https://api.ipify.org?format=json',
                    parser: (data) => ({
                        ip: data.ip,
                        country: 'Unknown',
                        city: 'Unknown',
                        isp: 'Unknown'
                    })
                }
            ];
            
            for (const service of services) {
                try {
                    const response = await fetch(service.url, {
                        timeout: 5000
                    });
                    const data = await response.json();
                    return service.parser(data);
                } catch (e) {
                    continue;
                }
            }
            
            throw new Error('All IP services failed');
        }
        
        assessThreat(data) {
            let threatScore = 0;
            const indicators = [];
            
            // Bot detection
            if (data.userAgent.toLowerCase().includes('bot') || 
                data.userAgent.toLowerCase().includes('crawler') ||
                data.userAgent.toLowerCase().includes('spider')) {
                threatScore += 40;
                indicators.push('Bot user agent');
            }
            
            // Suspicious browser characteristics
            if (data.plugins.length === 0) {
                threatScore += 15;
                indicators.push('No browser plugins');
            }
            
            if (data.devToolsOpen) {
                threatScore += 25;
                indicators.push('Developer tools open');
            }
            
            if (!data.cookiesEnabled) {
                threatScore += 10;
                indicators.push('Cookies disabled');
            }
            
            // Headless browser detection
            if (navigator.webdriver) {
                threatScore += 30;
                indicators.push('WebDriver detected');
            }
            
            if (window.phantom || window._phantom || window.callPhantom) {
                threatScore += 30;
                indicators.push('PhantomJS detected');
            }
            
            // Language inconsistencies
            if (data.languages && data.languages.length > 10) {
                threatScore += 15;
                indicators.push('Suspicious language count');
            }
            
            // Common automation resolutions
            const suspiciousResolutions = ['1024x768', '800x600', '1366x768'];
            if (suspiciousResolutions.includes(data.screenResolution)) {
                threatScore += 10;
                indicators.push('Common automation resolution');
            }
            
            // Referrer analysis
            if (data.referrer === '') {
                threatScore += 5;
                indicators.push('No referrer');
            }
            
            // Time-based analysis
            const hour = new Date().getHours();
            if (hour < 6 || hour > 23) {
                threatScore += 5;
                indicators.push('Unusual access time');
            }
            
            // Geolocation risk assessment
            const riskCountries = ['CN', 'RU', 'KP', 'IR'];
            if (riskCountries.includes(data.location?.country)) {
                threatScore += 20;
                indicators.push('High-risk country');
            }
            
            // Determine threat level
            let level = 'NONE';
            if (threatScore >= 60) level = 'CRITICAL';
            else if (threatScore >= 40) level = 'HIGH';
            else if (threatScore >= 20) level = 'MEDIUM';
            else if (threatScore >= 10) level = 'LOW';
            
            return {
                level,
                score: threatScore,
                indicators,
                riskFactors: indicators.length
            };
        }
        
        async processVisitor() {
            // Enhanced ML classification
            if (this.mlModel) {
                this.visitorData.classification = this.mlModel.classify(this.visitorData);
                this.visitorData.behaviorPrediction = this.mlModel.predictBehavior(this.visitorData);
            }
            
            // Store locally with enhanced data
            this.storeLocally();
            
            // Real-time threat detection
            if (this.visitorData.threatLevel.level !== 'NONE') {
                this.trackEvent('security_threat', {
                    threatLevel: this.visitorData.threatLevel.level,
                    threatScore: this.visitorData.threatLevel.score,
                    indicators: this.visitorData.threatLevel.indicators,
                    ip: this.visitorData.ip,
                    userAgent: this.visitorData.userAgent
                });
                
                if (this.visitorData.threatLevel.level === 'CRITICAL') {
                    this.handleCriticalThreat();
                }
            }
            
            // Try to send to server if available
            try {
                await this.sendToServer();
            } catch (e) {
                if (this.options.enableConsoleLog) {
                    console.log('📱 Server not available, using local storage');
                }
            }
            
            // Data retention cleanup
            this.cleanupOldData();
        }
        
        handleCriticalThreat() {
            // Log critical threat
            console.warn('🚨 CRITICAL THREAT DETECTED:', this.visitorData.threatLevel);
            
            // Optional: Block or redirect high-threat visitors
            if (this.options.blockCriticalThreats) {
                this.blockVisitor();
            }
            
            // Send immediate alert
            this.trackEvent('critical_threat_alert', {
                timestamp: Date.now(),
                visitorData: this.visitorData,
                actionTaken: this.options.blockCriticalThreats ? 'blocked' : 'logged'
            });
        }
        
        blockVisitor() {
            // Create blocking overlay
            const blockingOverlay = document.createElement('div');
            blockingOverlay.innerHTML = `
                <div style="
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background: #000;
                    color: #ff0040;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    z-index: 9999999;
                    font-family: 'Courier New', monospace;
                    text-align: center;
                ">
                    <div>
                        <h1 style="color: #ff0040; text-shadow: 0 0 10px #ff0040;">⚠️ ACCESS DENIED</h1>
                        <p>Suspicious activity detected.<br>Contact administrator if you believe this is an error.</p>
                        <div style="font-size: 12px; opacity: 0.5; margin-top: 20px;">
                            Session ID: ${this.sessionId}
                        </div>
                    </div>
                </div>
            `;
            document.body.appendChild(blockingOverlay);
        }
        
        storeLocally() {
            try {
                // Get existing data
                const stored = JSON.parse(localStorage.getItem(this.options.storageKey) || '[]');
                
                // Add current visitor with enhanced data
                const enhancedVisitor = {
                    ...this.visitorData,
                    events: this.events,
                    heatmapData: this.heatmapData.slice(-100), // Keep last 100 points
                    sessionRecording: this.sessionRecording.slice(-50), // Keep last 50 actions
                    scrollEvents: this.scrollEvents.slice(-20),
                    clickEvents: this.clickEvents.slice(-50),
                    formInteractions: this.formInteractions.slice(-20),
                    errorEvents: this.errorEvents,
                    performanceMetrics: this.performanceMetrics,
                    timeOnSite: Date.now() - this.startTime,
                    abTestVariant: this.abTestVariant
                };
                
                stored.push(enhancedVisitor);
                
                // Keep only recent visits
                if (stored.length > this.options.maxStoredVisits) {
                    stored.splice(0, stored.length - this.options.maxStoredVisits);
                }
                
                localStorage.setItem(this.options.storageKey, JSON.stringify(stored));
                
                // Only show notification in development mode
                if (this.options.enableNotifications && 
                    (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')) {
                    this.showStorageNotification();
                }
            } catch (error) {
                console.error('Failed to store visitor data locally:', error);
            }
        }
        
        cleanupOldData() {
            if (!this.options.dataRetentionDays) return;
            
            try {
                const stored = JSON.parse(localStorage.getItem(this.options.storageKey) || '[]');
                const cutoffDate = Date.now() - (this.options.dataRetentionDays * 24 * 60 * 60 * 1000);
                
                const filteredData = stored.filter(visitor => 
                    new Date(visitor.timestamp).getTime() > cutoffDate
                );
                
                if (filteredData.length !== stored.length) {
                    localStorage.setItem(this.options.storageKey, JSON.stringify(filteredData));
                    if (this.options.enableConsoleLog) {
                        console.log(`🗑️ Cleaned up ${stored.length - filteredData.length} old visitor records`);
                    }
                }
            } catch (error) {
                console.error('Failed to cleanup old data:', error);
            }
        }
        
        async sendToServer() {
            // This would attempt to send to a server endpoint
            if (this.options.serverEndpoint) {
                const response = await fetch(this.options.serverEndpoint, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-API-Key': this.options.apiKey
                    },
                    body: JSON.stringify({
                        visitor: this.visitorData,
                        events: this.events,
                        heatmapData: this.heatmapData,
                        sessionData: {
                            recording: this.sessionRecording,
                            scrollEvents: this.scrollEvents,
                            clickEvents: this.clickEvents,
                            formInteractions: this.formInteractions,
                            errorEvents: this.errorEvents
                        },
                        performance: this.performanceMetrics,
                        abTest: this.abTestVariant
                    })
                });
                
                if (!response.ok) {
                    throw new Error(`Server responded with ${response.status}`);
                }
                
                return await response.json();
            } else {
                throw new Error('No server endpoint configured');
            }
        }
        
        showStorageNotification() {
            const notification = document.createElement('div');
            notification.className = 'xxmxli-tracker-notification';
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
            notification.innerHTML = '📱 FULL Visitor data stored locally (development mode)';
            
            // Add fade animation
            if (!document.querySelector('#xxmxli-fade-style')) {
                const style = document.createElement('style');
                style.id = 'xxmxli-fade-style';
                style.textContent = `
                    @keyframes fadeInOut {
                        0% { opacity: 0; transform: translateX(-20px); }
                        20% { opacity: 1; transform: translateX(0); }
                        80% { opacity: 1; transform: translateX(0); }
                        100% { opacity: 0; transform: translateX(-20px); }
                    }
                `;
                document.head.appendChild(style);
            }
            
            document.body.appendChild(notification);
            
            // Remove after animation
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.remove();
                }
            }, 3000);
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
            window.XXMXLIFullTracker = this;
        }
        
        openDashboard() {
            const dashboard = this.createAdvancedDashboard();
            document.body.appendChild(dashboard);
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
        
        createAdvancedDashboard() {
            const stored = JSON.parse(localStorage.getItem(this.options.storageKey) || '[]');
            const stats = this.calculateAdvancedStats(stored);
            
            const modal = document.createElement('div');
            modal.className = 'xxmxli-dashboard-modal';
            modal.innerHTML = `
                <div style="
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background: rgba(0, 0, 0, 0.95);
                    z-index: 999999;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-family: 'Courier New', monospace;
                    overflow-y: auto;
                ">
                    <div style="
                        background: #0a0a0a;
                        border: 2px solid #00ff00;
                        border-radius: 8px;
                        padding: 25px;
                        max-width: 95vw;
                        max-height: 90vh;
                        overflow-y: auto;
                        color: #00ff00;
                        box-shadow: 0 0 40px rgba(0, 255, 0, 0.3);
                        width: 1200px;
                    ">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; border-bottom: 1px solid #00ff00; padding-bottom: 15px;">
                            <h2 style="margin: 0; text-shadow: 0 0 15px #00ff00; font-size: 24px;">🔍 XXMXLI FULL Tracker Dashboard</h2>
                            <button class="xxmxli-close-btn" style="
                                background: #ff0040;
                                border: 1px solid #ff0040;
                                color: white;
                                padding: 8px 15px;
                                border-radius: 4px;
                                cursor: pointer;
                                font-size: 16px;
                            ">✕ Close</button>
                        </div>
                        
                        <!-- Stats Grid -->
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 25px;">
                            ${this.renderStatsCards(stats)}
                        </div>
                        
                        <!-- Navigation Tabs -->
                        <div style="margin-bottom: 20px;">
                            <div class="xxmxli-tabs" style="display: flex; border-bottom: 1px solid #00ff00;">
                                <button class="xxmxli-tab active" data-tab="overview">📊 Overview</button>
                                <button class="xxmxli-tab" data-tab="security">🛡️ Security</button>
                                <button class="xxmxli-tab" data-tab="behavior">🎯 Behavior</button>
                                <button class="xxmxli-tab" data-tab="performance">⚡ Performance</button>
                                <button class="xxmxli-tab" data-tab="heatmap">🔥 Heatmap</button>
                                <button class="xxmxli-tab" data-tab="settings">⚙️ Settings</button>
                            </div>
                        </div>
                        
                        <!-- Tab Content -->
                        <div class="xxmxli-tab-content">
                            <div id="overview" class="xxmxli-tab-panel active">
                                ${this.renderOverviewPanel(stored, stats)}
                            </div>
                            <div id="security" class="xxmxli-tab-panel">
                                ${this.renderSecurityPanel(stored)}
                            </div>
                            <div id="behavior" class="xxmxli-tab-panel">
                                ${this.renderBehaviorPanel(stored)}
                            </div>
                            <div id="performance" class="xxmxli-tab-panel">
                                ${this.renderPerformancePanel(stored)}
                            </div>
                            <div id="heatmap" class="xxmxli-tab-panel">
                                ${this.renderHeatmapPanel()}
                            </div>
                            <div id="settings" class="xxmxli-tab-panel">
                                ${this.renderSettingsPanel()}
                            </div>
                        </div>
                        
                        <!-- Action Buttons -->
                        <div style="margin-top: 25px; padding-top: 15px; border-top: 1px solid #00ff00; display: flex; gap: 10px;">
                            <button class="xxmxli-export-btn" style="
                                background: #0080ff;
                                border: 1px solid #0080ff;
                                color: white;
                                padding: 10px 20px;
                                border-radius: 4px;
                                cursor: pointer;
                            ">📥 Export All Data</button>
                            
                            <button class="xxmxli-clear-btn" style="
                                background: #ff4000;
                                border: 1px solid #ff4000;
                                color: white;
                                padding: 10px 20px;
                                border-radius: 4px;
                                cursor: pointer;
                            ">🗑️ Clear Data</button>
                            
                            <button class="xxmxli-refresh-btn" style="
                                background: #00ff00;
                                border: 1px solid #00ff00;
                                color: #000;
                                padding: 10px 20px;
                                border-radius: 4px;
                                cursor: pointer;
                            ">🔄 Refresh</button>
                        </div>
                    </div>
                </div>
            `;
            
            // Add event listeners
            this.attachDashboardEvents(modal);
            
            return modal;
        }
        
        renderStatsCards(stats) {
            return `
                <div class="stat-card" style="background: rgba(0, 255, 0, 0.1); padding: 15px; border-radius: 6px; border: 1px solid #00ff00;">
                    <div style="font-size: 28px; font-weight: bold;">${stats.total}</div>
                    <div style="font-size: 12px; opacity: 0.8;">TOTAL VISITORS</div>
                </div>
                <div class="stat-card" style="background: rgba(0, 128, 255, 0.1); padding: 15px; border-radius: 6px; border: 1px solid #0080ff;">
                    <div style="font-size: 28px; font-weight: bold; color: #0080ff;">${stats.unique}</div>
                    <div style="font-size: 12px; opacity: 0.8;">UNIQUE IPS</div>
                </div>
                <div class="stat-card" style="background: rgba(255, 64, 0, 0.1); padding: 15px; border-radius: 6px; border: 1px solid #ff4000;">
                    <div style="font-size: 28px; font-weight: bold; color: #ff4000;">${stats.threats}</div>
                    <div style="font-size: 12px; opacity: 0.8;">THREATS DETECTED</div>
                </div>
                <div class="stat-card" style="background: rgba(255, 255, 0, 0.1); padding: 15px; border-radius: 6px; border: 1px solid #ffff00;">
                    <div style="font-size: 28px; font-weight: bold; color: #ffff00;">${stats.today}</div>
                    <div style="font-size: 12px; opacity: 0.8;">TODAY'S VISITS</div>
                </div>
                <div class="stat-card" style="background: rgba(255, 0, 255, 0.1); padding: 15px; border-radius: 6px; border: 1px solid #ff00ff;">
                    <div style="font-size: 28px; font-weight: bold; color: #ff00ff;">${stats.avgTime}s</div>
                    <div style="font-size: 12px; opacity: 0.8;">AVG TIME ON SITE</div>
                </div>
                <div class="stat-card" style="background: rgba(0, 255, 255, 0.1); padding: 15px; border-radius: 6px; border: 1px solid #00ffff;">
                    <div style="font-size: 28px; font-weight: bold; color: #00ffff;">${stats.topCountry}</div>
                    <div style="font-size: 12px; opacity: 0.8;">TOP COUNTRY</div>
                </div>
            `;
        }
        
        renderOverviewPanel(stored, stats) {
            return `
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                    <div>
                        <h3 style="color: #00ff00; margin-bottom: 15px;">📈 Recent Visitors</h3>
                        <div style="max-height: 400px; overflow-y: auto;">
                            ${this.renderAdvancedVisitorTable(stored.slice(-10).reverse())}
                        </div>
                    </div>
                    <div>
                        <h3 style="color: #00ff00; margin-bottom: 15px;">🌍 Geographic Distribution</h3>
                        <div style="background: rgba(0, 255, 0, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(0, 255, 0, 0.2);">
                            ${this.renderGeographicChart(stored)}
                        </div>
                        
                        <h3 style="color: #00ff00; margin: 20px 0 15px 0;">🕰️ Visit Timeline</h3>
                        <div style="background: rgba(0, 255, 0, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(0, 255, 0, 0.2);">
                            ${this.renderTimelineChart(stored)}
                        </div>
                    </div>
                </div>
            `;
        }
        
        renderSecurityPanel(stored) {
            const threats = stored.filter(v => v.threatLevel && v.threatLevel.level !== 'NONE');
            const highThreats = threats.filter(v => v.threatLevel.level === 'HIGH' || v.threatLevel.level === 'CRITICAL');
            
            return `
                <div>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px;">
                        <div>
                            <h3 style="color: #ff4000; margin-bottom: 15px;">⚠️ High Priority Threats</h3>
                            <div style="max-height: 300px; overflow-y: auto;">
                                ${this.renderThreatTable(highThreats)}
                            </div>
                        </div>
                        <div>
                            <h3 style="color: #ffff00; margin-bottom: 15px;">📊 Threat Distribution</h3>
                            <div style="background: rgba(255, 64, 0, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(255, 64, 0, 0.2);">
                                ${this.renderThreatChart(stored)}
                            </div>
                        </div>
                    </div>
                    
                    <h3 style="color: #00ff00; margin-bottom: 15px;">🔍 All Security Events</h3>
                    <div style="max-height: 300px; overflow-y: auto;">
                        ${this.renderThreatTable(threats)}
                    </div>
                </div>
            `;
        }
        
        renderBehaviorPanel(stored) {
            return `
                <div>
                    <h3 style="color: #00ff00; margin-bottom: 15px;">🎯 User Behavior Analytics</h3>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                        <div>
                            <h4 style="color: #0080ff;">Click Heatmap Summary</h4>
                            <div style="background: rgba(0, 128, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(0, 128, 255, 0.2);">
                                Total Clicks: ${this.clickEvents.length}<br>
                                Most Clicked Area: ${this.getMostClickedArea()}<br>
                                Click Rate: ${(this.clickEvents.length / (Date.now() - this.startTime) * 60000).toFixed(2)}/min
                            </div>
                            
                            <h4 style="color: #ff00ff; margin-top: 15px;">Scroll Behavior</h4>
                            <div style="background: rgba(255, 0, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(255, 0, 255, 0.2);">
                                Max Scroll Depth: ${this.getMaxScrollDepth()}%<br>
                                Scroll Events: ${this.scrollEvents.length}<br>
                                Reading Pattern: ${this.analyzeReadingPattern()}
                            </div>
                        </div>
                        
                        <div>
                            <h4 style="color: #ffff00;">Form Interactions</h4>
                            <div style="background: rgba(255, 255, 0, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(255, 255, 0, 0.2);">
                                Forms Interacted: ${new Set(this.formInteractions.map(f => f.element)).size}<br>
                                Input Events: ${this.formInteractions.length}<br>
                                Completion Rate: ${this.calculateFormCompletionRate()}%
                            </div>
                            
                            <h4 style="color: #00ffff; margin-top: 15px;">Session Quality</h4>
                            <div style="background: rgba(0, 255, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(0, 255, 255, 0.2);">
                                Engagement Score: ${this.calculateEngagementScore()}/100<br>
                                Bounce Probability: ${this.calculateBounceRate()}%<br>
                                Session Duration: ${Math.round((Date.now() - this.startTime) / 1000)}s
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }
        
        renderPerformancePanel(stored) {
            return `
                <div>
                    <h3 style="color: #00ff00; margin-bottom: 15px;">⚡ Performance Metrics</h3>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                        <div>
                            <h4 style="color: #0080ff;">Page Load Performance</h4>
                            <div style="background: rgba(0, 128, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(0, 128, 255, 0.2);">
                                ${this.renderPagePerformance()}
                            </div>
                            
                            <h4 style="color: #ff00ff; margin-top: 15px;">Resource Loading</h4>
                            <div style="background: rgba(255, 0, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(255, 0, 255, 0.2);">
                                ${this.renderResourcePerformance()}
                            </div>
                        </div>
                        
                        <div>
                            <h4 style="color: #ffff00;">Error Tracking</h4>
                            <div style="background: rgba(255, 255, 0, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(255, 255, 0, 0.2); max-height: 200px; overflow-y: auto;">
                                ${this.renderErrorList()}
                            </div>
                            
                            <h4 style="color: #00ffff; margin-top: 15px;">Long Tasks</h4>
                            <div style="background: rgba(0, 255, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(0, 255, 255, 0.2);">
                                ${this.renderLongTasks()}
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }
        
        renderHeatmapPanel() {
            return `
                <div>
                    <h3 style="color: #00ff00; margin-bottom: 15px;">🔥 Interaction Heatmap</h3>
                    <div style="text-align: center; padding: 40px; background: rgba(0, 255, 0, 0.05); border-radius: 6px; border: 1px solid rgba(0, 255, 0, 0.2);">
                        <div style="font-size: 48px; margin-bottom: 20px;">🔥</div>
                        <div style="font-size: 18px; margin-bottom: 10px;">Interactive Heatmap</div>
                        <div style="opacity: 0.7;">Mouse movements: ${this.mouseMovements.length}</div>
                        <div style="opacity: 0.7;">Click events: ${this.clickEvents.length}</div>
                        <div style="opacity: 0.7;">Scroll events: ${this.scrollEvents.length}</div>
                        <button onclick="window.XXMXLIFullTracker.generateHeatmapVisualization()" style="
                            margin-top: 20px;
                            background: #00ff00;
                            color: #000;
                            border: none;
                            padding: 10px 20px;
                            border-radius: 4px;
                            cursor: pointer;
                        ">Generate Heatmap Visualization</button>
                    </div>
                </div>
            `;
        }
        
        renderSettingsPanel() {
            return `
                <div>
                    <h3 style="color: #00ff00; margin-bottom: 15px;">⚙️ Tracker Settings</h3>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                        <div>
                            <h4 style="color: #0080ff;">Current Configuration</h4>
                            <div style="background: rgba(0, 128, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(0, 128, 255, 0.2); font-size: 12px;">
                                <pre>${JSON.stringify({
                                    apiKey: this.options.apiKey,
                                    enableHeatmaps: this.options.enableHeatmaps,
                                    enableSessionRecording: this.options.enableSessionRecording,
                                    enableMLClassification: this.options.enableMLClassification,
                                    enableFraudDetection: this.options.enableFraudDetection,
                                    maxStoredVisits: this.options.maxStoredVisits,
                                    dataRetentionDays: this.options.dataRetentionDays
                                }, null, 2)}</pre>
                            </div>
                        </div>
                        
                        <div>
                            <h4 style="color: #ff00ff;">Session Information</h4>
                            <div style="background: rgba(255, 0, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(255, 0, 255, 0.2);">
                                Session ID: ${this.sessionId}<br>
                                Start Time: ${new Date(this.startTime).toLocaleString()}<br>
                                Duration: ${Math.round((Date.now() - this.startTime) / 1000)}s<br>
                                Events Tracked: ${this.events.length}<br>
                                ML Model: ${this.mlModel ? 'Active' : 'Disabled'}<br>
                                A/B Test: ${this.abTestVariant ? this.abTestVariant.name : 'None'}
                            </div>
                            
                            <div style="margin-top: 15px;">
                                <button onclick="window.XXMXLIFullTracker.downloadDebugReport()" style="
                                    background: #ff00ff;
                                    color: #000;
                                    border: none;
                                    padding: 8px 16px;
                                    border-radius: 4px;
                                    cursor: pointer;
                                    margin-right: 10px;
                                ">📋 Download Debug Report</button>
                                
                                <button onclick="window.XXMXLIFullTracker.resetTracker()" style="
                                    background: #ff4000;
                                    color: #fff;
                                    border: none;
                                    padding: 8px 16px;
                                    border-radius: 4px;
                                    cursor: pointer;
                                ">🔄 Reset Tracker</button>
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }
        
        attachDashboardEvents(modal) {
            // Close button
            const closeBtn = modal.querySelector('.xxmxli-close-btn');
            closeBtn.addEventListener('click', () => modal.remove());
            
            // Tab navigation
            modal.querySelectorAll('.xxmxli-tab').forEach(tab => {
                tab.addEventListener('click', () => {
                    modal.querySelectorAll('.xxmxli-tab').forEach(t => t.classList.remove('active'));
                    modal.querySelectorAll('.xxmxli-tab-panel').forEach(p => p.classList.remove('active'));
                    
                    tab.classList.add('active');
                    modal.querySelector(`#${tab.dataset.tab}`).classList.add('active');
                });
            });
            
            // Action buttons
            modal.querySelector('.xxmxli-export-btn').addEventListener('click', () => this.exportAdvancedData());
            modal.querySelector('.xxmxli-clear-btn').addEventListener('click', () => {
                this.clearData();
                modal.remove();
            });
            modal.querySelector('.xxmxli-refresh-btn').addEventListener('click', () => {
                modal.remove();
                this.openDashboard();
            });
            
            // Close on background click and Escape key
            modal.addEventListener('click', (e) => {
                if (e.target === modal || e.target === modal.firstElementChild) {
                    modal.remove();
                }
            });
            
            const handleKeydown = (e) => {
                if (e.key === 'Escape') {
                    modal.remove();
                    document.removeEventListener('keydown', handleKeydown);
                }
            };
            document.addEventListener('keydown', handleKeydown);
        }
        
        calculateAdvancedStats(visitors) {
            const today = new Date().toDateString();
            const uniqueIps = new Set(visitors.map(v => v.ip).filter(Boolean));
            const countries = visitors.map(v => v.location?.country).filter(Boolean);
            const topCountry = this.getMostFrequent(countries) || 'Unknown';
            const threats = visitors.filter(v => v.threatLevel && v.threatLevel.level !== 'NONE');
            const avgTime = visitors.length > 0 ? 
                Math.round(visitors.reduce((sum, v) => sum + (v.timeOnSite || 0), 0) / visitors.length / 1000) : 0;
            
            return {
                total: visitors.length,
                unique: uniqueIps.size,
                today: visitors.filter(v => new Date(v.timestamp).toDateString() === today).length,
                threats: threats.length,
                avgTime,
                topCountry
            };
        }
        
        getMostFrequent(arr) {
            if (!arr || arr.length === 0) return null;
            
            const frequency = {};
            arr.forEach(item => {
                if (item) {
                    frequency[item] = (frequency[item] || 0) + 1;
                }
            });
            
            const keys = Object.keys(frequency);
            if (keys.length === 0) return null;
            
            return keys.reduce((a, b) => frequency[a] > frequency[b] ? a : b);
        }
        
        renderAdvancedVisitorTable(visitors) {
            if (visitors.length === 0) {
                return '<div style="text-align: center; opacity: 0.6;">No visitors tracked yet</div>';
            }
            
            return `
                <table style="width: 100%; border-collapse: collapse; font-size: 11px;">
                    <thead>
                        <tr style="border-bottom: 1px solid #00ff00;">
                            <th style="padding: 6px; text-align: left;">Time</th>
                            <th style="padding: 6px; text-align: left;">IP</th>
                            <th style="padding: 6px; text-align: left;">Location</th>
                            <th style="padding: 6px; text-align: left;">Device</th>
                            <th style="padding: 6px; text-align: left;">Threat</th>
                            <th style="padding: 6px; text-align: left;">Score</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${visitors.map(visitor => `
                            <tr style="border-bottom: 1px solid rgba(0, 255, 0, 0.2);">
                                <td style="padding: 6px;">${new Date(visitor.timestamp).toLocaleTimeString()}</td>
                                <td style="padding: 6px;">${visitor.ip || 'Unknown'}</td>
                                <td style="padding: 6px;">${visitor.location?.city || 'Unknown'}, ${visitor.location?.country || 'Unknown'}</td>
                                <td style="padding: 6px;">${visitor.browser?.name || 'Unknown'} / ${visitor.operatingSystem || 'Unknown'}</td>
                                <td style="padding: 6px;">
                                    <span style="color: ${this.getThreatColor(visitor.threatLevel?.level)}">${visitor.threatLevel?.level || 'NONE'}</span>
                                </td>
                                <td style="padding: 6px;">${visitor.fraudScore || visitor.threatLevel?.score || 0}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            `;
        }
        
        getThreatColor(level) {
            switch(level) {
                case 'CRITICAL': return '#ff0040';
                case 'HIGH': return '#ff4000';
                case 'MEDIUM': return '#ff8000';
                case 'LOW': return '#ffff00';
                default: return '#00ff00';
            }
        }
        
        // Utility methods for dashboard panels
        getMostClickedArea() {
            if (this.clickEvents.length === 0) return 'No clicks yet';
            
            // Simple area detection based on screen quadrants
            const quadrants = { tl: 0, tr: 0, bl: 0, br: 0 };
            this.clickEvents.forEach(click => {
                const x = click.x / window.innerWidth;
                const y = click.y / window.innerHeight;
                
                if (x < 0.5 && y < 0.5) quadrants.tl++;
                else if (x >= 0.5 && y < 0.5) quadrants.tr++;
                else if (x < 0.5 && y >= 0.5) quadrants.bl++;
                else quadrants.br++;
            });
            
            const max = Math.max(...Object.values(quadrants));
            const area = Object.keys(quadrants).find(key => quadrants[key] === max);
            
            const areas = { tl: 'Top Left', tr: 'Top Right', bl: 'Bottom Left', br: 'Bottom Right' };
            return areas[area] || 'Unknown';
        }
        
        getMaxScrollDepth() {
            if (this.scrollEvents.length === 0) return 0;
            
            const maxScroll = Math.max(...this.scrollEvents.map(e => e.scrollY));
            const pageHeight = Math.max(...this.scrollEvents.map(e => e.maxScroll));
            
            return pageHeight > 0 ? Math.round((maxScroll / pageHeight) * 100) : 0;
        }
        
        analyzeReadingPattern() {
            if (this.scrollEvents.length < 3) return 'Insufficient data';
            
            const scrollSpeeds = [];
            for (let i = 1; i < this.scrollEvents.length; i++) {
                const timeDiff = this.scrollEvents[i].timestamp - this.scrollEvents[i-1].timestamp;
                const scrollDiff = Math.abs(this.scrollEvents[i].scrollY - this.scrollEvents[i-1].scrollY);
                scrollSpeeds.push(scrollDiff / timeDiff);
            }
            
            const avgSpeed = scrollSpeeds.reduce((a, b) => a + b, 0) / scrollSpeeds.length;
            
            if (avgSpeed > 2) return 'Fast scanner';
            if (avgSpeed > 0.5) return 'Normal reader';
            return 'Careful reader';
        }
        
        calculateFormCompletionRate() {
            if (this.formInteractions.length === 0) return 0;
            
            const formsStarted = new Set(this.formInteractions.map(f => f.element)).size;
            const formsWithSignificantInput = new Set(
                this.formInteractions.filter(f => f.valueLength > 5).map(f => f.element)
            ).size;
            
            return formsStarted > 0 ? Math.round((formsWithSignificantInput / formsStarted) * 100) : 0;
        }
        
        calculateEngagementScore() {
            let score = 0;
            const sessionDuration = Date.now() - this.startTime;
            
            // Time on site (max 30 points)
            score += Math.min(30, (sessionDuration / 60000) * 5); // 5 points per minute, max 30
            
            // Interactions (max 25 points)
            score += Math.min(25, this.clickEvents.length * 2);
            
            // Scroll depth (max 20 points)
            score += (this.getMaxScrollDepth() / 100) * 20;
            
            // Form interactions (max 15 points)
            score += Math.min(15, this.formInteractions.length * 3);
            
            // Page focus (max 10 points)
            score += Math.min(10, this.focusEvents.length);
            
            return Math.round(score);
        }
        
        calculateBounceRate() {
            const sessionDuration = Date.now() - this.startTime;
            const interactions = this.clickEvents.length + this.formInteractions.length;
            
            if (sessionDuration < 10000 && interactions === 0) return 95; // High bounce
            if (sessionDuration < 30000 && interactions < 2) return 70; // Medium bounce
            if (interactions > 5 || sessionDuration > 120000) return 10; // Low bounce
            
            return 40; // Moderate bounce
        }
        
        renderPagePerformance() {
            if (!this.visitorData) return 'No performance data available';
            
            return `
                Load Time: ${this.visitorData.pageLoadTime || 'N/A'}ms<br>
                DOM Ready: ${this.visitorData.domContentLoadedTime || 'N/A'}ms<br>
                First Paint: ${this.visitorData.firstPaintTime || 'N/A'}ms<br>
                First Contentful Paint: ${this.visitorData.firstContentfulPaintTime || 'N/A'}ms
            `;
        }
        
        renderResourcePerformance() {
            const resources = this.performanceMetrics.resources || [];
            if (resources.length === 0) return 'No resource data available';
            
            const totalSize = resources.reduce((sum, r) => sum + (r.size || 0), 0);
            const avgDuration = resources.reduce((sum, r) => sum + (r.duration || 0), 0) / resources.length;
            
            return `
                Resources Loaded: ${resources.length}<br>
                Total Size: ${Math.round(totalSize / 1024)}KB<br>
                Avg Load Time: ${Math.round(avgDuration)}ms<br>
                Slowest Resource: ${resources.reduce((max, r) => r.duration > (max.duration || 0) ? r : max, {}).name || 'N/A'}
            `;
        }
        
        renderErrorList() {
            if (this.errorEvents.length === 0) return 'No errors detected ✅';
            
            return this.errorEvents.slice(-5).map(error => `
                <div style="margin-bottom: 10px; padding: 8px; background: rgba(255, 64, 0, 0.1); border-radius: 4px;">
                    <strong>${error.message}</strong><br>
                    <small>${error.filename}:${error.lineno}</small>
                </div>
            `).join('');
        }
        
        renderLongTasks() {
            const longTasks = this.performanceMetrics.longTasks || [];
            if (longTasks.length === 0) return 'No long tasks detected ✅';
            
            const totalBlockingTime = longTasks.reduce((sum, task) => sum + task.duration, 0);
            
            return `
                Long Tasks: ${longTasks.length}<br>
                Total Blocking Time: ${Math.round(totalBlockingTime)}ms<br>
                Avg Task Duration: ${Math.round(totalBlockingTime / longTasks.length)}ms
            `;
        }
        
        // Advanced export functionality
        exportAdvancedData() {
            const stored = JSON.parse(localStorage.getItem(this.options.storageKey) || '[]');
            const exportData = {
                metadata: {
                    exportDate: new Date().toISOString(),
                    trackerVersion: '2.0-FULL',
                    sessionId: this.sessionId,
                    configuration: this.options
                },
                visitors: stored,
                currentSession: {
                    visitor: this.visitorData,
                    events: this.events,
                    heatmapData: this.heatmapData,
                    sessionRecording: this.sessionRecording,
                    scrollEvents: this.scrollEvents,
                    clickEvents: this.clickEvents,
                    formInteractions: this.formInteractions,
                    errorEvents: this.errorEvents,
                    performanceMetrics: this.performanceMetrics,
                    abTestVariant: this.abTestVariant
                },
                analytics: {
                    stats: this.calculateAdvancedStats(stored),
                    engagementScore: this.calculateEngagementScore(),
                    bounceRate: this.calculateBounceRate(),
                    maxScrollDepth: this.getMaxScrollDepth(),
                    readingPattern: this.analyzeReadingPattern()
                }
            };
            
            const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            
            const a = document.createElement('a');
            a.href = url;
            a.download = `xxmxli-full-tracker-${new Date().toISOString().split('T')[0]}.json`;
            a.click();
            
            URL.revokeObjectURL(url);
        }
        
        clearData() {
            if (confirm('🚨 Are you sure you want to clear ALL visitor tracking data? This cannot be undone!')) {
                localStorage.removeItem(this.options.storageKey);
                this.events = [];
                this.heatmapData = [];
                this.sessionRecording = [];
                this.clickEvents = [];
                this.scrollEvents = [];
                this.formInteractions = [];
                this.errorEvents = [];
                this.performanceMetrics = {};
                
                alert('✅ All visitor tracking data cleared!');
            }
        }
        
        // Public API methods (enhanced)
        getAdvancedStats() {
            const stored = JSON.parse(localStorage.getItem(this.options.storageKey) || '[]');
            return this.calculateAdvancedStats(stored);
        }
        
        getVisitors() {
            return JSON.parse(localStorage.getItem(this.options.storageKey) || '[]');
        }
        
        getCurrentSession() {
            return {
                visitor: this.visitorData,
                events: this.events,
                heatmapData: this.heatmapData,
                sessionRecording: this.sessionRecording,
                performanceMetrics: this.performanceMetrics,
                engagementScore: this.calculateEngagementScore(),
                bounceRate: this.calculateBounceRate()
            };
        }
        
        trackCustomEvent(eventName, data = {}) {
            this.trackEvent(`custom_${eventName}`, data);
        }
        
        trackConversion(conversionType, value = null) {
            this.trackEvent('conversion', {
                type: conversionType,
                value: value,
                timestamp: Date.now()
            });
        }
        
        trackVisit() {
            return this.init();
        }
        
        // Additional utility methods
        generateHeatmapVisualization() {
            // Create a simple heatmap overlay
            const overlay = document.createElement('div');
            overlay.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100vw;
                height: 100vh;
                pointer-events: none;
                z-index: 999998;
            `;
            
            this.clickEvents.forEach(click => {
                const dot = document.createElement('div');
                dot.style.cssText = `
                    position: absolute;
                    left: ${click.x}px;
                    top: ${click.y}px;
                    width: 10px;
                    height: 10px;
                    background: radial-gradient(circle, rgba(255,0,64,0.8) 0%, rgba(255,0,64,0) 70%);
                    border-radius: 50%;
                    transform: translate(-50%, -50%);
                `;
                overlay.appendChild(dot);
            });
            
            document.body.appendChild(overlay);
            
            setTimeout(() => {
                overlay.remove();
            }, 5000);
            
            alert('🔥 Heatmap visualization displayed for 5 seconds!');
        }
        
        downloadDebugReport() {
            const report = {
                timestamp: new Date().toISOString(),
                sessionInfo: {
                    sessionId: this.sessionId,
                    startTime: new Date(this.startTime).toISOString(),
                    duration: Date.now() - this.startTime,
                    userAgent: navigator.userAgent,
                    url: window.location.href
                },
                trackerState: {
                    isTracking: this.isTracking,
                    eventsCount: this.events.length,
                    heatmapPoints: this.heatmapData.length,
                    clickEvents: this.clickEvents.length,
                    scrollEvents: this.scrollEvents.length,
                    formInteractions: this.formInteractions.length,
                    errorEvents: this.errorEvents.length
                },
                configuration: this.options,
                visitorData: this.visitorData,
                performanceMetrics: this.performanceMetrics,
                mlModel: this.mlModel ? 'Active' : 'Disabled',
                abTestVariant: this.abTestVariant
            };
            
            const blob = new Blob([JSON.stringify(report, null, 2)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            
            const a = document.createElement('a');
            a.href = url;
            a.download = `xxmxli-debug-report-${Date.now()}.json`;
            a.click();
            
            URL.revokeObjectURL(url);
        }
        
        resetTracker() {
            if (confirm('🔄 Reset the tracker? This will restart the current session.')) {
                this.isTracking = false;
                this.events = [];
                this.heatmapData = [];
                this.sessionRecording = [];
                this.clickEvents = [];
                this.scrollEvents = [];
                this.formInteractions = [];
                this.errorEvents = [];
                this.performanceMetrics = {};
                this.startTime = Date.now();
                this.sessionId = this.generateSessionId();
                
                this.init();
                alert('✅ Tracker reset successfully!');
            }
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
        window.XXMXLITracker = new XXMXLIFullVisitorTracker(config);
        
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
        module.exports = XXMXLIFullVisitorTracker;
    }
    
})();
