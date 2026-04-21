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

if ($data && isset($data->username) && isset($data->password) && isset($data->fullname)) {
    $fullname = $conn->real_escape_string($data->fullname);
    $phone = isset($data->phone) ? $conn->real_escape_string($data->phone) : '';
    $username = $conn->real_escape_string($data->username);
    $location = isset($data->location) ? $conn->real_escape_string($data->location) : '';
    
    // Note: Storing plaintext for now to match your DB, or use password_hash if you update DB
    $password = $data->password; 

    // Database column is 'number', not 'phone'
    $sql = "INSERT INTO users (fullname, number, username, password, location) 
            VALUES ('$fullname', '$phone', '$username', '$password', '$location')";
    
    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success", "message" => "Account created successfully!"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Database Error: " . $conn->error]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Missing data."]);
}
$conn->close();
?>