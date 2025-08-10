<?php
/**
 * XXMXLI Real-time Visitors API
 * Provides current visitor count and real-time visitor data
 */

require_once '../../config/analytics.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit;
}

try {
    // Get active visitors (last 5 minutes)
    $activeThreshold = date('c', strtotime('-5 minutes'));
    $visitors = getActiveVisitors($activeThreshold);
    
    // Get geographic distribution
    $locations = getVisitorLocations($visitors);
    
    // Get current page tracking
    $currentPages = getCurrentPageTracking();

    echo json_encode([
        'status' => 'success',
        'count' => count($visitors),
        'visitors' => $visitors,
        'locations' => $locations,
        'currentPages' => $currentPages,
        'timestamp' => date('c')
    ]);

} catch (Exception $e) {
    error_log("Real-time visitors API error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error']);
}

function getActiveVisitors($activeThreshold) {
    // Load recent events to determine active visitors
    $allEvents = loadDataFile(ANALYTICS_DATA_DIR . 'all_events.json');
    
    // Get events from active threshold
    $recentEvents = array_filter($allEvents, function($event) use ($activeThreshold) {
        return $event['timestamp'] >= $activeThreshold;
    });

    // Group by session to get unique active visitors
    $activeSessions = [];
    
    foreach ($recentEvents as $event) {
        $sessionId = $event['sessionId'];
        
        if (!isset($activeSessions[$sessionId])) {
            $activeSessions[$sessionId] = [
                'sessionId' => $sessionId,
                'userId' => $event['userId'],
                'firstSeen' => $event['timestamp'],
                'lastSeen' => $event['timestamp'],
                'currentPage' => $event['url'] ?? '/',
                'country' => null,
                'ip' => $event['ip'] ?? 'unknown',
                'userAgent' => $event['userAgent'] ?? '',
                'isActive' => true
            ];
        } else {
            // Update last seen time and current page
            $activeSessions[$sessionId]['lastSeen'] = max(
                $activeSessions[$sessionId]['lastSeen'], 
                $event['timestamp']
            );
            
            if (isset($event['url'])) {
                $activeSessions[$sessionId]['currentPage'] = $event['url'];
            }
        }

        // Update location if available
        if ($event['eventType'] === 'visitor_location' && isset($event['data']['location'])) {
            $activeSessions[$sessionId]['country'] = $event['data']['location']['country'];
            $activeSessions[$sessionId]['city'] = $event['data']['location']['city'];
            $activeSessions[$sessionId]['location'] = $event['data']['location'];
        }
    }

    // Determine if visitors are currently active (last heartbeat within 2 minutes)
    $heartbeatThreshold = date('c', strtotime('-2 minutes'));
    
    foreach ($activeSessions as &$session) {
        $session['isActive'] = $session['lastSeen'] >= $heartbeatThreshold;
        $session['page'] = parse_url($session['currentPage'], PHP_URL_PATH) ?: '/';
    }

    return array_values($activeSessions);
}

function getVisitorLocations($visitors) {
    $locations = [];
    
    foreach ($visitors as $visitor) {
        if (isset($visitor['location'])) {
            $locations[] = $visitor['location'];
        } elseif (isset($visitor['country'])) {
            $locations[] = [
                'country' => $visitor['country'],
                'city' => $visitor['city'] ?? null
            ];
        }
    }

    return $locations;
}

function getCurrentPageTracking() {
    // Get current page distribution
    $allEvents = loadDataFile(ANALYTICS_DATA_DIR . 'all_events.json');
    
    // Get recent page views (last 30 minutes)
    $recentThreshold = date('c', strtotime('-30 minutes'));
    $recentPageViews = array_filter($allEvents, function($event) use ($recentThreshold) {
        return $event['eventType'] === 'page_view' && $event['timestamp'] >= $recentThreshold;
    });

    // Count pages
    $pageStats = [];
    foreach ($recentPageViews as $event) {
        $page = parse_url($event['url'], PHP_URL_PATH) ?: '/';
        $pageStats[$page] = ($pageStats[$page] ?? 0) + 1;
    }

    // Sort by popularity
    arsort($pageStats);

    return [
        'pages' => array_slice($pageStats, 0, 10, true), // Top 10 pages
        'total' => array_sum($pageStats)
    ];
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
?>