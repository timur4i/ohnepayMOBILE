import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config.dart';
import '../services/api_service.dart';

class TransferTab extends StatefulWidget {
  const TransferTab({super.key});
  @override
  State<TransferTab> createState() => _TransferTabState();
}

class _TransferTabState extends State<TransferTab> {
  final _formKey  = GlobalKey<FormState>();
  final _accCtrl  = TextEditingController();
  final _sumCtrl  = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final receiver = int.tryParse(_accCtrl.text.trim()) ?? 0;
    final amount   = double.tryParse(_sumCtrl.text.trim().replaceAll(',', '.')) ?? 0;

    setState(() => _loading = true);
    final res = await ApiService.transfer(receiver, amount, _noteCtrl.text.trim());
    setState(() => _loading = false);
    if (!mounted) return;

    if (res['success'] == true) {
      _accCtrl.clear();
      _sumCtrl.clear();
      _noteCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Перевод выполнен успешно'),
        backgroundColor: kGreen,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error'] ?? 'Ошибка'),
        backgroundColor: kRed,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Перевод')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: kPrimary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Перевод выполняется мгновенно на счёт другого пользователя ohnePay.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('Номер счёта получателя',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Например: 1001',
                  prefixIcon: Icon(Icons.account_circle_outlined, color: kSub),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите номер счёта';
                  if ((int.tryParse(v) ?? 0) <= 0) return 'Некорректный номер';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Сумма (сум)',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sumCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixIcon: Icon(Icons.payments_outlined, color: kSub),
                  suffixText: 'сум',
                  suffixStyle: TextStyle(color: kSub),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите сумму';
                  final d = double.tryParse(v.replaceAll(',', '.'));
                  if (d == null || d <= 0) return 'Некорректная сумма';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Примечание (необязательно)',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteCtrl,
                style: const TextStyle(color: Colors.white),
                maxLength: 100,
                decoration: const InputDecoration(
                  hintText: 'Например: за обед',
                  prefixIcon: Icon(Icons.edit_note, color: kSub),
                  counterStyle: TextStyle(color: kSub),
                ),
              ),
              const SizedBox(height: 32),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.send),
                      label: const Text('Отправить перевод'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _accCtrl.dispose();
    _sumCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }
}
