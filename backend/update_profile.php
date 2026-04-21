<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

set_error_handler(function($errno, $errstr, $errfile, $errline) {
    echo json_encode(["status" => "error", "message" => "PHP Error: $errstr (Line $errline)"]);
    exit;
});

set_exception_handler(function($exception) {
    echo json_encode(["status" => "error", "message" => "Exception: " . $exception->getMessage()]);
    exit;
});

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

include 'db_connect.php';

$data = null;
$contentType = $_SERVER['CONTENT_TYPE'] ?? '';

if (strpos($contentType, 'application/json') !== false) {
    $input = file_get_contents("php://input");
    $data = json_decode($input);
} else {
    $data = (object) $_POST;
}

if ($data && isset($data->username) && isset($data->location)) {
    $username = $conn->real_escape_string($data->username);
    $location = $conn->real_escape_string($data->location);

    $sql = "UPDATE users SET location = '$location' WHERE username = '$username'";
    if ($conn->query($sql) === TRUE) {
        if ($conn->affected_rows >= 0) {
            echo json_encode(["status" => "success", "message" => "Profile location updated."]);
        } else {
            echo json_encode(["status" => "error", "message" => "No profile updated."]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Database Error: " . $conn->error]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Missing required fields: username, location"]);
}

$conn->close();
?>
