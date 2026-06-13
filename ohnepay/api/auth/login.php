<?php
require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../config.php');
require_once(__DIR__ . '/../helpers/jwt.php');
require_once(__DIR__ . '/../helpers/response.php');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('Method not allowed', 405);

$body = json_decode(file_get_contents('php://input'), true) ?? [];
$email    = trim($body['email'] ?? '');
$password = $body['password'] ?? '';

if (!$email || !$password) fail('Введите email и пароль');

$stmt = mysqli_prepare($conn,
    "SELECT u.AccNo, c.Pass, u.Name FROM userinfo u
     JOIN credentials c ON u.AccNo = c.AccNo
     WHERE u.Email = ?");
mysqli_stmt_bind_param($stmt, 's', $email);
mysqli_stmt_execute($stmt);
$row = mysqli_fetch_assoc(mysqli_stmt_get_result($stmt));

if (!$row || !password_verify($password, $row['Pass'])) {
    fail('Неверный email или пароль');
}

$token = jwt_encode([
    'sub' => (int)$row['AccNo'],
    'iat' => time(),
    'exp' => time() + JWT_EXPIRY,
]);

ok(['token' => $token, 'accNo' => (int)$row['AccNo'], 'name' => $row['Name']]);
