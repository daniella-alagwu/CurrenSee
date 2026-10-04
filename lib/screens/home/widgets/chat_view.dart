import 'dart:async';
import 'package:flutter/material.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';


class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.load,
    required this.send,
    required this.mySender,
    this.emptyText = 'No messages yet.',
  });

  final Future<List<Map<String, dynamic>>> Function() load;
  final Future<void> Function(String body) send;
  final String mySender; // 'USER' or 'ADMIN'
  final String emptyText;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh(initial: true);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool initial = false}) async {
    try {
      final items = await widget.load();
      if (!mounted) return;
      final changed = items.length != _items.length ||
          (items.isNotEmpty && _items.isNotEmpty && items.last['id'] != _items.last['id']);
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
      if (changed || initial) _toBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (_items.isEmpty) _error = e.toString();
        });
      }
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.send(text);
      _ctrl.clear();
      await _refresh();
      _toBottom();
    } catch (e) {
      if (mounted) showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _time(Object? v) {
    final t = DateTime.tryParse('$v')?.toLocal();
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _messages()),
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    cursorColor: AppColors.forestGreen,
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.goldWarm,
                    foregroundColor: AppColors.textDark,
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _messages() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.forestGreen));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!,
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            GoldButton(label: 'Try again', onPressed: () => _refresh(initial: true)),
          ]),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(widget.emptyText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final m = _items[i];
        final mine = m['sender'] == widget.mySender;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            decoration: BoxDecoration(
              color: mine ? AppColors.forestGreen : AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(mine ? 16 : 4),
                bottomRight: Radius.circular(mine ? 4 : 16),
              ),
              border: mine ? null : Border.all(color: AppColors.borderSlate),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${m['body']}',
                    style: TextStyle(
                        color: mine ? AppColors.white : AppColors.textDark, height: 1.35)),
                const SizedBox(height: 2),
                Text(_time(m['createdAt']),
                    style: TextStyle(
                        fontSize: 10.5,
                        color: mine ? AppColors.white.withValues(alpha: 0.7) : AppColors.textMuted)),
              ],
            ),
          ),
        );
      },
    );
  }
}