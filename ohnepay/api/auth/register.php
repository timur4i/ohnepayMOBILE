<?php
require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../config.php');
require_once(__DIR__ . '/../helpers/jwt.php');
require_once(__DIR__ . '/../helpers/response.php');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('Method not allowed', 405);

$body     = json_decode(file_get_contents('php://input'), true) ?? [];
$name     = trim($body['name'] ?? '');
$address  = trim($body['address'] ?? '');
$email    = trim($body['email'] ?? '');
$password = $body['password'] ?? '';
$otp      = trim($body['otp'] ?? '');

if (!$name || !$email || !$password) fail('Заполните все обязательные поля');
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) fail('Некорректный email');
if (strlen($password) < 6) fail('Пароль должен содержать минимум 6 символов');
if (!$otp) fail('Введите код подтверждения');

// Проверяем OTP
$check = mysqli_prepare($conn,
    "SELECT id FROM otp_codes WHERE email = ? AND code = ? AND expires_at > NOW() AND used = 0");
mysqli_stmt_bind_param($check, 'ss', $email, $otp);
mysqli_stmt_execute($check);
$otpRow = mysqli_fetch_assoc(mysqli_stmt_get_result($check));
if (!$otpRow) fail('Неверный или устаревший код подтверждения');

// Помечаем OTP как использованный
$upd = mysqli_prepare($conn, "UPDATE otp_codes SET used = 1 WHERE id = ?");
mysqli_stmt_bind_param($upd, 'i', $otpRow['id']);
mysqli_stmt_execute($upd);

// Проверяем дубликат email
$dup = mysqli_prepare($conn, "SELECT AccNo FROM userinfo WHERE Email = ?");
mysqli_stmt_bind_param($dup, 's', $email);
mysqli_stmt_execute($dup);
mysqli_stmt_store_result($dup);
if (mysqli_stmt_num_rows($dup) > 0) fail('Аккаунт с таким email уже существует');

$passHash = password_hash($password, PASSWORD_DEFAULT);

$s1 = mysqli_prepare($conn, "INSERT INTO credentials (Pass) VALUES (?)");
mysqli_stmt_bind_param($s1, 's', $passHash);
mysqli_stmt_execute($s1);
$accNo = (int)mysqli_insert_id($conn);

$s2 = mysqli_prepare($conn, "INSERT INTO balance (AccNo, Balance) VALUES (?, 0)");
mysqli_stmt_bind_param($s2, 'i', $accNo);
mysqli_stmt_execute($s2);

$s3 = mysqli_prepare($conn,
    "INSERT INTO userinfo (AccNo, Name, Address, Email) VALUES (?, ?, ?, ?)");
mysqli_stmt_bind_param($s3, 'isss', $accNo, $name, $address, $email);
mysqli_stmt_execute($s3);

$token = jwt_encode([
    'sub' => $accNo,
    'iat' => time(),
    'exp' => time() + JWT_EXPIRY,
]);

ok(['token' => $token, 'accNo' => $accNo, 'name' => $name]);
