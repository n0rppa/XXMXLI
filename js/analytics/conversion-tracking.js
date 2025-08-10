/**
 * XXMXLI Conversion Tracking Module
 * Goal-based conversion funnels, custom event tracking, ROI calculations
 */

class ConversionTrackingModule {
    constructor(core) {
        this.core = core;
        this.config = {
            goals: {
                'contact_form': {
                    name: 'Contact Form Submission',
                    selector: '#contact-form',
                    event: 'submit',
                    value: 10
                },
                'newsletter_signup': {
                    name: 'Newsletter Signup',
                    selector: '.newsletter-form',
                    event: 'submit',
                    value: 5
                },
                'download': {
                    name: 'File Download',
                    selector: '[download]',
                    event: 'click',
                    value: 1
                },
                'external_link': {
                    name: 'External Link Click',
                    selector: 'a[href^="http"]:not([href*="xxmxli.com"])',
                    event: 'click',
                    value: 1
                },
                'gallery_view': {
                    name: 'Gallery View',
                    selector: '.gallery-item',
                    event: 'click',
                    value: 2
                },
                'music_play': {
                    name: 'Music Play',
                    selector: '.play-button',
                    event: 'click',
                    value: 3
                }
            },
            funnels: {
                'engagement': {
                    name: 'User Engagement Funnel',
                    steps: ['page_view', 'gallery_view', 'music_play', 'contact_form']
                },
                'content': {
                    name: 'Content Consumption Funnel',
                    steps: ['page_view', 'gallery_view', 'download']
                }
            }
        };
        
        this.activeGoals = new Set();
        this.userFunnels = new Map();
        this.conversionQueue = [];
    }

    async init() {
        this.setupGoalTracking();
        this.bindEvents();
        this.initializeFunnels();
        
        if (this.core.config.debug) {
            console.log('🎯 Conversion tracking module initialized');
        }
    }

    setupGoalTracking() {
        // Set up automatic goal tracking
        Object.entries(this.config.goals).forEach(([goalId, goal]) => {
            const elements = document.querySelectorAll(goal.selector);
            
            elements.forEach(element => {
                element.addEventListener(goal.event, (e) => {
                    this.trackConversion(goalId, {
                        element: goal.selector,
                        value: goal.value,
                        elementText: element.textContent?.trim().substring(0, 100) || '',
                        elementHref: element.href || '',
                        timestamp: Date.now()
                    });
                });
            });

            if (elements.length > 0) {
                this.activeGoals.add(goalId);
                if (this.core.config.debug) {
                    console.log(`🎯 Goal tracking setup: ${goal.name} (${elements.length} elements)`);
                }
            }
        });
    }

    bindEvents() {
        // Track page views for funnel analysis
        this.core.on('page_view', (data) => {
            this.trackFunnelStep('page_view', data);
        });

        // Set up mutation observer for dynamic content
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.type === 'childList') {
                    this.setupGoalTracking(); // Re-setup for new elements
                }
            });
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    initializeFunnels() {
        // Initialize funnel tracking for current user
        Object.entries(this.config.funnels).forEach(([funnelId, funnel]) => {
            this.userFunnels.set(funnelId, {
                steps: [],
                currentStep: 0,
                startTime: Date.now(),
                lastActivity: Date.now()
            });
        });
    }

    trackConversion(goalId, data = {}) {
        const goal = this.config.goals[goalId];
        if (!goal) return;

        const conversionData = {
            goalId: goalId,
            goalName: goal.name,
            value: goal.value,
            timestamp: Date.now(),
            url: window.location.href,
            page: document.title,
            ...data
        };

        // Send conversion event
        this.core.sendEvent('conversion', conversionData);

        // Track in funnels
        this.trackFunnelStep(goalId, conversionData);

        // Queue for batch processing
        this.conversionQueue.push(conversionData);

        // Show conversion notification if debug mode
        if (this.core.config.debug) {
            this.showConversionNotification(goal.name, goal.value);
        }

        // Trigger conversion event for other modules
        this.core.emit('conversion', conversionData);
    }

    trackFunnelStep(stepId, data = {}) {
        Object.entries(this.config.funnels).forEach(([funnelId, funnel]) => {
            if (funnel.steps.includes(stepId)) {
                const userFunnel = this.userFunnels.get(funnelId);
                if (!userFunnel) return;

                const stepIndex = funnel.steps.indexOf(stepId);
                
                // Check if this is the next expected step
                if (stepIndex === userFunnel.currentStep) {
                    userFunnel.steps.push({
                        stepId: stepId,
                        timestamp: Date.now(),
                        data: data
                    });
                    userFunnel.currentStep++;
                    userFunnel.lastActivity = Date.now();

                    // Send funnel progress event
                    this.core.sendEvent('funnel_progress', {
                        funnelId: funnelId,
                        funnelName: funnel.name,
                        step: stepIndex + 1,
                        totalSteps: funnel.steps.length,
                        stepId: stepId,
                        completed: userFunnel.currentStep === funnel.steps.length,
                        duration: Date.now() - userFunnel.startTime
                    });

                    if (this.core.config.debug) {
                        console.log(`📊 Funnel progress: ${funnel.name} - Step ${stepIndex + 1}/${funnel.steps.length}`);
                    }
                }
            }
        });
    }

    showConversionNotification(goalName, value) {
        const notification = document.createElement('div');
        notification.className = 'conversion-notification';
        notification.innerHTML = `
            <div class="notification-content">
                <i class="fas fa-target"></i>
                <span>Goal: ${goalName}</span>
                <span class="value">+${value}</span>
            </div>
        `;

        // Style the notification
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: rgba(0, 255, 0, 0.1);
            border: 1px solid #00ff00;
            color: #00ff00;
            padding: 15px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            z-index: 10000;
            animation: slideInRight 0.5s ease-out;
        `;

        document.body.appendChild(notification);

        // Remove after 3 seconds
        setTimeout(() => {
            notification.style.animation = 'slideOutRight 0.5s ease-out';
            setTimeout(() => notification.remove(), 500);
        }, 3000);
    }

    // Custom goal creation
    createCustomGoal(goalId, config) {
        this.config.goals[goalId] = {
            name: config.name || goalId,
            selector: config.selector,
            event: config.event || 'click',
            value: config.value || 1,
            custom: true
        };

        this.setupGoalTracking();
        
        if (this.core.config.debug) {
            console.log(`🎯 Custom goal created: ${config.name}`);
        }
    }

    // ROI Calculations
    calculateROI(timeframe = 30) {
        const endDate = new Date();
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - timeframe);

        return new Promise(async (resolve) => {
            try {
                const response = await fetch(`${this.core.config.endpoint}conversion-analytics.php?from=${startDate.toISOString()}&to=${endDate.toISOString()}`);
                const data = await response.json();

                if (data.status === 'success') {
                    resolve(data.roi);
                } else {
                    resolve(null);
                }
            } catch (error) {
                console.error('❌ ROI calculation failed:', error);
                resolve(null);
            }
        });
    }

    // Funnel analysis
    async getFunnelAnalysis(funnelId = null) {
        try {
            const url = funnelId 
                ? `${this.core.config.endpoint}funnel-analysis.php?funnel=${funnelId}`
                : `${this.core.config.endpoint}funnel-analysis.php`;
                
            const response = await fetch(url);
            const data = await response.json();

            return data.status === 'success' ? data.analysis : null;
        } catch (error) {
            console.error('❌ Funnel analysis failed:', error);
            return null;
        }
    }

    // Conversion dashboard creation
    createConversionDashboard(containerId) {
        const container = document.getElementById(containerId);
        if (!container) return;

        container.innerHTML = `
            <div class="conversion-dashboard">
                <div class="dashboard-header">
                    <h2><i class="fas fa-target"></i> Conversion Tracking</h2>
                    <div class="dashboard-controls">
                        <select id="conversionTimeframe">
                            <option value="1">Last 24 hours</option>
                            <option value="7" selected>Last 7 days</option>
                            <option value="30">Last 30 days</option>
                        </select>
                        <button id="refreshConversions" class="btn-refresh">
                            <i class="fas fa-sync-alt"></i> Refresh
                        </button>
                    </div>
                </div>

                <div class="conversion-metrics">
                    <div class="metric-card">
                        <div class="metric-icon"><i class="fas fa-bullseye"></i></div>
                        <div class="metric-content">
                            <h3>Total Conversions</h3>
                            <div class="metric-value" id="total-conversions">0</div>
                        </div>
                    </div>
                    
                    <div class="metric-card">
                        <div class="metric-icon"><i class="fas fa-percent"></i></div>
                        <div class="metric-content">
                            <h3>Conversion Rate</h3>
                            <div class="metric-value" id="conversion-rate">0%</div>
                        </div>
                    </div>
                    
                    <div class="metric-card">
                        <div class="metric-icon"><i class="fas fa-dollar-sign"></i></div>
                        <div class="metric-content">
                            <h3>Total Value</h3>
                            <div class="metric-value" id="total-value">0</div>
                        </div>
                    </div>
                </div>

                <div class="conversion-goals">
                    <h3><i class="fas fa-list"></i> Active Goals</h3>
                    <div id="goals-list" class="goals-grid">
                        <!-- Goals will be populated here -->
                    </div>
                </div>

                <div class="conversion-funnels">
                    <h3><i class="fas fa-filter"></i> Conversion Funnels</h3>
                    <div id="funnels-container">
                        <!-- Funnels will be populated here -->
                    </div>
                </div>

                <div class="recent-conversions">
                    <h3><i class="fas fa-clock"></i> Recent Conversions</h3>
                    <div id="recent-conversions-list" class="conversions-feed">
                        <!-- Recent conversions will be populated here -->
                    </div>
                </div>
            </div>
        `;

        this.updateConversionDashboard();
        this.bindDashboardEvents();
    }

    bindDashboardEvents() {
        const timeframeSelect = document.getElementById('conversionTimeframe');
        if (timeframeSelect) {
            timeframeSelect.addEventListener('change', () => {
                this.updateConversionDashboard();
            });
        }

        const refreshBtn = document.getElementById('refreshConversions');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.updateConversionDashboard();
            });
        }
    }

    async updateConversionDashboard() {
        try {
            const timeframe = document.getElementById('conversionTimeframe')?.value || 7;
            const response = await fetch(`${this.core.config.endpoint}conversion-analytics.php?days=${timeframe}`);
            const data = await response.json();

            if (data.status === 'success') {
                this.updateConversionMetrics(data.metrics);
                this.updateGoalsList(data.goals);
                this.updateFunnelsList(data.funnels);
                this.updateRecentConversions(data.recent);
            }
        } catch (error) {
            console.error('❌ Failed to update conversion dashboard:', error);
        }
    }

    updateConversionMetrics(metrics) {
        const elements = {
            'total-conversions': metrics.totalConversions || 0,
            'conversion-rate': `${(metrics.conversionRate || 0).toFixed(2)}%`,
            'total-value': metrics.totalValue || 0
        };

        Object.entries(elements).forEach(([id, value]) => {
            const element = document.getElementById(id);
            if (element) {
                element.textContent = value;
            }
        });
    }

    updateGoalsList(goals) {
        const goalsContainer = document.getElementById('goals-list');
        if (!goalsContainer) return;

        goalsContainer.innerHTML = Object.entries(this.config.goals).map(([goalId, goal]) => {
            const goalStats = goals[goalId] || { conversions: 0, value: 0 };
            const isActive = this.activeGoals.has(goalId);

            return `
                <div class="goal-card ${isActive ? 'active' : 'inactive'}">
                    <div class="goal-header">
                        <h4>${goal.name}</h4>
                        <div class="goal-status ${isActive ? 'active' : 'inactive'}">
                            ${isActive ? 'Active' : 'Inactive'}
                        </div>
                    </div>
                    <div class="goal-stats">
                        <div class="stat">
                            <span class="stat-label">Conversions:</span>
                            <span class="stat-value">${goalStats.conversions}</span>
                        </div>
                        <div class="stat">
                            <span class="stat-label">Value:</span>
                            <span class="stat-value">${goalStats.value}</span>
                        </div>
                    </div>
                    <div class="goal-details">
                        <div class="detail">Selector: <code>${goal.selector}</code></div>
                        <div class="detail">Event: <code>${goal.event}</code></div>
                    </div>
                </div>
            `;
        }).join('');
    }

    updateFunnelsList(funnels) {
        const funnelsContainer = document.getElementById('funnels-container');
        if (!funnelsContainer) return;

        funnelsContainer.innerHTML = Object.entries(this.config.funnels).map(([funnelId, funnel]) => {
            const funnelStats = funnels[funnelId] || { completions: 0, dropoffRate: 100 };

            return `
                <div class="funnel-card">
                    <h4>${funnel.name}</h4>
                    <div class="funnel-steps">
                        ${funnel.steps.map((step, index) => `
                            <div class="funnel-step">
                                <div class="step-number">${index + 1}</div>
                                <div class="step-name">${step}</div>
                            </div>
                        `).join('<div class="step-arrow">→</div>')}
                    </div>
                    <div class="funnel-stats">
                        <div class="stat">
                            <span class="stat-label">Completions:</span>
                            <span class="stat-value">${funnelStats.completions}</span>
                        </div>
                        <div class="stat">
                            <span class="stat-label">Drop-off Rate:</span>
                            <span class="stat-value">${funnelStats.dropoffRate.toFixed(1)}%</span>
                        </div>
                    </div>
                </div>
            `;
        }).join('');
    }

    updateRecentConversions(recent) {
        const recentContainer = document.getElementById('recent-conversions-list');
        if (!recentContainer) return;

        recentContainer.innerHTML = recent.slice(0, 10).map(conversion => `
            <div class="conversion-item">
                <div class="conversion-info">
                    <div class="conversion-goal">${conversion.goalName}</div>
                    <div class="conversion-time">${this.formatTimeAgo(conversion.timestamp)}</div>
                </div>
                <div class="conversion-value">+${conversion.value}</div>
            </div>
        `).join('');
    }

    formatTimeAgo(timestamp) {
        const seconds = Math.floor((Date.now() - new Date(timestamp).getTime()) / 1000);
        
        if (seconds < 60) return `${seconds}s ago`;
        if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
        if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
        return `${Math.floor(seconds / 86400)}d ago`;
    }

    // Public API methods
    getActiveGoals() {
        return Array.from(this.activeGoals);
    }

    getUserFunnelProgress(funnelId) {
        return this.userFunnels.get(funnelId);
    }

    getAllFunnelProgress() {
        return Object.fromEntries(this.userFunnels);
    }
}

// Register module
if (typeof window !== 'undefined') {
    window.ConversionTrackingModule = ConversionTrackingModule;
}