<?php
// db_connect.php
$servername = "localhost";
$username = "u793073111_Safewalk"; // e.g., u123456789_safewalk
$password = "izzaZsht_0018";
$dbname = "u793073111_Safewalk"; // e.g., u123456789_safewalk_db

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Database connection failed: " . $conn->connect_error]));
}
?>