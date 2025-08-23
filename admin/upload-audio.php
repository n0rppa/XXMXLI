<?php
// Include authentication
require_once 'auth.php';
authenticate();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Configuration
$uploadDir = '../assets/audio/';
$tracklistFile = '../assets/audio/tracklist.json';
$maxFileSize = 50 * 1024 * 1024; // 50MB
$allowedTypes = ['audio/mpeg', 'audio/wav', 'audio/flac', 'audio/ogg', 'audio/mp4', 'audio/x-m4a'];
$allowedExtensions = ['mp3', 'wav', 'flac', 'ogg', 'm4a', 'aac'];

function jsonResponse($success, $message, $data = null) {
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data' => $data
    ]);
    exit();
}

function getAudioDuration($filePath) {
    // Try to get duration using getID3 if available
    if (class_exists('getID3')) {
        $getID3 = new getID3;
        $fileInfo = $getID3->analyze($filePath);
        if (isset($fileInfo['playtime_seconds'])) {
            $seconds = round($fileInfo['playtime_seconds']);
            return sprintf('%d:%02d', floor($seconds / 60), $seconds % 60);
        }
    }
    
    // Fallback: try using ffprobe if available
    $ffprobe = shell_exec("which ffprobe 2>/dev/null");
    if ($ffprobe) {
        $cmd = "ffprobe -v quiet -show_entries format=duration -of csv=\"p=0\" " . escapeshellarg($filePath);
        $duration = shell_exec($cmd);
        if ($duration) {
            $seconds = round(floatval(trim($duration)));
            return sprintf('%d:%02d', floor($seconds / 60), $seconds % 60);
        }
    }
    
    return null;
}

function sanitizeFilename($filename) {
    // Remove any directory path
    $filename = basename($filename);
    
    // Replace spaces with underscores and remove special characters
    $filename = preg_replace('/[^a-zA-Z0-9._-]/', '_', $filename);
    
    // Remove multiple underscores
    $filename = preg_replace('/_+/', '_', $filename);
    
    return $filename;
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
    
    // Create directory if it doesn't exist
    $dir = dirname($tracklistFile);
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
    
    $json = json_encode($tracks, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
    return file_put_contents($tracklistFile, $json) !== false;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Only POST requests are allowed');
}

// Check if upload directory exists, create if not
if (!is_dir($uploadDir)) {
    if (!mkdir($uploadDir, 0755, true)) {
        jsonResponse(false, 'Failed to create upload directory');
    }
}

// Check if any files were uploaded
if (empty($_FILES)) {
    jsonResponse(false, 'No files were uploaded');
}

$uploadedFiles = [];
$errors = [];

// Load existing tracklist
$tracklist = loadTracklist();

foreach ($_FILES as $key => $file) {
    if ($file['error'] !== UPLOAD_ERR_OK) {
        $errors[] = "Upload error for {$file['name']}: " . $file['error'];
        continue;
    }
    
    // Check file size
    if ($file['size'] > $maxFileSize) {
        $errors[] = "File {$file['name']} is too large (max 50MB)";
        continue;
    }
    
    // Check file type
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    
    if (!in_array($mimeType, $allowedTypes)) {
        $errors[] = "File {$file['name']} has invalid type: {$mimeType}";
        continue;
    }
    
    // Check file extension
    $extension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    if (!in_array($extension, $allowedExtensions)) {
        $errors[] = "File {$file['name']} has invalid extension: {$extension}";
        continue;
    }
    
    // Sanitize filename
    $filename = sanitizeFilename($file['name']);
    
    // Check if file already exists
    $targetPath = $uploadDir . $filename;
    $counter = 1;
    $originalFilename = $filename;
    
    while (file_exists($targetPath)) {
        $filenameWithoutExt = pathinfo($originalFilename, PATHINFO_FILENAME);
        $extension = pathinfo($originalFilename, PATHINFO_EXTENSION);
        $filename = $filenameWithoutExt . '_' . $counter . '.' . $extension;
        $targetPath = $uploadDir . $filename;
        $counter++;
    }
    
    // Move uploaded file
    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        // Try to get audio duration
        $duration = getAudioDuration($targetPath);
        
        // Extract title from filename (remove extension and replace underscores)
        $title = ucwords(str_replace(['_', '-'], ' ', pathinfo($filename, PATHINFO_FILENAME)));
        
        // Create track entry
        $track = [
            'file' => $filename,
            'title' => $title,
            'artist' => 'n0rppa',
            'album' => '',
            'duration' => $duration,
            'picture' => ''
        ];
        
        // Add to tracklist
        $tracklist[] = $track;
        
        $uploadedFiles[] = [
            'id' => count($tracklist) - 1,
            'filename' => $filename,
            'title' => $title,
            'artist' => 'n0rppa',
            'album' => '',
            'duration' => $duration,
            'size' => $file['size']
        ];
    } else {
        $errors[] = "Failed to move uploaded file: {$file['name']}";
    }
}

// Save updated tracklist
if (!empty($uploadedFiles)) {
    if (!saveTracklist($tracklist)) {
        jsonResponse(false, 'Files uploaded but failed to update tracklist');
    }
}

if (empty($uploadedFiles) && !empty($errors)) {
    jsonResponse(false, 'Upload failed: ' . implode(', ', $errors));
}

$message = count($uploadedFiles) . ' files uploaded successfully';
if (!empty($errors)) {
    $message .= '. Errors: ' . implode(', ', $errors);
}

jsonResponse(true, $message, ['uploaded' => $uploadedFiles, 'errors' => $errors]);
?>
