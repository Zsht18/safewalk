<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

// Catch ALL errors and return as JSON
set_error_handler(function($errno, $errstr, $errfile, $errline) {
    echo json_encode(["status" => "error", "message" => "PHP Error: $errstr (Line $errline)"]);
    exit;
});

set_exception_handler(function($exception) {
    echo json_encode(["status" => "error", "message" => "Exception: " . $exception->getMessage()]);
    exit;
});

// Handle CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

include 'db_connect.php';

$username = isset($_GET['username']) ? $conn->real_escape_string($_GET['username']) : '';

if (!empty($username)) {
    $sql = "SELECT id, fullname, username, number, location FROM users WHERE username = '$username' LIMIT 1";
    $result = $conn->query($sql);
    
    if ($result && $result->num_rows > 0) {
        $user = $result->fetch_assoc();
        echo json_encode([
            "status" => "success",
            "data" => [
                "id" => (int)$user['id'],
                "fullname" => $user['fullname'],
                "username" => $user['username'],
                "phone" => $user['number'],
                "location" => $user['location']
            ]
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "User not found"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Username parameter required"]);
}

$conn->close();
?>
