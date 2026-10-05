import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/screens/rate_alerts_screen.dart';
import 'package:currensee/services/notification_store.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _store = NotificationStore.instance;
  Set<Object?> _newIds = {}; // unread when the screen opened, so they stay highlighted

  @override
  void initState() {
    super.initState();
    Future.microtask(_open);
  }

  Future<void> _open() async {
    await _store.refresh();
    if (!mounted) return;
    setState(() => _newIds = {
          for (final i in _store.items)
            if (i['isRead'] != true) i['id'],
        });
    await _store.markAllRead();
  }

  String _ago(Object? v) {
    final t = DateTime.tryParse('$v')?.toLocal();
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    if (d.inDays < 7) return '${d.inDays} d ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Rate alerts',
            icon: const Icon(Icons.add_alert_outlined),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const RateAlertsScreen())),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final items = _store.items;
          if (!_store.loaded && _store.error == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.forestGreen));
          }
          return RefreshIndicator(
            color: AppColors.forestGreen,
            onRefresh: _store.refresh,
            child: items.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Icon(Icons.notifications_none_rounded, size: 52, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _store.error != null && !_store.loaded
                            ? _store.error!
                            : 'No notifications yet.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RateAlertsScreen())),
                        child: const Text('Set a rate alert'),
                      ),
                    ),
                  ])
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = items[i];
                      final isNew = _newIds.contains(n['id']);
                      final alert = n['type'] == 'ALERT';
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isNew ? AppColors.mintTint.withValues(alpha: 0.5) : AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isNew ? AppColors.mintTint : AppColors.borderSlate),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: alert ? const Color(0xFFFEF6E0) : AppColors.mintTint,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                alert ? Icons.trending_up_rounded : Icons.campaign_outlined,
                                color: alert ? AppColors.goldDeep : AppColors.forestGreen,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${n['title']}',
                                      style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 3),
                                  Text('${n['body']}',
                                      style: const TextStyle(
                                          color: AppColors.textDark, height: 1.35, fontSize: 13.5)),
                                  const SizedBox(height: 6),
                                  Text(_ago(n['createdAt']),
                                      style: const TextStyle(
                                          color: AppColors.textMuted, fontSize: 11.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}