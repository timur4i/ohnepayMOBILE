<?php
require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../config.php');
require_once(__DIR__ . '/../helpers/jwt.php');
require_once(__DIR__ . '/../helpers/response.php');
require_once(__DIR__ . '/../helpers/middleware.php');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('Method not allowed', 405);

$accNo = requireAuth();
$body  = json_decode(file_get_contents('php://input'), true) ?? [];
$name    = trim($body['name'] ?? '');
$address = trim($body['address'] ?? '');

if (!$name) fail('Имя не может быть пустым');

$stmt = mysqli_prepare($conn, "UPDATE userinfo SET Name = ?, Address = ? WHERE AccNo = ?");
mysqli_stmt_bind_param($stmt, 'ssi', $name, $address, $accNo);
mysqli_stmt_execute($stmt);

ok(['message' => 'Профиль обновлён']);
