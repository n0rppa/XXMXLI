<?php
/**
 * XXMXLI User Analytics API
 * Provides metrics and chart data for user analytics dashboard
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
    $dateRange = isset($_GET['range']) ? (int)$_GET['range'] : 7;
    $dateFrom = date('Y-m-d', strtotime("-{$dateRange} days"));
    $dateTo = date('Y-m-d');

    // Calculate metrics
    $metrics = calculateMetrics($dateFrom, $dateTo);
    
    // Generate chart data
    $chartData = generateChartData($dateFrom, $dateTo);
    
    // Get real-time data
    $realtimeData = getRealtimeData();

    echo json_encode([
        'status' => 'success',
        'metrics' => $metrics,
        'chartData' => $chartData,
        'realtimeData' => $realtimeData,
        'dateRange' => [
            'from' => $dateFrom,
            'to' => $dateTo
        ]
    ]);

} catch (Exception $e) {
    error_log("User Analytics API error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error']);
}

function calculateMetrics($dateFrom, $dateTo) {
    // Load data files
    $pageViews = loadDataFile(ANALYTICS_DATA_DIR . 'page_views.json');
    $sessions = loadDataFile(ANALYTICS_DATA_DIR . 'sessions.json');
    $conversions = loadDataFile(ANALYTICS_DATA_DIR . 'conversions.json');

    // Filter data by date range
    $pageViews = filterByDateRange($pageViews, $dateFrom, $dateTo);
    $sessions = filterByDateRange($sessions, $dateFrom, $dateTo);
    $conversions = filterByDateRange($conversions, $dateFrom, $dateTo);

    // Calculate page views
    $totalPageViews = count($pageViews);

    // Calculate unique visitors
    $uniqueUsers = array_unique(array_column($pageViews, 'userId'));
    $uniqueVisitors = count($uniqueUsers);

    // Calculate bounce rate
    $bounceRate = calculateBounceRate($sessions, $pageViews);

    // Calculate average session duration
    $avgSessionDuration = calculateAvgSessionDuration($sessions);

    // Count conversions
    $totalConversions = count($conversions);

    return [
        'pageViews' => $totalPageViews,
        'uniqueVisitors' => $uniqueVisitors,
        'bounceRate' => $bounceRate,
        'sessionDuration' => $avgSessionDuration,
        'conversions' => $totalConversions
    ];
}

function generateChartData($dateFrom, $dateTo) {
    $pageViews = loadDataFile(ANALYTICS_DATA_DIR . 'page_views.json');
    $sessions = loadDataFile(ANALYTICS_DATA_DIR . 'sessions.json');

    // Generate date labels
    $labels = [];
    $current = strtotime($dateFrom);
    $end = strtotime($dateTo);
    
    while ($current <= $end) {
        $labels[] = date('M j', $current);
        $current = strtotime('+1 day', $current);
    }

    // Page views data
    $pageViewsData = [];
    $uniqueVisitorsData = [];
    $bounceRateData = [];

    foreach ($labels as $index => $label) {
        $date = date('Y-m-d', strtotime($dateFrom . " +{$index} days"));
        
        // Count page views for this date
        $dayPageViews = array_filter($pageViews, function($pv) use ($date) {
            return date('Y-m-d', strtotime($pv['timestamp'])) === $date;
        });
        $pageViewsData[] = count($dayPageViews);

        // Count unique visitors for this date
        $dayUsers = array_unique(array_column($dayPageViews, 'userId'));
        $uniqueVisitorsData[] = count($dayUsers);

        // Calculate bounce rate for this date
        $daySessions = array_filter($sessions, function($s) use ($date) {
            return date('Y-m-d', strtotime($s['startTime'])) === $date;
        });
        $bounceRateData[] = calculateBounceRate($daySessions, $dayPageViews);
    }

    return [
        'pageViews' => [
            'labels' => $labels,
            'values' => $pageViewsData
        ],
        'uniqueVisitors' => [
            'labels' => $labels,
            'values' => $uniqueVisitorsData
        ],
        'bounceRate' => [
            'labels' => $labels,
            'values' => $bounceRateData
        ]
    ];
}

function getRealtimeData() {
    // Get recent events (last 5 minutes)
    $recentTime = date('c', strtotime('-5 minutes'));
    $allEvents = loadDataFile(ANALYTICS_DATA_DIR . 'all_events.json');
    
    $recentEvents = array_filter($allEvents, function($event) use ($recentTime) {
        return $event['timestamp'] >= $recentTime;
    });

    // Count active users (last 30 minutes)
    $activeTime = date('c', strtotime('-30 minutes'));
    $activeEvents = array_filter($allEvents, function($event) use ($activeTime) {
        return $event['timestamp'] >= $activeTime;
    });
    
    $activeUsers = array_unique(array_column($activeEvents, 'userId'));

    return [
        'activeUsers' => count($activeUsers),
        'recentEvents' => array_slice(array_reverse($recentEvents), 0, 20),
        'currentTime' => date('c')
    ];
}

function calculateBounceRate($sessions, $pageViews) {
    if (empty($sessions)) return 0;

    $bouncedSessions = 0;
    
    foreach ($sessions as $session) {
        // Count page views for this session
        $sessionPageViews = array_filter($pageViews, function($pv) use ($session) {
            return $pv['sessionId'] === $session['sessionId'];
        });
        
        // If only one page view, it's a bounce
        if (count($sessionPageViews) <= 1) {
            $bouncedSessions++;
        }
    }

    return round(($bouncedSessions / count($sessions)) * 100, 2);
}

function calculateAvgSessionDuration($sessions) {
    if (empty($sessions)) return 0;

    $totalDuration = 0;
    $validSessions = 0;

    foreach ($sessions as $session) {
        if (isset($session['endTime']) && isset($session['startTime'])) {
            $duration = strtotime($session['endTime']) - strtotime($session['startTime']);
            if ($duration > 0) {
                $totalDuration += $duration;
                $validSessions++;
            }
        }
    }

    return $validSessions > 0 ? round($totalDuration / $validSessions) : 0;
}

function filterByDateRange($data, $dateFrom, $dateTo) {
    return array_filter($data, function($item) use ($dateFrom, $dateTo) {
        $itemDate = date('Y-m-d', strtotime($item['timestamp']));
        return $itemDate >= $dateFrom && $itemDate <= $dateTo;
    });
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