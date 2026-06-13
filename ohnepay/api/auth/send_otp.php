<?php
require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../config.php');
require_once(__DIR__ . '/../helpers/response.php');
require_once(__DIR__ . '/../helpers/mailer.php');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('Method not allowed', 405);

$body  = json_decode(file_get_contents('php://input'), true) ?? [];
$email = trim($body['email'] ?? '');

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) fail('Некорректный email');

// Rate limit: не чаще 1 раза в 60 секунд
$rl = mysqli_prepare($conn,
    "SELECT created_at FROM otp_codes WHERE email = ? ORDER BY created_at DESC LIMIT 1");
mysqli_stmt_bind_param($rl, 's', $email);
mysqli_stmt_execute($rl);
$rlRow = mysqli_fetch_assoc(mysqli_stmt_get_result($rl));
if ($rlRow && (time() - strtotime($rlRow['created_at'])) < 60) {
    fail('Подождите 60 секунд перед повторной отправкой');
}

// Удаляем старые коды для этого email
$del = mysqli_prepare($conn, "DELETE FROM otp_codes WHERE email = ?");
mysqli_stmt_bind_param($del, 's', $email);
mysqli_stmt_execute($del);

// Генерируем 6-значный код
$code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
$exp  = date('Y-m-d H:i:s', time() + 600); // 10 минут

$ins = mysqli_prepare($conn,
    "INSERT INTO otp_codes (email, code, expires_at) VALUES (?, ?, ?)");
mysqli_stmt_bind_param($ins, 'sss', $email, $code, $exp);
mysqli_stmt_execute($ins);

$html = "
<div style='font-family:Arial,sans-serif;max-width:480px;margin:0 auto;background:#0A0F1E;color:#fff;padding:32px;border-radius:12px'>
  <h2 style='color:#4169E1;margin-bottom:8px'>ohnePay</h2>
  <p style='color:#8B9AAF;margin-bottom:24px'>Код подтверждения регистрации</p>
  <div style='background:#141E33;border-radius:10px;padding:24px;text-align:center'>
    <span style='font-size:36px;font-weight:bold;letter-spacing:8px;color:#00D4AA'>$code</span>
  </div>
  <p style='color:#8B9AAF;margin-top:20px;font-size:13px'>Код действителен 10 минут. Не передавайте его никому.</p>
</div>
";

$sent = sendMail($email, 'Код подтверждения ohnePay', $html);
if (!$sent) fail('Не удалось отправить письмо. Проверьте email.');

ok(['message' => 'Код отправлен на ' . $email]);
