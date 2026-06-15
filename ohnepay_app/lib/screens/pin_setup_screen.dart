import 'package:flutter/material.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../widgets/num_pad.dart';
import 'main_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});
  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin        = '';
  String _confirmPin = '';
  bool   _confirming = false;

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('PIN-коды не совпадают. Попробуйте снова.'),
        backgroundColor: kRed,
        duration: Duration(seconds: 2),
      ));
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() { _confirmPin = ''; _confirming = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _confirming ? _confirmPin : _pin;
    return PopScope(
      canPop: _confirming,
      onPopInvokedWithResult: (popped, _) {
        if (!popped && _confirming) {
          setState(() { _confirming = false; _confirmPin = ''; });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _confirming
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () =>
                      setState(() { _confirming = false; _confirmPin = ''; }),
                )
              : null,
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline,
                    color: kPrimary, size: 32),
              ),
              const SizedBox(height: 24),
              Text(
                _confirming ? 'Подтвердите PIN-код' : 'Создайте PIN-код',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kText),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _confirming
                      ? 'Введите PIN ещё раз для подтверждения'
                      : 'Придумайте 4-значный PIN-код для защиты входа',
                  style: const TextStyle(color: kSub, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              PinDots(filled: current.length),
              const SizedBox(height: 48),
              NumPad(onKey: _onKey, onDelete: _onDelete),
            ],
          ),
        ),
      ),
    );
  }
}
