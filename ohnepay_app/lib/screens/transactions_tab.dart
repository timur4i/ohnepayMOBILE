import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../services/api_service.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});
  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  List<Map<String, dynamic>> _txs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getTransactions(limit: 100);
    if (!mounted) return;
    setState(() {
      _txs = List<Map<String, dynamic>>.from(res['transactions'] ?? []);
      _loading = false;
    });
  }

  String _fmt(double v) => NumberFormat.decimalPattern('ru_RU').format(v.round());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История операций')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        backgroundColor: kCard,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _txs.isEmpty
                ? const Center(
                    child: Text('Операций пока нет',
                        style: TextStyle(color: kSub)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _txs.length,
                    itemBuilder: (_, i) => _TxCard(tx: _txs[i], fmt: _fmt),
                  ),
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  final String Function(double) fmt;
  const _TxCard({required this.tx, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isOut = tx['is_out'] as bool;
    final amount = (tx['amount'] as num).toDouble();
    final dt = DateTime.tryParse(tx['datetime'] ?? '') ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'ru_RU').format(dt);
    final remarks = (tx['remarks'] as String?) ?? '';

    IconData icon;
    String typeLabel;
    switch (tx['type']) {
      case 'service':
        icon = Icons.receipt_long;
        typeLabel = 'Оплата услуги';
        break;
      case 'topup':
        icon = Icons.add_circle_outline;
        typeLabel = 'Пополнение';
        break;
      case 'transfer_in':
        icon = Icons.south_west;
        typeLabel = 'Входящий перевод';
        break;
      default:
        icon = Icons.north_east;
        typeLabel = 'Исходящий перевод';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isOut ? kRed : kGreen).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: isOut ? kRed : kGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['counterpart'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(typeLabel,
                    style: const TextStyle(color: kSub, fontSize: 11)),
                if (remarks.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(remarks,
                      style: const TextStyle(color: kSub, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 2),
                Text(dateStr,
                    style: const TextStyle(color: kSub, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isOut ? '−' : '+'}${fmt(amount)}',
            style: TextStyle(
                color: isOut ? kRed : kGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ],
      ),
    );
  }
}
