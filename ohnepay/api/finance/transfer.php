<?php
require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../config.php');
require_once(__DIR__ . '/../helpers/jwt.php');
require_once(__DIR__ . '/../helpers/response.php');
require_once(__DIR__ . '/../helpers/middleware.php');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('Method not allowed', 405);

$accNo = requireAuth();
$body  = json_decode(file_get_contents('php://input'), true) ?? [];

$receiverAccNo = (int)($body['receiver_accno'] ?? 0);
$amount        = (float)($body['amount'] ?? 0);
$remarks       = trim($body['remarks'] ?? '');

if ($receiverAccNo <= 0) fail('Укажите номер счёта получателя');
if ($amount <= 0)        fail('Сумма должна быть больше нуля');
if ($receiverAccNo === $accNo) fail('Нельзя перевести самому себе');

// Проверяем баланс отправителя
$sb = mysqli_prepare($conn, "SELECT Balance FROM balance WHERE AccNo = ?");
mysqli_stmt_bind_param($sb, 'i', $accNo);
mysqli_stmt_execute($sb);
$sRow = mysqli_fetch_assoc(mysqli_stmt_get_result($sb));
if (!$sRow) fail('Аккаунт отправителя не найден', 404);
$senderBalance = (float)$sRow['Balance'];
if ($senderBalance < $amount) fail('Недостаточно средств');

// Проверяем существование получателя
$rb = mysqli_prepare($conn, "SELECT Balance FROM balance WHERE AccNo = ?");
mysqli_stmt_bind_param($rb, 'i', $receiverAccNo);
mysqli_stmt_execute($rb);
$rRow = mysqli_fetch_assoc(mysqli_stmt_get_result($rb));
if (!$rRow) fail('Счёт получателя не найден');
$receiverBalance = (float)$rRow['Balance'];

$newSenderBal   = $senderBalance - $amount;
$newReceiverBal = $receiverBalance + $amount;

$u1 = mysqli_prepare($conn, "UPDATE balance SET Balance = ? WHERE AccNo = ?");
mysqli_stmt_bind_param($u1, 'di', $newSenderBal, $accNo);
mysqli_stmt_execute($u1);

$u2 = mysqli_prepare($conn, "UPDATE balance SET Balance = ? WHERE AccNo = ?");
mysqli_stmt_bind_param($u2, 'di', $newReceiverBal, $receiverAccNo);
mysqli_stmt_execute($u2);

$ins = mysqli_prepare($conn,
    "INSERT INTO transactions (Sender, Receiver, Amount, Remarks, SenBalance, RecBalance)
     VALUES (?, ?, ?, ?, ?, ?)");
mysqli_stmt_bind_param($ins, 'iidsdd', $accNo, $receiverAccNo, $amount, $remarks, $newSenderBal, $newReceiverBal);
mysqli_stmt_execute($ins);

ok(['message' => 'Перевод выполнен', 'new_balance' => $newSenderBal]);
