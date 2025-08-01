<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Check if request is POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

// Get and validate form data
$name = trim($_POST['name'] ?? '');
$email = trim($_POST['email'] ?? '');
$subject = trim($_POST['subject'] ?? 'Yhteydenotto verkkosivuilta');
$message = trim($_POST['message'] ?? '');

// Validation
if (empty($name) || empty($email) || empty($message)) {
    echo json_encode(['success' => false, 'message' => 'Kaikki pakolliset kentät tulee täyttää']);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['success' => false, 'message' => 'Virheellinen sähköpostiosoite']);
    exit;
}

// Sanitize data
$name = htmlspecialchars($name, ENT_QUOTES, 'UTF-8');
$email = htmlspecialchars($email, ENT_QUOTES, 'UTF-8');
$subject = htmlspecialchars($subject, ENT_QUOTES, 'UTF-8');
$message = htmlspecialchars($message, ENT_QUOTES, 'UTF-8');

// Email settings
$to_emails = [
    'eemelipitkanen55@gmail.com',
    'emiliohurppi@protonmail.com'
];

$email_subject = 'XXMXLI - ' . $subject;
$email_body = "
Uusi yhteydenotto XXMXLI-verkkosivuilta

Lähettäjä: {$name}
Sähköposti: {$email}
Aihe: {$subject}

Viesti:
{$message}

--
Lähetetty: " . date('Y-m-d H:i:s') . "
IP-osoite: " . $_SERVER['REMOTE_ADDR'] . "
";

$headers = [
    'From: noreply@xxmxli.com',
    'Reply-To: ' . $email,
    'X-Mailer: PHP/' . phpversion(),
    'Content-Type: text/plain; charset=UTF-8'
];

$headers_string = implode("\r\n", $headers);

// Send emails
$success_count = 0;
foreach ($to_emails as $to_email) {
    if (mail($to_email, $email_subject, $email_body, $headers_string)) {
        $success_count++;
    }
}

// Save to file
$log_entry = [
    'timestamp' => date('Y-m-d H:i:s'),
    'name' => $name,
    'email' => $email,
    'subject' => $subject,
    'message' => $message,
    'ip' => $_SERVER['REMOTE_ADDR'],
    'user_agent' => $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown'
];

$log_line = date('Y-m-d H:i:s') . " | {$name} ({$email}) | {$subject} | " . str_replace(["\r", "\n"], ' ', $message) . " | IP: " . $_SERVER['REMOTE_ADDR'] . "\n";

// Try to write to file
$file_written = false;
try {
    $file_written = file_put_contents('yhteydenotot.txt', $log_line, FILE_APPEND | LOCK_EX) !== false;
} catch (Exception $e) {
    error_log("Failed to write contact log: " . $e->getMessage());
}

// Response
if ($success_count > 0 || $file_written) {
    echo json_encode([
        'success' => true,
        'message' => 'Viesti lähetetty onnistuneesti!'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Viestin lähetys epäonnistui. Yritä myöhemmin uudelleen.'
    ]);
}
?>