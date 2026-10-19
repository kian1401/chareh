import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/service_locator.dart';
import '../../shared/ui.dart';
import '../auth/auth_state.dart';

class _Msg {
  _Msg(this.text, this.mine);
  final String text;
  final bool mine;
}

/// 🤖 دستیار مخصوص متخصص — عیب‌یابی لوازم خانگی، نقشه‌خوانی و راهنمایی قبل از حضور
/// تا وقتی کلید Gemini را ادمین وارد نکند، با کارشناس آفلاین داخلی کار می‌کند.
class ProviderAiHelperScreen extends StatefulWidget {
  const ProviderAiHelperScreen({super.key});

  @override
  State<ProviderAiHelperScreen> createState() => _ProviderAiHelperScreenState();
}

class _ProviderAiHelperScreenState extends State<ProviderAiHelperScreen> {
  final _ctrl = TextEditingController();
  final List<_Msg> _msgs = [
    _Msg('👋 سلاممتخصص! من کارشناس چارهام. علائم دستگاه را بگو تا راهنمای قدم‌به‌قدم بگم — مثلا «یخچال سامسونگ سرد نمی‌کند» یا «نقشهٔ تاسیسات را چطور بخوانم؟». اگر ادمین کلید Gemini را بچسباند از اینجا به AI واقعی وصل می‌شم 🚀', false),
  ];
  bool _busy = false;

  final _suggestions = const [
    'یخچال سرد نمی‌کند',
    'لباسشویی آب تخلیه نمی‌کند',
    'نقشهٔ تاسیسات خواندن',
    'کولر آب نمی‌دهد',
    'اجاق‌گاز روشن نمی‌شود',
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.loggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('دستیار متخصص')),
        body: const NeedLogin(emoji: '🤖', title: 'برای استفاده از دستیار هوشمند وارد حساب متخصص شو'),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(children: const [
          Text('🤖'), SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('دستیار عیب‌یابی متخصص', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            Text('آفلاین فعال • اتصال Gemini در مسیر', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final m in _msgs) _bubble(m),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('🤔 در حال تحلیل...', style: TextStyle(color: Color(0xFF6B7280))),
                ),
            ],
          ),
        ),
        // پیشنهادها
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final s in _suggestions)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 11.5)),
                    onPressed: _busy ? null : () => _ask(s),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _busy ? null : _ask,
                  decoration: const InputDecoration(
                    hintText: 'علائم و ایراد را توصیف کن...',
                    prefixIcon: Icon(Icons.build_circle_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _busy ? null : () => _ask(_ctrl.text),
                icon: const Icon(Icons.send_rounded),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _bubble(_Msg m) {
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: m.mine ? Theme.of(context).colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: m.mine ? null : Border.all(color: const Color(0xFFEDEAF6)),
        ),
        child: Text(m.text,
            style: TextStyle(
              fontSize: 13.5, height: 1.8,
              color: m.mine ? Colors.white : const Color(0xFF1F2937),
            )),
      ),
    );
  }

  Future<void> _ask(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _msgs.add(_Msg(text.trim(), true));
      _ctrl.clear();
      _busy = true;
    });
    final res = await RepoHub.instance.misc.askProviderExpert(text.trim());
    if (mounted) {
      setState(() {
        _msgs.add(_Msg(res, false));
        _busy = false;
      });
    }
  }
}
