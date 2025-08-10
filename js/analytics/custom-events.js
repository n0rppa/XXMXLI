/**
 * XXMXLI Custom Event Tracking Module
 * User interaction logging, custom business metrics, advanced segmentation
 */

class CustomEventsModule {
    constructor(core) {
        this.core = core;
        this.config = {
            autoTrackClicks: true,
            autoTrackForms: true,
            autoTrackVideos: true,
            autoTrackDownloads: true,
            autoTrackExternalLinks: true,
            customEvents: {},
            segments: {},
            triggers: {}
        };
        
        this.eventQueue = [];
        this.userSegments = new Set();
        this.customMetrics = new Map();
        this.eventCounts = new Map();
    }

    async init() {
        this.setupAutoTracking();
        this.setupCustomEventListeners();
        this.setupSegmentation();
        this.setupEventTriggers();
        this.bindEvents();
        
        if (this.core.config.debug) {
            console.log('📊 Custom Events module initialized');
        }
    }

    setupAutoTracking() {
        if (this.config.autoTrackClicks) {
            this.trackClicks();
        }
        
        if (this.config.autoTrackForms) {
            this.trackForms();
        }
        
        if (this.config.autoTrackVideos) {
            this.trackVideos();
        }
        
        if (this.config.autoTrackDownloads) {
            this.trackDownloads();
        }
        
        if (this.config.autoTrackExternalLinks) {
            this.trackExternalLinks();
        }
    }

    trackClicks() {
        document.addEventListener('click', (e) => {
            const element = e.target;
            const eventData = {
                eventName: 'click',
                category: 'interaction',
                element: this.getElementSelector(element),
                text: element.textContent?.trim().substring(0, 100) || '',
                position: { x: e.clientX, y: e.clientY },
                timestamp: Date.now()
            };

            // Add specific tracking for important elements
            if (element.matches('button, .btn')) {
                eventData.subcategory = 'button';
                eventData.buttonType = element.type || 'button';
            } else if (element.matches('a')) {
                eventData.subcategory = 'link';
                eventData.href = element.href;
                eventData.isInternal = this.isInternalLink(element.href);
            } else if (element.matches('img')) {
                eventData.subcategory = 'image';
                eventData.src = element.src;
                eventData.alt = element.alt;
            }

            this.trackCustomEvent(eventData);
        });
    }

    trackForms() {
        const forms = document.querySelectorAll('form');
        
        forms.forEach((form, formIndex) => {
            const formId = form.id || form.className || `form-${formIndex}`;
            
            // Track form start (first field focus)
            const fields = form.querySelectorAll('input, textarea, select');
            let formStarted = false;
            
            fields.forEach((field, fieldIndex) => {
                field.addEventListener('focus', () => {
                    if (!formStarted) {
                        formStarted = true;
                        this.trackCustomEvent({
                            eventName: 'form_start',
                            category: 'form',
                            formId: formId,
                            fieldCount: fields.length,
                            timestamp: Date.now()
                        });
                    }
                    
                    this.trackCustomEvent({
                        eventName: 'field_focus',
                        category: 'form',
                        formId: formId,
                        fieldId: field.id || field.name || `field-${fieldIndex}`,
                        fieldType: field.type || field.tagName.toLowerCase(),
                        timestamp: Date.now()
                    });
                });

                field.addEventListener('blur', () => {
                    this.trackCustomEvent({
                        eventName: 'field_blur',
                        category: 'form',
                        formId: formId,
                        fieldId: field.id || field.name || `field-${fieldIndex}`,
                        hasValue: !!field.value,
                        valueLength: field.value?.length || 0,
                        timestamp: Date.now()
                    });
                });
            });

            // Track form submission
            form.addEventListener('submit', (e) => {
                const formData = new FormData(form);
                const filledFields = Array.from(formData.entries()).filter(([key, value]) => value).length;
                
                this.trackCustomEvent({
                    eventName: 'form_submit',
                    category: 'form',
                    formId: formId,
                    totalFields: fields.length,
                    filledFields: filledFields,
                    completionRate: (filledFields / fields.length) * 100,
                    timestamp: Date.now()
                });
            });
        });
    }

    trackVideos() {
        const videos = document.querySelectorAll('video');
        
        videos.forEach((video, videoIndex) => {
            const videoId = video.id || video.src || `video-${videoIndex}`;
            
            const events = ['play', 'pause', 'ended', 'loadstart', 'loadeddata'];
            
            events.forEach(eventType => {
                video.addEventListener(eventType, () => {
                    this.trackCustomEvent({
                        eventName: `video_${eventType}`,
                        category: 'media',
                        videoId: videoId,
                        currentTime: video.currentTime,
                        duration: video.duration,
                        progress: video.duration ? (video.currentTime / video.duration) * 100 : 0,
                        timestamp: Date.now()
                    });
                });
            });

            // Track video milestones
            video.addEventListener('timeupdate', () => {
                const progress = (video.currentTime / video.duration) * 100;
                const milestones = [25, 50, 75, 95];
                
                milestones.forEach(milestone => {
                    if (progress >= milestone && !video.dataset[`milestone_${milestone}`]) {
                        video.dataset[`milestone_${milestone}`] = 'true';
                        
                        this.trackCustomEvent({
                            eventName: 'video_milestone',
                            category: 'media',
                            videoId: videoId,
                            milestone: milestone,
                            currentTime: video.currentTime,
                            timestamp: Date.now()
                        });
                    }
                });
            });
        });
    }

    trackDownloads() {
        document.addEventListener('click', (e) => {
            const link = e.target.closest('a');
            if (!link) return;

            const href = link.href;
            const downloadTypes = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', 
                                   '.zip', '.rar', '.mp3', '.mp4', '.avi', '.mov', '.jpg', '.png'];
            
            const isDownload = downloadTypes.some(type => href.toLowerCase().includes(type)) || 
                              link.hasAttribute('download');
            
            if (isDownload) {
                this.trackCustomEvent({
                    eventName: 'file_download',
                    category: 'download',
                    url: href,
                    filename: this.getFilenameFromUrl(href),
                    fileType: this.getFileTypeFromUrl(href),
                    linkText: link.textContent?.trim().substring(0, 100) || '',
                    timestamp: Date.now()
                });
            }
        });
    }

    trackExternalLinks() {
        document.addEventListener('click', (e) => {
            const link = e.target.closest('a');
            if (!link || !link.href) return;

            if (!this.isInternalLink(link.href)) {
                this.trackCustomEvent({
                    eventName: 'external_link_click',
                    category: 'navigation',
                    url: link.href,
                    domain: new URL(link.href).hostname,
                    linkText: link.textContent?.trim().substring(0, 100) || '',
                    openInNewTab: link.target === '_blank',
                    timestamp: Date.now()
                });
            }
        });
    }

    setupCustomEventListeners() {
        // Set up listeners for data-track attributes
        document.addEventListener('click', (e) => {
            const element = e.target.closest('[data-track]');
            if (!element) return;

            const trackData = element.dataset.track;
            try {
                const eventData = JSON.parse(trackData);
                this.trackCustomEvent({
                    ...eventData,
                    category: eventData.category || 'custom',
                    timestamp: Date.now()
                });
            } catch (err) {
                // Simple string tracking
                this.trackCustomEvent({
                    eventName: trackData,
                    category: 'custom',
                    element: this.getElementSelector(element),
                    timestamp: Date.now()
                });
            }
        });
    }

    setupSegmentation() {
        // Define user segments based on behavior
        this.config.segments = {
            'high_engagement': {
                name: 'High Engagement Users',
                conditions: [
                    { metric: 'session_duration', operator: '>', value: 300000 }, // 5 minutes
                    { metric: 'page_views', operator: '>', value: 3 }
                ]
            },
            'bounce_risk': {
                name: 'Bounce Risk Users',
                conditions: [
                    { metric: 'session_duration', operator: '<', value: 30000 }, // 30 seconds
                    { metric: 'page_views', operator: '=', value: 1 }
                ]
            },
            'converter': {
                name: 'Converters',
                conditions: [
                    { metric: 'conversions', operator: '>', value: 0 }
                ]
            },
            'form_abandoner': {
                name: 'Form Abandoners',
                conditions: [
                    { metric: 'form_starts', operator: '>', value: 0 },
                    { metric: 'form_submits', operator: '=', value: 0 }
                ]
            }
        };

        // Check segments periodically
        setInterval(() => {
            this.evaluateUserSegments();
        }, 30000); // Every 30 seconds
    }

    setupEventTriggers() {
        // Define triggers that fire based on custom events
        this.config.triggers = {
            'scroll_depth_75': {
                event: 'scroll_depth',
                condition: { value: 75 },
                action: () => {
                    this.trackCustomEvent({
                        eventName: 'engaged_reader',
                        category: 'engagement',
                        trigger: 'scroll_depth_75',
                        timestamp: Date.now()
                    });
                }
            },
            'time_on_page_2min': {
                event: 'time_threshold',
                condition: { duration: 120000 }, // 2 minutes
                action: () => {
                    this.trackCustomEvent({
                        eventName: 'time_engaged_user',
                        category: 'engagement',
                        trigger: 'time_on_page_2min',
                        timestamp: Date.now()
                    });
                }
            }
        };

        // Set up time-based triggers
        setTimeout(() => {
            if (this.config.triggers.time_on_page_2min) {
                this.config.triggers.time_on_page_2min.action();
            }
        }, 120000);
    }

    // Main tracking method
    trackCustomEvent(eventData) {
        const enrichedEvent = {
            ...eventData,
            sessionId: this.core.sessionId,
            userId: this.core.userId,
            url: window.location.href,
            timestamp: eventData.timestamp || Date.now(),
            userAgent: navigator.userAgent,
            viewport: {
                width: window.innerWidth,
                height: window.innerHeight
            },
            page: {
                title: document.title,
                path: window.location.pathname
            }
        };

        // Add custom properties if available
        if (this.customMetrics.has(eventData.eventName)) {
            enrichedEvent.customMetrics = this.customMetrics.get(eventData.eventName);
        }

        // Update event counts
        const eventKey = `${eventData.category}:${eventData.eventName}`;
        this.eventCounts.set(eventKey, (this.eventCounts.get(eventKey) || 0) + 1);

        // Add to queue
        this.eventQueue.push(enrichedEvent);

        // Send to core analytics
        this.core.sendEvent('custom_event', enrichedEvent);

        // Check if this event triggers any segments or actions
        this.checkEventTriggers(enrichedEvent);

        if (this.core.config.debug) {
            console.log('📊 Custom event tracked:', enrichedEvent);
        }
    }

    checkEventTriggers(event) {
        Object.entries(this.config.triggers).forEach(([triggerId, trigger]) => {
            if (this.shouldTrigger(event, trigger)) {
                trigger.action();
            }
        });
    }

    shouldTrigger(event, trigger) {
        // Simple trigger logic - can be extended
        if (trigger.event === event.eventName) {
            if (trigger.condition) {
                return this.evaluateCondition(event, trigger.condition);
            }
            return true;
        }
        return false;
    }

    evaluateCondition(event, condition) {
        if (condition.value !== undefined) {
            return event.data && event.data.value >= condition.value;
        }
        return false;
    }

    evaluateUserSegments() {
        const metrics = this.calculateUserMetrics();
        
        Object.entries(this.config.segments).forEach(([segmentId, segment]) => {
            const meetsConditions = segment.conditions.every(condition => {
                const metricValue = metrics[condition.metric] || 0;
                
                switch (condition.operator) {
                    case '>': return metricValue > condition.value;
                    case '<': return metricValue < condition.value;
                    case '=': return metricValue === condition.value;
                    case '>=': return metricValue >= condition.value;
                    case '<=': return metricValue <= condition.value;
                    default: return false;
                }
            });

            if (meetsConditions && !this.userSegments.has(segmentId)) {
                this.userSegments.add(segmentId);
                
                this.trackCustomEvent({
                    eventName: 'segment_entered',
                    category: 'segmentation',
                    segmentId: segmentId,
                    segmentName: segment.name,
                    timestamp: Date.now()
                });
            }
        });
    }

    calculateUserMetrics() {
        const sessionStart = this.core.startTime;
        const sessionDuration = performance.now() - sessionStart;
        
        return {
            session_duration: sessionDuration,
            page_views: this.eventCounts.get('navigation:page_view') || 1,
            conversions: this.eventCounts.get('conversion:conversion') || 0,
            form_starts: this.eventCounts.get('form:form_start') || 0,
            form_submits: this.eventCounts.get('form:form_submit') || 0,
            clicks: this.eventCounts.get('interaction:click') || 0,
            scroll_events: this.eventCounts.get('scroll:scroll_depth') || 0
        };
    }

    // Utility methods
    getElementSelector(element) {
        if (element.id) return `#${element.id}`;
        if (element.className) return `.${element.className.split(' ')[0]}`;
        return element.tagName.toLowerCase();
    }

    isInternalLink(url) {
        try {
            const link = new URL(url);
            return link.hostname === window.location.hostname;
        } catch {
            return true; // Relative URLs are internal
        }
    }

    getFilenameFromUrl(url) {
        try {
            const pathname = new URL(url).pathname;
            return pathname.split('/').pop() || 'unknown';
        } catch {
            return 'unknown';
        }
    }

    getFileTypeFromUrl(url) {
        const filename = this.getFilenameFromUrl(url);
        const extension = filename.split('.').pop()?.toLowerCase();
        return extension || 'unknown';
    }

    bindEvents() {
        // Send queued events periodically
        setInterval(() => {
            this.flushEventQueue();
        }, 10000); // Every 10 seconds

        // Send events before page unload
        window.addEventListener('beforeunload', () => {
            this.flushEventQueue();
        });
    }

    flushEventQueue() {
        if (this.eventQueue.length === 0) return;

        // Send batch of events
        this.core.sendEvent('custom_events_batch', {
            events: this.eventQueue.splice(0, 50), // Send up to 50 events at once
            timestamp: Date.now()
        });
    }

    // Public API methods
    track(eventName, properties = {}) {
        this.trackCustomEvent({
            eventName: eventName,
            category: properties.category || 'custom',
            ...properties
        });
    }

    identify(userId, traits = {}) {
        this.trackCustomEvent({
            eventName: 'user_identify',
            category: 'user',
            userId: userId,
            traits: traits
        });
    }

    addCustomMetric(eventName, metricName, value) {
        if (!this.customMetrics.has(eventName)) {
            this.customMetrics.set(eventName, {});
        }
        this.customMetrics.get(eventName)[metricName] = value;
    }

    createSegment(segmentId, segmentConfig) {
        this.config.segments[segmentId] = segmentConfig;
    }

    createTrigger(triggerId, triggerConfig) {
        this.config.triggers[triggerId] = triggerConfig;
    }

    // Dashboard creation
    createCustomEventsDashboard(containerId) {
        const container = document.getElementById(containerId);
        if (!container) return;

        const metrics = this.calculateUserMetrics();
        const topEvents = this.getTopEvents();

        container.innerHTML = `
            <div class="custom-events-dashboard">
                <div class="dashboard-header">
                    <h2><i class="fas fa-chart-bar"></i> Custom Event Tracking</h2>
                    <div class="dashboard-controls">
                        <button id="trackTestEvent" class="btn-test">
                            <i class="fas fa-plus"></i> Track Test Event
                        </button>
                        <button id="clearEvents" class="btn-clear">
                            <i class="fas fa-trash"></i> Clear Data
                        </button>
                        <button id="refreshEvents" class="btn-refresh">
                            <i class="fas fa-sync-alt"></i> Refresh
                        </button>
                    </div>
                </div>

                <div class="events-metrics">
                    <div class="metric-cards">
                        <div class="metric-card">
                            <h3>Total Events</h3>
                            <div class="metric-value">${this.eventQueue.length + this.getTotalEventCount()}</div>
                        </div>
                        <div class="metric-card">
                            <h3>Event Types</h3>
                            <div class="metric-value">${this.eventCounts.size}</div>
                        </div>
                        <div class="metric-card">
                            <h3>User Segments</h3>
                            <div class="metric-value">${this.userSegments.size}</div>
                        </div>
                        <div class="metric-card">
                            <h3>Session Duration</h3>
                            <div class="metric-value">${Math.round(metrics.session_duration / 1000)}s</div>
                        </div>
                    </div>
                </div>

                <div class="events-breakdown">
                    <div class="breakdown-section">
                        <h3><i class="fas fa-list"></i> Top Events</h3>
                        <div class="events-list">
                            ${topEvents.map(([event, count]) => `
                                <div class="event-item">
                                    <span class="event-name">${event}</span>
                                    <span class="event-count">${count}</span>
                                </div>
                            `).join('')}
                        </div>
                    </div>

                    <div class="breakdown-section">
                        <h3><i class="fas fa-users"></i> User Segments</h3>
                        <div class="segments-list">
                            ${Array.from(this.userSegments).map(segmentId => `
                                <div class="segment-item active">
                                    <span class="segment-name">${this.config.segments[segmentId]?.name || segmentId}</span>
                                    <span class="segment-status">✓ Active</span>
                                </div>
                            `).join('')}
                            ${this.userSegments.size === 0 ? '<div class="no-segments">No segments matched</div>' : ''}
                        </div>
                    </div>
                </div>

                <div class="recent-events">
                    <h3><i class="fas fa-clock"></i> Recent Events</h3>
                    <div class="events-feed">
                        ${this.eventQueue.slice(-10).reverse().map(event => `
                            <div class="event-feed-item">
                                <div class="event-info">
                                    <span class="event-category">${event.category}</span>
                                    <span class="event-name">${event.eventName}</span>
                                </div>
                                <div class="event-time">${this.formatTime(event.timestamp)}</div>
                            </div>
                        `).join('')}
                        ${this.eventQueue.length === 0 ? '<div class="no-events">No recent events</div>' : ''}
                    </div>
                </div>

                <div class="event-triggers">
                    <h3><i class="fas fa-bolt"></i> Active Triggers</h3>
                    <div class="triggers-list">
                        ${Object.entries(this.config.triggers).map(([triggerId, trigger]) => `
                            <div class="trigger-item">
                                <span class="trigger-name">${triggerId}</span>
                                <span class="trigger-event">${trigger.event}</span>
                            </div>
                        `).join('')}
                    </div>
                </div>
            </div>
        `;

        this.bindCustomEventsDashboardEvents();
    }

    bindCustomEventsDashboardEvents() {
        const testBtn = document.getElementById('trackTestEvent');
        if (testBtn) {
            testBtn.addEventListener('click', () => {
                this.track('test_event', {
                    category: 'test',
                    value: Math.floor(Math.random() * 100),
                    timestamp: Date.now()
                });
                
                // Refresh dashboard
                setTimeout(() => {
                    this.createCustomEventsDashboard(testBtn.closest('.custom-events-dashboard').parentElement.id);
                }, 100);
            });
        }

        const clearBtn = document.getElementById('clearEvents');
        if (clearBtn) {
            clearBtn.addEventListener('click', () => {
                this.eventQueue = [];
                this.eventCounts.clear();
                this.createCustomEventsDashboard(clearBtn.closest('.custom-events-dashboard').parentElement.id);
            });
        }

        const refreshBtn = document.getElementById('refreshEvents');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.createCustomEventsDashboard(refreshBtn.closest('.custom-events-dashboard').parentElement.id);
            });
        }
    }

    getTopEvents() {
        return Array.from(this.eventCounts.entries())
            .sort((a, b) => b[1] - a[1])
            .slice(0, 10);
    }

    getTotalEventCount() {
        return Array.from(this.eventCounts.values()).reduce((sum, count) => sum + count, 0);
    }

    formatTime(timestamp) {
        return new Date(timestamp).toLocaleTimeString();
    }

    // Public API
    getEventQueue() {
        return this.eventQueue;
    }

    getEventCounts() {
        return this.eventCounts;
    }

    getUserSegments() {
        return Array.from(this.userSegments);
    }

    getCustomMetrics() {
        return this.customMetrics;
    }
}

// Register module
if (typeof window !== 'undefined') {
    window.CustomEventsModule = CustomEventsModule;
}