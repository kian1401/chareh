import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/persian_utils.dart';
import '../../data/models.dart';
import '../../data/service_locator.dart';
import '../auth/auth_state.dart';

/// چت مشتری ⇄ سرویس‌دهنده (روی هر سفارش)
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.threadId,
    required this.title,
    this.peerEmoji = '🧑‍🔧',
  });

  final String threadId;
  final String title;
  final String peerEmoji;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    final portal = context.read<AuthState>().portal;
    await RepoHub.instance.chat.send(
      widget.threadId,
      text,
      fromCustomer: portal == UserRole.customer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.peerEmoji),
            const SizedBox(width: 8),
            Text(widget.title, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: RepoHub.instance.chat.watchThread(widget.threadId),
              builder: (_, snap) {
                final msgs = snap.data ?? [];
                if (msgs.isEmpty) {
                  return const Center(
                    child: Text(
                      'گفتگو را آغاز کنید 👋',
                      style: TextStyle(color: AppColors.subtext),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    return Align(
                      alignment: m.isMine
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * .75,
                        ),
                        decoration: BoxDecoration(
                          color: m.isMine ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: m.isMine
                              ? null
                              : Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              m.text,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.7,
                                color: m.isMine ? Colors.white : AppColors.text,
                              ),
                            ),
                            Text(
                              timeAgoFa(m.at),
                              style: TextStyle(
                                fontSize: 9.5,
                                color: m.isMine
                                    ? Colors.white70
                                    : AppColors.subtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
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
                      hintText: 'پیام بنویسید…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
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
