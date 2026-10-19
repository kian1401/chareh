import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/service_locator.dart';

class _Msg {
  final bool mine;
  final String text;
  const _Msg(this.mine, this.text);
}

/// دستیار هوشمند — در حالت موک پاسخ قاعده‌محور، در حالت Firebase از طریق Cloud Function `aiAssistant` (Gemini)
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [
    const _Msg(false,
        'سلام! من دستیار هوشمند چارهم 🤖💜\nمی‌توانم درباره‌ی قیمت‌ها، انتخاب سرویس، رزرو و پیگیری کمکتان کنم.'),
  ];
  bool _typing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _ctrl.text).trim();
    if (text.isEmpty || _typing) return;
    _ctrl.clear();
    setState(() {
      _messages.add(_Msg(true, text));
      _typing = true;
    });
    _scrollToEnd();
    final reply = await RepoHub.instance.misc.askAssistant(text);
    if (!mounted) return;
    setState(() {
      _typing = false;
      _messages.add(_Msg(false, reply));
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      'قیمت نظافت منزل چقدره؟',
      'سرویس کولر می‌خوام ❄️',
      'چطور سفارشم را لغو کنم؟',
      'سفارشم کجاست؟',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('دستیار چاره', style: TextStyle(fontSize: 16)),
            Text('پاسخگوی ۲۴ ساعته ✨',
                style: TextStyle(fontSize: 10.5, color: AppColors.success)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) {
                  return _Bubble(
                    mine: false,
                    child: Text('• • •',
                        style: TextStyle(
                            color: AppColors.primary.withValues(alpha: .6),
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                  );
                }
                final m = _messages[i];
                return _Bubble(mine: m.mine, child: Text(m.text, style: TextStyle(height: 1.8, fontSize: 13, color: m.mine ? Colors.white : AppColors.text)));
              },
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ActionChip(
                label: Text(suggestions[i], style: const TextStyle(fontSize: 11.5)),
                onPressed: () => _send(suggestions[i]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                        hintText: 'سوال‌تان را بپرسید…'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _typing ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.mine, required this.child});
  final bool mine;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(16),
            topLeft: const Radius.circular(16),
            bottomRight: Radius.circular(mine ? 16 : 4),
            bottomLeft: Radius.circular(mine ? 4 : 16),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }
}
