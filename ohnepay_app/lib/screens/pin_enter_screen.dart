import 'package:flutter/material.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../widgets/num_pad.dart';
import 'main_screen.dart';
import 'forgot_pin_screen.dart';

class PinEnterScreen extends StatefulWidget {
  const PinEnterScreen({super.key});
  @override
  State<PinEnterScreen> createState() => _PinEnterScreenState();
}

class _PinEnterScreenState extends State<PinEnterScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool   _checking = false;
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0,   end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end:  12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin:  12.0, end: -12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -12.0, end:  12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin:  12.0, end:   0.0), weight: 1),
    ]).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onKey(String d) {
    if (_checking || _pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) _checkPin();
  }

  void _onDelete() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _checkPin() async {
    _checking = true;
    final saved = await ApiService.getPin();
    if (!mounted) return;
    if (_pin == saved) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } else {
      await _shakeCtrl.forward(from: 0);
      if (!mounted) return;
      setState(() { _pin = ''; _checking = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Неверный PIN-код. Попробуйте снова.'),
        backgroundColor: kRed,
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [kPrimary, kAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              const Text('ohnePay',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: kText)),
              const SizedBox(height: 6),
              const Text('Введите PIN-код для входа',
                  style: TextStyle(color: kSub, fontSize: 14)),
              const SizedBox(height: 52),
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_shakeAnim.value, 0),
                  child: child,
                ),
                child: PinDots(filled: _pin.length),
              ),
              const SizedBox(height: 52),
              NumPad(onKey: _onKey, onDelete: _onDelete),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ForgotPinScreen()),
                ),
                child: const Text('Забыли PIN-код?',
                    style: TextStyle(color: kSub, fontSize: 14)),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
