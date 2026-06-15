import 'package:flutter/material.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../widgets/num_pad.dart';
import 'main_screen.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});
  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  int    _step       = 1; // 1=email, 2=otp, 3=new pin
  bool   _loading    = false;
  int    _resendSecs = 0;
  String _email      = '';

  final _emailCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();

  // Step 3 PIN state
  String _pin        = '';
  String _confirmPin = '';
  bool   _confirming = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  // ─── Step 1: Send OTP ───────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Введите корректный email', kRed);
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.sendForgotPinOtp(email);
    setState(() => _loading = false);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _email      = email;
        _step       = 2;
        _resendSecs = 60;
      });
      _startTimer();
    } else {
      _snack(res['error'] ?? 'Ошибка', kRed);
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSecs--);
      return _resendSecs > 0;
    });
  }

  // ─── Step 2: Verify OTP ─────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      _snack('Введите 6-значный код', kRed);
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.verifyOtp(_email, otp);
    setState(() => _loading = false);
    if (!mounted) return;
    if (res['success'] == true) {
      // Auto-login with returned JWT
      if (res['token'] != null) {
        await ApiService.saveSession(
          res['token'] as String,
          res['accNo'] as int,
          res['name']  as String,
        );
      }
      setState(() => _step = 3);
    } else {
      _snack(res['error'] ?? 'Неверный код', kRed);
    }
  }

  // ─── Step 3: New PIN ────────────────────────────────────────────────────────
  void _onKey(String d) {
    if (_confirming) {
      if (_confirmPin.length >= 4) return;
      setState(() => _confirmPin += d);
      if (_confirmPin.length == 4) _checkConfirm();
    } else {
      if (_pin.length >= 4) return;
      setState(() => _pin += d);
      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _confirming = true);
        });
      }
    }
  }

  void _onDelete() {
    setState(() {
      if (_confirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _checkConfirm() async {
    if (_confirmPin == _pin) {
      await ApiService.savePin(_pin);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } else {
      _snack('PIN-коды не совпадают. Попробуйте снова.', kRed);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() { _confirmPin = ''; _confirming = false; });
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
    ));
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Восстановление доступа'),
        leading: _step == 3 && _confirming
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    setState(() { _confirming = false; _confirmPin = ''; }),
              )
            : null,
        automaticallyImplyLeading: _step < 3 || !_confirming,
      ),
      body: SafeArea(child: _buildStep()),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 2:
        return _buildOtpStep();
      case 3:
        return _buildPinStep();
      default:
        return _buildEmailStep();
    }
  }

  // Step 1 — email
  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.email_outlined, color: kPrimary, size: 28),
          ),
          const SizedBox(height: 20),
          const Text('Введите ваш email',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 8),
          const Text(
              'Если email зарегистрирован, мы отправим '
              'код для сброса PIN-кода.',
              style: TextStyle(color: kSub, fontSize: 14)),
          const SizedBox(height: 32),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: kText),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined, color: kSub),
            ),
          ),
          const SizedBox(height: 24),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _sendOtp,
                    child: const Text('Отправить код'),
                  ),
                ),
        ],
      ),
    );
  }

  // Step 2 — OTP
  Widget _buildOtpStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_outlined,
                color: kAccent, size: 28),
          ),
          const SizedBox(height: 20),
          const Text('Введите код из письма',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: kText)),
          const SizedBox(height: 8),
          Text('Код отправлен на $_email',
              style: const TextStyle(color: kSub, fontSize: 14)),
          const SizedBox(height: 32),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(
                color: kText,
                fontSize: 28,
                letterSpacing: 10,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '------',
              hintStyle: TextStyle(color: kBorder, letterSpacing: 10),
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _verifyOtp,
                    child: const Text('Подтвердить'),
                  ),
                ),
          const SizedBox(height: 16),
          Center(
            child: _resendSecs > 0
                ? Text('Повторно через ${_resendSecs}с',
                    style: const TextStyle(color: kSub, fontSize: 13))
                : TextButton(
                    onPressed: _loading ? null : _sendOtp,
                    child: const Text('Отправить снова'),
                  ),
          ),
        ],
      ),
    );
  }

  // Step 3 — new PIN
  Widget _buildPinStep() {
    final current = _confirming ? _confirmPin : _pin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_reset, color: kPrimary, size: 28),
        ),
        const SizedBox(height: 24),
        Text(
          _confirming ? 'Подтвердите PIN-код' : 'Создайте новый PIN-код',
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: kText),
        ),
        const SizedBox(height: 8),
        Text(
          _confirming
              ? 'Введите PIN ещё раз для подтверждения'
              : 'Придумайте 4-значный PIN-код',
          style: const TextStyle(color: kSub, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        PinDots(filled: current.length),
        const SizedBox(height: 48),
        NumPad(onKey: _onKey, onDelete: _onDelete),
      ],
    );
  }
}
