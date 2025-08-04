# 🔍 XXMXLI Visitor Tracker Plugin

A lightweight, self-contained visitor tracking solution that works on any website. No servers required!

## ✨ Features

- **🎯 Real-time Visitor Tracking** - Track visitors as they browse your site
- **🌍 IP Detection & Geolocation** - Automatic location detection via public APIs
- **🔍 Browser Fingerprinting** - Unique visitor identification
- **🛡️ Threat Assessment** - Built-in security analysis
- **💾 Local Storage Fallback** - Works without any server infrastructure
- **📊 Built-in Dashboard** - Press `Ctrl+Shift+V` to open admin panel
- **📥 Export/Import Data** - Download visitor data as JSON
- **🎨 Cyberpunk Theme** - Hacker-style UI design
- **⚡ Zero Dependencies** - Single JavaScript file, no external libraries

## 🚀 Quick Start

### Option 1: Basic Installation
Add this single line to your website's `<head>` or before closing `</body>`:

```html
<script src="visitor-tracker-plugin.js"></script>
```

### Option 2: With Custom Configuration
```html
<script src="visitor-tracker-plugin.js" 
        data-enable-notifications="true"
        data-max-stored-visits="200"
        data-theme="cyberpunk"></script>
```

### Option 3: Manual Initialization
```html
<script src="visitor-tracker-plugin.js" data-auto-track="false"></script>
<script>
    const tracker = new XXMXLIVisitorTracker({
        enableConsoleLog: true,
        enableNotifications: false,
        maxStoredVisits: 100
    });
    tracker.init();
</script>
```

## 📊 Usage

### Opening the Dashboard
- **Keyboard Shortcut**: `Ctrl+Shift+V`
- **JavaScript**: `window.XXMXLITracker.openDashboard()`

### JavaScript API
```javascript
// Get visitor statistics
const stats = window.XXMXLITracker.getStats();
console.log('Total visitors:', stats.total);
console.log('Unique IPs:', stats.unique);
console.log('Today:', stats.today);

// Get all visitor data
const visitors = window.XXMXLITracker.getVisitors();

// Export data to file
window.XXMXLITracker.exportData();

// Clear all data
window.XXMXLITracker.clearData();

// Track a new visit manually
window.XXMXLITracker.trackVisit();
```

## ⚙️ Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `apiKey` | string | `'xxmxli-tracker'` | Unique identifier for your tracker |
| `enableConsoleLog` | boolean | `true` | Enable console logging |
| `enableNotifications` | boolean | `false` | Show browser notifications |
| `storageKey` | string | `'xxmxli_visitors'` | localStorage key for data |
| `maxStoredVisits` | number | `100` | Maximum visits to store locally |
| `autoTrack` | boolean | `true` | Automatically start tracking |
| `dashboardEnabled` | boolean | `true` | Enable dashboard functionality |
| `theme` | string | `'cyberpunk'` | UI theme (currently only cyberpunk) |

## 📈 What Data is Collected

The plugin collects the following visitor information:

- **Session Data**: Unique session ID, timestamp, URL, referrer
- **Browser Info**: User agent, language, platform, plugins
- **Screen Info**: Resolution, viewport size, color depth
- **Network Info**: IP address, location, ISP (via public APIs)
- **Device Info**: Battery level, connection type (if available)
- **Security**: Threat assessment based on behavior patterns

## 🛡️ Privacy & Security

- **Local Storage Only**: All data stored in visitor's browser
- **No External Servers**: Works completely offline
- **Public APIs Only**: IP detection uses public geolocation services
- **No Personal Data**: No names, emails, or sensitive information
- **GDPR Friendly**: Minimal data collection, local storage
- **Threat Detection**: Identifies potentially malicious visitors

## 🎨 Dashboard Features

The built-in dashboard provides:

- **Real-time Statistics**: Total visitors, unique IPs, daily counts
- **Visitor Table**: Recent visitors with details
- **Threat Analysis**: Color-coded threat levels
- **Data Export**: Download JSON files
- **Data Management**: Clear or import data
- **Responsive Design**: Works on all screen sizes

## 🌍 Browser Compatibility

- ✅ Chrome 60+
- ✅ Firefox 55+
- ✅ Safari 12+
- ✅ Edge 79+
- ✅ Mobile browsers

## 📦 File Structure

```
plugins/
├── visitor-tracker-plugin.js    # Main plugin file (self-contained)
├── plugin-demo.html            # Demo page with examples
└── README.md                   # This file
```

## 🔧 Advanced Usage

### Custom Threat Assessment
```javascript
const tracker = new XXMXLIVisitorTracker({
    customThreatRules: (data) => {
        let score = 0;
        if (data.userAgent.includes('bot')) score += 50;
        if (data.location.country === 'Unknown') score += 20;
        return score >= 70 ? 'HIGH' : score >= 30 ? 'MEDIUM' : 'LOW';
    }
});
```

### Server Integration (Optional)
```javascript
const tracker = new XXMXLIVisitorTracker({
    serverEndpoint: 'https://your-api.com/track',
    apiKey: 'your-secret-key'
});
```

### Multiple Trackers
```javascript
// Main site tracker
const mainTracker = new XXMXLIVisitorTracker({
    storageKey: 'main_visitors'
});

// Admin panel tracker
const adminTracker = new XXMXLIVisitorTracker({
    storageKey: 'admin_visitors',
    autoTrack: false
});
```

## 🚀 Deployment

### GitHub Pages
1. Upload `visitor-tracker-plugin.js` to your repository
2. Add the script tag to your HTML files
3. Deploy - it works immediately!

### Cloudflare Pages
1. Add the plugin to your build output
2. Include in your HTML templates
3. Enjoy enhanced performance with Cloudflare's CDN

### Any Web Server
1. Upload the plugin file
2. Reference it in your HTML
3. Works on any hosting platform!

## 🔍 Troubleshooting

### Plugin Not Working?
- Check browser console for errors
- Ensure script tag is properly formatted
- Verify file path is correct

### Dashboard Not Opening?
- Press `Ctrl+Shift+V` (not Cmd on Mac)
- Check `window.XXMXLITracker` exists in console
- Ensure `dashboardEnabled` is not set to false

### No Location Data?
- IP detection requires internet connection
- Some browsers block geolocation APIs
- VPN/proxy users may show generic locations

## 📞 Support

For issues, questions, or feature requests:
- GitHub Issues: [Report a bug](https://github.com/n0rppa/XXMXLI/issues)
- Email: Contact via your website
- Demo: Check `plugin-demo.html` for working examples

## 📄 License

This plugin is part of the XXMXLI project. Use freely for personal and commercial projects.

---

**Made with 🔥 by XXMXLI**  
*Digital Studio - Hacker-style visitor tracking*
