<?php
require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../config.php');
require_once(__DIR__ . '/../helpers/jwt.php');
require_once(__DIR__ . '/../helpers/response.php');
require_once(__DIR__ . '/../helpers/middleware.php');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('Method not allowed', 405);

$accNo = requireAuth();
$body  = json_decode(file_get_contents('php://input'), true) ?? [];
$cardId = (int)($body['card_id'] ?? 0);

if ($cardId <= 0) fail('Неверный ID карты');

$stmt = mysqli_prepare($conn,
    "DELETE FROM cards WHERE id = ? AND OwnerAccNo = ?");
mysqli_stmt_bind_param($stmt, 'ii', $cardId, $accNo);
mysqli_stmt_execute($stmt);

if (mysqli_stmt_affected_rows($stmt) === 0) fail('Карта не найдена');

ok(['message' => 'Карта удалена']);
