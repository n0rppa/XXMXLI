/**
 * XXMXLI Data Tracker v1.0
 * Dedicated data collection and analysis system
 * 
 * Features:
 * - Custom data collection with flexible schemas
 * - Real-time data processing and analytics
 * - Data export and visualization tools
 * - Event tracking with custom metrics
 * - Performance data monitoring
 * - User behavior analytics
 * - Data filtering and search capabilities
 * - Automated data backup and storage
 * 
 * Usage: <script src="data-tracker.js"></script>
 */

(function() {
    'use strict';
    
    class XXMXLIDataTracker {
        constructor(options = {}) {
            this.options = {
                apiKey: options.apiKey || 'xxmxli-data-tracker',
                storageKey: options.storageKey || 'xxmxli_data_tracker',
                maxDataPoints: options.maxDataPoints || 10000,
                autoSave: options.autoSave !== false,
                enableConsoleLog: options.enableConsoleLog !== false,
                enableRealTimeAnalytics: options.enableRealTimeAnalytics !== false,
                enableDataVisualization: options.enableDataVisualization !== false,
                enableAutoBackup: options.enableAutoBackup !== false,
                backupInterval: options.backupInterval || 300000, // 5 minutes
                compressionEnabled: options.compressionEnabled !== false,
                encryptionKey: options.encryptionKey || null,
                customSchemas: options.customSchemas || {},
                dataRetentionDays: options.dataRetentionDays || 90,
                realTimeUpdateInterval: options.realTimeUpdateInterval || 1000,
                ...options
            };
            
            this.data = [];
            this.schemas = {};
            this.analytics = {};
            this.filters = {};
            this.isTracking = false;
            this.startTime = Date.now();
            this.lastBackup = null;
            this.dataChangeListeners = [];
            this.realTimeAnalytics = {};
            
            // Performance metrics
            this.performanceData = {
                collections: 0,
                processingTime: 0,
                memoryUsage: 0,
                errors: []
            };
            
            // Event queues
            this.eventQueue = [];
            this.processingQueue = [];
            
            this.init();
        }
        
        async init() {
            try {
                this.loadData();
                this.setupSchemas();
                this.startRealTimeAnalytics();
                this.setupAutoBackup();
                this.setupDashboard();
                
                this.isTracking = true;
                
                if (this.options.enableConsoleLog) {
                    console.log('🔍 XXMXLI Data Tracker initialized', {
                        dataPoints: this.data.length,
                        schemas: Object.keys(this.schemas).length,
                        features: this.getEnabledFeatures()
                    });
                }
                
                this.trackEvent('system', 'tracker_initialized', {
                    timestamp: Date.now(),
                    config: this.options
                });
                
            } catch (error) {
                console.error('Failed to initialize data tracker:', error);
                this.performanceData.errors.push({
                    type: 'initialization_error',
                    message: error.message,
                    timestamp: Date.now()
                });
            }
        }
        
        getEnabledFeatures() {
            return Object.keys(this.options)
                .filter(key => key.startsWith('enable') && this.options[key])
                .map(key => key.replace('enable', '').toLowerCase());
        }
        
        setupSchemas() {
            // Default data schemas
            this.schemas = {
                event: {
                    id: 'string',
                    category: 'string',
                    action: 'string',
                    label: 'string',
                    value: 'number',
                    timestamp: 'number',
                    sessionId: 'string',
                    userId: 'string',
                    metadata: 'object'
                },
                performance: {
                    id: 'string',
                    metric: 'string',
                    value: 'number',
                    unit: 'string',
                    timestamp: 'number',
                    context: 'object'
                },
                user_action: {
                    id: 'string',
                    action: 'string',
                    element: 'string',
                    coordinates: 'object',
                    timestamp: 'number',
                    duration: 'number',
                    metadata: 'object'
                },
                custom: {
                    id: 'string',
                    type: 'string',
                    data: 'object',
                    timestamp: 'number',
                    tags: 'array'
                },
                ...this.options.customSchemas
            };
        }
        
        startRealTimeAnalytics() {
            if (!this.options.enableRealTimeAnalytics) return;
            
            setInterval(() => {
                this.updateRealTimeAnalytics();
                this.notifyDataChangeListeners();
            }, this.options.realTimeUpdateInterval);
        }
        
        updateRealTimeAnalytics() {
            const now = Date.now();
            const last24h = now - (24 * 60 * 60 * 1000);
            const lastHour = now - (60 * 60 * 1000);
            const last5min = now - (5 * 60 * 1000);
            
            const recentData = this.data.filter(item => item.timestamp > last24h);
            const hourlyData = this.data.filter(item => item.timestamp > lastHour);
            const recentActivity = this.data.filter(item => item.timestamp > last5min);
            
            this.realTimeAnalytics = {
                total: this.data.length,
                last24h: recentData.length,
                lastHour: hourlyData.length,
                last5min: recentActivity.length,
                categoriesLast24h: this.getCategoryBreakdown(recentData),
                topActions: this.getTopActions(recentData),
                performanceMetrics: this.calculatePerformanceMetrics(),
                dataRate: this.calculateDataRate(),
                memoryUsage: this.estimateMemoryUsage(),
                lastUpdated: now
            };
        }
        
        getCategoryBreakdown(data) {
            const breakdown = {};
            data.forEach(item => {
                const category = item.category || 'uncategorized';
                breakdown[category] = (breakdown[category] || 0) + 1;
            });
            return breakdown;
        }
        
        getTopActions(data) {
            const actions = {};
            data.forEach(item => {
                if (item.action) {
                    actions[item.action] = (actions[item.action] || 0) + 1;
                }
            });
            
            return Object.entries(actions)
                .sort(([,a], [,b]) => b - a)
                .slice(0, 10)
                .map(([action, count]) => ({ action, count }));
        }
        
        calculatePerformanceMetrics() {
            const avgProcessingTime = this.performanceData.processingTime / Math.max(1, this.performanceData.collections);
            
            return {
                collections: this.performanceData.collections,
                avgProcessingTime: Math.round(avgProcessingTime * 100) / 100,
                memoryUsage: this.performanceData.memoryUsage,
                errorCount: this.performanceData.errors.length,
                dataPoints: this.data.length
            };
        }
        
        calculateDataRate() {
            const now = Date.now();
            const last5min = now - (5 * 60 * 1000);
            const recentCount = this.data.filter(item => item.timestamp > last5min).length;
            
            return {
                per5min: recentCount,
                perMinute: Math.round(recentCount / 5 * 100) / 100,
                perSecond: Math.round(recentCount / 300 * 100) / 100
            };
        }
        
        estimateMemoryUsage() {
            const dataString = JSON.stringify(this.data);
            const sizeInBytes = new Blob([dataString]).size;
            const sizeInKB = Math.round(sizeInBytes / 1024 * 100) / 100;
            const sizeInMB = Math.round(sizeInKB / 1024 * 100) / 100;
            
            return {
                bytes: sizeInBytes,
                kb: sizeInKB,
                mb: sizeInMB,
                formatted: sizeInMB > 1 ? `${sizeInMB} MB` : `${sizeInKB} KB`
            };
        }
        
        setupAutoBackup() {
            if (!this.options.enableAutoBackup) return;
            
            setInterval(() => {
                this.createBackup();
            }, this.options.backupInterval);
        }
        
        createBackup() {
            try {
                const backup = {
                    timestamp: Date.now(),
                    data: this.data,
                    analytics: this.realTimeAnalytics,
                    performance: this.performanceData,
                    version: '1.0'
                };
                
                const backupKey = `${this.options.storageKey}_backup_${Date.now()}`;
                localStorage.setItem(backupKey, JSON.stringify(backup));
                
                this.lastBackup = Date.now();
                
                // Keep only last 5 backups
                this.cleanupOldBackups();
                
                if (this.options.enableConsoleLog) {
                    console.log('📦 Data backup created', { 
                        size: this.estimateMemoryUsage().formatted,
                        dataPoints: this.data.length 
                    });
                }
                
            } catch (error) {
                this.performanceData.errors.push({
                    type: 'backup_error',
                    message: error.message,
                    timestamp: Date.now()
                });
            }
        }
        
        cleanupOldBackups() {
            const keys = Object.keys(localStorage);
            const backupKeys = keys.filter(key => key.startsWith(`${this.options.storageKey}_backup_`));
            
            if (backupKeys.length > 5) {
                backupKeys.sort().slice(0, -5).forEach(key => {
                    localStorage.removeItem(key);
                });
            }
        }
        
        // Data collection methods
        trackEvent(category, action, data = {}) {
            const startTime = performance.now();
            
            try {
                const eventData = {
                    id: this.generateId(),
                    category: category,
                    action: action,
                    timestamp: Date.now(),
                    sessionId: this.getSessionId(),
                    ...data
                };
                
                if (this.validateData(eventData, 'event')) {
                    this.addData(eventData);
                    
                    if (this.options.enableConsoleLog) {
                        console.log('📊 Event tracked:', eventData);
                    }
                }
                
            } catch (error) {
                this.performanceData.errors.push({
                    type: 'tracking_error',
                    category: category,
                    action: action,
                    message: error.message,
                    timestamp: Date.now()
                });
            } finally {
                const processingTime = performance.now() - startTime;
                this.performanceData.processingTime += processingTime;
                this.performanceData.collections++;
            }
        }
        
        trackPerformance(metric, value, unit = 'ms', context = {}) {
            const performanceData = {
                id: this.generateId(),
                metric: metric,
                value: value,
                unit: unit,
                timestamp: Date.now(),
                context: context
            };
            
            if (this.validateData(performanceData, 'performance')) {
                this.addData(performanceData);
            }
        }
        
        trackUserAction(action, element = null, coordinates = null, metadata = {}) {
            const actionData = {
                id: this.generateId(),
                action: action,
                element: element,
                coordinates: coordinates,
                timestamp: Date.now(),
                duration: metadata.duration || null,
                metadata: metadata
            };
            
            if (this.validateData(actionData, 'user_action')) {
                this.addData(actionData);
            }
        }
        
        trackCustomData(type, data, tags = []) {
            const customData = {
                id: this.generateId(),
                type: type,
                data: data,
                timestamp: Date.now(),
                tags: tags
            };
            
            if (this.validateData(customData, 'custom')) {
                this.addData(customData);
            }
        }
        
        addData(item) {
            this.data.push(item);
            
            // Maintain max data points limit
            if (this.data.length > this.options.maxDataPoints) {
                this.data.shift();
            }
            
            if (this.options.autoSave) {
                this.saveData();
            }
            
            // Update memory usage
            this.performanceData.memoryUsage = this.estimateMemoryUsage().bytes;
        }
        
        validateData(data, schemaType) {
            const schema = this.schemas[schemaType];
            if (!schema) return true; // No schema validation
            
            try {
                for (const [field, type] of Object.entries(schema)) {
                    const value = data[field];
                    
                    if (value !== undefined && value !== null) {
                        const actualType = Array.isArray(value) ? 'array' : typeof value;
                        
                        if (type !== actualType && type !== 'any') {
                            console.warn(`Data validation warning: ${field} expected ${type}, got ${actualType}`);
                        }
                    }
                }
                return true;
            } catch (error) {
                this.performanceData.errors.push({
                    type: 'validation_error',
                    schema: schemaType,
                    message: error.message,
                    timestamp: Date.now()
                });
                return false;
            }
        }
        
        // Data query and filtering
        query(filters = {}) {
            let results = [...this.data];
            
            // Apply filters
            if (filters.category) {
                results = results.filter(item => item.category === filters.category);
            }
            
            if (filters.action) {
                results = results.filter(item => item.action === filters.action);
            }
            
            if (filters.dateRange) {
                const { start, end } = filters.dateRange;
                results = results.filter(item => 
                    item.timestamp >= start && item.timestamp <= end
                );
            }
            
            if (filters.search) {
                const searchTerm = filters.search.toLowerCase();
                results = results.filter(item => 
                    JSON.stringify(item).toLowerCase().includes(searchTerm)
                );
            }
            
            if (filters.tags) {
                results = results.filter(item => 
                    item.tags && filters.tags.some(tag => item.tags.includes(tag))
                );
            }
            
            // Apply sorting
            if (filters.sortBy) {
                results.sort((a, b) => {
                    const aVal = a[filters.sortBy];
                    const bVal = b[filters.sortBy];
                    
                    if (filters.sortOrder === 'desc') {
                        return bVal > aVal ? 1 : -1;
                    } else {
                        return aVal > bVal ? 1 : -1;
                    }
                });
            }
            
            // Apply limit
            if (filters.limit) {
                results = results.slice(0, filters.limit);
            }
            
            return results;
        }
        
        aggregate(field, operation = 'count', filters = {}) {
            const data = this.query(filters);
            
            switch (operation) {
                case 'count':
                    return data.length;
                
                case 'sum':
                    return data.reduce((sum, item) => sum + (item[field] || 0), 0);
                
                case 'avg':
                    const values = data.map(item => item[field]).filter(v => typeof v === 'number');
                    return values.length > 0 ? values.reduce((a, b) => a + b, 0) / values.length : 0;
                
                case 'min':
                    const minValues = data.map(item => item[field]).filter(v => typeof v === 'number');
                    return minValues.length > 0 ? Math.min(...minValues) : null;
                
                case 'max':
                    const maxValues = data.map(item => item[field]).filter(v => typeof v === 'number');
                    return maxValues.length > 0 ? Math.max(...maxValues) : null;
                
                case 'group':
                    const groups = {};
                    data.forEach(item => {
                        const key = item[field] || 'unknown';
                        groups[key] = (groups[key] || 0) + 1;
                    });
                    return groups;
                
                default:
                    return null;
            }
        }
        
        // Data persistence
        saveData() {
            try {
                const dataToSave = {
                    data: this.data,
                    analytics: this.realTimeAnalytics,
                    performance: this.performanceData,
                    lastSaved: Date.now()
                };
                
                if (this.options.compressionEnabled) {
                    // Simple compression simulation
                    const compressed = JSON.stringify(dataToSave);
                    localStorage.setItem(this.options.storageKey, compressed);
                } else {
                    localStorage.setItem(this.options.storageKey, JSON.stringify(dataToSave));
                }
                
            } catch (error) {
                this.performanceData.errors.push({
                    type: 'save_error',
                    message: error.message,
                    timestamp: Date.now()
                });
            }
        }
        
        loadData() {
            try {
                const saved = localStorage.getItem(this.options.storageKey);
                if (saved) {
                    const parsed = JSON.parse(saved);
                    this.data = parsed.data || [];
                    this.realTimeAnalytics = parsed.analytics || {};
                    this.performanceData = parsed.performance || this.performanceData;
                    
                    // Clean old data based on retention policy
                    this.cleanupOldData();
                }
            } catch (error) {
                console.error('Failed to load data:', error);
                this.data = [];
            }
        }
        
        cleanupOldData() {
            if (!this.options.dataRetentionDays) return;
            
            const cutoffDate = Date.now() - (this.options.dataRetentionDays * 24 * 60 * 60 * 1000);
            const originalLength = this.data.length;
            
            this.data = this.data.filter(item => item.timestamp > cutoffDate);
            
            const removedCount = originalLength - this.data.length;
            if (removedCount > 0 && this.options.enableConsoleLog) {
                console.log(`🗑️ Cleaned up ${removedCount} old data points`);
            }
        }
        
        // Export and import
        exportData(format = 'json', filters = {}) {
            const dataToExport = this.query(filters);
            
            let exportContent;
            let mimeType;
            let fileExtension;
            
            switch (format.toLowerCase()) {
                case 'csv':
                    exportContent = this.convertToCSV(dataToExport);
                    mimeType = 'text/csv';
                    fileExtension = 'csv';
                    break;
                
                case 'json':
                default:
                    exportContent = JSON.stringify({
                        metadata: {
                            exportDate: new Date().toISOString(),
                            totalRecords: dataToExport.length,
                            filters: filters,
                            version: '1.0'
                        },
                        data: dataToExport,
                        analytics: this.realTimeAnalytics,
                        performance: this.performanceData
                    }, null, 2);
                    mimeType = 'application/json';
                    fileExtension = 'json';
                    break;
            }
            
            const blob = new Blob([exportContent], { type: mimeType });
            const url = URL.createObjectURL(blob);
            
            const a = document.createElement('a');
            a.href = url;
            a.download = `xxmxli-data-export-${Date.now()}.${fileExtension}`;
            a.click();
            
            URL.revokeObjectURL(url);
            
            this.trackEvent('system', 'data_exported', {
                format: format,
                recordCount: dataToExport.length,
                fileSize: blob.size
            });
        }
        
        convertToCSV(data) {
            if (data.length === 0) return '';
            
            const headers = Object.keys(data[0]);
            const csvContent = [
                headers.join(','),
                ...data.map(row => 
                    headers.map(header => {
                        const value = row[header];
                        if (typeof value === 'object') {
                            return `"${JSON.stringify(value).replace(/"/g, '""')}"`;
                        }
                        return `"${String(value).replace(/"/g, '""')}"`;
                    }).join(',')
                )
            ].join('\n');
            
            return csvContent;
        }
        
        importData(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                
                reader.onload = (e) => {
                    try {
                        const content = e.target.result;
                        let importedData;
                        
                        if (file.name.endsWith('.json')) {
                            const parsed = JSON.parse(content);
                            importedData = parsed.data || parsed;
                        } else if (file.name.endsWith('.csv')) {
                            importedData = this.parseCSV(content);
                        } else {
                            throw new Error('Unsupported file format');
                        }
                        
                        // Validate and add imported data
                        let addedCount = 0;
                        importedData.forEach(item => {
                            if (this.validateData(item, 'custom')) {
                                this.addData({
                                    ...item,
                                    id: item.id || this.generateId(),
                                    timestamp: item.timestamp || Date.now()
                                });
                                addedCount++;
                            }
                        });
                        
                        this.trackEvent('system', 'data_imported', {
                            fileName: file.name,
                            importedCount: addedCount,
                            fileSize: file.size
                        });
                        
                        resolve({ imported: addedCount, total: importedData.length });
                        
                    } catch (error) {
                        reject(error);
                    }
                };
                
                reader.onerror = () => reject(new Error('Failed to read file'));
                reader.readAsText(file);
            });
        }
        
        parseCSV(content) {
            const lines = content.split('\n');
            const headers = lines[0].split(',').map(h => h.replace(/"/g, ''));
            
            return lines.slice(1).map(line => {
                const values = line.split(',').map(v => v.replace(/"/g, ''));
                const obj = {};
                
                headers.forEach((header, index) => {
                    let value = values[index];
                    
                    // Try to parse as JSON or number
                    try {
                        if (value.startsWith('{') || value.startsWith('[')) {
                            obj[header] = JSON.parse(value);
                        } else if (!isNaN(value) && value !== '') {
                            obj[header] = Number(value);
                        } else {
                            obj[header] = value;
                        }
                    } catch {
                        obj[header] = value;
                    }
                });
                
                return obj;
            }).filter(obj => Object.keys(obj).length > 0);
        }
        
        // Dashboard and visualization
        setupDashboard() {
            // Add keyboard shortcut (Ctrl+Shift+D) to open data dashboard
            document.addEventListener('keydown', (e) => {
                if (e.ctrlKey && e.shiftKey && e.key === 'D') {
                    this.openDashboard();
                }
            });
            
            // Add to window for manual access
            window.XXMXLIDataTracker = this;
        }
        
        openDashboard() {
            const dashboard = this.createDashboard();
            document.body.appendChild(dashboard);
        }
        
        createDashboard() {
            const modal = document.createElement('div');
            modal.className = 'xxmxli-data-dashboard-modal';
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
                        border: 2px solid #0080ff;
                        border-radius: 8px;
                        padding: 25px;
                        max-width: 95vw;
                        max-height: 90vh;
                        overflow-y: auto;
                        color: #0080ff;
                        box-shadow: 0 0 40px rgba(0, 128, 255, 0.3);
                        width: 1200px;
                    ">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px; border-bottom: 1px solid #0080ff; padding-bottom: 15px;">
                            <h2 style="margin: 0; text-shadow: 0 0 15px #0080ff; font-size: 24px;">📊 XXMXLI Data Tracker Dashboard</h2>
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
                            ${this.renderStatsCards()}
                        </div>
                        
                        <!-- Navigation Tabs -->
                        <div style="margin-bottom: 20px;">
                            <div class="xxmxli-data-tabs" style="display: flex; border-bottom: 1px solid #0080ff;">
                                <button class="xxmxli-data-tab active" data-tab="overview">📈 Overview</button>
                                <button class="xxmxli-data-tab" data-tab="analytics">📊 Analytics</button>
                                <button class="xxmxli-data-tab" data-tab="query">🔍 Query</button>
                                <button class="xxmxli-data-tab" data-tab="performance">⚡ Performance</button>
                                <button class="xxmxli-data-tab" data-tab="export">💾 Export/Import</button>
                            </div>
                        </div>
                        
                        <!-- Tab Content -->
                        <div class="xxmxli-data-tab-content">
                            <div id="overview" class="xxmxli-data-tab-panel active">
                                ${this.renderOverviewPanel()}
                            </div>
                            <div id="analytics" class="xxmxli-data-tab-panel">
                                ${this.renderAnalyticsPanel()}
                            </div>
                            <div id="query" class="xxmxli-data-tab-panel">
                                ${this.renderQueryPanel()}
                            </div>
                            <div id="performance" class="xxmxli-data-tab-panel">
                                ${this.renderPerformancePanel()}
                            </div>
                            <div id="export" class="xxmxli-data-tab-panel">
                                ${this.renderExportPanel()}
                            </div>
                        </div>
                        
                        <!-- Action Buttons -->
                        <div style="margin-top: 25px; padding-top: 15px; border-top: 1px solid #0080ff; display: flex; gap: 10px;">
                            <button class="xxmxli-data-export-btn" style="
                                background: #0080ff;
                                border: 1px solid #0080ff;
                                color: white;
                                padding: 10px 20px;
                                border-radius: 4px;
                                cursor: pointer;
                            ">📥 Quick Export</button>
                            
                            <button class="xxmxli-data-clear-btn" style="
                                background: #ff4000;
                                border: 1px solid #ff4000;
                                color: white;
                                padding: 10px 20px;
                                border-radius: 4px;
                                cursor: pointer;
                            ">🗑️ Clear Data</button>
                            
                            <button class="xxmxli-data-backup-btn" style="
                                background: #00ff00;
                                border: 1px solid #00ff00;
                                color: #000;
                                padding: 10px 20px;
                                border-radius: 4px;
                                cursor: pointer;
                            ">📦 Create Backup</button>
                        </div>
                    </div>
                </div>
            `;
            
            // Add event listeners
            this.attachDashboardEvents(modal);
            
            return modal;
        }
        
        renderStatsCards() {
            return `
                <div class="stat-card" style="background: rgba(0, 128, 255, 0.1); padding: 15px; border-radius: 6px; border: 1px solid #0080ff;">
                    <div style="font-size: 28px; font-weight: bold; color: #0080ff;">${this.data.length}</div>
                    <div style="font-size: 12px; opacity: 0.8;">TOTAL DATA POINTS</div>
                </div>
                <div class="stat-card" style="background: rgba(0, 255, 0, 0.1); padding: 15px; border-radius: 6px; border: 1px solid #00ff00;">
                    <div style="font-size: 28px; font-weight: bold; color: #00ff00;">${this.realTimeAnalytics.last24h || 0}</div>
                    <div style="font-size: 12px; opacity: 0.8;">LAST 24 HOURS</div>
                </div>
                <div class="stat-card" style="background: rgba(255, 255, 0, 0.1); padding: 15px; border-radius: 6px; border: 1px solid #ffff00;">
                    <div style="font-size: 28px; font-weight: bold; color: #ffff00;">${this.estimateMemoryUsage().formatted}</div>
                    <div style="font-size: 12px; opacity: 0.8;">MEMORY USAGE</div>
                </div>
                <div class="stat-card" style="background: rgba(255, 0, 255, 0.1); padding: 15px; border-radius: 6px; border: 1px solid #ff00ff;">
                    <div style="font-size: 28px; font-weight: bold; color: #ff00ff;">${Object.keys(this.schemas).length}</div>
                    <div style="font-size: 12px; opacity: 0.8;">DATA SCHEMAS</div>
                </div>
                <div class="stat-card" style="background: rgba(255, 64, 0, 0.1); padding: 15px; border-radius: 6px; border: 1px solid #ff4000;">
                    <div style="font-size: 28px; font-weight: bold; color: #ff4000;">${this.calculateDataRate().perMinute}</div>
                    <div style="font-size: 12px; opacity: 0.8;">RATE/MINUTE</div>
                </div>
                <div class="stat-card" style="background: rgba(0, 255, 255, 0.1); padding: 15px; border-radius: 6px; border: 1px solid #00ffff;">
                    <div style="font-size: 28px; font-weight: bold; color: #00ffff;">${this.performanceData.errors.length}</div>
                    <div style="font-size: 12px; opacity: 0.8;">ERRORS</div>
                </div>
            `;
        }
        
        renderOverviewPanel() {
            return `
                <div>
                    <h3 style="color: #0080ff; margin-bottom: 15px;">📈 Data Overview</h3>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                        <div>
                            <h4 style="color: #00ff00;">Recent Activity</h4>
                            <div style="background: rgba(0, 255, 0, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(0, 255, 0, 0.2); max-height: 300px; overflow-y: auto;">
                                ${this.renderRecentActivity()}
                            </div>
                        </div>
                        <div>
                            <h4 style="color: #ffff00;">Category Breakdown</h4>
                            <div style="background: rgba(255, 255, 0, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(255, 255, 0, 0.2);">
                                ${this.renderCategoryBreakdown()}
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }
        
        renderAnalyticsPanel() {
            return `
                <div>
                    <h3 style="color: #0080ff; margin-bottom: 15px;">📊 Real-Time Analytics</h3>
                    <div id="analytics-content">
                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                            <div>
                                <h4 style="color: #ff00ff;">Top Actions</h4>
                                <div style="background: rgba(255, 0, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(255, 0, 255, 0.2);">
                                    ${this.renderTopActions()}
                                </div>
                            </div>
                            <div>
                                <h4 style="color: #00ffff;">Performance Trends</h4>
                                <div style="background: rgba(0, 255, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(0, 255, 255, 0.2);">
                                    ${this.renderPerformanceTrends()}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }
        
        renderQueryPanel() {
            return `
                <div>
                    <h3 style="color: #0080ff; margin-bottom: 15px;">🔍 Data Query Interface</h3>
                    <div style="margin-bottom: 20px;">
                        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 15px;">
                            <div>
                                <label style="display: block; margin-bottom: 5px; color: #00ff00;">Category:</label>
                                <select id="query-category" style="width: 100%; padding: 5px; background: #000; color: #00ff00; border: 1px solid #00ff00;">
                                    <option value="">All Categories</option>
                                    ${this.getUniqueCategories().map(cat => `<option value="${cat}">${cat}</option>`).join('')}
                                </select>
                            </div>
                            <div>
                                <label style="display: block; margin-bottom: 5px; color: #00ff00;">Action:</label>
                                <input type="text" id="query-action" placeholder="Enter action" style="width: 100%; padding: 5px; background: #000; color: #00ff00; border: 1px solid #00ff00;">
                            </div>
                            <div>
                                <label style="display: block; margin-bottom: 5px; color: #00ff00;">Search:</label>
                                <input type="text" id="query-search" placeholder="Search in data" style="width: 100%; padding: 5px; background: #000; color: #00ff00; border: 1px solid #00ff00;">
                            </div>
                            <div>
                                <label style="display: block; margin-bottom: 5px; color: #00ff00;">Limit:</label>
                                <input type="number" id="query-limit" value="100" min="1" max="10000" style="width: 100%; padding: 5px; background: #000; color: #00ff00; border: 1px solid #00ff00;">
                            </div>
                        </div>
                        <button onclick="window.XXMXLIDataTracker.executeQuery()" style="background: #0080ff; color: white; border: 1px solid #0080ff; padding: 10px 20px; border-radius: 4px; cursor: pointer;">🔍 Execute Query</button>
                    </div>
                    <div id="query-results" style="background: rgba(0, 128, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(0, 128, 255, 0.2); max-height: 400px; overflow-y: auto;">
                        <div style="text-align: center; opacity: 0.6;">Execute a query to see results</div>
                    </div>
                </div>
            `;
        }
        
        renderPerformancePanel() {
            return `
                <div>
                    <h3 style="color: #0080ff; margin-bottom: 15px;">⚡ Performance Monitoring</h3>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                        <div>
                            <h4 style="color: #ffff00;">Processing Metrics</h4>
                            <div style="background: rgba(255, 255, 0, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(255, 255, 0, 0.2);">
                                Collections: ${this.performanceData.collections}<br>
                                Avg Processing Time: ${this.calculatePerformanceMetrics().avgProcessingTime}ms<br>
                                Memory Usage: ${this.estimateMemoryUsage().formatted}<br>
                                Error Count: ${this.performanceData.errors.length}
                            </div>
                            
                            <h4 style="color: #ff00ff; margin-top: 15px;">Data Rates</h4>
                            <div style="background: rgba(255, 0, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(255, 0, 255, 0.2);">
                                Per Second: ${this.calculateDataRate().perSecond}<br>
                                Per Minute: ${this.calculateDataRate().perMinute}<br>
                                Last 5 Minutes: ${this.calculateDataRate().per5min}
                            </div>
                        </div>
                        
                        <div>
                            <h4 style="color: #00ffff;">Recent Errors</h4>
                            <div style="background: rgba(0, 255, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(0, 255, 255, 0.2); max-height: 300px; overflow-y: auto;">
                                ${this.renderRecentErrors()}
                            </div>
                        </div>
                    </div>
                </div>
            `;
        }
        
        renderExportPanel() {
            return `
                <div>
                    <h3 style="color: #0080ff; margin-bottom: 15px;">💾 Export & Import Data</h3>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                        <div>
                            <h4 style="color: #00ff00;">Export Data</h4>
                            <div style="background: rgba(0, 255, 0, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(0, 255, 0, 0.2);">
                                <div style="margin-bottom: 10px;">
                                    <label style="display: block; margin-bottom: 5px;">Format:</label>
                                    <select id="export-format" style="width: 100%; padding: 5px; background: #000; color: #00ff00; border: 1px solid #00ff00;">
                                        <option value="json">JSON</option>
                                        <option value="csv">CSV</option>
                                    </select>
                                </div>
                                <button onclick="window.XXMXLIDataTracker.exportData(document.getElementById('export-format').value)" style="background: #00ff00; color: #000; border: 1px solid #00ff00; padding: 8px 16px; border-radius: 4px; cursor: pointer; width: 100%;">📥 Export All Data</button>
                            </div>
                        </div>
                        
                        <div>
                            <h4 style="color: #ffff00;">Import Data</h4>
                            <div style="background: rgba(255, 255, 0, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(255, 255, 0, 0.2);">
                                <input type="file" id="import-file" accept=".json,.csv" style="width: 100%; margin-bottom: 10px; color: #ffff00;">
                                <button onclick="window.XXMXLIDataTracker.handleFileImport()" style="background: #ffff00; color: #000; border: 1px solid #ffff00; padding: 8px 16px; border-radius: 4px; cursor: pointer; width: 100%;">📤 Import Data</button>
                            </div>
                        </div>
                    </div>
                    
                    <div style="margin-top: 20px;">
                        <h4 style="color: #ff00ff;">Backup Management</h4>
                        <div style="background: rgba(255, 0, 255, 0.05); padding: 15px; border-radius: 6px; border: 1px solid rgba(255, 0, 255, 0.2);">
                            Last Backup: ${this.lastBackup ? new Date(this.lastBackup).toLocaleString() : 'Never'}<br>
                            <button onclick="window.XXMXLIDataTracker.createBackup()" style="background: #ff00ff; color: #000; border: 1px solid #ff00ff; padding: 8px 16px; border-radius: 4px; cursor: pointer; margin-top: 10px;">📦 Create Manual Backup</button>
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
            modal.querySelectorAll('.xxmxli-data-tab').forEach(tab => {
                tab.addEventListener('click', () => {
                    modal.querySelectorAll('.xxmxli-data-tab').forEach(t => t.classList.remove('active'));
                    modal.querySelectorAll('.xxmxli-data-tab-panel').forEach(p => p.classList.remove('active'));
                    
                    tab.classList.add('active');
                    modal.querySelector(`#${tab.dataset.tab}`).classList.add('active');
                });
            });
            
            // Action buttons
            modal.querySelector('.xxmxli-data-export-btn').addEventListener('click', () => this.exportData('json'));
            modal.querySelector('.xxmxli-data-clear-btn').addEventListener('click', () => {
                if (confirm('⚠️ Are you sure you want to clear all data? This cannot be undone!')) {
                    this.clearAllData();
                    modal.remove();
                }
            });
            modal.querySelector('.xxmxli-data-backup-btn').addEventListener('click', () => this.createBackup());
            
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
        
        // Helper methods for dashboard rendering
        renderRecentActivity() {
            const recent = this.data.slice(-10).reverse();
            if (recent.length === 0) return '<div style="opacity: 0.6;">No recent activity</div>';
            
            return recent.map(item => `
                <div style="margin-bottom: 8px; padding: 8px; background: rgba(0, 0, 0, 0.2); border-radius: 4px; font-size: 12px;">
                    <strong>${item.category || 'Unknown'}</strong> - ${item.action || 'N/A'}<br>
                    <span style="opacity: 0.7;">${new Date(item.timestamp).toLocaleTimeString()}</span>
                </div>
            `).join('');
        }
        
        renderCategoryBreakdown() {
            const categories = this.aggregate('category', 'group');
            if (Object.keys(categories).length === 0) return '<div style="opacity: 0.6;">No data available</div>';
            
            return Object.entries(categories)
                .sort(([,a], [,b]) => b - a)
                .slice(0, 10)
                .map(([category, count]) => `
                    <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                        <span>${category}</span>
                        <span style="color: #ffff00;">${count}</span>
                    </div>
                `).join('');
        }
        
        renderTopActions() {
            const topActions = this.realTimeAnalytics.topActions || [];
            if (topActions.length === 0) return '<div style="opacity: 0.6;">No actions tracked</div>';
            
            return topActions.map(({ action, count }) => `
                <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                    <span>${action}</span>
                    <span style="color: #ff00ff;">${count}</span>
                </div>
            `).join('');
        }
        
        renderPerformanceTrends() {
            const metrics = this.calculatePerformanceMetrics();
            return `
                <div style="font-size: 13px;">
                    Collections: ${metrics.collections}<br>
                    Avg Processing: ${metrics.avgProcessingTime}ms<br>
                    Memory: ${this.estimateMemoryUsage().formatted}<br>
                    Error Rate: ${((metrics.errorCount / Math.max(1, metrics.collections)) * 100).toFixed(2)}%
                </div>
            `;
        }
        
        renderRecentErrors() {
            const recentErrors = this.performanceData.errors.slice(-5).reverse();
            if (recentErrors.length === 0) return '<div style="color: #00ff00; opacity: 0.8;">No errors ✅</div>';
            
            return recentErrors.map(error => `
                <div style="margin-bottom: 10px; padding: 8px; background: rgba(255, 64, 0, 0.1); border-radius: 4px; font-size: 12px;">
                    <strong style="color: #ff4000;">${error.type}</strong><br>
                    ${error.message}<br>
                    <span style="opacity: 0.7;">${new Date(error.timestamp).toLocaleString()}</span>
                </div>
            `).join('');
        }
        
        // Utility methods
        generateId() {
            return 'data_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
        }
        
        getSessionId() {
            if (!this.sessionId) {
                this.sessionId = 'session_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            }
            return this.sessionId;
        }
        
        getUniqueCategories() {
            const categories = new Set();
            this.data.forEach(item => {
                if (item.category) categories.add(item.category);
            });
            return Array.from(categories).sort();
        }
        
        executeQuery() {
            const category = document.getElementById('query-category')?.value || '';
            const action = document.getElementById('query-action')?.value || '';
            const search = document.getElementById('query-search')?.value || '';
            const limit = parseInt(document.getElementById('query-limit')?.value) || 100;
            
            const filters = {
                ...(category && { category }),
                ...(action && { action }),
                ...(search && { search }),
                limit,
                sortBy: 'timestamp',
                sortOrder: 'desc'
            };
            
            const results = this.query(filters);
            
            const resultsDiv = document.getElementById('query-results');
            if (resultsDiv) {
                resultsDiv.innerHTML = `
                    <div style="margin-bottom: 10px; font-weight: bold;">
                        Query Results: ${results.length} items
                    </div>
                    ${results.length === 0 ? '<div style="opacity: 0.6;">No results found</div>' : 
                      results.slice(0, 50).map(item => `
                        <div style="margin-bottom: 8px; padding: 8px; background: rgba(0, 0, 0, 0.2); border-radius: 4px; font-size: 12px;">
                            <strong>${item.category || 'N/A'}</strong> - ${item.action || 'N/A'}<br>
                            <span style="opacity: 0.7;">${new Date(item.timestamp).toLocaleString()}</span><br>
                            <pre style="margin: 5px 0 0 0; font-size: 11px; opacity: 0.8; max-height: 60px; overflow: hidden;">${JSON.stringify(item, null, 2)}</pre>
                        </div>
                      `).join('')
                    }
                    ${results.length > 50 ? `<div style="opacity: 0.6; margin-top: 10px;">Showing first 50 of ${results.length} results</div>` : ''}
                `;
            }
        }
        
        handleFileImport() {
            const fileInput = document.getElementById('import-file');
            const file = fileInput?.files[0];
            
            if (!file) {
                alert('Please select a file to import');
                return;
            }
            
            this.importData(file)
                .then(result => {
                    alert(`✅ Import successful!\nImported: ${result.imported} records\nTotal in file: ${result.total} records`);
                })
                .catch(error => {
                    alert(`❌ Import failed: ${error.message}`);
                });
        }
        
        clearAllData() {
            this.data = [];
            this.performanceData.errors = [];
            this.performanceData.collections = 0;
            this.performanceData.processingTime = 0;
            this.realTimeAnalytics = {};
            
            this.saveData();
            
            this.trackEvent('system', 'data_cleared', {
                timestamp: Date.now()
            });
        }
        
        // Data change listeners
        addDataChangeListener(callback) {
            this.dataChangeListeners.push(callback);
        }
        
        removeDataChangeListener(callback) {
            this.dataChangeListeners = this.dataChangeListeners.filter(cb => cb !== callback);
        }
        
        notifyDataChangeListeners() {
            this.dataChangeListeners.forEach(callback => {
                try {
                    callback(this.realTimeAnalytics);
                } catch (error) {
                    console.error('Error in data change listener:', error);
                }
            });
        }
        
        // Public API
        getData() {
            return [...this.data];
        }
        
        getAnalytics() {
            return { ...this.realTimeAnalytics };
        }
        
        getPerformanceData() {
            return { ...this.performanceData };
        }
        
        getSchemas() {
            return { ...this.schemas };
        }
        
        addSchema(name, schema) {
            this.schemas[name] = schema;
            this.trackEvent('system', 'schema_added', { schemaName: name });
        }
        
        removeSchema(name) {
            if (this.schemas[name]) {
                delete this.schemas[name];
                this.trackEvent('system', 'schema_removed', { schemaName: name });
            }
        }
    }
    
    // Auto-initialize if not disabled
    if (typeof window !== 'undefined') {
        // Check for configuration in script tag
        const script = document.querySelector('script[src*="data-tracker"]');
        const config = script?.dataset ? Object.fromEntries(
            Object.entries(script.dataset).map(([k, v]) => [k, v === 'true' ? true : v === 'false' ? false : v])
        ) : {};
        
        // Initialize tracker
        window.XXMXLIDataTracker = new XXMXLIDataTracker(config);
        
        // Add CSS for better styling
        const style = document.createElement('style');
        style.textContent = `
            .xxmxli-data-tab {
                background: transparent;
                border: 1px solid #0080ff;
                color: #0080ff;
                padding: 8px 16px;
                cursor: pointer;
                margin-right: 5px;
                border-radius: 4px 4px 0 0;
                font-family: 'Courier New', monospace;
                transition: all 0.3s ease;
            }
            
            .xxmxli-data-tab:hover {
                background: rgba(0, 128, 255, 0.1);
            }
            
            .xxmxli-data-tab.active {
                background: rgba(0, 128, 255, 0.2);
                border-bottom-color: #0a0a0a;
            }
            
            .xxmxli-data-tab-panel {
                display: none;
            }
            
            .xxmxli-data-tab-panel.active {
                display: block;
            }
        `;
        document.head.appendChild(style);
        
        console.log('📊 XXMXLI Data Tracker loaded! Press Ctrl+Shift+D to open dashboard.');
    }
    
    // Export for module systems
    if (typeof module !== 'undefined' && module.exports) {
        module.exports = XXMXLIDataTracker;
    }
    
})();
