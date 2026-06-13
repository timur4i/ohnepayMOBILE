<?php
require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../config.php');
require_once(__DIR__ . '/../helpers/jwt.php');
require_once(__DIR__ . '/../helpers/response.php');
require_once(__DIR__ . '/../helpers/middleware.php');

$accNo = requireAuth();
$limit = min((int)($_GET['limit'] ?? 50), 100);

$stmt = mysqli_prepare($conn,
    "SELECT id, Sender, Receiver, Amount, Remarks, SenBalance, RecBalance, DateTime
     FROM transactions
     WHERE Sender = ? OR Receiver = ?
     ORDER BY DateTime DESC
     LIMIT ?");
mysqli_stmt_bind_param($stmt, 'iii', $accNo, $accNo, $limit);
mysqli_stmt_execute($stmt);
$rows = mysqli_fetch_all(mysqli_stmt_get_result($stmt), MYSQLI_ASSOC);

$SERVICE_NAMES = [
    8001 => 'Связь',        8002 => 'Рестораны',    8003 => 'Такси Яндекс',
    8004 => 'Образование',  8005 => 'Интернет',      8006 => 'Электроэнергия',
    8007 => 'Газ',          8008 => 'Вода',           8009 => 'ТВ и кино',
    8010 => 'Госуслуги',    8011 => 'Кредит',         8012 => 'Игры',
    8013 => 'Благотворит.', 8014 => 'Парковка',
];

$result = [];
foreach ($rows as $r) {
    $sender   = (int)$r['Sender'];
    $receiver = (int)$r['Receiver'];
    $isOut    = $sender === $accNo;
    $isService = $receiver >= 8001 && $receiver <= 8014;
    $isTopup   = $sender === 999 && !$isOut;

    if ($isService) {
        $type        = 'service';
        $counterpart = $SERVICE_NAMES[$receiver] ?? 'Услуга';
    } elseif ($isTopup) {
        $type        = 'topup';
        $counterpart = 'Пополнение счёта';
    } elseif ($isOut) {
        $type        = 'transfer_out';
        $counterpart = 'Счёт #' . $receiver;
    } else {
        $type        = 'transfer_in';
        $counterpart = 'Счёт #' . $sender;
    }

    $result[] = [
        'id'          => (int)$r['id'],
        'type'        => $type,
        'counterpart' => $counterpart,
        'amount'      => (float)$r['Amount'],
        'remarks'     => $r['Remarks'] ?? '',
        'balance'     => (float)($isOut ? $r['SenBalance'] : $r['RecBalance']),
        'datetime'    => $r['DateTime'],
        'is_out'      => $isOut || $isService,
    ];
}

ok(['transactions' => $result]);
