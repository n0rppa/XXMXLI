<?php
/**
 * XXMXLI Conversion Analytics API
 * Provides conversion metrics, funnel analysis, and ROI calculations
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
    $days = isset($_GET['days']) ? (int)$_GET['days'] : 7;
    $from = isset($_GET['from']) ? $_GET['from'] : date('c', strtotime("-{$days} days"));
    $to = isset($_GET['to']) ? $_GET['to'] : date('c');

    // Calculate conversion metrics
    $metrics = calculateConversionMetrics($from, $to);
    
    // Get goal statistics
    $goals = getGoalStatistics($from, $to);
    
    // Get funnel analysis
    $funnels = getFunnelAnalysis($from, $to);
    
    // Get recent conversions
    $recent = getRecentConversions(20);
    
    // Calculate ROI
    $roi = calculateROI($from, $to);

    echo json_encode([
        'status' => 'success',
        'metrics' => $metrics,
        'goals' => $goals,
        'funnels' => $funnels,
        'recent' => $recent,
        'roi' => $roi,
        'dateRange' => [
            'from' => $from,
            'to' => $to
        ]
    ]);

} catch (Exception $e) {
    error_log("Conversion Analytics API error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error']);
}

function calculateConversionMetrics($from, $to) {
    // Load conversion data
    $conversions = loadDataFile(ANALYTICS_DATA_DIR . 'conversions.json');
    $pageViews = loadDataFile(ANALYTICS_DATA_DIR . 'page_views.json');

    // Filter by date range
    $conversions = filterByDateRange($conversions, $from, $to);
    $pageViews = filterByDateRange($pageViews, $from, $to);

    $totalConversions = count($conversions);
    $totalPageViews = count($pageViews);
    $totalValue = array_sum(array_column($conversions, 'value'));

    $conversionRate = $totalPageViews > 0 ? ($totalConversions / $totalPageViews) * 100 : 0;

    // Calculate unique conversion rate
    $uniqueConversions = array_unique(array_column($conversions, 'userId'));
    $uniqueVisitors = array_unique(array_column($pageViews, 'userId'));
    $uniqueConversionRate = count($uniqueVisitors) > 0 ? (count($uniqueConversions) / count($uniqueVisitors)) * 100 : 0;

    return [
        'totalConversions' => $totalConversions,
        'totalPageViews' => $totalPageViews,
        'totalValue' => $totalValue,
        'conversionRate' => round($conversionRate, 2),
        'uniqueConversionRate' => round($uniqueConversionRate, 2),
        'averageValue' => $totalConversions > 0 ? round($totalValue / $totalConversions, 2) : 0
    ];
}

function getGoalStatistics($from, $to) {
    $conversions = loadDataFile(ANALYTICS_DATA_DIR . 'conversions.json');
    $conversions = filterByDateRange($conversions, $from, $to);

    $goalStats = [];

    // Group conversions by goal
    foreach ($conversions as $conversion) {
        $goalId = $conversion['goal'];
        
        if (!isset($goalStats[$goalId])) {
            $goalStats[$goalId] = [
                'conversions' => 0,
                'value' => 0,
                'uniqueUsers' => []
            ];
        }

        $goalStats[$goalId]['conversions']++;
        $goalStats[$goalId]['value'] += $conversion['value'] ?? 0;
        
        if (!in_array($conversion['userId'], $goalStats[$goalId]['uniqueUsers'])) {
            $goalStats[$goalId]['uniqueUsers'][] = $conversion['userId'];
        }
    }

    // Calculate final statistics
    foreach ($goalStats as $goalId => &$stats) {
        $stats['uniqueConversions'] = count($stats['uniqueUsers']);
        unset($stats['uniqueUsers']); // Remove the array to keep response clean
    }

    return $goalStats;
}

function getFunnelAnalysis($from, $to) {
    $allEvents = loadDataFile(ANALYTICS_DATA_DIR . 'all_events.json');
    $allEvents = filterByDateRange($allEvents, $from, $to);

    // Define funnels (should match the JS configuration)
    $funnels = [
        'engagement' => [
            'name' => 'User Engagement Funnel',
            'steps' => ['page_view', 'gallery_view', 'music_play', 'contact_form']
        ],
        'content' => [
            'name' => 'Content Consumption Funnel',
            'steps' => ['page_view', 'gallery_view', 'download']
        ]
    ];

    $funnelStats = [];

    foreach ($funnels as $funnelId => $funnel) {
        $funnelStats[$funnelId] = analyzeFunnelSteps($allEvents, $funnel['steps']);
    }

    return $funnelStats;
}

function analyzeFunnelSteps($events, $steps) {
    // Group events by user
    $userEvents = [];
    foreach ($events as $event) {
        $userId = $event['userId'];
        if (!isset($userEvents[$userId])) {
            $userEvents[$userId] = [];
        }
        $userEvents[$userId][] = $event;
    }

    $stepStats = [];
    $totalUsers = count($userEvents);
    $usersAtStep = [];

    // Initialize step statistics
    foreach ($steps as $index => $step) {
        $stepStats[$step] = [
            'users' => 0,
            'completionRate' => 0,
            'dropoffRate' => 0
        ];
        $usersAtStep[$index] = [];
    }

    // Analyze each user's journey
    foreach ($userEvents as $userId => $userEventList) {
        // Sort events by timestamp
        usort($userEventList, function($a, $b) {
            return strtotime($a['timestamp']) - strtotime($b['timestamp']);
        });

        $currentStep = 0;
        $userReachedSteps = [];

        foreach ($userEventList as $event) {
            $eventType = $event['eventType'];
            
            // Check if this event matches any funnel step
            for ($i = $currentStep; $i < count($steps); $i++) {
                if ($eventType === $steps[$i] || 
                    ($eventType === 'conversion' && isset($event['data']['goal']) && $event['data']['goal'] === $steps[$i])) {
                    
                    if (!in_array($userId, $usersAtStep[$i])) {
                        $usersAtStep[$i][] = $userId;
                        $userReachedSteps[] = $i;
                    }
                    
                    $currentStep = $i + 1;
                    break;
                }
            }
        }
    }

    // Calculate statistics for each step
    foreach ($steps as $index => $step) {
        $usersAtThisStep = count($usersAtStep[$index]);
        $stepStats[$step]['users'] = $usersAtThisStep;
        
        if ($index === 0) {
            $stepStats[$step]['completionRate'] = $totalUsers > 0 ? ($usersAtThisStep / $totalUsers) * 100 : 0;
        } else {
            $previousStepUsers = count($usersAtStep[$index - 1]);
            $stepStats[$step]['completionRate'] = $previousStepUsers > 0 ? ($usersAtThisStep / $previousStepUsers) * 100 : 0;
        }
        
        $stepStats[$step]['dropoffRate'] = 100 - $stepStats[$step]['completionRate'];
    }

    // Overall funnel statistics
    $completions = count($usersAtStep[count($steps) - 1]);
    $overallCompletionRate = $totalUsers > 0 ? ($completions / $totalUsers) * 100 : 0;

    return [
        'totalUsers' => $totalUsers,
        'completions' => $completions,
        'completionRate' => round($overallCompletionRate, 2),
        'dropoffRate' => round(100 - $overallCompletionRate, 2),
        'steps' => $stepStats
    ];
}

function getRecentConversions($limit = 20) {
    $conversions = loadDataFile(ANALYTICS_DATA_DIR . 'conversions.json');

    // Sort by timestamp (most recent first)
    usort($conversions, function($a, $b) {
        return strtotime($b['timestamp']) - strtotime($a['timestamp']);
    });

    // Return limited number of recent conversions
    return array_slice($conversions, 0, $limit);
}

function calculateROI($from, $to) {
    $conversions = loadDataFile(ANALYTICS_DATA_DIR . 'conversions.json');
    $conversions = filterByDateRange($conversions, $from, $to);

    $totalRevenue = array_sum(array_column($conversions, 'value'));
    
    // For demonstration, assume a cost basis
    // In a real implementation, this would come from advertising spend, etc.
    $estimatedCost = $totalRevenue * 0.2; // Assume 20% cost basis
    
    $roi = $estimatedCost > 0 ? (($totalRevenue - $estimatedCost) / $estimatedCost) * 100 : 0;

    return [
        'revenue' => $totalRevenue,
        'cost' => $estimatedCost,
        'roi' => round($roi, 2),
        'roiLabel' => $roi > 0 ? 'Positive' : ($roi < 0 ? 'Negative' : 'Break-even')
    ];
}

function filterByDateRange($data, $from, $to) {
    $fromTime = strtotime($from);
    $toTime = strtotime($to);

    return array_filter($data, function($item) use ($fromTime, $toTime) {
        $itemTime = strtotime($item['timestamp']);
        return $itemTime >= $fromTime && $itemTime <= $toTime;
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