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

try {
    header('Content-Type: application/json');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');

    // Handle preflight requests
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(200);
        exit;
    }

    // Configuration
    $DATA_DIR = '../data/';
    $VISITORS_FILE = $DATA_DIR . 'visitors.json';
    $DAILY_STATS_FILE = $DATA_DIR . 'daily_stats.json';

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
            return $v['isBlocked'] ?? false;
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
        $countries = getCountryStats($visitors);
        echo json_encode($countries);
        break;
        
    case 'browsers':
        $browsers = getBrowserStats($visitors);
        echo json_encode($browsers);
        break;
        
    default:
        http_response_code(400);
        echo json_encode(['error' => 'Invalid action']);
        break;
}

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
                return $v['isBlocked'] ?? false;
            })),
            'botVisitors' => count(array_filter($visitors, function($v) {
                return $v['securityFlags']['botDetected'] ?? false;
            }))
        ],
        'timeframe' => [
            'last24h' => array_filter($visitors, function($v) use ($last24h) {
                return strtotime($v['timestamp']) > $last24h;
            }),
            'last7d' => array_filter($visitors, function($v) use ($last7d) {
                return strtotime($v['timestamp']) > $last7d;
            }),
            'today' => array_filter($visitors, function($v) use ($today) {
                return date('Y-m-d', strtotime($v['timestamp'])) === $today;
            })
        ],
        'topCountries' => getTopCountries($visitors, 10),
        'topISPs' => getTopISPs($visitors, 10),
        'topBrowsers' => getTopBrowsers($visitors, 10),
        'recentVisitors' => array_slice(array_reverse($visitors), 0, 10),
        'dailyTrend' => getDailyTrend($dailyStats, 7)
    ];
    
    // Convert timeframe arrays to counts
    $stats['timeframe']['last24h'] = count($stats['timeframe']['last24h']);
    $stats['timeframe']['last7d'] = count($stats['timeframe']['last7d']);
    $stats['timeframe']['today'] = count($stats['timeframe']['today']);
    
    return $stats;
}

function getTopCountries($visitors, $limit) {
    $countries = [];
    foreach ($visitors as $visitor) {
        $country = $visitor['location']['country'] ?? 'Unknown';
        $countries[$country] = ($countries[$country] ?? 0) + 1;
    }
    arsort($countries);
    return array_slice($countries, 0, $limit, true);
}

function getTopISPs($visitors, $limit) {
    $isps = [];
    foreach ($visitors as $visitor) {
        $isp = $visitor['location']['isp'] ?? 'Unknown';
        $isps[$isp] = ($isps[$isp] ?? 0) + 1;
    }
    arsort($isps);
    return array_slice($isps, 0, $limit, true);
}

function getTopBrowsers($visitors, $limit) {
    $browsers = [];
    foreach ($visitors as $visitor) {
        $browser = $visitor['browser']['name'] ?? 'Unknown';
        $browsers[$browser] = ($browsers[$browser] ?? 0) + 1;
    }
    arsort($browsers);
    return array_slice($browsers, 0, $limit, true);
}

function getCountryStats($visitors) {
    $countries = [];
    foreach ($visitors as $visitor) {
        $country = $visitor['location']['country'] ?? 'Unknown';
        $countryCode = $visitor['location']['countryCode'] ?? 'XX';
        
        if (!isset($countries[$country])) {
            $countries[$country] = [
                'name' => $country,
                'code' => $countryCode,
                'visits' => 0,
                'blocked' => 0,
                'uniqueIPs' => []
            ];
        }
        
        $countries[$country]['visits']++;
        if ($visitor['isBlocked'] ?? false) {
            $countries[$country]['blocked']++;
        }
        
        $ip = $visitor['ip'];
        if (!in_array($ip, $countries[$country]['uniqueIPs'])) {
            $countries[$country]['uniqueIPs'][] = $ip;
        }
    }
    
    // Convert uniqueIPs to count and sort
    foreach ($countries as &$country) {
        $country['uniqueIPs'] = count($country['uniqueIPs']);
    }
    
    uasort($countries, function($a, $b) {
        return $b['visits'] - $a['visits'];
    });
    
    return array_values($countries);
}

function getBrowserStats($visitors) {
    $browsers = [];
    foreach ($visitors as $visitor) {
        $browser = $visitor['browser']['name'] ?? 'Unknown';
        $version = $visitor['browser']['version'] ?? 'Unknown';
        
        if (!isset($browsers[$browser])) {
            $browsers[$browser] = [
                'name' => $browser,
                'visits' => 0,
                'versions' => []
            ];
        }
        
        $browsers[$browser]['visits']++;
        $browsers[$browser]['versions'][$version] = ($browsers[$browser]['versions'][$version] ?? 0) + 1;
    }
    
    // Sort versions within each browser
    foreach ($browsers as &$browser) {
        arsort($browser['versions']);
    }
    
    uasort($browsers, function($a, $b) {
        return $b['visits'] - $a['visits'];
    });
    
    return array_values($browsers);
}

function getDailyTrend($dailyStats, $days) {
    $trend = [];
    for ($i = $days - 1; $i >= 0; $i--) {
        $date = date('Y-m-d', strtotime("-$i days"));
        $dayStats = $dailyStats[$date] ?? null;
        
        $trend[] = [
            'date' => $date,
            'visits' => $dayStats['totalVisits'] ?? 0,
            'uniqueIPs' => count($dayStats['uniqueIPs'] ?? []),
            'blockedAttempts' => $dayStats['blockedAttempts'] ?? 0
        ];
    }
    
    return $trend;
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
