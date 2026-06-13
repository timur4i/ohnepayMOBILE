<?php
require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../config.php');
require_once(__DIR__ . '/../helpers/jwt.php');
require_once(__DIR__ . '/../helpers/response.php');
require_once(__DIR__ . '/../helpers/middleware.php');

$accNo = requireAuth();

$stmt = mysqli_prepare($conn,
    "SELECT id, CardNumber, CardHolder, ExpiryDate, Balance FROM cards WHERE OwnerAccNo = ? ORDER BY id ASC");
mysqli_stmt_bind_param($stmt, 'i', $accNo);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

$cards = [];
while ($row = mysqli_fetch_assoc($result)) {
    $cards[] = [
        'id'         => (int)$row['id'],
        'cardNumber' => $row['CardNumber'],
        'cardHolder' => $row['CardHolder'],
        'expiryDate' => $row['ExpiryDate'],
        'balance'    => (float)$row['Balance'],
    ];
}

ok(['cards' => $cards]);
