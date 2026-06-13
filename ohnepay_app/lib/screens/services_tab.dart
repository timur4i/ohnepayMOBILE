import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config.dart';
import '../services/api_service.dart';

const _services = [
  {'code': 8001, 'name': 'Связь',         'icon': Icons.phone_android},
  {'code': 8002, 'name': 'Рестораны',     'icon': Icons.restaurant},
  {'code': 8003, 'name': 'Такси',         'icon': Icons.local_taxi},
  {'code': 8004, 'name': 'Образование',   'icon': Icons.school},
  {'code': 8005, 'name': 'Интернет',      'icon': Icons.wifi},
  {'code': 8006, 'name': 'Электричество', 'icon': Icons.bolt},
  {'code': 8007, 'name': 'Газ',           'icon': Icons.local_fire_department},
  {'code': 8008, 'name': 'Вода',          'icon': Icons.water_drop},
  {'code': 8009, 'name': 'ТВ и кино',     'icon': Icons.tv},
  {'code': 8010, 'name': 'Госуслуги',     'icon': Icons.account_balance},
  {'code': 8011, 'name': 'Кредит',        'icon': Icons.credit_card},
  {'code': 8012, 'name': 'Игры',          'icon': Icons.sports_esports},
  {'code': 8013, 'name': 'Благотворит.',  'icon': Icons.favorite},
  {'code': 8014, 'name': 'Парковка',      'icon': Icons.local_parking},
];

final _iconColors = [
  const Color(0xFF4169E1), const Color(0xFFFF6B6B), const Color(0xFFFFB347),
  const Color(0xFF00D4AA), const Color(0xFF4169E1), const Color(0xFFFFD700),
  const Color(0xFFFF8C00), const Color(0xFF00BFFF), const Color(0xFF9370DB),
  const Color(0xFF20B2AA), const Color(0xFF32CD32), const Color(0xFFFF69B4),
  const Color(0xFFDC143C), const Color(0xFF808080),
];

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});
  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  final _formKey  = GlobalKey<FormState>();
  final _accCtrl  = TextEditingController();
  final _sumCtrl  = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _transferLoading = false;
  bool _transferExpanded = true;

  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    final receiver = int.tryParse(_accCtrl.text.trim()) ?? 0;
    final amount   = double.tryParse(_sumCtrl.text.trim().replaceAll(',', '.')) ?? 0;

    setState(() => _transferLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final res = await ApiService.transfer(receiver, amount, _noteCtrl.text.trim());
    if (!mounted) return;
    setState(() => _transferLoading = false);

    if (res['success'] == true) {
      _accCtrl.clear(); _sumCtrl.clear(); _noteCtrl.clear();
      messenger.showSnackBar(const SnackBar(
        content: Text('Перевод выполнен успешно'),
        backgroundColor: kGreen,
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(res['error'] ?? 'Ошибка'),
        backgroundColor: kRed,
      ));
    }
  }

  void _showPayDialog(BuildContext context,
      Map<String, dynamic> svc, Color color) {
    final provCtrl = TextEditingController();
    final idCtrl   = TextEditingController();
    final sumCtrl  = TextEditingController();
    bool loading   = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(svc['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Text(svc['name'] as String,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              TextField(
                controller: provCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Поставщик / Оператор',
                  prefixIcon: Icon(Icons.business, color: kSub),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: idCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Номер счёта / ID',
                  prefixIcon: Icon(Icons.tag, color: kSub),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: sumCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                    color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Сумма',
                  prefixIcon: Icon(Icons.payments_outlined, color: kSub),
                  suffixText: 'сум',
                  suffixStyle: TextStyle(color: kSub),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : () async {
                    final prov   = provCtrl.text.trim();
                    final id     = idCtrl.text.trim();
                    final amount = double.tryParse(
                        sumCtrl.text.trim().replaceAll(',', '.')) ?? 0;
                    if (prov.isEmpty || id.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Заполните все поля'),
                        backgroundColor: kRed,
                      ));
                      return;
                    }
                    set(() => loading = true);
                    final messenger = ScaffoldMessenger.of(context);
                    final res = await ApiService.payService(
                      code: svc['code'] as int,
                      title: svc['name'] as String,
                      provider: prov,
                      identifier: id,
                      amount: amount,
                    );
                    set(() => loading = false);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    messenger.showSnackBar(SnackBar(
                      content: Text(res['success'] == true
                          ? 'Оплачено успешно' : (res['error'] ?? 'Ошибка')),
                      backgroundColor:
                          res['success'] == true ? kGreen : kRed,
                    ));
                  },
                  child: loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Оплатить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Платежи')),
      body: ListView(
        children: [
          // ── Transfer section ──
          GestureDetector(
            onTap: () => setState(() => _transferExpanded = !_transferExpanded),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: Radius.circular(_transferExpanded ? 0 : 16),
                ),
                border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: kPrimary, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Перевод',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
                  Icon(
                    _transferExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: kSub,
                  ),
                ],
              ),
            ),
          ),
          if (_transferExpanded)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
                border: Border.all(color: kBorder),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Номер счёта получателя',
                        prefixIcon: Icon(Icons.account_circle_outlined,
                            color: kSub),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Введите номер счёта';
                        if ((int.tryParse(v) ?? 0) <= 0) {
                          return 'Некорректный номер';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sumCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'Сумма',
                        prefixIcon:
                            Icon(Icons.payments_outlined, color: kSub),
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteCtrl,
                      style: const TextStyle(color: Colors.white),
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Примечание (необязательно)',
                        prefixIcon: Icon(Icons.edit_note, color: kSub),
                        counterStyle: TextStyle(color: kSub),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _transferLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _submitTransfer,
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Отправить перевод'),
                          ),
                  ],
                ),
              ),
            ),

          // ── Services grid ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: const Text('Оплата услуг',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: _services.length,
            itemBuilder: (context, i) {
              final svc   = _services[i];
              final color = _iconColors[i % _iconColors.length];
              return GestureDetector(
                onTap: () => _showPayDialog(context, svc, color),
                child: Container(
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(svc['icon'] as IconData,
                            color: color, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(svc['name'] as String,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
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
