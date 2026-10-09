import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/api_client.dart';
import 'package:currensee/auth/auth_widgets.dart';

const String _appealTag = 'ACCOUNT_SUSPENSION_APPEAL';

class _AppealTag extends StatelessWidget {
  const _AppealTag();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.redTint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Account suspension appeal',
            style: TextStyle(
                color: AppColors.negativeRed,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );
}

class AdminInboxScreen extends StatefulWidget {
  const AdminInboxScreen({super.key});

  @override
  State<AdminInboxScreen> createState() => _AdminInboxScreenState();
}

class _AdminInboxScreenState extends State<AdminInboxScreen> {
  List<Map<String, dynamic>> _threads = const [];
  bool _loading = true;
  bool _appealsOnly = false;
  String? _error;

  static bool _isAppeal(Map<String, dynamic> t) => t['lastTag'] == _appealTag;

  List<Map<String, dynamic>> get _visible =>
      _appealsOnly ? _threads.where(_isAppeal).toList() : _threads;

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
      final threads = await ApiClient.getAdminThreads();
      if (mounted) setState(() => _threads = threads);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _date(Object? value) {
    final parsed = DateTime.tryParse('$value')?.toLocal();
    if (parsed == null) return '';
    return '${parsed.month}/${parsed.day} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _open(Map<String, dynamic> thread) async {
    final rawId = thread['userId'];
    if (rawId is! num) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminChatScreen(
          userId: rawId.toInt(),
          title: (thread['name'] as String?)?.trim().isNotEmpty == true
              ? thread['name'] as String
              : '${thread['email'] ?? 'User'}',
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surfaceSlate,
        appBar: AppBar(
          title: const Text('Support inbox'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Wrap(spacing: 8, children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: !_appealsOnly,
                    onSelected: (_) => setState(() => _appealsOnly = false),
                  ),
                  ChoiceChip(
                    label: const Text('Suspension appeals'),
                    selected: _appealsOnly,
                    onSelected: (_) => setState(() => _appealsOnly = true),
                  ),
                ]),
              ),
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.forestGreen))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        GoldButton(label: 'Try again', onPressed: _load),
                      ]),
                    ),
                  )
                : _visible.isEmpty
                    ? Center(
                        child: Text(
                            _appealsOnly
                                ? 'No suspension appeals.'
                                : 'No support conversations yet.',
                            style: const TextStyle(color: AppColors.textMuted)),
                      )
                    : RefreshIndicator(
                        color: AppColors.forestGreen,
                        onRefresh: _load,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _visible.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final thread = _visible[index];
                            final name = (thread['name'] as String?)?.trim();
                            final title = name?.isNotEmpty == true
                                ? name!
                                : '${thread['email'] ?? 'User'}';
                            final unread = (thread['unread'] as num?)?.toInt() ?? 0;
                            return ListTile(
                              tileColor: AppColors.white,
                              leading: CircleAvatar(
                                backgroundColor: AppColors.mintTint,
                                foregroundColor: AppColors.forestGreen,
                                child: Text(title.isEmpty ? '?' : title[0].toUpperCase()),
                              ),
                              title: Text(title,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isAppeal(thread))
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 3),
                                      child: _AppealTag(),
                                    ),
                                  Text('${thread['lastMessage'] ?? ''}',
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(_date(thread['lastAt']),
                                      style: const TextStyle(
                                          color: AppColors.textMuted, fontSize: 11)),
                                  if (unread > 0)
                                    Container(
                                      margin: const EdgeInsets.only(top: 5),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.forestGreen,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text('$unread',
                                          style: const TextStyle(
                                              color: AppColors.white, fontSize: 11)),
                                    ),
                                ],
                              ),
                              onTap: () => _open(thread),
                            );
                          },
                        ),
                      ),
      );
}

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key, required this.userId, required this.title});
  final int userId;
  final String title;

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _message = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = const [];
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _sending = false;
  bool _reactivating = false;
  String? _error;

  bool get _suspended => _user?['status'] == 'SUSPENDED';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await ApiClient.getAdminThread(widget.userId);
      Map<String, dynamic>? user;
      try {
        final d = await ApiClient.getAdminUser(widget.userId);
        user = d['user'] as Map<String, dynamic>?;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _messages = messages;
          _user = user ?? _user;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _message.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiClient.adminReply(widget.userId, body);
      _message.clear();
      await _load();
    } catch (error) {
      if (mounted) showAuthError(context, error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _reactivate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reactivate account?'),
        content: Text('${widget.title} will be able to use CurrenSee again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reactivate')),
        ],
      ),
    );
    if (ok != true || _reactivating) return;
    setState(() => _reactivating = true);
    try {
      await ApiClient.adminUserAction(widget.userId, 'unsuspend');
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account reactivated.'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (error) {
      if (mounted) showAuthError(context, error.toString());
    } finally {
      if (mounted) setState(() => _reactivating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surfaceSlate,
        appBar: AppBar(title: Text(widget.title)),
        body: Column(
          children: [
            if (_suspended)
              Container(
                width: double.infinity,
                color: AppColors.redTint,
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                child: Row(children: [
                  const Icon(Icons.block_rounded, color: AppColors.negativeRed, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('This account is suspended.',
                        style: TextStyle(
                            color: AppColors.textDark, fontWeight: FontWeight.w700)),
                  ),
                  FilledButton(
                    onPressed: _reactivating ? null : _reactivate,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.forestGreen),
                    child: _reactivating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white))
                        : const Text('Reactivate'),
                  ),
                ]),
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.forestGreen))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              GoldButton(label: 'Try again', onPressed: _load),
                            ]),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.forestGreen,
                          onRefresh: _load,
                          child: ListView.builder(
                            controller: _scroll,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final item = _messages[index];
                              final fromAdmin = item['sender'] == 'ADMIN';
                              return Align(
                                alignment: fromAdmin
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(
                                      maxWidth: MediaQuery.sizeOf(context).width * .78),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: fromAdmin ? AppColors.forestGreen : AppColors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (item['tag'] == _appealTag)
                                        const Padding(
                                          padding: EdgeInsets.only(bottom: 6),
                                          child: _AppealTag(),
                                        ),
                                      Text('${item['body'] ?? ''}',
                                          style: TextStyle(
                                              color: fromAdmin
                                                  ? AppColors.white
                                                  : AppColors.textDark)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _message,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                            hintText: 'Write a reply', counterText: ''),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                      tooltip: 'Send reply',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}