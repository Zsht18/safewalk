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

// Detect available columns so this endpoint works even if the table schema differs.
$columns = [];
$columnsResult = $conn->query("SHOW COLUMNS FROM reports");
if ($columnsResult) {
    while ($column = $columnsResult->fetch_assoc()) {
        $columns[] = $column['Field'];
    }
}

$hasId = in_array('id', $columns, true);
$hasTimestamp = in_array('timestamp', $columns, true);
$orderBy = $hasTimestamp ? 'timestamp DESC' : ($hasId ? 'id DESC' : '');

// Fetch all reports from the database.
$sql = "SELECT * FROM reports" . ($orderBy !== '' ? " ORDER BY $orderBy" : '');
$result = $conn->query($sql);

if ($result) {
    $reports = [];
    $fallbackId = 1;
    while ($row = $result->fetch_assoc()) {
        $reports[] = [
            "id" => $hasId ? (int)$row['id'] : $fallbackId++,
            "fullname" => isset($row['fullname']) ? $row['fullname'] : '',
            "location" => isset($row['location']) ? $row['location'] : '',
            "report" => isset($row['report']) ? $row['report'] : '',
            "status" => isset($row['status']) ? $row['status'] : 'pending',
            "latitude" => (isset($row['latitude']) && $row['latitude'] !== '') ? (float)$row['latitude'] : null,
            "longitude" => (isset($row['longitude']) && $row['longitude'] !== '') ? (float)$row['longitude'] : null,
            "timestamp" => isset($row['timestamp']) ? $row['timestamp'] : null
        ];
    }
    echo json_encode($reports);
} else {
    echo json_encode(["status" => "error", "message" => "Database Error: " . $conn->error]);
}

$conn->close();
?>
