<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
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

if ($data && isset($data->fullname) && isset($data->location) && isset($data->report)) {
    $fullname = $conn->real_escape_string($data->fullname);
    $location = $conn->real_escape_string($data->location);
    $report = $conn->real_escape_string($data->report);
    $latitude = isset($data->latitude) ? (float)$data->latitude : null;
    $longitude = isset($data->longitude) ? (float)$data->longitude : null;
    $status = "pending";
    $timestamp = date('Y-m-d H:i:s');

    // Detect report table columns so this works across slightly different schemas.
    $columns = [];
    $columnsResult = $conn->query("SHOW COLUMNS FROM reports");
    if ($columnsResult) {
        while ($column = $columnsResult->fetch_assoc()) {
            $columns[] = $column['Field'];
        }
    }

    $insertColumns = [];
    $insertValues = [];

    if (in_array('fullname', $columns, true)) {
        $insertColumns[] = 'fullname';
        $insertValues[] = "'$fullname'";
    }

    if (in_array('location', $columns, true)) {
        $insertColumns[] = 'location';
        $insertValues[] = "'$location'";
    }

    if (in_array('report', $columns, true)) {
        $insertColumns[] = 'report';
        $insertValues[] = "'$report'";
    }

    if (in_array('latitude', $columns, true)) {
        $insertColumns[] = 'latitude';
        $insertValues[] = ($latitude === null) ? 'NULL' : (string)$latitude;
    }

    if (in_array('longitude', $columns, true)) {
        $insertColumns[] = 'longitude';
        $insertValues[] = ($longitude === null) ? 'NULL' : (string)$longitude;
    }

    if (in_array('status', $columns, true)) {
        $insertColumns[] = 'status';
        $insertValues[] = "'$status'";
    }

    if (in_array('timestamp', $columns, true)) {
        $insertColumns[] = 'timestamp';
        $insertValues[] = "'$timestamp'";
    }

    if (count($insertColumns) < 3) {
        echo json_encode([
            "status" => "error",
            "message" => "Reports table schema is missing required columns (fullname, location, report)."
        ]);
        $conn->close();
        exit;
    }

    $sql = "INSERT INTO reports (" . implode(', ', $insertColumns) . ") VALUES (" . implode(', ', $insertValues) . ")";
    
    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success", "message" => "Report submitted successfully!", "id" => $conn->insert_id]);
    } else {
        echo json_encode(["status" => "error", "message" => "Database Error: " . $conn->error]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Missing required fields: fullname, location, report"]);
}
$conn->close();
?>
