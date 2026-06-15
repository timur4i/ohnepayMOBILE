<?php
ob_start(); // захватываем любой мусорный вывод

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    ob_end_clean(); http_response_code(200); exit;
}

function fp_fail($msg, $code = 400) {
    ob_end_clean();
    http_response_code($code);
    echo json_encode(['success' => false, 'error' => $msg], JSON_UNESCAPED_UNICODE);
    exit;
}
function fp_ok($data) {
    ob_end_clean();
    http_response_code(200);
    echo json_encode(array_merge(['success' => true], $data), JSON_UNESCAPED_UNICODE);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fp_fail('Method not allowed', 405);

require_once(__DIR__ . '/../../configs/db.php');

$body  = json_decode(file_get_contents('php://input'), true) ?? [];
$email = trim($body['email'] ?? '');

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) fp_fail('Некорректный email');

// Проверяем, зарегистрирован ли email
$chk = mysqli_prepare($conn, "SELECT id FROM users WHERE Email = ?");
mysqli_stmt_bind_param($chk, 's', $email);
mysqli_stmt_execute($chk);
mysqli_stmt_store_result($chk);
$exists = mysqli_stmt_num_rows($chk) > 0;
mysqli_stmt_close($chk);
if (!$exists) fp_fail('Сначала зарегистрируйтесь');

// Rate limit 60 сек
$rl = mysqli_prepare($conn,
    "SELECT created_at FROM otp_codes WHERE email = ? ORDER BY created_at DESC LIMIT 1");
mysqli_stmt_bind_param($rl, 's', $email);
mysqli_stmt_execute($rl);
mysqli_stmt_store_result($rl);
mysqli_stmt_bind_result($rl, $rl_ts);
mysqli_stmt_fetch($rl);
mysqli_stmt_close($rl);
if ($rl_ts && (time() - strtotime($rl_ts)) < 60) {
    fp_fail('Подождите 60 секунд перед повторной отправкой');
}

// Удаляем старые коды
$del = mysqli_prepare($conn, "DELETE FROM otp_codes WHERE email = ?");
mysqli_stmt_bind_param($del, 's', $email);
mysqli_stmt_execute($del);
mysqli_stmt_close($del);

// Генерируем код
$code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
$exp  = date('Y-m-d H:i:s', time() + 600);

$ins = mysqli_prepare($conn,
    "INSERT INTO otp_codes (email, code, expires_at) VALUES (?, ?, ?)");
mysqli_stmt_bind_param($ins, 'sss', $email, $code, $exp);
mysqli_stmt_execute($ins);
mysqli_stmt_close($ins);

// Подключаем mailer ПОСЛЕ всех DB-операций
require_once(__DIR__ . '/../helpers/mailer.php');

$html = "
<div style='font-family:Arial,sans-serif;max-width:480px;margin:0 auto;
     background:#0A0F1E;color:#fff;padding:32px;border-radius:12px'>
  <h2 style='color:#4169E1;margin-bottom:8px'>ohnePay</h2>
  <p style='color:#8B9AAF;margin-bottom:24px'>Сброс PIN-кода</p>
  <div style='background:#141E33;border-radius:10px;padding:24px;text-align:center'>
    <span style='font-size:36px;font-weight:bold;letter-spacing:8px;color:#00D4AA'>$code</span>
  </div>
  <p style='color:#8B9AAF;margin-top:20px;font-size:13px'>
    Код действителен 10 минут. Не передавайте его никому.
  </p>
</div>";

$sent = sendMail($email, 'Сброс PIN-кода ohnePay', $html);
if (!$sent) fp_fail('Не удалось отправить письмо. Проверьте email.');

fp_ok(['message' => 'Код отправлен на ' . $email]);
