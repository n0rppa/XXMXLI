# XXMXLI Data Tracker v1.0

🔍 **Dedicated data collection and analysis system** - A comprehensive, standalone data tracking solution.

## 🌟 Features

### 📊 Data Collection
- **Custom data schemas** with flexible validation
- **Event tracking** with categories and actions
- **Performance metrics** collection and monitoring
- **User behavior** tracking and analysis
- **Custom data types** with metadata support

### 📈 Real-Time Analytics
- **Live data processing** with 1-second updates
- **Category breakdown** and action analysis
- **Performance trending** and error monitoring
- **Memory usage** tracking and optimization
- **Data rate** calculations (per second/minute)

### 🔍 Query & Search
- **Advanced filtering** by category, action, date range
- **Full-text search** across all data fields
- **Sorting and pagination** for large datasets
- **Aggregation functions** (count, sum, avg, min, max)
- **Real-time query execution** with results preview

### 💾 Data Management
- **Export capabilities** (JSON, CSV formats)
- **Import functionality** for external data
- **Automatic backup** system with retention
- **Data compression** for storage optimization
- **Retention policies** with automatic cleanup

### 🎛️ Dashboard Interface
- **Multi-tab dashboard** with comprehensive views
- **Real-time visualizations** and metrics
- **Performance monitoring** panel
- **Export/Import** management interface
- **Error tracking** and debugging tools

## 🚀 Quick Setup

### Basic Implementation
```html
<!-- Include the data tracker -->
<script src="plugins/data-tracker.js"></script>

<!-- Tracker auto-initializes with default settings -->
```

### Advanced Configuration
```javascript
const dataTracker = new XXMXLIDataTracker({
    maxDataPoints: 10000,
    enableRealTimeAnalytics: true,
    enableDataVisualization: true,
    enableAutoBackup: true,
    backupInterval: 300000, // 5 minutes
    dataRetentionDays: 90,
    customSchemas: {
        custom_event: {
            id: 'string',
            name: 'string',
            value: 'number',
            metadata: 'object'
        }
    }
});
```

## 📋 Data Schemas

### Default Schemas
```javascript
{
    // Event tracking
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
    
    // Performance metrics
    performance: {
        id: 'string',
        metric: 'string',
        value: 'number',
        unit: 'string',
        timestamp: 'number',
        context: 'object'
    },
    
    // User actions
    user_action: {
        id: 'string',
        action: 'string',
        element: 'string',
        coordinates: 'object',
        timestamp: 'number',
        duration: 'number',
        metadata: 'object'
    },
    
    // Custom data
    custom: {
        id: 'string',
        type: 'string',
        data: 'object',
        timestamp: 'number',
        tags: 'array'
    }
}
```

## 🔧 API Reference

### Data Collection
```javascript
// Track events
dataTracker.trackEvent('user_interaction', 'button_click', {
    label: 'signup_button',
    value: 1,
    metadata: { page: 'homepage' }
});

// Track performance
dataTracker.trackPerformance('page_load_time', 1234, 'ms', {
    page: 'homepage',
    user_agent: navigator.userAgent
});

// Track user actions
dataTracker.trackUserAction('click', '#signup-button', { x: 100, y: 200 }, {
    duration: 150
});

// Track custom data
dataTracker.trackCustomData('conversion', {
    type: 'purchase',
    amount: 99.99,
    currency: 'USD'
}, ['ecommerce', 'payment']);
```

### Data Querying
```javascript
// Basic query
const recentEvents = dataTracker.query({
    category: 'user_interaction',
    dateRange: {
        start: Date.now() - 24*60*60*1000, // Last 24 hours
        end: Date.now()
    },
    limit: 100
});

// Advanced filtering
const filteredData = dataTracker.query({
    search: 'button',
    sortBy: 'timestamp',
    sortOrder: 'desc',
    tags: ['ecommerce']
});

// Aggregation
const clickCount = dataTracker.aggregate('action', 'count', {
    category: 'user_interaction'
});

const avgLoadTime = dataTracker.aggregate('value', 'avg', {
    category: 'performance',
    action: 'page_load'
});
```

### Data Export/Import
```javascript
// Export data
dataTracker.exportData('json', {
    category: 'user_interaction',
    dateRange: { start: startDate, end: endDate }
});

dataTracker.exportData('csv');

// Import data
const fileInput = document.querySelector('#file-input');
dataTracker.importData(fileInput.files[0])
    .then(result => {
        console.log(`Imported ${result.imported} records`);
    })
    .catch(error => {
        console.error('Import failed:', error);
    });
```

### Real-Time Analytics
```javascript
// Get current analytics
const analytics = dataTracker.getAnalytics();
console.log('Data points today:', analytics.last24h);
console.log('Top actions:', analytics.topActions);

// Listen for data changes
dataTracker.addDataChangeListener((analytics) => {
    console.log('Data updated:', analytics);
});

// Get performance metrics
const performance = dataTracker.getPerformanceData();
console.log('Processing time:', performance.avgProcessingTime);
```

### Schema Management
```javascript
// Add custom schema
dataTracker.addSchema('product_view', {
    id: 'string',
    product_id: 'string',
    user_id: 'string',
    timestamp: 'number',
    price: 'number',
    category: 'string'
});

// Remove schema
dataTracker.removeSchema('old_schema');

// Get all schemas
const schemas = dataTracker.getSchemas();
```

## 🎮 Dashboard Controls

### Keyboard Shortcuts
- **Ctrl+Shift+D** - Open data dashboard
- **Escape** - Close dashboard

### Dashboard Features
- **Overview Panel** - Recent activity and category breakdown
- **Analytics Panel** - Real-time metrics and trends
- **Query Panel** - Interactive data querying interface
- **Performance Panel** - System performance monitoring
- **Export/Import Panel** - Data management tools

## 📊 Configuration Options

```javascript
{
    // Core settings
    apiKey: 'xxmxli-data-tracker',
    storageKey: 'xxmxli_data_tracker',
    maxDataPoints: 10000,
    autoSave: true,
    enableConsoleLog: true,
    
    // Real-time features
    enableRealTimeAnalytics: true,
    enableDataVisualization: true,
    realTimeUpdateInterval: 1000,
    
    // Backup and retention
    enableAutoBackup: true,
    backupInterval: 300000, // 5 minutes
    dataRetentionDays: 90,
    
    // Performance
    compressionEnabled: true,
    encryptionKey: null,
    
    // Custom schemas
    customSchemas: {}
}
```

## 📈 Performance Monitoring

The data tracker includes built-in performance monitoring:

- **Collection Performance** - Tracks processing time per operation
- **Memory Usage** - Monitors data storage and memory consumption
- **Error Tracking** - Logs and reports system errors
- **Data Rates** - Calculates throughput metrics
- **Processing Analytics** - Provides optimization insights

## 🔒 Data Security

- **Local Storage** - Data stored securely in browser localStorage
- **Optional Encryption** - Configure encryption key for sensitive data
- **Data Validation** - Schema-based validation prevents data corruption
- **Backup System** - Automatic backups prevent data loss
- **Retention Policies** - Automatic cleanup of old data

## 💡 Use Cases

### E-commerce Tracking
```javascript
// Track product views
dataTracker.trackEvent('product', 'view', {
    product_id: 'abc123',
    category: 'electronics',
    price: 299.99
});

// Track purchases
dataTracker.trackEvent('purchase', 'completed', {
    order_id: 'order_456',
    amount: 299.99,
    items: 1
});
```

### Performance Monitoring
```javascript
// Track page load times
window.addEventListener('load', () => {
    const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart;
    dataTracker.trackPerformance('page_load', loadTime, 'ms');
});

// Track API response times
fetch('/api/data')
    .then(response => {
        dataTracker.trackPerformance('api_response', response.timing, 'ms', {
            endpoint: '/api/data',
            status: response.status
        });
    });
```

### User Behavior Analysis
```javascript
// Track button clicks
document.addEventListener('click', (e) => {
    if (e.target.tagName === 'BUTTON') {
        dataTracker.trackUserAction('click', e.target.id, {
            x: e.clientX,
            y: e.clientY
        });
    }
});

// Track form interactions
document.addEventListener('input', (e) => {
    if (e.target.tagName === 'INPUT') {
        dataTracker.trackUserAction('input', e.target.name, null, {
            value_length: e.target.value.length
        });
    }
});
```

## 🛠️ Troubleshooting

### Common Issues

**Dashboard not opening:**
```javascript
// Check if tracker is initialized
if (window.XXMXLIDataTracker) {
    window.XXMXLIDataTracker.openDashboard();
} else {
    console.log('Data tracker not initialized');
}
```

**Data not saving:**
```javascript
// Manually save data
dataTracker.saveData();

// Check localStorage availability
if (typeof Storage !== 'undefined') {
    console.log('LocalStorage is available');
} else {
    console.log('LocalStorage not supported');
}
```

**Performance issues:**
```javascript
// Reduce max data points
const tracker = new XXMXLIDataTracker({
    maxDataPoints: 5000, // Reduce from default 10000
    realTimeUpdateInterval: 5000 // Update less frequently
});

// Check memory usage
const memoryUsage = dataTracker.estimateMemoryUsage();
console.log('Memory usage:', memoryUsage.formatted);
```

## 📄 License

This data tracker is part of the XXMXLI project. See main project for licensing terms.

## 🔄 Version History

### v1.0 (Current)
- Complete data collection and analysis system
- Real-time analytics with performance monitoring
- Advanced query interface with filtering
- Export/Import capabilities with multiple formats
- Automatic backup system with retention policies
- Multi-tab dashboard with comprehensive visualizations
- Custom schema support with validation
- Performance optimization and error tracking

---

**Need help?** Press `Ctrl+Shift+D` to open the interactive dashboard!
