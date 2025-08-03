<?php
/**
 * XXMXLI Visitor Logger API
 * Logs visitor data to JSON file with security checks
 */

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

// Configuration
$DATA_DIR = '../data/';
$VISITORS_FILE = $DATA_DIR . 'visitors.json';
$DAILY_STATS_FILE = $DATA_DIR . 'daily_stats.json';
$MAX_LOG_SIZE = 10 * 1024 * 1024; // 10MB max log file
$MAX_ENTRIES = 10000; // Maximum number of visitor entries

// Ensure data directory exists
if (!is_dir($DATA_DIR)) {
    if (!mkdir($DATA_DIR, 0755, true)) {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to create data directory']);
        exit;
    }
}

// Get and validate input
$input = file_get_contents('php://input');
$visitorData = json_decode($input, true);

if (!$visitorData) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid JSON data']);
    exit;
}

// Validate required fields
$requiredFields = ['ip', 'timestamp', 'sessionId'];
foreach ($requiredFields as $field) {
    if (!isset($visitorData[$field])) {
        http_response_code(400);
        echo json_encode(['error' => "Missing required field: $field"]);
        exit;
    }
}

// Get real visitor IP (handle proxies/CDN)
function getRealIP() {
    $ipKeys = [
        'HTTP_CF_CONNECTING_IP',    // Cloudflare
        'HTTP_X_FORWARDED_FOR',     // Proxy
        'HTTP_X_REAL_IP',           // Nginx
        'HTTP_X_CLIENT_IP',         // Proxy
        'REMOTE_ADDR'               // Standard
    ];
    
    foreach ($ipKeys as $key) {
        if (!empty($_SERVER[$key])) {
            $ip = $_SERVER[$key];
            // Handle comma-separated IPs
            if (strpos($ip, ',') !== false) {
                $ip = trim(explode(',', $ip)[0]);
            }
            // Validate IP
            if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
                return $ip;
            }
        }
    }
    return $_SERVER['REMOTE_ADDR'] ?? 'Unknown';
}

// Add server-side data
$visitorData['serverIP'] = getRealIP();
$visitorData['serverTime'] = date('Y-m-d H:i:s');
$visitorData['userAgent'] = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
$visitorData['requestMethod'] = $_SERVER['REQUEST_METHOD'];
$visitorData['httpHost'] = $_SERVER['HTTP_HOST'] ?? 'Unknown';
$visitorData['requestUri'] = $_SERVER['REQUEST_URI'] ?? 'Unknown';

// Security checks
$visitorData['securityFlags'] = [
    'proxyDetected' => ($visitorData['ip'] !== $visitorData['serverIP']),
    'suspiciousUA' => checkSuspiciousUserAgent($visitorData['userAgent']),
    'botDetected' => checkIfBot($visitorData['userAgent']),
    'vpnDetected' => false // Would need external API for VPN detection
];

function checkSuspiciousUserAgent($ua) {
    $suspiciousPatterns = [
        'curl', 'wget', 'python', 'bot', 'crawler', 'spider', 'scraper',
        'hack', 'attack', 'exploit', 'scan', 'vulnerability'
    ];
    
    foreach ($suspiciousPatterns as $pattern) {
        if (stripos($ua, $pattern) !== false) {
            return true;
        }
    }
    return false;
}

function checkIfBot($ua) {
    $botPatterns = [
        'googlebot', 'bingbot', 'slurp', 'duckduckbot', 'baiduspider',
        'yandexbot', 'facebookexternalhit', 'twitterbot', 'linkedinbot'
    ];
    
    foreach ($botPatterns as $pattern) {
        if (stripos($ua, $pattern) !== false) {
            return true;
        }
    }
    return false;
}

// Load existing visitors data
$visitors = [];
if (file_exists($VISITORS_FILE)) {
    $existingData = file_get_contents($VISITORS_FILE);
    $visitors = json_decode($existingData, true) ?? [];
}

// Check file size and truncate if necessary
if (file_exists($VISITORS_FILE) && filesize($VISITORS_FILE) > $MAX_LOG_SIZE) {
    // Keep only the most recent entries
    $visitors = array_slice($visitors, -($MAX_ENTRIES / 2));
}

// Add new visitor data
$visitors[] = $visitorData;

// Keep only recent entries
if (count($visitors) > $MAX_ENTRIES) {
    $visitors = array_slice($visitors, -$MAX_ENTRIES);
}

// Save visitors data
$jsonData = json_encode($visitors, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
if (file_put_contents($VISITORS_FILE, $jsonData, LOCK_EX) === false) {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to save visitor data']);
    exit;
}

// Update daily statistics
updateDailyStats($visitorData);

// Prepare response
$response = [
    'success' => true,
    'message' => 'Visitor data logged successfully',
    'sessionId' => $visitorData['sessionId'],
    'serverTime' => $visitorData['serverTime'],
    'visitorCount' => count($visitors),
    'securityFlags' => $visitorData['securityFlags']
];

echo json_encode($response);

function updateDailyStats($visitorData) {
    global $DAILY_STATS_FILE;
    
    $today = date('Y-m-d');
    $stats = [];
    
    // Load existing stats
    if (file_exists($DAILY_STATS_FILE)) {
        $stats = json_decode(file_get_contents($DAILY_STATS_FILE), true) ?? [];
    }
    
    // Initialize today's stats if not exists
    if (!isset($stats[$today])) {
        $stats[$today] = [
            'totalVisits' => 0,
            'uniqueIPs' => [],
            'countries' => [],
            'browsers' => [],
            'blockedVisits' => 0,
            'botVisits' => 0
        ];
    }
    
    // Update stats
    $todayStats = &$stats[$today];
    $todayStats['totalVisits']++;
    
    // Track unique IPs
    if (!in_array($visitorData['ip'], $todayStats['uniqueIPs'])) {
        $todayStats['uniqueIPs'][] = $visitorData['ip'];
    }
    
    // Track countries
    if (isset($visitorData['location']['country'])) {
        $country = $visitorData['location']['country'];
        $todayStats['countries'][$country] = ($todayStats['countries'][$country] ?? 0) + 1;
    }
    
    // Track browsers
    if (isset($visitorData['browser']['name'])) {
        $browser = $visitorData['browser']['name'];
        $todayStats['browsers'][$browser] = ($todayStats['browsers'][$browser] ?? 0) + 1;
    }
    
    // Track blocked visits
    if ($visitorData['isBlocked']) {
        $todayStats['blockedVisits']++;
    }
    
    // Track bot visits
    if ($visitorData['securityFlags']['botDetected']) {
        $todayStats['botVisits']++;
    }
    
    // Keep only last 30 days
    $stats = array_slice($stats, -30, null, true);
    
    // Save updated stats
    file_put_contents($DAILY_STATS_FILE, json_encode($stats, JSON_PRETTY_PRINT), LOCK_EX);
}
?>
