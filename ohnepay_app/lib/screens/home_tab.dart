import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../services/api_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Map<String, dynamic>> _recent = [];
  List<Map<String, dynamic>> _cards  = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getTransactions(limit: 5),
      ApiService.getCards(),
    ]);
    if (!mounted) return;
    setState(() {
      _recent  = List<Map<String, dynamic>>.from(results[0]['transactions'] ?? []);
      _cards   = List<Map<String, dynamic>>.from(results[1]['cards'] ?? []);
      _loading = false;
    });
  }

  String _fmt(double v) => NumberFormat.decimalPattern('ru_RU').format(v.round());

  static Map<String, dynamic> _bankInfo(String number) {
    final n = number.replaceAll(' ', '');
    if (n.startsWith('8600')) return {'name': 'Uzcard',     'color': const Color(0xFF1B5E20), 'abbr': 'UZ',  'cvv': false};
    if (n.startsWith('9860')) return {'name': 'Humo',       'color': const Color(0xFFBF360C), 'abbr': 'HU',  'cvv': false};
    if (n.startsWith('5614')) return {'name': 'Uzcard',     'color': const Color(0xFF1B5E20), 'abbr': 'UZ',  'cvv': false};
    if (n.startsWith('4'))    return {'name': 'Visa',       'color': const Color(0xFF0D47A1), 'abbr': 'VI',  'cvv': true};
    if (n.startsWith('5'))    return {'name': 'Mastercard', 'color': const Color(0xFF880E4F), 'abbr': 'MC',  'cvv': true};
    if (n.startsWith('6'))    return {'name': 'UnionPay',   'color': const Color(0xFF4A148C), 'abbr': 'UP',  'cvv': false};
    return {'name': 'Карта', 'color': kSub, 'abbr': '??', 'cvv': false};
  }

  static String _maskCard(String n) {
    final d = n.replaceAll(' ', '');
    if (d.length < 8) return n;
    return '•••• •••• •••• ${d.substring(d.length - 4)}';
  }

  void _confirmDeleteCard(int cardId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить карту?',
            style: TextStyle(color: Colors.white)),
        content: const Text('Карта будет удалена из вашего аккаунта.',
            style: TextStyle(color: kSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: kSub)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final res = await ApiService.deleteCard(cardId);
              messenger.showSnackBar(SnackBar(
                content: Text(res['success'] == true
                    ? 'Карта удалена'
                    : (res['error'] ?? 'Ошибка')),
                backgroundColor: res['success'] == true ? kGreen : kRed,
              ));
              if (res['success'] == true) _load();
            },
            child: const Text('Удалить', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
  }

  void _showAddCard() {
    final numCtrl    = TextEditingController();
    final holderCtrl = TextEditingController();
    final expCtrl    = TextEditingController();
    final cvvCtrl    = TextEditingController();
    bool loading     = false;
    bool obscureCvv  = true;
    Map<String, dynamic> bank = _bankInfo('');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with bank detection
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: bank['color'] as Color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(bank['abbr'] as String,
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Добавить карту',
                          style: TextStyle(color: Colors.white,
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(bank['name'] as String,
                          style: const TextStyle(color: kSub, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Card number
              TextField(
                controller: numCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, letterSpacing: 2),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                ],
                onChanged: (v) => set(() => bank = _bankInfo(v)),
                decoration: InputDecoration(
                  labelText: 'Номер карты',
                  prefixIcon: const Icon(Icons.credit_card, color: kSub),
                  suffixIcon: bank['abbr'] != '??' ? Container(
                    margin: const EdgeInsets.all(8),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: bank['color'] as Color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(bank['abbr'] as String,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ) : null,
                ),
              ),
              const SizedBox(height: 14),

              // Card holder
              TextField(
                controller: holderCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Имя держателя (как на карте)',
                  prefixIcon: Icon(Icons.person_outlined, color: kSub),
                ),
              ),
              const SizedBox(height: 14),

              // Expiry + CVV row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      inputFormatters: [_ExpiryFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'ММ/ГГ',
                        prefixIcon: Icon(Icons.calendar_today_outlined,
                            color: kSub),
                      ),
                    ),
                  ),
                  if (bank['cvv'] == true) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: cvvCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: obscureCvv,
                        maxLength: 3,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: Colors.white,
                            letterSpacing: 4),
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          counterText: '',
                          prefixIcon: const Icon(Icons.lock_outline, color: kSub),
                          suffixIcon: IconButton(
                            icon: Icon(
                                obscureCvv
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: kSub, size: 18),
                            onPressed: () => set(() => obscureCvv = !obscureCvv),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : () async {
                    final num     = numCtrl.text.replaceAll(' ', '');
                    final holder  = holderCtrl.text.trim();
                    final exp     = expCtrl.text.trim();
                    final needCvv = bank['cvv'] == true;
                    final cvv     = cvvCtrl.text.trim();

                    String? err;
                    if (num.length < 16) {
                      err = 'Введите полный номер карты (16 цифр)';
                    } else if (holder.isEmpty) {
                      err = 'Введите имя держателя карты';
                    } else if (!exp.contains('/') || exp.length < 4) {
                      err = 'Введите срок действия (ММ/ГГ)';
                    } else if (needCvv && cvv.length < 3) {
                      err = 'Введите CVV (3 цифры)';
                    }
                    if (err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(err),
                        backgroundColor: kRed,
                      ));
                      return;
                    }

                    set(() => loading = true);
                    final messenger = ScaffoldMessenger.of(context);
                    final res = await ApiService.addCard(
                      cardNumber: num,
                      cardHolder: holder,
                      expiryDate: exp,
                    );
                    set(() => loading = false);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    messenger.showSnackBar(SnackBar(
                      content: Text(res['success'] == true
                          ? 'Карта добавлена'
                          : (res['error'] ?? 'Ошибка')),
                      backgroundColor:
                          res['success'] == true ? kGreen : kRed,
                    ));
                    if (res['success'] == true) _load();
                  },
                  child: loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Добавить карту'),
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
      appBar: AppBar(
        title: const Text('ohnePay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: kPrimary,
              backgroundColor: kCard,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Cards section header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Мои карты',
                          style: TextStyle(color: Colors.white,
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: _showAddCard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: kPrimary.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add, color: kPrimary, size: 16),
                              SizedBox(width: 4),
                              Text('Добавить',
                                  style: TextStyle(color: kPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Cards list or empty state
                  if (_cards.isEmpty)
                    GestureDetector(
                      onTap: _showAddCard,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kBorder),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.add_card_outlined,
                                color: kSub, size: 40),
                            SizedBox(height: 10),
                            Text('Добавьте свою карту',
                                style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                            SizedBox(height: 4),
                            Text('Uzcard · Humo · Visa · Mastercard',
                                style: TextStyle(color: kSub, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ..._cards.map((card) {
                          final bank    = _bankInfo(card['cardNumber'] as String);
                          final balance = (card['balance'] as num?)?.toDouble() ?? 0.0;
                          final cardId  = card['id'] as int;
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  (bank['color'] as Color),
                                  (bank['color'] as Color)
                                      .withValues(alpha: 0.65),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(bank['name'] as String,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(bank['abbr'] as String,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _confirmDeleteCard(cardId),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.delete_outline,
                                                color: Colors.white70, size: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text('${_fmt(balance)} сум',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Text(_maskCard(card['cardNumber'] as String),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        letterSpacing: 2)),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                          card['cardHolder'] as String,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    Text(card['expiryDate'] as String,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),

                  const SizedBox(height: 28),

                  // Recent transactions
                  if (_recent.isNotEmpty) ...[
                    const Text('Последние операции',
                        style: TextStyle(color: Colors.white,
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ..._recent.map((tx) => _TxTile(tx: tx, fmt: _fmt)),
                  ],
                ],
              ),
            ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return next.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll('/', '');
    if (digits.length > 4) return old;
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2) buf.write('/');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return next.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _TxTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final String Function(double) fmt;
  const _TxTile({required this.tx, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isOut  = tx['is_out'] as bool;
    final amount = (tx['amount'] as num).toDouble();
    final dt     = DateTime.tryParse(tx['datetime'] ?? '') ?? DateTime.now();
    final dateStr = DateFormat('dd.MM HH:mm').format(dt);

    IconData icon;
    switch (tx['type']) {
      case 'service':     icon = Icons.receipt_long;   break;
      case 'topup':       icon = Icons.add_circle;     break;
      case 'transfer_in': icon = Icons.arrow_downward; break;
      default:            icon = Icons.arrow_upward;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (isOut ? kRed : kGreen).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isOut ? kRed : kGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['counterpart'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(dateStr,
                    style: const TextStyle(color: kSub, fontSize: 11)),
              ],
            ),
          ),
          Text('${isOut ? '-' : '+'}${fmt(amount)} сум',
              style: TextStyle(
                  color: isOut ? kRed : kGreen,
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
