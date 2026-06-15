<?php
ob_start();

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    ob_end_clean(); http_response_code(200); exit;
}

function vo_fail($msg, $code = 400) {
    ob_end_clean();
    http_response_code($code);
    echo json_encode(['success' => false, 'error' => $msg], JSON_UNESCAPED_UNICODE);
    exit;
}
function vo_ok($data) {
    ob_end_clean();
    http_response_code(200);
    echo json_encode(array_merge(['success' => true], $data), JSON_UNESCAPED_UNICODE);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') vo_fail('Method not allowed', 405);

require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../helpers/jwt.php');

$body  = json_decode(file_get_contents('php://input'), true) ?? [];
$email = trim($body['email'] ?? '');
$code  = trim($body['otp']   ?? '');

if (empty($email) || empty($code)) vo_fail('Email и код обязательны');

// Проверяем код
$stmt = mysqli_prepare($conn,
    "SELECT id FROM otp_codes WHERE email = ? AND code = ? AND used = 0 AND expires_at > NOW()");
mysqli_stmt_bind_param($stmt, 'ss', $email, $code);
mysqli_stmt_execute($stmt);
mysqli_stmt_store_result($stmt);
$found = mysqli_stmt_num_rows($stmt) > 0;
mysqli_stmt_bind_result($stmt, $otp_id);
mysqli_stmt_fetch($stmt);
mysqli_stmt_close($stmt);

if (!$found) vo_fail('Неверный или устаревший код');

// Помечаем как использованный
$upd = mysqli_prepare($conn, "UPDATE otp_codes SET used = 1 WHERE email = ? AND code = ?");
mysqli_stmt_bind_param($upd, 'ss', $email, $code);
mysqli_stmt_execute($upd);
mysqli_stmt_close($upd);

// Получаем данные пользователя и выдаём JWT
$usr = mysqli_prepare($conn, "SELECT id, Name, AccNo FROM users WHERE Email = ?");
mysqli_stmt_bind_param($usr, 's', $email);
mysqli_stmt_execute($usr);
mysqli_stmt_store_result($usr);
mysqli_stmt_bind_result($usr, $uid, $uname, $uacc);
mysqli_stmt_fetch($usr);
mysqli_stmt_close($usr);

if (!$uid) vo_fail('Пользователь не найден');

$token = generateToken(['user_id' => (int)$uid]);

vo_ok([
    'message' => 'Код подтверждён',
    'token'   => $token,
    'accNo'   => (int)$uacc,
    'name'    => $uname,
]);
