import 'package:flutter/material.dart';
import '../config.dart';

class NumPad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onDelete;

  const NumPad({super.key, required this.onKey, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _row(['1', '2', '3']),
          _row(['4', '5', '6']),
          _row(['7', '8', '9']),
          _row(['', '0', '⌫']),
        ],
      ),
    );
  }

  Widget _row(List<String> keys) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map(_key).toList(),
      );

  Widget _key(String k) {
    if (k.isEmpty) return const SizedBox(width: 88, height: 72);
    final isDel = k == '⌫';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isDel ? onDelete : () => onKey(k),
      child: Container(
        width: 88,
        height: 72,
        alignment: Alignment.center,
        child: isDel
            ? const Icon(Icons.backspace_outlined, color: kSub, size: 26)
            : Text(k,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: kText)),
      ),
    );
  }
}

class PinDots extends StatelessWidget {
  final int filled;
  final int total;
  const PinDots({super.key, required this.filled, this.total = 4});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled ? kPrimary : kBorder,
            border: Border.all(
                color: i < filled ? kPrimary : kSub.withValues(alpha: 0.4),
                width: 1.5),
          ),
        ),
      ),
    );
  }
}
