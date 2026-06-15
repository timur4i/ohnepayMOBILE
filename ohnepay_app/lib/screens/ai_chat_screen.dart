import 'package:flutter/material.dart';
import '../config.dart';
import '../services/api_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _loading = false;

  Future<void> _send() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty || _loading) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(text: q, isUser: true));
      _loading = true;
    });
    _scrollDown();

    final res = await ApiService.aiChat(q);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _msgs.add(_Msg(
        text: res['success'] == true
            ? res['answer'] as String
            : (res['error'] as String? ?? 'Ошибка'),
        isUser: false,
        isError: res['success'] != true,
      ));
    });
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: kAccent, size: 20),
            SizedBox(width: 8),
            Text('AI Ассистент'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _msgs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: kAccent.withValues(alpha: 0.5), size: 64),
                        const SizedBox(height: 16),
                        const Text('Задайте вопрос о ваших финансах',
                            style: TextStyle(color: kSub)),
                        const SizedBox(height: 8),
                        const Text('Например: «Сколько я потратил в этом месяце?»',
                            style: TextStyle(color: kSub, fontSize: 12),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _msgs.length,
                    itemBuilder: (_, i) => _BubbleWidget(msg: _msgs[i]),
                  ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Думаю...', style: TextStyle(color: kSub, fontSize: 12)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: kCard,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: kText),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Задайте вопрос...',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }
}

class _Msg {
  final String text;
  final bool isUser;
  final bool isError;
  _Msg({required this.text, required this.isUser, this.isError = false});
}

class _BubbleWidget extends StatelessWidget {
  final _Msg msg;
  const _BubbleWidget({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: msg.isUser
              ? kPrimary
              : msg.isError
                  ? kRed.withValues(alpha: 0.15)
                  : kCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: msg.isUser
              ? null
              : Border.all(color: msg.isError ? kRed : kBorder),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : (msg.isError ? kRed : kText),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
