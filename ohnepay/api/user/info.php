<?php
require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../config.php');
require_once(__DIR__ . '/../helpers/jwt.php');
require_once(__DIR__ . '/../helpers/response.php');
require_once(__DIR__ . '/../helpers/middleware.php');

$accNo = requireAuth();

$stmt = mysqli_prepare($conn, "SELECT Name, Address, Email FROM userinfo WHERE AccNo = ?");
mysqli_stmt_bind_param($stmt, 'i', $accNo);
mysqli_stmt_execute($stmt);
$row = mysqli_fetch_assoc(mysqli_stmt_get_result($stmt));

if (!$row) fail('Пользователь не найден', 404);

ok([
    'accNo'   => $accNo,
    'name'    => $row['Name'],
    'address' => $row['Address'],
    'email'   => $row['Email'],
]);
