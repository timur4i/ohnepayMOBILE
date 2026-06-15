import 'package:flutter/material.dart';
import '../config.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'pin_setup_screen.dart';
import 'pin_enter_screen.dart';
import 'forgot_pin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res =
        await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text);
    setState(() => _loading = false);

    if (!mounted) return;
    if (res['success'] == true) {
      final nav = Navigator.of(context);
      await ApiService.saveSession(
        res['token'] as String,
        res['accNo'] as int,
        res['name'] as String,
      );
      nav.pushReplacement(MaterialPageRoute(
        builder: (_) => ApiService.isPinSet
            ? const PinEnterScreen()
            : const PinSetupScreen(),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'Ошибка входа'),
          backgroundColor: kRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimary, kAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text('ohnePay',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: kText)),
                ),
                const Center(
                  child: Text('Цифровой банкинг',
                      style: TextStyle(color: kSub, fontSize: 14)),
                ),
                const SizedBox(height: 48),
                const Text('Добро пожаловать',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: kText)),
                const SizedBox(height: 4),
                const Text('Войдите в свой аккаунт',
                    style: TextStyle(color: kSub)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: kText),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: kSub),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Введите корректный email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: kText),
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: const Icon(Icons.lock_outlined, color: kSub),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: kSub),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Введите пароль' : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPinScreen())),
                    child: const Text('Забыли пароль?',
                        style: TextStyle(color: kSub, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 16),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text('Войти'),
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Нет аккаунта?',
                        style: TextStyle(color: kSub)),
                    TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                      child: const Text('Зарегистрироваться'),
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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
