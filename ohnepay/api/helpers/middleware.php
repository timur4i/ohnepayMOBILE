<?php
function requireAuth(): int {
    // Apache sometimes strips HTTP_AUTHORIZATION — check all sources
    $header = $_SERVER['HTTP_AUTHORIZATION']
           ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
           ?? '';
    if (!$header) {
        $all = function_exists('getallheaders') ? getallheaders() : [];
        $header = $all['Authorization'] ?? $all['authorization'] ?? '';
    }
    if (!preg_match('/^Bearer\s+(.+)$/i', $header, $m)) {
        fail('Требуется авторизация', 401);
    }
    $payload = jwt_decode($m[1]);
    if (!$payload) {
        fail('Токен недействителен или истёк', 401);
    }
    return (int)$payload['sub'];
}
