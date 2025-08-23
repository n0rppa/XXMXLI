<?php
// Include authentication
require_once 'auth.php';
authenticate();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

$tracklistFile = '../assets/audio/tracklist.json';

function jsonResponse($success, $message, $data = null) {
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data' => $data
    ]);
    exit();
}

function loadTracklist() {
    global $tracklistFile;
    
    if (!file_exists($tracklistFile)) {
        return [];
    }
    
    $content = file_get_contents($tracklistFile);
    if ($content === false) {
        return [];
    }
    
    $tracks = json_decode($content, true);
    return is_array($tracks) ? $tracks : [];
}

function saveTracklist($tracks) {
    global $tracklistFile;
    
    $json = json_encode($tracks, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    return file_put_contents($tracklistFile, $json) !== false;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Only POST requests are allowed');
}

$input = json_decode(file_get_contents('php://input'), true);

if (!$input || !isset($input['index']) || !isset($input['metadata'])) {
    jsonResponse(false, 'Invalid input data');
}

$index = intval($input['index']);
$metadata = $input['metadata'];

// Load tracklist
$tracklist = loadTracklist();

if ($index < 0 || $index >= count($tracklist)) {
    jsonResponse(false, 'Invalid track index');
}

// Update metadata
if (isset($metadata['title'])) {
    $tracklist[$index]['title'] = trim($metadata['title']);
}
if (isset($metadata['artist'])) {
    $tracklist[$index]['artist'] = trim($metadata['artist']);
}
if (isset($metadata['album'])) {
    $tracklist[$index]['album'] = trim($metadata['album']);
}
if (isset($metadata['duration'])) {
    $tracklist[$index]['duration'] = trim($metadata['duration']);
}

// Save updated tracklist
if (saveTracklist($tracklist)) {
    jsonResponse(true, 'Track metadata updated successfully');
} else {
    jsonResponse(false, 'Failed to save tracklist');
}
?>
