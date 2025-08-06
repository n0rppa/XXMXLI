/**
 * XXMXLI User Behavior Heatmaps Module
 * Click tracking, scroll depth analysis, mouse movement patterns
 */

class HeatmapsModule {
    constructor(core) {
        this.core = core;
        this.config = {
            clickTracking: true,
            scrollTracking: true,
            mouseMovement: true,
            formAnalytics: true,
            samplingRate: 0.1, // 10% of users
            maxDataPoints: 1000,
            heatmapResolution: { width: 1920, height: 1080 }
        };
        
        this.clickData = [];
        this.scrollData = [];
        this.mouseData = [];
        this.formData = [];
        this.isTracking = false;
        this.sessionStartTime = Date.now();
    }

    async init() {
        // Check if user should be tracked based on sampling rate
        if (Math.random() > this.config.samplingRate) {
            if (this.core.config.debug) {
                console.log('🔥 Heatmap tracking skipped due to sampling rate');
            }
            return;
        }

        this.isTracking = true;
        this.setupClickTracking();
        this.setupScrollTracking();
        this.setupMouseTracking();
        this.setupFormAnalytics();
        this.bindEvents();
        
        if (this.core.config.debug) {
            console.log('🔥 Heatmaps module initialized with tracking enabled');
        }
    }

    setupClickTracking() {
        if (!this.config.clickTracking || !this.isTracking) return;

        document.addEventListener('click', (e) => {
            this.recordClick(e);
        }, { passive: true });

        document.addEventListener('contextmenu', (e) => {
            this.recordClick(e, 'right-click');
        }, { passive: true });
    }

    recordClick(event, type = 'click') {
        const clickData = {
            type: type,
            x: event.clientX,
            y: event.clientY,
            pageX: event.pageX,
            pageY: event.pageY,
            timestamp: Date.now() - this.sessionStartTime,
            element: this.getElementInfo(event.target),
            viewport: {
                width: window.innerWidth,
                height: window.innerHeight
            },
            scroll: {
                x: window.scrollX,
                y: window.scrollY
            }
        };

        this.clickData.push(clickData);
        this.sendHeatmapData('click', clickData);

        // Limit data points to prevent memory issues
        if (this.clickData.length > this.config.maxDataPoints) {
            this.clickData = this.clickData.slice(-this.config.maxDataPoints);
        }
    }

    setupScrollTracking() {
        if (!this.config.scrollTracking || !this.isTracking) return;

        let scrollTimeout;
        let lastScrollY = window.scrollY;
        let scrollDirection = 'down';

        window.addEventListener('scroll', () => {
            clearTimeout(scrollTimeout);
            
            const currentScrollY = window.scrollY;
            scrollDirection = currentScrollY > lastScrollY ? 'down' : 'up';
            lastScrollY = currentScrollY;

            scrollTimeout = setTimeout(() => {
                this.recordScroll(scrollDirection);
            }, 150); // Debounce scroll events
        }, { passive: true });

        // Track scroll milestones
        this.setupScrollMilestones();
    }

    recordScroll(direction) {
        const scrollPercentage = Math.round(
            (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100
        );

        const scrollData = {
            scrollY: window.scrollY,
            scrollPercentage: Math.min(scrollPercentage, 100),
            direction: direction,
            timestamp: Date.now() - this.sessionStartTime,
            viewport: {
                width: window.innerWidth,
                height: window.innerHeight
            },
            documentHeight: document.body.scrollHeight
        };

        this.scrollData.push(scrollData);
        this.sendHeatmapData('scroll', scrollData);

        // Limit data points
        if (this.scrollData.length > this.config.maxDataPoints) {
            this.scrollData = this.scrollData.slice(-this.config.maxDataPoints);
        }
    }

    setupScrollMilestones() {
        const milestones = [25, 50, 75, 90, 100];
        const reachedMilestones = new Set();

        window.addEventListener('scroll', () => {
            const scrollPercentage = Math.round(
                (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100
            );

            milestones.forEach(milestone => {
                if (scrollPercentage >= milestone && !reachedMilestones.has(milestone)) {
                    reachedMilestones.add(milestone);
                    
                    this.core.sendEvent('heatmap_scroll', {
                        milestone: milestone,
                        timestamp: Date.now() - this.sessionStartTime,
                        timeToReach: Date.now() - this.sessionStartTime
                    });
                }
            });
        }, { passive: true });
    }

    setupMouseTracking() {
        if (!this.config.mouseMovement || !this.isTracking) return;

        let mouseTimeout;
        let isRecording = false;
        const recordingInterval = 500; // Record every 500ms during movement

        document.addEventListener('mousemove', (e) => {
            if (!isRecording) {
                isRecording = true;
                this.recordMouseMovement(e);
            }

            clearTimeout(mouseTimeout);
            mouseTimeout = setTimeout(() => {
                isRecording = false;
            }, recordingInterval);
        }, { passive: true });

        // Track mouse hover on important elements
        this.setupHoverTracking();
    }

    recordMouseMovement(event) {
        const mouseData = {
            x: event.clientX,
            y: event.clientY,
            pageX: event.pageX,
            pageY: event.pageY,
            timestamp: Date.now() - this.sessionStartTime,
            viewport: {
                width: window.innerWidth,
                height: window.innerHeight
            }
        };

        this.mouseData.push(mouseData);

        // Send mouse data in batches to reduce requests
        if (this.mouseData.length % 10 === 0) {
            this.sendHeatmapData('mouse_movement', {
                batch: this.mouseData.slice(-10)
            });
        }

        // Limit data points
        if (this.mouseData.length > this.config.maxDataPoints) {
            this.mouseData = this.mouseData.slice(-this.config.maxDataPoints);
        }
    }

    setupHoverTracking() {
        const importantSelectors = [
            'a', 'button', '.btn', '.link', '.menu-item',
            'img', '.gallery-item', '.card', '.product'
        ];

        importantSelectors.forEach(selector => {
            const elements = document.querySelectorAll(selector);
            
            elements.forEach(element => {
                let hoverStartTime;

                element.addEventListener('mouseenter', (e) => {
                    hoverStartTime = Date.now();
                }, { passive: true });

                element.addEventListener('mouseleave', (e) => {
                    if (hoverStartTime) {
                        const hoverDuration = Date.now() - hoverStartTime;
                        
                        this.core.sendEvent('heatmap_hover', {
                            element: this.getElementInfo(e.target),
                            duration: hoverDuration,
                            timestamp: Date.now() - this.sessionStartTime
                        });
                    }
                }, { passive: true });
            });
        });
    }

    setupFormAnalytics() {
        if (!this.config.formAnalytics || !this.isTracking) return;

        const forms = document.querySelectorAll('form');
        
        forms.forEach(form => {
            this.trackFormInteractions(form);
        });

        // Track dynamic forms
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                mutation.addedNodes.forEach((node) => {
                    if (node.nodeType === 1) { // Element node
                        const forms = node.querySelectorAll ? node.querySelectorAll('form') : [];
                        forms.forEach(form => this.trackFormInteractions(form));
                    }
                });
            });
        });

        observer.observe(document.body, { childList: true, subtree: true });
    }

    trackFormInteractions(form) {
        const formId = form.id || form.className || 'unnamed-form';
        const fields = form.querySelectorAll('input, textarea, select');

        fields.forEach((field, index) => {
            const fieldId = field.id || field.name || `field-${index}`;
            let focusStartTime;

            // Track field focus
            field.addEventListener('focus', (e) => {
                focusStartTime = Date.now();
                
                this.core.sendEvent('heatmap_form', {
                    action: 'focus',
                    formId: formId,
                    fieldId: fieldId,
                    fieldType: field.type || field.tagName.toLowerCase(),
                    timestamp: Date.now() - this.sessionStartTime
                });
            }, { passive: true });

            // Track field blur
            field.addEventListener('blur', (e) => {
                const focusDuration = focusStartTime ? Date.now() - focusStartTime : 0;
                
                this.core.sendEvent('heatmap_form', {
                    action: 'blur',
                    formId: formId,
                    fieldId: fieldId,
                    fieldType: field.type || field.tagName.toLowerCase(),
                    focusDuration: focusDuration,
                    hasValue: !!field.value,
                    valueLength: field.value ? field.value.length : 0,
                    timestamp: Date.now() - this.sessionStartTime
                });
            }, { passive: true });

            // Track field changes
            field.addEventListener('input', (e) => {
                this.core.sendEvent('heatmap_form', {
                    action: 'input',
                    formId: formId,
                    fieldId: fieldId,
                    fieldType: field.type || field.tagName.toLowerCase(),
                    valueLength: field.value ? field.value.length : 0,
                    timestamp: Date.now() - this.sessionStartTime
                });
            }, { passive: true });
        });

        // Track form submission
        form.addEventListener('submit', (e) => {
            const formData = new FormData(form);
            const filledFields = Array.from(formData.entries()).length;
            const totalFields = fields.length;

            this.core.sendEvent('heatmap_form', {
                action: 'submit',
                formId: formId,
                filledFields: filledFields,
                totalFields: totalFields,
                completionRate: (filledFields / totalFields) * 100,
                timestamp: Date.now() - this.sessionStartTime
            });
        }, { passive: true });
    }

    getElementInfo(element) {
        return {
            tagName: element.tagName.toLowerCase(),
            id: element.id || null,
            className: element.className || null,
            text: element.textContent ? element.textContent.trim().substring(0, 100) : null,
            href: element.href || null,
            position: this.getElementPosition(element)
        };
    }

    getElementPosition(element) {
        const rect = element.getBoundingClientRect();
        return {
            left: rect.left + window.scrollX,
            top: rect.top + window.scrollY,
            width: rect.width,
            height: rect.height
        };
    }

    sendHeatmapData(type, data) {
        this.core.sendEvent(`heatmap_${type}`, data);
    }

    bindEvents() {
        // Send accumulated data before page unload
        window.addEventListener('beforeunload', () => {
            this.sendSessionSummary();
        });

        // Send data periodically
        setInterval(() => {
            this.sendPeriodicUpdate();
        }, 30000); // Every 30 seconds
    }

    sendSessionSummary() {
        if (!this.isTracking) return;

        const summary = {
            sessionDuration: Date.now() - this.sessionStartTime,
            totalClicks: this.clickData.length,
            totalScrollEvents: this.scrollData.length,
            totalMouseMovements: this.mouseData.length,
            maxScrollDepth: Math.max(...this.scrollData.map(s => s.scrollPercentage), 0),
            clickHeatmap: this.generateClickHeatmap(),
            scrollHeatmap: this.generateScrollHeatmap()
        };

        this.core.sendEvent('heatmap_session_summary', summary);
    }

    sendPeriodicUpdate() {
        if (!this.isTracking) return;

        const update = {
            timestamp: Date.now() - this.sessionStartTime,
            recentClicks: this.clickData.slice(-10),
            currentScroll: window.scrollY,
            currentScrollPercentage: Math.round(
                (window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100
            )
        };

        this.core.sendEvent('heatmap_update', update);
    }

    generateClickHeatmap() {
        const resolution = this.config.heatmapResolution;
        const cellSize = 50; // 50x50 pixel cells
        const grid = {};

        this.clickData.forEach(click => {
            // Normalize coordinates to standard resolution
            const normalizedX = Math.floor((click.pageX / click.viewport.width) * resolution.width);
            const normalizedY = Math.floor((click.pageY / document.body.scrollHeight) * resolution.height);
            
            // Grid cell coordinates
            const cellX = Math.floor(normalizedX / cellSize);
            const cellY = Math.floor(normalizedY / cellSize);
            const cellKey = `${cellX},${cellY}`;

            grid[cellKey] = (grid[cellKey] || 0) + 1;
        });

        return grid;
    }

    generateScrollHeatmap() {
        const sections = {};
        const sectionHeight = 100; // 100px sections

        this.scrollData.forEach(scroll => {
            const section = Math.floor(scroll.scrollY / sectionHeight);
            sections[section] = (sections[section] || 0) + 1;
        });

        return sections;
    }

    // Heatmap visualization
    createHeatmapDashboard(containerId) {
        const container = document.getElementById(containerId);
        if (!container) return;

        container.innerHTML = `
            <div class="heatmap-dashboard">
                <div class="dashboard-header">
                    <h2><i class="fas fa-fire"></i> User Behavior Heatmaps</h2>
                    <div class="dashboard-controls">
                        <button id="toggleHeatmap" class="btn-toggle">
                            <i class="fas fa-eye"></i> ${this.isTracking ? 'Hide' : 'Show'} Tracking
                        </button>
                        <button id="exportHeatmap" class="btn-export">
                            <i class="fas fa-download"></i> Export Data
                        </button>
                        <button id="refreshHeatmap" class="btn-refresh">
                            <i class="fas fa-sync-alt"></i> Refresh
                        </button>
                    </div>
                </div>

                <div class="heatmap-status">
                    <div class="status-card">
                        <h3>Tracking Status</h3>
                        <div class="status-indicator ${this.isTracking ? 'active' : 'inactive'}">
                            ${this.isTracking ? '🔥 Active' : '⏸️ Inactive'}
                        </div>
                        <div class="status-details">
                            ${this.isTracking ? 
                                `Sampling Rate: ${(this.config.samplingRate * 100).toFixed(1)}%` :
                                'Not tracking due to sampling'
                            }
                        </div>
                    </div>

                    <div class="status-card">
                        <h3>Session Data</h3>
                        <div class="data-stats">
                            <div class="stat-item">
                                <span class="stat-label">Clicks:</span>
                                <span class="stat-value">${this.clickData.length}</span>
                            </div>
                            <div class="stat-item">
                                <span class="stat-label">Scroll Events:</span>
                                <span class="stat-value">${this.scrollData.length}</span>
                            </div>
                            <div class="stat-item">
                                <span class="stat-label">Mouse Movements:</span>
                                <span class="stat-value">${this.mouseData.length}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="heatmap-visualizations">
                    <div class="viz-section">
                        <h3><i class="fas fa-mouse-pointer"></i> Click Heatmap</h3>
                        <div id="click-heatmap" class="heatmap-container">
                            ${this.renderClickHeatmap()}
                        </div>
                    </div>

                    <div class="viz-section">
                        <h3><i class="fas fa-arrows-alt-v"></i> Scroll Depth</h3>
                        <div id="scroll-heatmap" class="heatmap-container">
                            ${this.renderScrollDepthChart()}
                        </div>
                    </div>

                    <div class="viz-section">
                        <h3><i class="fas fa-chart-line"></i> Mouse Movement</h3>
                        <div id="mouse-heatmap" class="heatmap-container">
                            ${this.renderMouseTrails()}
                        </div>
                    </div>

                    ${this.formData.length > 0 ? `
                    <div class="viz-section">
                        <h3><i class="fas fa-wpforms"></i> Form Analytics</h3>
                        <div id="form-analytics" class="heatmap-container">
                            ${this.renderFormAnalytics()}
                        </div>
                    </div>
                    ` : ''}
                </div>

                <div class="heatmap-insights">
                    <h3><i class="fas fa-lightbulb"></i> Insights</h3>
                    <div id="heatmap-insights" class="insights-list">
                        ${this.generateInsights()}
                    </div>
                </div>
            </div>
        `;

        this.bindHeatmapDashboardEvents();
    }

    renderClickHeatmap() {
        if (this.clickData.length === 0) {
            return '<div class="no-data">No click data available</div>';
        }

        const clickHeatmap = this.generateClickHeatmap();
        const maxClicks = Math.max(...Object.values(clickHeatmap));

        return `
            <div class="heatmap-legend">
                <span>Low</span>
                <div class="legend-gradient"></div>
                <span>High</span>
            </div>
            <div class="click-summary">
                <strong>Total Clicks:</strong> ${this.clickData.length}<br>
                <strong>Hottest Spot:</strong> ${maxClicks} clicks<br>
                <strong>Coverage:</strong> ${Object.keys(clickHeatmap).length} areas
            </div>
        `;
    }

    renderScrollDepthChart() {
        if (this.scrollData.length === 0) {
            return '<div class="no-data">No scroll data available</div>';
        }

        const maxDepth = Math.max(...this.scrollData.map(s => s.scrollPercentage));
        const avgDepth = this.scrollData.reduce((sum, s) => sum + s.scrollPercentage, 0) / this.scrollData.length;

        return `
            <div class="scroll-stats">
                <div class="scroll-bar">
                    <div class="scroll-progress" style="height: ${maxDepth}%"></div>
                    <div class="scroll-average" style="top: ${100-avgDepth}%"></div>
                </div>
                <div class="scroll-details">
                    <div><strong>Max Depth:</strong> ${maxDepth.toFixed(1)}%</div>
                    <div><strong>Avg Depth:</strong> ${avgDepth.toFixed(1)}%</div>
                    <div><strong>Total Scrolls:</strong> ${this.scrollData.length}</div>
                </div>
            </div>
        `;
    }

    renderMouseTrails() {
        if (this.mouseData.length === 0) {
            return '<div class="no-data">No mouse movement data available</div>';
        }

        return `
            <div class="mouse-summary">
                <div><strong>Movement Points:</strong> ${this.mouseData.length}</div>
                <div><strong>Session Duration:</strong> ${Math.round((Date.now() - this.sessionStartTime) / 1000)}s</div>
                <div><strong>Avg Movements/min:</strong> ${Math.round((this.mouseData.length / ((Date.now() - this.sessionStartTime) / 60000)))}</div>
            </div>
        `;
    }

    renderFormAnalytics() {
        return '<div class="form-placeholder">Form analytics data will be displayed here</div>';
    }

    generateInsights() {
        const insights = [];

        // Click insights
        if (this.clickData.length > 0) {
            const avgClickY = this.clickData.reduce((sum, c) => sum + c.pageY, 0) / this.clickData.length;
            const documentHeight = document.body.scrollHeight;
            const clickConcentration = (avgClickY / documentHeight) * 100;

            if (clickConcentration < 30) {
                insights.push('👆 Most clicks are concentrated in the upper third of the page');
            } else if (clickConcentration > 70) {
                insights.push('👇 Users are clicking more towards the bottom of the page');
            }
        }

        // Scroll insights
        if (this.scrollData.length > 0) {
            const maxScroll = Math.max(...this.scrollData.map(s => s.scrollPercentage));
            
            if (maxScroll < 50) {
                insights.push('📊 Users are not scrolling much - consider moving important content higher');
            } else if (maxScroll > 90) {
                insights.push('📜 Users are engaging with content throughout the entire page');
            }
        }

        // General insights
        if (this.isTracking) {
            const sessionMinutes = (Date.now() - this.sessionStartTime) / 60000;
            const clicksPerMinute = this.clickData.length / sessionMinutes;
            
            if (clicksPerMinute > 5) {
                insights.push('🎯 High click activity - users are actively engaging');
            } else if (clicksPerMinute < 1) {
                insights.push('🤔 Low click activity - consider making CTAs more prominent');
            }
        }

        if (insights.length === 0) {
            insights.push('📈 Collect more data to generate actionable insights');
        }

        return insights.map(insight => `<div class="insight-item">${insight}</div>`).join('');
    }

    bindHeatmapDashboardEvents() {
        const toggleBtn = document.getElementById('toggleHeatmap');
        if (toggleBtn) {
            toggleBtn.addEventListener('click', () => {
                // This would typically toggle tracking, but for demo purposes we'll just update the display
                console.log('Toggle heatmap tracking');
            });
        }

        const exportBtn = document.getElementById('exportHeatmap');
        if (exportBtn) {
            exportBtn.addEventListener('click', () => {
                this.exportHeatmapData();
            });
        }

        const refreshBtn = document.getElementById('refreshHeatmap');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.createHeatmapDashboard(refreshBtn.closest('.heatmap-dashboard').parentElement.id);
            });
        }
    }

    exportHeatmapData() {
        const data = {
            session: {
                startTime: this.sessionStartTime,
                duration: Date.now() - this.sessionStartTime,
                url: window.location.href,
                userAgent: navigator.userAgent
            },
            clicks: this.clickData,
            scrolls: this.scrollData,
            mouseMovements: this.mouseData.slice(-100), // Limit mouse data for export
            summary: {
                totalClicks: this.clickData.length,
                totalScrolls: this.scrollData.length,
                maxScrollDepth: Math.max(...this.scrollData.map(s => s.scrollPercentage), 0),
                clickHeatmap: this.generateClickHeatmap(),
                scrollHeatmap: this.generateScrollHeatmap()
            }
        };

        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `heatmap-data-${new Date().toISOString().slice(0, 10)}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    // Public API methods
    getClickData() {
        return this.clickData;
    }

    getScrollData() {
        return this.scrollData;
    }

    getMouseData() {
        return this.mouseData.slice(-100); // Return recent data only
    }

    isTrackingEnabled() {
        return this.isTracking;
    }
}

// Register module
if (typeof window !== 'undefined') {
    window.HeatmapsModule = HeatmapsModule;
}