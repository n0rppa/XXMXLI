<?php
/**
 * XXMXLI A/B Testing API
 * Manages A/B tests and provides test results
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
    // Load A/B tests configuration
    $testsConfig = loadABTestsConfig();
    
    // Filter active tests
    $activeTests = array_filter($testsConfig, function($test) {
        return $test['status'] === 'active' && 
               strtotime($test['startDate']) <= time() &&
               (!isset($test['endDate']) || strtotime($test['endDate']) >= time());
    });

    echo json_encode([
        'status' => 'success',
        'tests' => $activeTests,
        'totalTests' => count($testsConfig),
        'activeTests' => count($activeTests)
    ]);

} catch (Exception $e) {
    error_log("A/B Testing API error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error']);
}

function loadABTestsConfig() {
    $configFile = ANALYTICS_DATA_DIR . 'ab_tests_config.json';
    
    if (!file_exists($configFile)) {
        // Return default tests if no config exists
        return getDefaultABTests();
    }
    
    $content = file_get_contents($configFile);
    if ($content === false) {
        return getDefaultABTests();
    }
    
    $config = json_decode($content, true);
    return $config === null ? getDefaultABTests() : $config;
}

function getDefaultABTests() {
    return [
        'header_color' => [
            'name' => 'Header Color Test',
            'description' => 'Test different header colors for better engagement',
            'status' => 'active',
            'variants' => [
                'control' => [
                    'name' => 'Original Green',
                    'weight' => 50,
                    'changes' => []
                ],
                'variant_a' => [
                    'name' => 'Cyan Accent',
                    'weight' => 50,
                    'changes' => [
                        [
                            'type' => 'css',
                            'selector' => '.header',
                            'property' => 'border-bottom-color',
                            'value' => '#00ffff'
                        ],
                        [
                            'type' => 'css',
                            'selector' => '.nav-container a',
                            'property' => 'color',
                            'value' => '#00ffff'
                        ]
                    ]
                ]
            ],
            'goal' => 'contact_form',
            'startDate' => date('c'),
            'endDate' => date('c', strtotime('+30 days'))
        ],
        'cta_button' => [
            'name' => 'Call-to-Action Button Test',
            'description' => 'Test different CTA button styles',
            'status' => 'active',
            'variants' => [
                'control' => [
                    'name' => 'Original Style',
                    'weight' => 50,
                    'changes' => []
                ],
                'variant_b' => [
                    'name' => 'Larger Button',
                    'weight' => 50,
                    'changes' => [
                        [
                            'type' => 'css',
                            'selector' => '.btn, button',
                            'property' => 'padding',
                            'value' => '15px 25px'
                        ],
                        [
                            'type' => 'css',
                            'selector' => '.btn, button',
                            'property' => 'font-size',
                            'value' => '18px'
                        ]
                    ]
                ]
            ],
            'goal' => 'newsletter_signup',
            'startDate' => date('c'),
            'endDate' => date('c', strtotime('+14 days'))
        ]
    ];
}
?>