<?php
define('JWT_SECRET', 'ohnepay_jwt_s3cr3t_key_change_in_prod');
define('JWT_EXPIRY', 30 * 24 * 3600);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}
