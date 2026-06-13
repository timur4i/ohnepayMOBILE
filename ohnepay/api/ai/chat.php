<?php
require_once(__DIR__ . '/../../configs/db.php');
require_once(__DIR__ . '/../config.php');
require_once(__DIR__ . '/../helpers/jwt.php');
require_once(__DIR__ . '/../helpers/response.php');
require_once(__DIR__ . '/../helpers/middleware.php');
require_once(__DIR__ . '/../../scripts/ai_core.php');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('Method not allowed', 405);

$accNo = requireAuth();
$body  = json_decode(file_get_contents('php://input'), true) ?? [];
$question = trim($body['question'] ?? '');

if ($question === '') fail('Введите вопрос');

$result = aiAssistantAnswer($conn, $accNo, $question, 'ask');

if (!$result['ok']) fail($result['error']);

ok(['answer' => $result['answer']]);
