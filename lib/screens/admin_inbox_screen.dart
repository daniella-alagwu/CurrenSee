import 'package:flutter/material.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/api_client.dart';
import 'package:currensee/screens/home/widgets/chat_view.dart';

/// Admin: list of users who have written to support, tap one to reply.
class AdminInboxScreen extends StatefulWidget {
  const AdminInboxScreen({super.key});

  @override
  State<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends State<AdminInboxScreen> {
  List<Map<String, dynamic>> _threads = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await ApiClient.getAdminThreads();
      if (mounted) setState(() => _threads = t);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(title: const Text('Support inbox')),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.forestGreen));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GoldButton(label: 'Try again', onPressed: _load),
          ]),
        ),
      );
    }
    if (_threads.isEmpty) {
      return const Center(
          child: Text('No messages yet.', style: TextStyle(color: AppColors.textMuted)));
    }
    return RefreshIndicator(
      color: AppColors.forestGreen,
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _threads.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final t = _threads[i];
          final name = ((t['name'] as String?)?.trim().isNotEmpty ?? false)
              ? t['name'] as String
              : '${t['email']}';
          final unread = (t['unread'] as num?)?.toInt() ?? 0;
          return ListTile(
            tileColor: AppColors.white,
            leading: CircleAvatar(
              backgroundColor: AppColors.emeraldBg,
              child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.white)),
            ),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600)),
            subtitle: Text('${t['lastMessage'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: unread > 0
                ? CircleAvatar(
                    radius: 11,
                    backgroundColor: AppColors.goldWarm,
                    child: Text('$unread',
                        style: const TextStyle(
                            color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w800)),
                  )
                : null,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AdminChatScreen(userId: (t['userId'] as num).toInt(), title: name)),
              );
              _load();
            },
          );
        },
      ),
    );
  }
}

class AdminChatScreen extends StatelessWidget {
  const AdminChatScreen({super.key, required this.userId, required this.title});
  final int userId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(title: Text(title)),
      body: ChatView(
        mySender: 'ADMIN',
        load: () => ApiClient.getAdminThread(userId),
        send: (body) => ApiClient.adminReply(userId, body),
        emptyText: 'No messages in this conversation.',
      ),
    );
  }
}
