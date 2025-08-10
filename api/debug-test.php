<?php
/**
 * XXMXLI API Debug Test
 * Simple test endpoint to check if PHP and data files are working
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$response = [
    'status' => 'OK',
    'timestamp' => date('c'),
    'php_version' => phpversion(),
    'server_time' => time(),
    'files' => []
];

// Check data files
$dataDir = '../data/';
$files = ['visitors.json', 'daily_stats.json'];

foreach ($files as $file) {
    $filePath = $dataDir . $file;
    $fileInfo = [
        'name' => $file,
        'exists' => file_exists($filePath),
        'readable' => is_readable($filePath),
        'size' => file_exists($filePath) ? filesize($filePath) : 0
    ];
    
    if ($fileInfo['exists'] && $fileInfo['readable']) {
        $content = file_get_contents($filePath);
        $fileInfo['valid_json'] = json_last_error() === JSON_ERROR_NONE;
        $fileInfo['content_preview'] = substr($content, 0, 200);
        
        // Try to decode JSON
        $decoded = json_decode($content, true);
        if ($decoded !== null) {
            $fileInfo['structure'] = array_keys($decoded);
            if ($file === 'visitors.json' && isset($decoded['visitors'])) {
                $fileInfo['visitor_count'] = count($decoded['visitors']);
            }
        }
    }
    
    $response['files'][] = $fileInfo;
}

echo json_encode($response, JSON_PRETTY_PRINT);
?>
