<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

set_error_handler(function($errno, $errstr, $errfile, $errline) {
    echo json_encode(["status" => "error", "message" => "PHP Error: $errstr (Line $errline)"]);
    exit;
});

set_exception_handler(function($exception) {
    echo json_encode(["status" => "error", "message" => "Exception: " . $exception->getMessage()]);
    exit;
});

include 'db_connect.php';

function read_json_or_post() {
    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
    if (strpos($contentType, 'application/json') !== false) {
        $raw = file_get_contents('php://input');
        $decoded = json_decode($raw, true);
        return is_array($decoded) ? $decoded : [];
    }
    return $_POST;
}

function get_report_columns($conn) {
    $columns = [];
    $result = $conn->query("SHOW COLUMNS FROM reports");
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $columns[] = $row['Field'];
        }
    }
    return $columns;
}

$columns = get_report_columns($conn);
$hasId = in_array('id', $columns, true);
$hasStatus = in_array('status', $columns, true);
$hasTimestamp = in_array('timestamp', $columns, true);
$orderBy = $hasTimestamp ? 'timestamp DESC' : ($hasId ? 'id DESC' : '');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $sql = "SELECT * FROM reports" . ($orderBy !== '' ? " ORDER BY $orderBy" : '');
    $result = $conn->query($sql);

    if (!$result) {
        echo json_encode(["status" => "error", "message" => "Database Error: " . $conn->error]);
        $conn->close();
        exit;
    }

    $reports = [];
    while ($row = $result->fetch_assoc()) {
        $reports[] = $row;
    }

    echo json_encode(["status" => "success", "data" => $reports]);
    $conn->close();
    exit;
}

$data = read_json_or_post();
$action = isset($data['action']) ? $data['action'] : '';

if ($action === 'update_status') {
    if (!$hasId || !$hasStatus) {
        echo json_encode(["status" => "error", "message" => "Reports table must have id and status columns."]);
        $conn->close();
        exit;
    }

    if (!isset($data['id']) || !isset($data['status'])) {
        echo json_encode(["status" => "error", "message" => "Missing id or status."]);
        $conn->close();
        exit;
    }

    $id = (int)$data['id'];
    $status = $conn->real_escape_string(trim((string)$data['status']));

    $sql = "UPDATE reports SET status = '$status' WHERE id = $id";
    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success", "message" => "Report status updated."]);
    } else {
        echo json_encode(["status" => "error", "message" => "Database Error: " . $conn->error]);
    }

    $conn->close();
    exit;
}

if ($action === 'delete_report') {
    if (!$hasId) {
        echo json_encode(["status" => "error", "message" => "Reports table must have id column."]);
        $conn->close();
        exit;
    }

    if (!isset($data['id'])) {
        echo json_encode(["status" => "error", "message" => "Missing id."]);
        $conn->close();
        exit;
    }

    $id = (int)$data['id'];
    $sql = "DELETE FROM reports WHERE id = $id";
    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success", "message" => "Report deleted."]);
    } else {
        echo json_encode(["status" => "error", "message" => "Database Error: " . $conn->error]);
    }

    $conn->close();
    exit;
}

echo json_encode(["status" => "error", "message" => "Unsupported action."]);
$conn->close();
?>