<?php
/**
 * XXMXLI Blacklist Checker API
 * Checks if an IP is in the blacklist
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

// Get input
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!isset($data['ip'])) {
    http_response_code(400);
    echo json_encode(['error' => 'IP address required']);
    exit;
}

$checkIP = $data['ip'];

// Load blacklist from generated file
$blacklistFile = '../assets/security/blocked_ips.json';
$blocked = false;
$source = 'none';

if (file_exists($blacklistFile)) {
    $blacklistData = json_decode(file_get_contents($blacklistFile), true);
    
    if (isset($blacklistData['blocked_ips']) && in_array($checkIP, $blacklistData['blocked_ips'])) {
        $blocked = true;
        $source = 'blacklist_file';
    }
} else {
    // Fallback: check against simple patterns
    $blocked = checkSimpleBlacklist($checkIP);
    if ($blocked) {
        $source = 'pattern_match';
    }
}

// Additional security checks
$securityCheck = performSecurityChecks($checkIP);

$response = [
    'ip' => $checkIP,
    'blocked' => $blocked,
    'source' => $source,
    'timestamp' => date('Y-m-d H:i:s'),
    'security' => $securityCheck
];

echo json_encode($response);

function checkSimpleBlacklist($ip) {
    // Simple blacklist patterns (you can expand this)
    $blacklistedRanges = [
        '127.0.0.1',        // Localhost
        '0.0.0.0',          // Invalid
        '255.255.255.255'   // Broadcast
    ];
    
    foreach ($blacklistedRanges as $blockedIP) {
        if ($ip === $blockedIP) {
            return true;
        }
    }
    
    // Check for obviously suspicious IPs
    if (strpos($ip, '999.') === 0 || strpos($ip, '000.') === 0) {
        return true;
    }
    
    return false;
}

function performSecurityChecks($ip) {
    $checks = [
        'isPrivate' => filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE) === false,
        'isReserved' => filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_RES_RANGE) === false,
        'isValid' => filter_var($ip, FILTER_VALIDATE_IP) !== false,
        'isIPv6' => filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6) !== false,
        'isTor' => checkTorExit($ip),
        'riskLevel' => calculateRiskLevel($ip)
    ];
    
    return $checks;
}

function checkTorExit($ip) {
    // Simple Tor exit node detection (would need real Tor exit list)
    // This is a placeholder - in production, use actual Tor exit node lists
    return false;
}

function calculateRiskLevel($ip) {
    $risk = 0;
    
    // Check IP patterns
    $parts = explode('.', $ip);
    if (count($parts) === 4) {
        $firstOctet = intval($parts[0]);
        
        // Higher risk for certain ranges
        if ($firstOctet >= 1 && $firstOctet <= 2) $risk += 2; // Early internet blocks
        if ($firstOctet >= 240) $risk += 5; // Reserved ranges
        if ($firstOctet === 10 || $firstOctet === 172 || $firstOctet === 192) $risk -= 1; // Private (less risk)
    }
    
    // Determine risk level
    if ($risk <= 0) return 'low';
    if ($risk <= 3) return 'medium';
    return 'high';
}
?>
