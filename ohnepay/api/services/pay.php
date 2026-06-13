<?php
require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../config.php');
require_once(__DIR__ . '/../helpers/jwt.php');
require_once(__DIR__ . '/../helpers/response.php');
require_once(__DIR__ . '/../helpers/middleware.php');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('Method not allowed', 405);

$accNo = requireAuth();
$body  = json_decode(file_get_contents('php://input'), true) ?? [];

$code       = (int)($body['service_code'] ?? 0);
$title      = trim($body['service_title'] ?? '');
$provider   = trim($body['provider'] ?? '');
$identifier = trim($body['identifier'] ?? '');
$amount     = (float)($body['amount'] ?? 0);

$allowed = [
    8001 => 'Связь',        8002 => 'Рестораны',    8003 => 'Такси Яндекс',
    8004 => 'Образование',  8005 => 'Интернет',      8006 => 'Электроэнергия',
    8007 => 'Газ',          8008 => 'Вода',           8009 => 'ТВ и кино',
    8010 => 'Госуслуги',    8011 => 'Кредит',         8012 => 'Игры',
    8013 => 'Благотворит.', 8014 => 'Парковка',
];

if (!isset($allowed[$code])) fail('Неверная категория услуги');
if ($amount <= 0)             fail('Введите сумму');

$sb = mysqli_prepare($conn, "SELECT Balance FROM balance WHERE AccNo = ?");
mysqli_stmt_bind_param($sb, 'i', $accNo);
mysqli_stmt_execute($sb);
$row = mysqli_fetch_assoc(mysqli_stmt_get_result($sb));
if (!$row) fail('Аккаунт не найден', 404);

$balance = (float)$row['Balance'];
if ($balance < $amount) fail('Недостаточно средств');

$newBalance = $balance - $amount;
$upd = mysqli_prepare($conn, "UPDATE balance SET Balance = ? WHERE AccNo = ?");
mysqli_stmt_bind_param($upd, 'di', $newBalance, $accNo);
mysqli_stmt_execute($upd);

$desc = trim($title . ' — ' . $provider . ($identifier !== '' ? ' (' . $identifier . ')' : ''));
$ins  = mysqli_prepare($conn,
    "INSERT INTO transactions (Sender, Receiver, Amount, Remarks, SenBalance, RecBalance)
     VALUES (?, ?, ?, ?, ?, 0)");
mysqli_stmt_bind_param($ins, 'iidsd', $accNo, $code, $amount, $desc, $newBalance);
mysqli_stmt_execute($ins);

ok(['message' => 'Оплата выполнена', 'new_balance' => $newBalance]);
