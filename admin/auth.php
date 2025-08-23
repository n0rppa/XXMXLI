<?php
// Simple admin authentication check
function checkAdminAuth() {
    session_start();
    
    // Check if admin is logged in
    if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
        header('HTTP/1.1 401 Unauthorized');
        echo json_encode(['success' => false, 'message' => 'Authentication required']);
        exit();
    }
    
    return true;
}

// Check for basic auth as fallback
function checkBasicAuth() {
    $valid_users = [
        'admin' => 'xxmxli2025', // Change this password!
        'n0rppa' => 'music2025'   // Change this password!
    ];
    
    if (!isset($_SERVER['PHP_AUTH_USER']) || !isset($_SERVER['PHP_AUTH_PW'])) {
        header('WWW-Authenticate: Basic realm="XXMXLI Admin"');
        header('HTTP/1.1 401 Unauthorized');
        echo json_encode(['success' => false, 'message' => 'Authentication required']);
        exit();
    }
    
    $user = $_SERVER['PHP_AUTH_USER'];
    $pass = $_SERVER['PHP_AUTH_PW'];
    
    if (!isset($valid_users[$user]) || $valid_users[$user] !== $pass) {
        header('WWW-Authenticate: Basic realm="XXMXLI Admin"');
        header('HTTP/1.1 401 Unauthorized');
        echo json_encode(['success' => false, 'message' => 'Invalid credentials']);
        exit();
    }
    
    return true;
}

// Check authentication - try session first, then basic auth
function authenticate() {
    // Try session-based auth first
    session_start();
    if (isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true) {
        return true;
    }
    
    // Fall back to basic auth
    return checkBasicAuth();
}
?>
