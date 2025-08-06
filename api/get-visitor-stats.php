<?php
/**
 * XXMXLI Visitor Statistics API
 * Returns visitor analytics and statistics
 */

// Error reporting for debugging - remove in production
error_reporting(E_ALL);
ini_set('display_errors', 0); // Don't display errors to browser
ini_set('log_errors', 1);

// Capture any output that might interfere with JSON
ob_start();

// Headers
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    // Configuration
    $DATA_DIR = '../data/';
    $VISITORS_FILE = $DATA_DIR . 'visitors.json';
    $DAILY_STATS_FILE = $DATA_DIR . 'daily_stats.json';

    // Function definitions
    function calculateStatistics($visitors, $dailyStats) {
        $now = time();
        $today = date('Y-m-d');
        
        // Time periods
        $last24h = $now - (24 * 3600);
        $last7d = $now - (7 * 24 * 3600);
        
        $stats = [
            'overview' => [
                'totalVisitors' => count($visitors),
                'uniqueIPs' => count(array_unique(array_column($visitors, 'ip'))),
                'blockedVisitors' => count(array_filter($visitors, function($v) {
                    return $v['blocked'] ?? $v['isBlocked'] ?? false;
                })),
                'botVisitors' => count(array_filter($visitors, function($v) {
                    return ($v['securityFlags']['botDetected'] ?? false) || 
                           stripos($v['userAgent'] ?? '', 'bot') !== false;
                }))
            ],
            'timeframe' => [
                'last24h' => count(array_filter($visitors, function($v) use ($last24h) {
                    return strtotime($v['timestamp']) > $last24h;
                })),
                'last7d' => count(array_filter($visitors, function($v) use ($last7d) {
                    return strtotime($v['timestamp']) > $last7d;
                })),
                'today' => count(array_filter($visitors, function($v) use ($today) {
                    return date('Y-m-d', strtotime($v['timestamp'])) === $today;
                }))
            ],
            'topCountries' => getTopCountries($visitors, 10),
            'topBrowsers' => getTopBrowsers($visitors, 10),
            'recentVisitors' => array_slice(array_reverse($visitors), 0, 10),
            'dailyTrend' => getDailyTrend($dailyStats, 7)
        ];
        
        return $stats;
    }

    function getTopCountries($visitors, $limit) {
        $countries = [];
        foreach ($visitors as $visitor) {
            $country = $visitor['country'] ?? $visitor['location']['country'] ?? 'Unknown';
            $countries[$country] = ($countries[$country] ?? 0) + 1;
        }
        arsort($countries);
        $result = [];
        $i = 0;
        foreach ($countries as $name => $visits) {
            if ($i >= $limit) break;
            $result[] = ['name' => $name, 'visits' => $visits];
            $i++;
        }
        return $result;
    }

    function getTopBrowsers($visitors, $limit) {
        $browsers = [];
        foreach ($visitors as $visitor) {
            $userAgent = $visitor['userAgent'] ?? '';
            $browser = 'Unknown';
            
            if (stripos($userAgent, 'Chrome') !== false) $browser = 'Chrome';
            elseif (stripos($userAgent, 'Firefox') !== false) $browser = 'Firefox';
            elseif (stripos($userAgent, 'Safari') !== false) $browser = 'Safari';
            elseif (stripos($userAgent, 'Edge') !== false) $browser = 'Edge';
            elseif (stripos($userAgent, 'Opera') !== false) $browser = 'Opera';
            
            $browsers[$browser] = ($browsers[$browser] ?? 0) + 1;
        }
        arsort($browsers);
        $result = [];
        $i = 0;
        foreach ($browsers as $name => $visits) {
            if ($i >= $limit) break;
            $result[] = ['name' => $name, 'visits' => $visits];
            $i++;
        }
        return $result;
    }

    function getDailyTrend($dailyStats, $days) {
        $trend = [];
        for ($i = $days - 1; $i >= 0; $i--) {
            $date = date('Y-m-d', strtotime("-$i days"));
            $dayStats = $dailyStats[$date] ?? null;
            
            $trend[] = [
                'date' => $date,
                'visits' => $dayStats['visits'] ?? 0,
                'uniqueIPs' => is_array($dayStats['uniqueIPs'] ?? null) ? 
                             count($dayStats['uniqueIPs']) : 
                             ($dayStats['uniqueIPs'] ?? 0),
                'blocked' => $dayStats['blocked'] ?? 0
            ];
        }
        
        return $trend;
    }

    // Load visitors data
    $visitors = [];
    if (file_exists($VISITORS_FILE)) {
        $visitorsRaw = json_decode(file_get_contents($VISITORS_FILE), true) ?? [];
        // Handle both array format and object format
        if (isset($visitorsRaw['visitors'])) {
            $visitors = $visitorsRaw['visitors'];
        } else if (is_array($visitorsRaw)) {
            $visitors = $visitorsRaw;
        }
    }

    // Load daily stats
    $dailyStats = [];
    if (file_exists($DAILY_STATS_FILE)) {
        $dailyStats = json_decode(file_get_contents($DAILY_STATS_FILE), true) ?? [];
    }

    // Get query parameters
    $action = $_GET['action'] ?? 'overview';
    $limit = min(intval($_GET['limit'] ?? 100), 1000); // Max 1000 records
    $offset = intval($_GET['offset'] ?? 0);

    switch ($action) {
        case 'overview':
            $stats = calculateStatistics($visitors, $dailyStats);
            echo json_encode($stats);
            break;
            
        case 'visitors':
            $visitorList = array_slice(array_reverse($visitors), $offset, $limit);
            echo json_encode([
                'visitors' => $visitorList,
                'total' => count($visitors),
                'offset' => $offset,
                'limit' => $limit
            ]);
            break;
            
        case 'blocked':
            $blockedVisitors = array_filter($visitors, function($v) {
                return $v['blocked'] ?? $v['isBlocked'] ?? false;
            });
            $blockedList = array_slice(array_reverse($blockedVisitors), $offset, $limit);
            echo json_encode([
                'blocked' => $blockedList,
                'total' => count($blockedVisitors),
                'offset' => $offset,
                'limit' => $limit
            ]);
            break;
            
        case 'daily':
            echo json_encode($dailyStats);
            break;
            
        case 'countries':
            $countries = getTopCountries($visitors, 50);
            echo json_encode($countries);
            break;
            
        case 'browsers':
            $browsers = getTopBrowsers($visitors, 20);
            echo json_encode($browsers);
            break;
            
        default:
            http_response_code(400);
            echo json_encode(['error' => 'Invalid action']);
            break;
    }

} catch (Exception $e) {
    // Clear any output buffer
    ob_clean();
    
    // Log the error
    error_log("XXMXLI API Error: " . $e->getMessage());
    
    // Return error as JSON
    http_response_code(500);
    echo json_encode([
        'error' => 'Internal server error',
        'message' => 'Failed to load visitor statistics',
        'debug' => $e->getMessage() // Remove this in production
    ]);
} finally {
    // Clear output buffer and send response
    ob_end_flush();
}
?>
