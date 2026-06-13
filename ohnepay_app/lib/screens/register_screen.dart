import 'package:flutter/material.dart';
import '../config.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _otpCtrl     = TextEditingController();

  bool _loading     = false;
  bool _obscure     = true;
  bool _otpSent     = false;
  int  _resendSecs  = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailCtrl.text.trim().isEmpty ||
        !_emailCtrl.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Введите корректный email'),
        backgroundColor: kRed,
      ));
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.sendOtp(_emailCtrl.text.trim());
    setState(() => _loading = false);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _otpSent    = true;
        _resendSecs = 60;
      });
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Код отправлен'),
        backgroundColor: kGreen,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error'] ?? 'Ошибка отправки кода'),
        backgroundColor: kRed,
      ));
    }
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSecs--);
      return _resendSecs > 0;
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_otpCtrl.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Введите 6-значный код из письма'),
        backgroundColor: kRed,
      ));
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.register(
      _nameCtrl.text.trim(),
      '',
      _emailCtrl.text.trim(),
      _passCtrl.text,
      _otpCtrl.text.trim(),
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (res['success'] == true) {
      final nav = Navigator.of(context);
      await ApiService.saveSession(
        res['token'] as String,
        res['accNo'] as int,
        res['name'] as String,
      );
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error'] ?? 'Ошибка регистрации'),
        backgroundColor: kRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text('Создать аккаунт',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Заполните данные для регистрации',
                    style: TextStyle(color: kSub)),
                const SizedBox(height: 32),

                // Имя
                TextFormField(
                  controller: _nameCtrl,
                  enabled: !_otpSent,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Полное имя *',
                    prefixIcon: Icon(Icons.person_outlined, color: kSub),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
                ),
                const SizedBox(height: 16),

                // Email + кнопка отправки кода
                TextFormField(
                  controller: _emailCtrl,
                  enabled: !_otpSent,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email_outlined, color: kSub),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Введите корректный email'
                      : null,
                ),
                const SizedBox(height: 16),

                // Пароль
                TextFormField(
                  controller: _passCtrl,
                  enabled: !_otpSent,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Пароль *',
                    prefixIcon: const Icon(Icons.lock_outlined, color: kSub),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: kSub),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Минимум 6 символов'
                      : null,
                ),
                const SizedBox(height: 16),

                // Подтвердить пароль
                TextFormField(
                  controller: _confirmCtrl,
                  enabled: !_otpSent,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Подтвердите пароль *',
                    prefixIcon: Icon(Icons.lock_outlined, color: kSub),
                  ),
                  validator: (v) =>
                      v != _passCtrl.text ? 'Пароли не совпадают' : null,
                ),
                const SizedBox(height: 24),

                // Кнопка "Отправить код" или поле OTP
                if (!_otpSent) ...[
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _sendOtp,
                            icon: const Icon(Icons.send_outlined),
                            label: const Text('Отправить код на email'),
                          ),
                        ),
                ] else ...[
                  // OTP поле
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kPrimary.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mark_email_read_outlined,
                                color: kAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Код отправлен на ${_emailCtrl.text.trim()}',
                                style: const TextStyle(
                                    color: kSub, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              letterSpacing: 8,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: '000000',
                            hintStyle: TextStyle(color: kSub, letterSpacing: 8),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => setState(() {
                                _otpSent = false;
                                _otpCtrl.clear();
                              }),
                              child: const Text('Изменить данные',
                                  style: TextStyle(color: kSub, fontSize: 12)),
                            ),
                            _resendSecs > 0
                                ? Text(
                                    'Повторно через ${_resendSecs}с',
                                    style: const TextStyle(
                                        color: kSub, fontSize: 12),
                                  )
                                : TextButton(
                                    onPressed: _loading ? null : _sendOtp,
                                    child: const Text('Отправить снова',
                                        style: TextStyle(
                                            color: kPrimary, fontSize: 12)),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _register,
                            child: const Text('Зарегистрироваться'),
                          ),
                        ),
                ],

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Уже есть аккаунт?',
                        style: TextStyle(color: kSub)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Войти'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
