<?php
require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../config.php');
require_once(__DIR__ . '/../helpers/jwt.php');
require_once(__DIR__ . '/../helpers/response.php');
require_once(__DIR__ . '/../helpers/middleware.php');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('Method not allowed', 405);

$accNo = requireAuth();
$body  = json_decode(file_get_contents('php://input'), true) ?? [];

$cardNumber = preg_replace('/\D/', '', $body['card_number'] ?? '');
$cardHolder = trim($body['card_holder'] ?? '');
$expiryDate = trim($body['expiry_date'] ?? '');

if (strlen($cardNumber) < 16) fail('Введите корректный номер карты (16 цифр)');
if ($cardHolder === '')        fail('Введите имя держателя карты');
if (!preg_match('/^\d{2}\/\d{2}$/', $expiryDate)) fail('Формат даты: MM/YY');

$check = mysqli_prepare($conn, "SELECT id FROM cards WHERE CardNumber = ? AND OwnerAccNo = ?");
mysqli_stmt_bind_param($check, 'si', $cardNumber, $accNo);
mysqli_stmt_execute($check);
if (mysqli_num_rows(mysqli_stmt_get_result($check)) > 0) fail('Эта карта уже добавлена');

$ins = mysqli_prepare($conn,
    "INSERT INTO cards (OwnerAccNo, CardNumber, CardHolder, ExpiryDate, Balance) VALUES (?, ?, ?, ?, 0)");
mysqli_stmt_bind_param($ins, 'isss', $accNo, $cardNumber, $cardHolder, $expiryDate);
mysqli_stmt_execute($ins);

ok(['message' => 'Карта успешно добавлена']);
