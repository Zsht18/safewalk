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

function get_user_columns($conn) {
    $columns = [];
    $result = $conn->query("SHOW COLUMNS FROM users");
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $columns[] = $row['Field'];
        }
    }
    return $columns;
}

$columns = get_user_columns($conn);
$phoneColumn = in_array('number', $columns, true) ? 'number' : (in_array('phone', $columns, true) ? 'phone' : null);
$hasId = in_array('id', $columns, true);

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $orderBy = $hasId ? ' ORDER BY id DESC' : '';
    $sql = "SELECT * FROM users" . $orderBy;
    $result = $conn->query($sql);

    if (!$result) {
        echo json_encode(["status" => "error", "message" => "Database Error: " . $conn->error]);
        $conn->close();
        exit;
    }

    $users = [];
    while ($row = $result->fetch_assoc()) {
        $users[] = $row;
    }

    echo json_encode(["status" => "success", "data" => $users]);
    $conn->close();
    exit;
}

$data = read_json_or_post();
$action = isset($data['action']) ? $data['action'] : '';

if ($action === 'create_user') {
    if (!isset($data['fullname']) || !isset($data['username']) || !isset($data['password'])) {
        echo json_encode(["status" => "error", "message" => "fullname, username, and password are required."]);
        $conn->close();
        exit;
    }

    $fullname = $conn->real_escape_string(trim((string)$data['fullname']));
    $username = $conn->real_escape_string(trim((string)$data['username']));
    $password = $conn->real_escape_string((string)$data['password']);
    $location = isset($data['location']) ? $conn->real_escape_string(trim((string)$data['location'])) : '';
    $phone = isset($data['phone']) ? $conn->real_escape_string(trim((string)$data['phone'])) : '';

    $insertColumns = [];
    $insertValues = [];

    if (in_array('fullname', $columns, true)) {
        $insertColumns[] = 'fullname';
        $insertValues[] = "'$fullname'";
    }
    if ($phoneColumn !== null) {
        $insertColumns[] = $phoneColumn;
        $insertValues[] = "'$phone'";
    }
    if (in_array('username', $columns, true)) {
        $insertColumns[] = 'username';
        $insertValues[] = "'$username'";
    }
    if (in_array('password', $columns, true)) {
        $insertColumns[] = 'password';
        $insertValues[] = "'$password'";
    }
    if (in_array('location', $columns, true)) {
        $insertColumns[] = 'location';
        $insertValues[] = "'$location'";
    }

    if (empty($insertColumns)) {
        echo json_encode(["status" => "error", "message" => "No compatible users table columns found."]);
        $conn->close();
        exit;
    }

    $sql = "INSERT INTO users (" . implode(', ', $insertColumns) . ") VALUES (" . implode(', ', $insertValues) . ")";

    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success", "message" => "User created.", "id" => $conn->insert_id]);
    } else {
        echo json_encode(["status" => "error", "message" => "Database Error: " . $conn->error]);
    }

    $conn->close();
    exit;
}

if ($action === 'update_user') {
    if (!isset($data['id'])) {
        echo json_encode(["status" => "error", "message" => "id is required."]);
        $conn->close();
        exit;
    }

    $id = (int)$data['id'];
    $updates = [];

    if (isset($data['fullname']) && in_array('fullname', $columns, true)) {
        $value = $conn->real_escape_string(trim((string)$data['fullname']));
        $updates[] = "fullname = '$value'";
    }
    if (isset($data['username']) && in_array('username', $columns, true)) {
        $value = $conn->real_escape_string(trim((string)$data['username']));
        $updates[] = "username = '$value'";
    }
    if (isset($data['password']) && in_array('password', $columns, true)) {
        $value = $conn->real_escape_string((string)$data['password']);
        $updates[] = "password = '$value'";
    }
    if (isset($data['location']) && in_array('location', $columns, true)) {
        $value = $conn->real_escape_string(trim((string)$data['location']));
        $updates[] = "location = '$value'";
    }
    if (isset($data['phone']) && $phoneColumn !== null) {
        $value = $conn->real_escape_string(trim((string)$data['phone']));
        $updates[] = "$phoneColumn = '$value'";
    }

    if (empty($updates)) {
        echo json_encode(["status" => "error", "message" => "No fields provided to update."]);
        $conn->close();
        exit;
    }

    $sql = "UPDATE users SET " . implode(', ', $updates) . " WHERE id = $id";

    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success", "message" => "User updated."]);
    } else {
        echo json_encode(["status" => "error", "message" => "Database Error: " . $conn->error]);
    }

    $conn->close();
    exit;
}

if ($action === 'delete_user') {
    if (!isset($data['id'])) {
        echo json_encode(["status" => "error", "message" => "id is required."]);
        $conn->close();
        exit;
    }

    $id = (int)$data['id'];
    $sql = "DELETE FROM users WHERE id = $id";

    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success", "message" => "User deleted."]);
    } else {
        echo json_encode(["status" => "error", "message" => "Database Error: " . $conn->error]);
    }

    $conn->close();
    exit;
}

echo json_encode(["status" => "error", "message" => "Unsupported action."]);
$conn->close();
?>