<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
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

// Parse both JSON and form-data
$data = null;
$contentType = $_SERVER['CONTENT_TYPE'] ?? '';

if (strpos($contentType, 'application/json') !== false) {
    $input = file_get_contents("php://input");
    $data = json_decode($input);
} else {
    $data = (object) $_POST;
}

if ($data && isset($data->username) && isset($data->password)) {
    $username = $conn->real_escape_string($data->username);
    $password = $data->password;

    // Query matches exactly what is in your DB
    $sql = "SELECT * FROM users WHERE username = '$username'";
    $result = $conn->query($sql);

    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        
        // Comparing plaintext because your DB shows "111"
        if ($password == $row['password']) {
            echo json_encode(["status" => "success", "message" => "Login successful!"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Incorrect password."]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Account not found."]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Missing credentials."]);
}
$conn->close();
?>