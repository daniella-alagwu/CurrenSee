import 'dart:async';
import 'package:flutter/material.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/api_client.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const _pageSize = 30;

  final _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  Timer? _debounce;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch(int offset) =>
      ApiClient.getAdminUsers(query: _query, limit: _pageSize, offset: offset);

  List<Map<String, dynamic>> _rows(Map<String, dynamic> d) =>
      (d['items'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _fetch(0);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(_rows(d));
        _total = (d['total'] as num?)?.toInt() ?? _items.length;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final d = await _fetch(_items.length);
      if (mounted) setState(() => _items.addAll(_rows(d)));
    } catch (e) {
      if (mounted) showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _query = v.trim();
      _load();
    });
  }

  Future<void> _openUser(Map<String, dynamic> u) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminUserDetailScreen(userId: (u['id'] as num).toInt())),
    );
    if (mounted) _load(); // the user may have been suspended, promoted or deleted
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(title: const Text('Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              cursorColor: AppColors.forestGreen,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('$_total ${_total == 1 ? 'user' : 'users'}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            ),
          Expanded(child: _body()),
        ],
      ),
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
    if (_items.isEmpty) {
      return const Center(
          child: Text('No users found.', style: TextStyle(color: AppColors.textMuted)));
    }
    final hasMore = _items.length < _total;
    return RefreshIndicator(
      color: AppColors.forestGreen,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          if (i == _items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: _loadingMore
                    ? const CircularProgressIndicator(color: AppColors.forestGreen)
                    : AuthLink(label: 'Load more', onPressed: _loadMore),
              ),
            );
          }
          final u = _items[i];
          final name = ((u['name'] as String?)?.trim().isNotEmpty ?? false)
              ? u['name'] as String
              : '${u['email']}';
          final suspended = u['status'] == 'SUSPENDED';
          final isAdmin = u['role'] == 'ADMIN';
          final isPrimaryAdmin = u['primaryAdmin'] == true || u['primaryAdmin'] == 1;
          return ListTile(
            tileColor: AppColors.white,
            leading: CircleAvatar(
              backgroundColor: suspended ? AppColors.textMuted : AppColors.emeraldBg,
              child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.white)),
            ),
            title: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    decoration: suspended ? TextDecoration.lineThrough : null)),
            subtitle: Text('${u['email']}', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPrimaryAdmin)
                  const _Chip('Primary', AppColors.goldDeep)
                else if (isAdmin)
                  const _Chip('Admin', AppColors.goldDeep),
                if (suspended) const _Chip('Suspended', AppColors.negativeRed),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
            onTap: () => _openUser(u),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}
