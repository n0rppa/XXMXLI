<?php
/**
 * XXMXLI Advanced Analytics Configuration
 * Central configuration for all analytics features
 */

// Database/Storage Configuration
define('ANALYTICS_DATA_DIR', __DIR__ . '/../data/analytics/');
define('VISITOR_DATA_FILE', ANALYTICS_DATA_DIR . 'visitors.json');
define('EVENTS_DATA_FILE', ANALYTICS_DATA_DIR . 'events.json');
define('CONVERSIONS_DATA_FILE', ANALYTICS_DATA_DIR . 'conversions.json');
define('PERFORMANCE_DATA_FILE', ANALYTICS_DATA_DIR . 'performance.json');
define('HEATMAP_DATA_FILE', ANALYTICS_DATA_DIR . 'heatmaps.json');
define('AB_TESTS_DATA_FILE', ANALYTICS_DATA_DIR . 'ab_tests.json');
define('SEO_DATA_FILE', ANALYTICS_DATA_DIR . 'seo.json');

// Analytics Configuration
$ANALYTICS_CONFIG = [
    'enabled' => true,
    'debug' => false,
    'gdpr_compliance' => true,
    
    // Data retention (in days)
    'data_retention' => [
        'visitors' => 90,
        'events' => 30,
        'performance' => 7,
        'heatmaps' => 14,
        'conversions' => 365
    ],
    
    // Real-time features
    'websocket' => [
        'enabled' => true,
        'port' => 8080,
        'host' => 'localhost'
    ],
    
    // Performance monitoring
    'performance' => [
        'core_web_vitals' => true,
        'resource_timing' => true,
        'error_tracking' => true,
        'sampling_rate' => 1.0 // 100% sampling
    ],
    
    // Conversion tracking
    'conversions' => [
        'default_goals' => [
            'contact_form' => ['selector' => '#contact-form', 'event' => 'submit'],
            'newsletter_signup' => ['selector' => '.newsletter-form', 'event' => 'submit'],
            'download' => ['selector' => '[download]', 'event' => 'click'],
            'external_link' => ['selector' => 'a[href^="http"]:not([href*="xxmxli.com"])', 'event' => 'click']
        ]
    ],
    
    // A/B Testing
    'ab_testing' => [
        'enabled' => true,
        'confidence_level' => 0.95,
        'min_sample_size' => 100
    ],
    
    // Heatmaps
    'heatmaps' => [
        'click_tracking' => true,
        'scroll_tracking' => true,
        'mouse_movement' => true,
        'form_analytics' => true,
        'sampling_rate' => 0.1 // 10% of visitors
    ],
    
    // SEO Analytics
    'seo' => [
        'keyword_tracking' => true,
        'meta_analysis' => true,
        'backlink_monitoring' => false, // Requires external API
        'google_search_console' => false // Requires API key
    ]
];

// Ensure analytics data directory exists
if (!is_dir(ANALYTICS_DATA_DIR)) {
    mkdir(ANALYTICS_DATA_DIR, 0755, true);
}

// Helper function to get config value
function getAnalyticsConfig($key = null) {
    global $ANALYTICS_CONFIG;
    if ($key === null) {
        return $ANALYTICS_CONFIG;
    }
    return $ANALYTICS_CONFIG[$key] ?? null;
}

// GDPR Compliance settings
$GDPR_CONFIG = [
    'cookie_consent_required' => true,
    'data_anonymization' => true,
    'opt_out_available' => true,
    'data_export_available' => true,
    'retention_policy_enforced' => true
];
?>