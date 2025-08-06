/**
 * XXMXLI Performance Monitoring Module
 * Page load time tracking, Core Web Vitals, error monitoring
 */

class PerformanceMonitoringModule {
    constructor(core) {
        this.core = core;
        this.config = {
            coreWebVitals: true,
            resourceTiming: true,
            navigationTiming: true,
            errorTracking: true,
            longTaskTracking: true,
            samplingRate: 1.0, // 100% sampling
            thresholds: {
                LCP: 2500, // Largest Contentful Paint (ms)
                FID: 100,  // First Input Delay (ms)
                CLS: 0.1   // Cumulative Layout Shift
            }
        };
        
        this.performanceData = {};
        this.webVitals = {};
        this.errors = [];
        this.longTasks = [];
    }

    async init() {
        await this.initializePerformanceObservers();
        this.measureNavigationTiming();
        this.measureResourceTiming();
        this.setupErrorTracking();
        this.bindEvents();
        
        if (this.core.config.debug) {
            console.log('⚡ Performance monitoring module initialized');
        }
    }

    async initializePerformanceObservers() {
        if (!window.PerformanceObserver) {
            console.warn('PerformanceObserver not supported');
            return;
        }

        // Core Web Vitals
        if (this.config.coreWebVitals) {
            this.observeCoreWebVitals();
        }

        // Long Task monitoring
        if (this.config.longTaskTracking) {
            this.observeLongTasks();
        }

        // Layout shift tracking
        this.observeLayoutShifts();
    }

    observeCoreWebVitals() {
        // Largest Contentful Paint (LCP)
        this.observeMetric('largest-contentful-paint', (entry) => {
            this.webVitals.LCP = Math.round(entry.startTime);
            this.evaluateMetric('LCP', this.webVitals.LCP, this.config.thresholds.LCP);
        });

        // First Input Delay (FID)
        this.observeMetric('first-input', (entry) => {
            this.webVitals.FID = Math.round(entry.processingStart - entry.startTime);
            this.evaluateMetric('FID', this.webVitals.FID, this.config.thresholds.FID);
        });

        // Cumulative Layout Shift (CLS)
        let clsValue = 0;
        this.observeMetric('layout-shift', (entry) => {
            if (!entry.hadRecentInput) {
                clsValue += entry.value;
                this.webVitals.CLS = Math.round(clsValue * 1000) / 1000;
                this.evaluateMetric('CLS', this.webVitals.CLS, this.config.thresholds.CLS);
            }
        });
    }

    observeMetric(type, callback) {
        try {
            const observer = new PerformanceObserver((list) => {
                list.getEntries().forEach(callback);
            });
            observer.observe({ type: type, buffered: true });
        } catch (error) {
            if (this.core.config.debug) {
                console.log(`Performance observer for ${type} not supported:`, error);
            }
        }
    }

    observeLongTasks() {
        try {
            const observer = new PerformanceObserver((list) => {
                list.getEntries().forEach((entry) => {
                    this.longTasks.push({
                        duration: Math.round(entry.duration),
                        startTime: Math.round(entry.startTime),
                        timestamp: Date.now()
                    });

                    // Send long task data
                    this.core.sendEvent('performance', {
                        type: 'long_task',
                        duration: Math.round(entry.duration),
                        startTime: Math.round(entry.startTime)
                    });
                });
            });
            observer.observe({ entryTypes: ['longtask'] });
        } catch (error) {
            if (this.core.config.debug) {
                console.log('Long task observer not supported:', error);
            }
        }
    }

    observeLayoutShifts() {
        let sessionValue = 0;
        let sessionEntries = [];

        this.observeMetric('layout-shift', (entry) => {
            if (!entry.hadRecentInput) {
                const firstSessionEntry = sessionEntries[0];
                const lastSessionEntry = sessionEntries[sessionEntries.length - 1];

                // If the entry occurred less than 1 second after the previous entry and
                // less than 5 seconds after the first entry in the session, include it
                if (sessionValue &&
                    entry.startTime - lastSessionEntry.startTime < 1000 &&
                    entry.startTime - firstSessionEntry.startTime < 5000) {
                    sessionValue += entry.value;
                    sessionEntries.push(entry);
                } else {
                    sessionValue = entry.value;
                    sessionEntries = [entry];
                }

                this.webVitals.CLS = Math.max(this.webVitals.CLS || 0, sessionValue);
            }
        });
    }

    measureNavigationTiming() {
        if (!performance.timing) return;

        const timing = performance.timing;
        const navigationStart = timing.navigationStart;

        this.performanceData.navigation = {
            DNS: timing.domainLookupEnd - timing.domainLookupStart,
            TCP: timing.connectEnd - timing.connectStart,
            SSL: timing.secureConnectionStart ? timing.connectEnd - timing.secureConnectionStart : 0,
            TTFB: timing.responseStart - navigationStart,
            download: timing.responseEnd - timing.responseStart,
            DOM: timing.domContentLoadedEventEnd - timing.domLoading,
            load: timing.loadEventEnd - navigationStart,
            total: timing.loadEventEnd - navigationStart
        };

        // Send navigation timing data
        this.core.sendEvent('performance', {
            type: 'navigation_timing',
            metrics: this.performanceData.navigation
        });
    }

    measureResourceTiming() {
        if (!performance.getEntriesByType) return;

        const resources = performance.getEntriesByType('resource');
        const resourceData = {
            totalResources: resources.length,
            resourceTypes: {},
            slowResources: [],
            totalSize: 0,
            totalDuration: 0
        };

        resources.forEach(resource => {
            const type = this.getResourceType(resource.name, resource.initiatorType);
            resourceData.resourceTypes[type] = (resourceData.resourceTypes[type] || 0) + 1;

            const duration = resource.responseEnd - resource.startTime;
            resourceData.totalDuration += duration;

            if (resource.transferSize) {
                resourceData.totalSize += resource.transferSize;
            }

            // Track slow resources (> 1 second)
            if (duration > 1000) {
                resourceData.slowResources.push({
                    name: resource.name,
                    duration: Math.round(duration),
                    size: resource.transferSize || 0,
                    type: type
                });
            }
        });

        this.performanceData.resources = resourceData;

        // Send resource timing data
        this.core.sendEvent('performance', {
            type: 'resource_timing',
            metrics: resourceData
        });
    }

    getResourceType(url, initiatorType) {
        if (initiatorType) return initiatorType;
        
        const extension = url.split('.').pop().toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].includes(extension)) return 'image';
        if (['css'].includes(extension)) return 'stylesheet';
        if (['js'].includes(extension)) return 'script';
        if (['woff', 'woff2', 'ttf', 'eot'].includes(extension)) return 'font';
        
        return 'other';
    }

    setupErrorTracking() {
        if (!this.config.errorTracking) return;

        // JavaScript errors
        window.addEventListener('error', (event) => {
            this.logError({
                type: 'javascript_error',
                message: event.message,
                filename: event.filename,
                lineno: event.lineno,
                colno: event.colno,
                stack: event.error ? event.error.stack : null,
                timestamp: Date.now()
            });
        });

        // Unhandled promise rejections
        window.addEventListener('unhandledrejection', (event) => {
            this.logError({
                type: 'unhandled_rejection',
                message: event.reason?.message || String(event.reason),
                stack: event.reason?.stack || null,
                timestamp: Date.now()
            });
        });

        // Resource loading errors
        window.addEventListener('error', (event) => {
            if (event.target && event.target !== window) {
                this.logError({
                    type: 'resource_error',
                    element: event.target.tagName.toLowerCase(),
                    source: event.target.src || event.target.href,
                    timestamp: Date.now()
                });
            }
        }, true);
    }

    logError(errorData) {
        this.errors.push(errorData);
        
        // Send error to analytics
        this.core.sendEvent('performance', {
            type: 'error',
            error: errorData
        });

        if (this.core.config.debug) {
            console.error('🐛 Error tracked:', errorData);
        }
    }

    evaluateMetric(name, value, threshold) {
        const isGood = name === 'CLS' ? value <= threshold : value <= threshold;
        const rating = this.getRating(name, value);
        
        // Send Core Web Vital data
        this.core.sendEvent('performance', {
            type: 'core_web_vital',
            metric: name,
            value: value,
            rating: rating,
            threshold: threshold,
            isGood: isGood
        });

        if (this.core.config.debug) {
            console.log(`📊 Core Web Vital - ${name}: ${value} (${rating})`);
        }
    }

    getRating(metric, value) {
        const thresholds = {
            LCP: { good: 2500, needsImprovement: 4000 },
            FID: { good: 100, needsImprovement: 300 },
            CLS: { good: 0.1, needsImprovement: 0.25 }
        };

        const threshold = thresholds[metric];
        if (!threshold) return 'unknown';

        if (value <= threshold.good) return 'good';
        if (value <= threshold.needsImprovement) return 'needs-improvement';
        return 'poor';
    }

    bindEvents() {
        // Monitor visibility changes
        document.addEventListener('visibilitychange', () => {
            if (document.visibilityState === 'hidden') {
                this.sendPerformanceSummary();
            }
        });

        // Monitor page unload
        window.addEventListener('beforeunload', () => {
            this.sendPerformanceSummary();
        });

        // Periodic performance updates
        setInterval(() => {
            this.updatePerformanceMetrics();
        }, 30000); // Every 30 seconds
    }

    updatePerformanceMetrics() {
        // Update current performance state
        const currentMemory = performance.memory ? {
            usedJSHeapSize: performance.memory.usedJSHeapSize,
            totalJSHeapSize: performance.memory.totalJSHeapSize,
            jsHeapSizeLimit: performance.memory.jsHeapSizeLimit
        } : null;

        this.core.sendEvent('performance', {
            type: 'performance_update',
            memory: currentMemory,
            timestamp: Date.now()
        });
    }

    sendPerformanceSummary() {
        const summary = {
            webVitals: this.webVitals,
            navigation: this.performanceData.navigation,
            resources: this.performanceData.resources,
            errors: this.errors.length,
            longTasks: this.longTasks.length,
            sessionDuration: performance.now()
        };

        this.core.sendEvent('performance', {
            type: 'session_summary',
            summary: summary
        });
    }

    // Dashboard creation
    createPerformanceDashboard(containerId) {
        const container = document.getElementById(containerId);
        if (!container) return;

        container.innerHTML = `
            <div class="performance-dashboard">
                <div class="dashboard-header">
                    <h2><i class="fas fa-bolt"></i> Performance Monitoring</h2>
                    <div class="dashboard-controls">
                        <button id="runPerformanceTest" class="btn-test">
                            <i class="fas fa-play"></i> Run Test
                        </button>
                        <button id="refreshPerformance" class="btn-refresh">
                            <i class="fas fa-sync-alt"></i> Refresh
                        </button>
                    </div>
                </div>

                <div class="core-web-vitals">
                    <h3><i class="fas fa-tachometer-alt"></i> Core Web Vitals</h3>
                    <div class="vitals-grid">
                        <div class="vital-card" data-vital="LCP">
                            <div class="vital-icon">⚡</div>
                            <div class="vital-content">
                                <h4>LCP</h4>
                                <div class="vital-value" id="lcp-value">-</div>
                                <div class="vital-label">Largest Contentful Paint</div>
                                <div class="vital-rating" id="lcp-rating">-</div>
                            </div>
                        </div>
                        
                        <div class="vital-card" data-vital="FID">
                            <div class="vital-icon">👆</div>
                            <div class="vital-content">
                                <h4>FID</h4>
                                <div class="vital-value" id="fid-value">-</div>
                                <div class="vital-label">First Input Delay</div>
                                <div class="vital-rating" id="fid-rating">-</div>
                            </div>
                        </div>
                        
                        <div class="vital-card" data-vital="CLS">
                            <div class="vital-icon">📏</div>
                            <div class="vital-content">
                                <h4>CLS</h4>
                                <div class="vital-value" id="cls-value">-</div>
                                <div class="vital-label">Cumulative Layout Shift</div>
                                <div class="vital-rating" id="cls-rating">-</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="performance-metrics">
                    <div class="metrics-section">
                        <h3><i class="fas fa-clock"></i> Load Times</h3>
                        <div id="load-times" class="metrics-list">
                            <!-- Load times will be populated here -->
                        </div>
                    </div>

                    <div class="metrics-section">
                        <h3><i class="fas fa-cube"></i> Resources</h3>
                        <div id="resource-metrics" class="metrics-list">
                            <!-- Resource metrics will be populated here -->
                        </div>
                    </div>
                </div>

                <div class="error-tracking">
                    <h3><i class="fas fa-bug"></i> Error Tracking</h3>
                    <div id="error-list" class="error-feed">
                        <!-- Errors will be populated here -->
                    </div>
                </div>

                <div class="performance-recommendations">
                    <h3><i class="fas fa-lightbulb"></i> Recommendations</h3>
                    <div id="recommendations-list" class="recommendations-feed">
                        <!-- Performance recommendations will be populated here -->
                    </div>
                </div>
            </div>
        `;

        this.updatePerformanceDashboard();
        this.bindDashboardEvents();
    }

    bindDashboardEvents() {
        const testBtn = document.getElementById('runPerformanceTest');
        if (testBtn) {
            testBtn.addEventListener('click', () => {
                this.runPerformanceTest();
            });
        }

        const refreshBtn = document.getElementById('refreshPerformance');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.updatePerformanceDashboard();
            });
        }
    }

    updatePerformanceDashboard() {
        this.updateCoreWebVitals();
        this.updateLoadTimes();
        this.updateResourceMetrics();
        this.updateErrorList();
        this.updateRecommendations();
    }

    updateCoreWebVitals() {
        // Update LCP
        if (this.webVitals.LCP) {
            document.getElementById('lcp-value').textContent = `${this.webVitals.LCP}ms`;
            document.getElementById('lcp-rating').textContent = this.getRating('LCP', this.webVitals.LCP);
            document.getElementById('lcp-rating').className = `vital-rating ${this.getRating('LCP', this.webVitals.LCP)}`;
        }

        // Update FID
        if (this.webVitals.FID) {
            document.getElementById('fid-value').textContent = `${this.webVitals.FID}ms`;
            document.getElementById('fid-rating').textContent = this.getRating('FID', this.webVitals.FID);
            document.getElementById('fid-rating').className = `vital-rating ${this.getRating('FID', this.webVitals.FID)}`;
        }

        // Update CLS
        if (this.webVitals.CLS) {
            document.getElementById('cls-value').textContent = this.webVitals.CLS.toFixed(3);
            document.getElementById('cls-rating').textContent = this.getRating('CLS', this.webVitals.CLS);
            document.getElementById('cls-rating').className = `vital-rating ${this.getRating('CLS', this.webVitals.CLS)}`;
        }
    }

    updateLoadTimes() {
        const container = document.getElementById('load-times');
        if (!container || !this.performanceData.navigation) return;

        const navigation = this.performanceData.navigation;
        container.innerHTML = Object.entries(navigation).map(([key, value]) => `
            <div class="metric-item">
                <span class="metric-name">${key.toUpperCase()}</span>
                <span class="metric-value">${value}ms</span>
            </div>
        `).join('');
    }

    updateResourceMetrics() {
        const container = document.getElementById('resource-metrics');
        if (!container || !this.performanceData.resources) return;

        const resources = this.performanceData.resources;
        container.innerHTML = `
            <div class="metric-item">
                <span class="metric-name">Total Resources</span>
                <span class="metric-value">${resources.totalResources}</span>
            </div>
            <div class="metric-item">
                <span class="metric-name">Total Size</span>
                <span class="metric-value">${this.formatBytes(resources.totalSize)}</span>
            </div>
            <div class="metric-item">
                <span class="metric-name">Slow Resources</span>
                <span class="metric-value">${resources.slowResources.length}</span>
            </div>
        `;
    }

    updateErrorList() {
        const container = document.getElementById('error-list');
        if (!container) return;

        container.innerHTML = this.errors.slice(0, 10).map(error => `
            <div class="error-item">
                <div class="error-type">${error.type}</div>
                <div class="error-message">${error.message}</div>
                <div class="error-time">${this.formatTimeAgo(error.timestamp)}</div>
            </div>
        `).join('');
    }

    updateRecommendations() {
        const container = document.getElementById('recommendations-list');
        if (!container) return;

        const recommendations = this.generateRecommendations();
        container.innerHTML = recommendations.map(rec => `
            <div class="recommendation-item ${rec.priority}">
                <div class="recommendation-title">${rec.title}</div>
                <div class="recommendation-description">${rec.description}</div>
            </div>
        `).join('');
    }

    generateRecommendations() {
        const recommendations = [];

        // LCP recommendations
        if (this.webVitals.LCP > 2500) {
            recommendations.push({
                title: 'Improve Largest Contentful Paint',
                description: 'Optimize images, eliminate render-blocking resources, and improve server response times.',
                priority: 'high'
            });
        }

        // FID recommendations
        if (this.webVitals.FID > 100) {
            recommendations.push({
                title: 'Reduce First Input Delay',
                description: 'Minimize JavaScript execution time and break up long tasks.',
                priority: 'medium'
            });
        }

        // CLS recommendations
        if (this.webVitals.CLS > 0.1) {
            recommendations.push({
                title: 'Improve Cumulative Layout Shift',
                description: 'Add size attributes to images and reserve space for dynamic content.',
                priority: 'high'
            });
        }

        // Error recommendations
        if (this.errors.length > 0) {
            recommendations.push({
                title: 'Fix JavaScript Errors',
                description: `${this.errors.length} errors detected. Review and fix to improve user experience.`,
                priority: 'high'
            });
        }

        // Resource recommendations
        if (this.performanceData.resources?.slowResources.length > 0) {
            recommendations.push({
                title: 'Optimize Slow Resources',
                description: `${this.performanceData.resources.slowResources.length} resources are loading slowly.`,
                priority: 'medium'
            });
        }

        return recommendations;
    }

    runPerformanceTest() {
        // Trigger a fresh performance measurement
        this.measureNavigationTiming();
        this.measureResourceTiming();
        this.updatePerformanceDashboard();
        
        if (this.core.config.debug) {
            console.log('🏃 Performance test completed');
        }
    }

    formatBytes(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    formatTimeAgo(timestamp) {
        const seconds = Math.floor((Date.now() - timestamp) / 1000);
        if (seconds < 60) return `${seconds}s ago`;
        if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
        return `${Math.floor(seconds / 3600)}h ago`;
    }

    // Public API
    getWebVitals() {
        return this.webVitals;
    }

    getPerformanceData() {
        return this.performanceData;
    }

    getErrors() {
        return this.errors;
    }
}

// Register module
if (typeof window !== 'undefined') {
    window.PerformanceMonitoringModule = PerformanceMonitoringModule;
}