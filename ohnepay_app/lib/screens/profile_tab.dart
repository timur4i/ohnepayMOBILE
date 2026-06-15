import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';
import 'ai_chat_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String _name = '', _email = '', _address = '';
  int _accNo = 0;
  double _balance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.getUserInfo(),
      ApiService.getBalance(),
    ]);
    if (!mounted) return;
    final info = results[0];
    final bal  = results[1];
    if (info['success'] == true) {
      setState(() {
        _name    = info['name']    ?? '';
        _email   = info['email']   ?? '';
        _address = info['address'] ?? '';
        _accNo   = info['accNo']   ?? 0;
        _balance = (bal['balance'] as num?)?.toDouble() ?? 0;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  String _fmt(double v) => NumberFormat.decimalPattern('ru_RU').format(v.round());

  void _logout() async {
    await ApiService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showEditProfile() {
    final nameCtrl    = TextEditingController(text: _name);
    final addressCtrl = TextEditingController(text: _address);
    bool loading      = false;

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
              const Text('Редактировать профиль',
                  style: TextStyle(
                      color: kText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: kText),
                decoration: const InputDecoration(
                  labelText: 'Полное имя',
                  prefixIcon: Icon(Icons.person_outlined, color: kSub),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(color: kText),
                decoration: const InputDecoration(
                  labelText: 'Адрес',
                  prefixIcon: Icon(Icons.home_outlined, color: kSub),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('Введите имя'),
                              backgroundColor: kRed,
                            ));
                            return;
                          }
                          set(() => loading = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final res = await ApiService.updateUser(
                              name, addressCtrl.text.trim());
                          set(() => loading = false);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          messenger.showSnackBar(SnackBar(
                            content: Text(res['success'] == true
                                ? 'Профиль обновлён'
                                : (res['error'] ?? 'Ошибка')),
                            backgroundColor:
                                res['success'] == true ? kGreen : kRed,
                          ));
                          if (res['success'] == true) _load();
                        },
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    bool loading  = false;
    bool obscure  = true;

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
              const Text('Сменить пароль',
                  style: TextStyle(
                      color: kText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: oldCtrl,
                obscureText: obscure,
                style: const TextStyle(color: kText),
                decoration: InputDecoration(
                  labelText: 'Текущий пароль',
                  prefixIcon: const Icon(Icons.lock_outlined, color: kSub),
                  suffixIcon: IconButton(
                    icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        color: kSub),
                    onPressed: () => set(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newCtrl,
                obscureText: obscure,
                style: const TextStyle(color: kText),
                decoration: const InputDecoration(
                  labelText: 'Новый пароль',
                  prefixIcon: Icon(Icons.lock_reset, color: kSub),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (oldCtrl.text.isEmpty || newCtrl.text.length < 6) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('Новый пароль: минимум 6 символов'),
                              backgroundColor: kRed,
                            ));
                            return;
                          }
                          set(() => loading = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final res = await ApiService.changePassword(
                              oldCtrl.text, newCtrl.text);
                          set(() => loading = false);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          messenger.showSnackBar(SnackBar(
                            content: Text(res['success'] == true
                                ? 'Пароль изменён'
                                : (res['error'] ?? 'Ошибка')),
                            backgroundColor:
                                res['success'] == true ? kGreen : kRed,
                          ));
                        },
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Сохранить'),
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
      appBar: AppBar(title: const Text('Профиль')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: kPrimary,
              backgroundColor: kCard,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Avatar
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
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _name.isNotEmpty
                              ? _name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(_name,
                        style: const TextStyle(
                            color: kText,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: '$_accNo'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Номер счёта скопирован'),
                        duration: Duration(seconds: 2),
                      ));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Счёт № $_accNo',
                            style: const TextStyle(color: kAccent, fontSize: 14)),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy, color: kAccent, size: 14),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Balance mini-card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), kPrimary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Баланс',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('${_fmt(_balance)} сум',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Info card
                  _InfoCard(items: [
                    _InfoRow(icon: Icons.email_outlined, label: 'Email', value: _email),
                    _InfoRow(icon: Icons.home_outlined, label: 'Адрес',
                        value: _address.isNotEmpty ? _address : 'Не указан'),
                  ]),
                  const SizedBox(height: 16),
                  // Actions
                  _ActionTile(
                    icon: Icons.edit_outlined,
                    iconColor: kAccent,
                    label: 'Редактировать профиль',
                    onTap: _showEditProfile,
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.auto_awesome,
                    iconColor: kAccent,
                    label: 'AI Финансовый ассистент',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AiChatScreen())),
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.lock_reset,
                    iconColor: kPrimary,
                    label: 'Сменить пароль',
                    onTap: _showChangePassword,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: kRed),
                    label: const Text('Выйти из аккаунта',
                        style: TextStyle(color: kRed)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: kRed),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> items;
  const _InfoCard({required this.items});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(item.icon, color: kSub, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label,
                              style:
                                  const TextStyle(color: kSub, fontSize: 11)),
                          Text(item.value,
                              style: const TextStyle(
                                  color: kText, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: kText, fontSize: 15)),
            ),
            const Icon(Icons.arrow_forward_ios, color: kSub, size: 14),
          ],
        ),
      ),
    );
  }
}
