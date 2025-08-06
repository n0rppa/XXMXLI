<?php
/**
 * XXMXLI Analytics Event Collector
 * Central API endpoint for collecting all analytics events
 */

require_once '../config/analytics.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

// Check if analytics is enabled
if (!getAnalyticsConfig('enabled')) {
    http_response_code(503);
    echo json_encode(['error' => 'Analytics disabled']);
    exit;
}

// Get and validate input
$input = file_get_contents('php://input');
$eventData = json_decode($input, true);

if (!$eventData) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid JSON data']);
    exit;
}

// Validate required fields
$requiredFields = ['eventType', 'sessionId', 'userId', 'timestamp'];
foreach ($requiredFields as $field) {
    if (!isset($eventData[$field])) {
        http_response_code(400);
        echo json_encode(['error' => "Missing required field: $field"]);
        exit;
    }
}

// Sanitize and enrich event data
$cleanEvent = [
    'id' => uniqid('event_'),
    'eventType' => sanitize($eventData['eventType']),
    'sessionId' => sanitize($eventData['sessionId']),
    'userId' => sanitize($eventData['userId']),
    'timestamp' => $eventData['timestamp'],
    'url' => sanitize($eventData['url'] ?? ''),
    'ip' => getRealIP(),
    'userAgent' => sanitize($_SERVER['HTTP_USER_AGENT'] ?? ''),
    'data' => $eventData['data'] ?? []
];

// Add server-side data
$cleanEvent['serverTimestamp'] = date('c');
$cleanEvent['processed'] = true;

try {
    // Route to appropriate handler based on event type
    $result = routeEvent($cleanEvent);
    
    // Log to main events file
    logEvent($cleanEvent);
    
    // Return success response
    echo json_encode([
        'status' => 'success',
        'eventId' => $cleanEvent['id'],
        'result' => $result
    ]);
    
} catch (Exception $e) {
    error_log("Analytics error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error']);
}

function routeEvent($event) {
    $eventType = $event['eventType'];
    
    switch ($eventType) {
        case 'session_start':
        case 'session_end':
            return handleSessionEvent($event);
            
        case 'page_view':
            return handlePageViewEvent($event);
            
        case 'conversion':
            return handleConversionEvent($event);
            
        case 'performance':
            return handlePerformanceEvent($event);
            
        case 'heatmap_click':
        case 'heatmap_scroll':
        case 'heatmap_movement':
            return handleHeatmapEvent($event);
            
        case 'ab_test':
            return handleABTestEvent($event);
            
        case 'seo_event':
            return handleSEOEvent($event);
            
        case 'custom_event':
            return handleCustomEvent($event);
            
        case 'error':
            return handleErrorEvent($event);
            
        default:
            return handleGenericEvent($event);
    }
}

function handleSessionEvent($event) {
    $sessionFile = ANALYTICS_DATA_DIR . 'sessions.json';
    $sessions = loadDataFile($sessionFile);
    
    if ($event['eventType'] === 'session_start') {
        $sessions[] = [
            'sessionId' => $event['sessionId'],
            'userId' => $event['userId'],
            'startTime' => $event['timestamp'],
            'ip' => $event['ip'],
            'userAgent' => $event['userAgent'],
            'data' => $event['data']
        ];
    } else {
        // Update session end
        for ($i = count($sessions) - 1; $i >= 0; $i--) {
            if ($sessions[$i]['sessionId'] === $event['sessionId']) {
                $sessions[$i]['endTime'] = $event['timestamp'];
                $sessions[$i]['duration'] = $event['data']['duration'] ?? 0;
                break;
            }
        }
    }
    
    saveDataFile($sessionFile, $sessions);
    updateDailyStats('sessions', $event);
    
    return ['processed' => true];
}

function handlePageViewEvent($event) {
    $pageViewsFile = ANALYTICS_DATA_DIR . 'page_views.json';
    $pageViews = loadDataFile($pageViewsFile);
    
    $pageViews[] = [
        'sessionId' => $event['sessionId'],
        'userId' => $event['userId'],
        'timestamp' => $event['timestamp'],
        'url' => $event['url'],
        'page' => $event['data']['page'] ?? '',
        'referrer' => $event['data']['referrer'] ?? '',
        'ip' => $event['ip']
    ];
    
    saveDataFile($pageViewsFile, $pageViews);
    updateDailyStats('page_views', $event);
    
    return ['processed' => true];
}

function handleConversionEvent($event) {
    $conversionsFile = ANALYTICS_DATA_DIR . 'conversions.json';
    $conversions = loadDataFile($conversionsFile);
    
    $conversions[] = [
        'sessionId' => $event['sessionId'],
        'userId' => $event['userId'],
        'timestamp' => $event['timestamp'],
        'goal' => $event['data']['goal'] ?? 'unknown',
        'value' => $event['data']['value'] ?? 0,
        'step' => $event['data']['step'] ?? 1,
        'funnel' => $event['data']['funnel'] ?? 'default',
        'url' => $event['url'],
        'ip' => $event['ip']
    ];
    
    saveDataFile($conversionsFile, $conversions);
    updateDailyStats('conversions', $event);
    
    return ['processed' => true];
}

function handlePerformanceEvent($event) {
    $performanceFile = ANALYTICS_DATA_DIR . 'performance.json';
    $performance = loadDataFile($performanceFile);
    
    $performance[] = [
        'sessionId' => $event['sessionId'],
        'userId' => $event['userId'],
        'timestamp' => $event['timestamp'],
        'url' => $event['url'],
        'metrics' => $event['data'],
        'ip' => $event['ip']
    ];
    
    saveDataFile($performanceFile, $performance);
    updateDailyStats('performance', $event);
    
    return ['processed' => true];
}

function handleHeatmapEvent($event) {
    $heatmapFile = ANALYTICS_DATA_DIR . 'heatmaps.json';
    $heatmaps = loadDataFile($heatmapFile);
    
    $heatmaps[] = [
        'sessionId' => $event['sessionId'],
        'userId' => $event['userId'],
        'timestamp' => $event['timestamp'],
        'type' => str_replace('heatmap_', '', $event['eventType']),
        'url' => $event['url'],
        'data' => $event['data'],
        'ip' => $event['ip']
    ];
    
    saveDataFile($heatmapFile, $heatmaps);
    updateDailyStats('heatmaps', $event);
    
    return ['processed' => true];
}

function handleABTestEvent($event) {
    $abTestFile = ANALYTICS_DATA_DIR . 'ab_tests.json';
    $abTests = loadDataFile($abTestFile);
    
    $abTests[] = [
        'sessionId' => $event['sessionId'],
        'userId' => $event['userId'],
        'timestamp' => $event['timestamp'],
        'testId' => $event['data']['testId'] ?? 'unknown',
        'variant' => $event['data']['variant'] ?? 'control',
        'event' => $event['data']['event'] ?? 'view',
        'url' => $event['url'],
        'ip' => $event['ip']
    ];
    
    saveDataFile($abTestFile, $abTests);
    updateDailyStats('ab_tests', $event);
    
    return ['processed' => true];
}

function handleSEOEvent($event) {
    $seoFile = ANALYTICS_DATA_DIR . 'seo.json';
    $seo = loadDataFile($seoFile);
    
    $seo[] = [
        'sessionId' => $event['sessionId'],
        'userId' => $event['userId'],
        'timestamp' => $event['timestamp'],
        'url' => $event['url'],
        'searchEngine' => $event['data']['searchEngine'] ?? '',
        'keyword' => $event['data']['keyword'] ?? '',
        'rank' => $event['data']['rank'] ?? 0,
        'ip' => $event['ip']
    ];
    
    saveDataFile($seoFile, $seo);
    updateDailyStats('seo', $event);
    
    return ['processed' => true];
}

function handleCustomEvent($event) {
    $customFile = ANALYTICS_DATA_DIR . 'custom_events.json';
    $customs = loadDataFile($customFile);
    
    $customs[] = [
        'sessionId' => $event['sessionId'],
        'userId' => $event['userId'],
        'timestamp' => $event['timestamp'],
        'eventName' => $event['data']['eventName'] ?? 'unknown',
        'category' => $event['data']['category'] ?? 'general',
        'value' => $event['data']['value'] ?? null,
        'properties' => $event['data']['properties'] ?? [],
        'url' => $event['url'],
        'ip' => $event['ip']
    ];
    
    saveDataFile($customFile, $customs);
    updateDailyStats('custom_events', $event);
    
    return ['processed' => true];
}

function handleErrorEvent($event) {
    $errorFile = ANALYTICS_DATA_DIR . 'errors.json';
    $errors = loadDataFile($errorFile);
    
    $errors[] = [
        'sessionId' => $event['sessionId'],
        'userId' => $event['userId'],
        'timestamp' => $event['timestamp'],
        'url' => $event['url'],
        'message' => $event['data']['message'] ?? '',
        'filename' => $event['data']['filename'] ?? '',
        'lineno' => $event['data']['lineno'] ?? 0,
        'stack' => $event['data']['stack'] ?? '',
        'ip' => $event['ip']
    ];
    
    saveDataFile($errorFile, $errors);
    updateDailyStats('errors', $event);
    
    return ['processed' => true];
}

function handleGenericEvent($event) {
    // For any unhandled event types, just log them
    updateDailyStats('generic_events', $event);
    return ['processed' => true];
}

function logEvent($event) {
    $eventsFile = ANALYTICS_DATA_DIR . 'all_events.json';
    $events = loadDataFile($eventsFile);
    
    $events[] = $event;
    
    // Keep only recent events to prevent file bloat
    $maxEvents = 50000;
    if (count($events) > $maxEvents) {
        $events = array_slice($events, -$maxEvents);
    }
    
    saveDataFile($eventsFile, $events);
}

function updateDailyStats($category, $event) {
    $date = date('Y-m-d');
    $statsFile = ANALYTICS_DATA_DIR . 'daily_stats.json';
    $stats = loadDataFile($statsFile);
    
    if (!isset($stats[$date])) {
        $stats[$date] = [];
    }
    
    if (!isset($stats[$date][$category])) {
        $stats[$date][$category] = ['count' => 0, 'unique_users' => [], 'unique_sessions' => []];
    }
    
    $stats[$date][$category]['count']++;
    
    // Track unique users and sessions
    if (!in_array($event['userId'], $stats[$date][$category]['unique_users'])) {
        $stats[$date][$category]['unique_users'][] = $event['userId'];
    }
    
    if (!in_array($event['sessionId'], $stats[$date][$category]['unique_sessions'])) {
        $stats[$date][$category]['unique_sessions'][] = $event['sessionId'];
    }
    
    saveDataFile($statsFile, $stats);
}

function loadDataFile($filename) {
    if (!file_exists($filename)) {
        return [];
    }
    
    $content = file_get_contents($filename);
    if ($content === false) {
        return [];
    }
    
    $data = json_decode($content, true);
    return $data === null ? [] : $data;
}

function saveDataFile($filename, $data) {
    $json = json_encode($data, JSON_PRETTY_PRINT);
    
    // Ensure directory exists
    $dir = dirname($filename);
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
    
    file_put_contents($filename, $json, LOCK_EX);
}

function sanitize($input) {
    if (is_string($input)) {
        return htmlspecialchars(trim($input), ENT_QUOTES, 'UTF-8');
    }
    return $input;
}

function getRealIP() {
    $headers = [
        'HTTP_CF_CONNECTING_IP',     // Cloudflare
        'HTTP_CLIENT_IP',            // Proxy
        'HTTP_X_FORWARDED_FOR',      // Load balancer/proxy
        'HTTP_X_FORWARDED',          // Proxy
        'HTTP_X_CLUSTER_CLIENT_IP',  // Cluster
        'HTTP_FORWARDED_FOR',        // Proxy
        'HTTP_FORWARDED',            // Proxy
        'REMOTE_ADDR'                // Standard
    ];

    foreach ($headers as $header) {
        if (isset($_SERVER[$header]) && !empty($_SERVER[$header])) {
            $ips = explode(',', $_SERVER[$header]);
            $ip = trim($ips[0]);
            
            if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
                return $ip;
            }
        }
    }

    return $_SERVER['REMOTE_ADDR'] ?? 'unknown';
}
?>