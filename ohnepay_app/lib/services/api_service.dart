import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  static String? _token;

  // Вызывается автоматически при 401 (токен истёк) — установите в main.dart
  static void Function()? onUnauthorized;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
  }

  static Future<void> saveSession(String token, int accNo, String name) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setInt('acc_no', accNo);
    await prefs.setString('user_name', name);
  }

  static Future<void> clearSession() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<int> getSavedAccNo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('acc_no') ?? 0;
  }

  static Future<String> getSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? '';
  }

  static bool get isLoggedIn => _token != null;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Map<String, dynamic> _handle(http.Response res) {
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode == 401) {
      clearSession();
      onUnauthorized?.call();
      return {'success': false, 'error': 'Сессия истекла. Войдите заново.', '__code': 401};
    }
    return data;
  }

  static Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(Uri.parse('$kBaseUrl$path'),
              headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } catch (e) {
      return {'success': false, 'error': 'Нет соединения с сервером'};
    }
  }

  static Future<Map<String, dynamic>> _get(String path,
      {Map<String, String>? params}) async {
    try {
      var uri = Uri.parse('$kBaseUrl$path');
      if (params != null) uri = uri.replace(queryParameters: params);
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));
      return _handle(res);
    } catch (e) {
      return {'success': false, 'error': 'Нет соединения с сервером'};
    }
  }

  // ── Auth ──
  static Future<Map<String, dynamic>> login(String email, String password) =>
      _post('/auth/login.php', {'email': email, 'password': password});

  static Future<Map<String, dynamic>> sendOtp(String email) =>
      _post('/auth/send_otp.php', {'email': email});

  static Future<Map<String, dynamic>> register(
          String name, String address, String email, String password, String otp) =>
      _post('/auth/register.php',
          {'name': name, 'address': address, 'email': email, 'password': password, 'otp': otp});

  static Future<Map<String, dynamic>> changePassword(
          String oldPass, String newPass) =>
      _post('/auth/change_password.php',
          {'old_password': oldPass, 'new_password': newPass});

  // ── User ──
  static Future<Map<String, dynamic>> getUserInfo() => _get('/user/info.php');

  static Future<Map<String, dynamic>> updateUser(String name, String address) =>
      _post('/user/update.php', {'name': name, 'address': address});

  // ── Finance ──
  static Future<Map<String, dynamic>> getBalance() =>
      _get('/finance/balance.php');

  static Future<Map<String, dynamic>> getTransactions({int limit = 50}) =>
      _get('/finance/transactions.php', params: {'limit': '$limit'});

  static Future<Map<String, dynamic>> transfer(
          int receiverAccNo, double amount, String remarks) =>
      _post('/finance/transfer.php', {
        'receiver_accno': receiverAccNo,
        'amount': amount,
        'remarks': remarks,
      });

  // ── Services ──
  static Future<Map<String, dynamic>> payService({
    required int code,
    required String title,
    required String provider,
    required String identifier,
    required double amount,
  }) =>
      _post('/services/pay.php', {
        'service_code': code,
        'service_title': title,
        'provider': provider,
        'identifier': identifier,
        'amount': amount,
      });

  // ── Cards ──
  static Future<Map<String, dynamic>> getCards() => _get('/user/cards.php');

  static Future<Map<String, dynamic>> addCard({
    required String cardNumber,
    required String cardHolder,
    required String expiryDate,
  }) =>
      _post('/user/add_card.php', {
        'card_number': cardNumber,
        'card_holder': cardHolder,
        'expiry_date': expiryDate,
      });

  static Future<Map<String, dynamic>> deleteCard(int cardId) =>
      _post('/user/delete_card.php', {'card_id': cardId});

  // ── AI ──
  static Future<Map<String, dynamic>> aiChat(String question) =>
      _post('/ai/chat.php', {'question': question});
}
