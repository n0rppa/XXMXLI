/**
 * XXMXLI User Analytics Module
 * Real-time metrics, interactive charts, date filtering
 */

class UserAnalyticsModule {
    constructor(core) {
        this.core = core;
        this.config = {
            updateInterval: 30000, // 30 seconds
            chartType: 'line',
            dateRange: 7, // days
            realtime: true
        };
        
        this.metrics = {
            pageViews: 0,
            uniqueVisitors: 0,
            bounceRate: 0,
            sessionDuration: 0,
            conversions: 0
        };
        
        this.charts = {};
        this.updateTimer = null;
    }

    async init() {
        await this.loadChartsLibrary();
        this.bindEvents();
        this.startRealtimeUpdates();
        
        if (this.core.config.debug) {
            console.log('📊 User Analytics module initialized');
        }
    }

    async loadChartsLibrary() {
        // Load Chart.js for interactive charts
        if (!window.Chart) {
            await this.core.loadScript('https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js');
        }
    }

    bindEvents() {
        // Track page views automatically
        this.core.on('page_view', (data) => {
            this.updateMetrics();
        });

        // Track user interactions
        document.addEventListener('click', (e) => {
            this.trackInteraction('click', {
                element: e.target.tagName,
                className: e.target.className,
                id: e.target.id,
                x: e.clientX,
                y: e.clientY
            });
        });

        // Track scroll depth
        let maxScroll = 0;
        window.addEventListener('scroll', () => {
            const scrollPercent = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100);
            if (scrollPercent > maxScroll) {
                maxScroll = scrollPercent;
                this.trackScrollDepth(scrollPercent);
            }
        });

        // Track session duration
        setInterval(() => {
            this.updateSessionDuration();
        }, 30000); // Update every 30 seconds
    }

    trackInteraction(type, data) {
        this.core.sendEvent('user_interaction', {
            interactionType: type,
            timestamp: Date.now(),
            ...data
        });
    }

    trackScrollDepth(percent) {
        // Only track meaningful scroll milestones
        const milestones = [25, 50, 75, 90, 100];
        if (milestones.includes(percent)) {
            this.core.sendEvent('scroll_depth', {
                percent: percent,
                timestamp: Date.now()
            });
        }
    }

    updateSessionDuration() {
        const duration = performance.now() - this.core.startTime;
        this.core.sendEvent('session_ping', {
            duration: Math.round(duration),
            timestamp: Date.now()
        });
    }

    startRealtimeUpdates() {
        if (this.config.realtime) {
            this.updateTimer = setInterval(() => {
                this.updateMetrics();
            }, this.config.updateInterval);
        }
    }

    async updateMetrics() {
        try {
            const response = await fetch(`${this.core.config.endpoint}user-analytics.php`);
            const data = await response.json();
            
            this.metrics = {
                ...this.metrics,
                ...data.metrics
            };

            this.updateDashboardMetrics();
            this.updateCharts(data.chartData);
            
        } catch (error) {
            console.error('❌ Failed to update metrics:', error);
        }
    }

    updateDashboardMetrics() {
        // Update metrics in any dashboard that exists
        const metricElements = {
            pageViews: document.getElementById('metric-page-views'),
            uniqueVisitors: document.getElementById('metric-unique-visitors'),
            bounceRate: document.getElementById('metric-bounce-rate'),
            sessionDuration: document.getElementById('metric-session-duration'),
            conversions: document.getElementById('metric-conversions')
        };

        Object.entries(metricElements).forEach(([key, element]) => {
            if (element) {
                element.textContent = this.formatMetric(key, this.metrics[key]);
            }
        });
    }

    formatMetric(type, value) {
        switch (type) {
            case 'bounceRate':
                return `${Math.round(value)}%`;
            case 'sessionDuration':
                return this.formatDuration(value);
            case 'pageViews':
            case 'uniqueVisitors':
            case 'conversions':
                return value.toLocaleString();
            default:
                return value;
        }
    }

    formatDuration(seconds) {
        const minutes = Math.floor(seconds / 60);
        const remainingSeconds = seconds % 60;
        return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
    }

    updateCharts(chartData) {
        if (!chartData) return;

        // Update page views chart
        this.updateChart('pageViewsChart', chartData.pageViews, 'Page Views');
        
        // Update unique visitors chart
        this.updateChart('uniqueVisitorsChart', chartData.uniqueVisitors, 'Unique Visitors');
        
        // Update bounce rate chart
        this.updateChart('bounceRateChart', chartData.bounceRate, 'Bounce Rate (%)');
    }

    updateChart(chartId, data, label) {
        const canvas = document.getElementById(chartId);
        if (!canvas) return;

        if (this.charts[chartId]) {
            // Update existing chart
            this.charts[chartId].data.labels = data.labels;
            this.charts[chartId].data.datasets[0].data = data.values;
            this.charts[chartId].update();
        } else {
            // Create new chart
            this.charts[chartId] = new Chart(canvas.getContext('2d'), {
                type: 'line',
                data: {
                    labels: data.labels,
                    datasets: [{
                        label: label,
                        data: data.values,
                        borderColor: '#00ff00',
                        backgroundColor: 'rgba(0, 255, 0, 0.1)',
                        borderWidth: 2,
                        fill: true,
                        tension: 0.4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            labels: {
                                color: '#00ff00',
                                font: {
                                    family: 'Courier New',
                                    size: 12
                                }
                            }
                        }
                    },
                    scales: {
                        x: {
                            ticks: {
                                color: '#00ff00',
                                font: {
                                    family: 'Courier New'
                                }
                            },
                            grid: {
                                color: 'rgba(0, 255, 0, 0.2)'
                            }
                        },
                        y: {
                            ticks: {
                                color: '#00ff00',
                                font: {
                                    family: 'Courier New'
                                }
                            },
                            grid: {
                                color: 'rgba(0, 255, 0, 0.2)'
                            }
                        }
                    }
                }
            });
        }
    }

    createDashboard(containerId) {
        const container = document.getElementById(containerId);
        if (!container) return;

        container.innerHTML = `
            <div class="analytics-dashboard">
                <div class="dashboard-header">
                    <h2><i class="fas fa-chart-line"></i> User Analytics</h2>
                    <div class="dashboard-controls">
                        <select id="dateRange">
                            <option value="1">Last 24 hours</option>
                            <option value="7" selected>Last 7 days</option>
                            <option value="30">Last 30 days</option>
                            <option value="90">Last 90 days</option>
                        </select>
                        <button id="exportData" class="btn-export">
                            <i class="fas fa-download"></i> Export
                        </button>
                        <button id="refreshData" class="btn-refresh">
                            <i class="fas fa-sync-alt"></i> Refresh
                        </button>
                    </div>
                </div>

                <div class="metrics-grid">
                    <div class="metric-card">
                        <div class="metric-icon"><i class="fas fa-eye"></i></div>
                        <div class="metric-content">
                            <h3>Page Views</h3>
                            <div class="metric-value" id="metric-page-views">0</div>
                        </div>
                    </div>
                    
                    <div class="metric-card">
                        <div class="metric-icon"><i class="fas fa-users"></i></div>
                        <div class="metric-content">
                            <h3>Unique Visitors</h3>
                            <div class="metric-value" id="metric-unique-visitors">0</div>
                        </div>
                    </div>
                    
                    <div class="metric-card">
                        <div class="metric-icon"><i class="fas fa-bounce"></i></div>
                        <div class="metric-content">
                            <h3>Bounce Rate</h3>
                            <div class="metric-value" id="metric-bounce-rate">0%</div>
                        </div>
                    </div>
                    
                    <div class="metric-card">
                        <div class="metric-icon"><i class="fas fa-clock"></i></div>
                        <div class="metric-content">
                            <h3>Avg Session</h3>
                            <div class="metric-value" id="metric-session-duration">0:00</div>
                        </div>
                    </div>
                    
                    <div class="metric-card">
                        <div class="metric-icon"><i class="fas fa-target"></i></div>
                        <div class="metric-content">
                            <h3>Conversions</h3>
                            <div class="metric-value" id="metric-conversions">0</div>
                        </div>
                    </div>
                </div>

                <div class="charts-grid">
                    <div class="chart-container">
                        <h3>Page Views Over Time</h3>
                        <canvas id="pageViewsChart"></canvas>
                    </div>
                    
                    <div class="chart-container">
                        <h3>Unique Visitors</h3>
                        <canvas id="uniqueVisitorsChart"></canvas>
                    </div>
                    
                    <div class="chart-container">
                        <h3>Bounce Rate Trend</h3>
                        <canvas id="bounceRateChart"></canvas>
                    </div>
                </div>

                <div class="real-time-section">
                    <h3><i class="fas fa-wifi"></i> Real-time Activity</h3>
                    <div id="realtimeActivity" class="realtime-feed">
                        <!-- Real-time events will be populated here -->
                    </div>
                </div>
            </div>
        `;

        this.bindDashboardEvents();
        this.updateMetrics();
    }

    bindDashboardEvents() {
        // Date range selector
        const dateRange = document.getElementById('dateRange');
        if (dateRange) {
            dateRange.addEventListener('change', (e) => {
                this.config.dateRange = parseInt(e.target.value);
                this.updateMetrics();
            });
        }

        // Export button
        const exportBtn = document.getElementById('exportData');
        if (exportBtn) {
            exportBtn.addEventListener('click', () => {
                this.exportData();
            });
        }

        // Refresh button
        const refreshBtn = document.getElementById('refreshData');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.updateMetrics();
            });
        }
    }

    async exportData() {
        try {
            const response = await fetch(`${this.core.config.endpoint}export-analytics.php?range=${this.config.dateRange}`);
            const blob = await response.blob();
            
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `analytics-export-${new Date().toISOString().split('T')[0]}.json`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);
            
        } catch (error) {
            console.error('❌ Export failed:', error);
        }
    }

    // Real-time activity feed
    addRealtimeActivity(event) {
        const feed = document.getElementById('realtimeActivity');
        if (!feed) return;

        const eventElement = document.createElement('div');
        eventElement.className = 'realtime-event';
        eventElement.innerHTML = `
            <div class="event-time">${new Date().toLocaleTimeString()}</div>
            <div class="event-description">${this.formatRealtimeEvent(event)}</div>
        `;

        feed.insertBefore(eventElement, feed.firstChild);

        // Keep only last 20 events
        while (feed.children.length > 20) {
            feed.removeChild(feed.lastChild);
        }
    }

    formatRealtimeEvent(event) {
        switch (event.type) {
            case 'page_view':
                return `📄 Page view: ${event.data.page}`;
            case 'conversion':
                return `🎯 Conversion: ${event.data.goal}`;
            case 'session_start':
                return `👤 New visitor from ${event.data.country || 'Unknown'}`;
            case 'error':
                return `❌ Error: ${event.data.message}`;
            default:
                return `ℹ️ ${event.type}`;
        }
    }

    destroy() {
        if (this.updateTimer) {
            clearInterval(this.updateTimer);
        }
        
        Object.values(this.charts).forEach(chart => {
            chart.destroy();
        });
        
        this.charts = {};
    }
}

// Register module
if (typeof window !== 'undefined') {
    window.UserAnalyticsModule = UserAnalyticsModule;
}