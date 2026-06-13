<?php
require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../config.php');
require_once(__DIR__ . '/../helpers/jwt.php');
require_once(__DIR__ . '/../helpers/response.php');
require_once(__DIR__ . '/../helpers/middleware.php');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('Method not allowed', 405);

$accNo = requireAuth();
$body  = json_decode(file_get_contents('php://input'), true) ?? [];
$old   = $body['old_password'] ?? '';
$new   = $body['new_password'] ?? '';

if (!$old || !$new) fail('Укажите старый и новый пароль');
if (strlen($new) < 6) fail('Новый пароль должен содержать минимум 6 символов');

$stmt = mysqli_prepare($conn, "SELECT Pass FROM credentials WHERE AccNo = ?");
mysqli_stmt_bind_param($stmt, 'i', $accNo);
mysqli_stmt_execute($stmt);
$row = mysqli_fetch_assoc(mysqli_stmt_get_result($stmt));

if (!$row || !password_verify($old, $row['Pass'])) fail('Неверный текущий пароль');

$newHash = password_hash($new, PASSWORD_DEFAULT);
$upd = mysqli_prepare($conn, "UPDATE credentials SET Pass = ? WHERE AccNo = ?");
mysqli_stmt_bind_param($upd, 'si', $newHash, $accNo);
mysqli_stmt_execute($upd);

ok(['message' => 'Пароль успешно изменён']);
