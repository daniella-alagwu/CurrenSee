import 'package:flutter/material.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/api_client.dart';
import 'widgets/conversion_tile.dart';

//conversion history section.
class ConversionHistoryScreen extends StatefulWidget {
  const ConversionHistoryScreen({super.key});

  @override
  State<ConversionHistoryScreen> createState() => _ConversionHistoryScreenState();
}

class _ConversionHistoryScreenState extends State<ConversionHistoryScreen> {
  static const int _pageSize = 30;

  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<List<Map<String, dynamic>>> _fetch(int offset) async {
    final data = await ApiClient.getConversionHistory(limit: _pageSize, offset: offset);
    return (data['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _fetch(0);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page);
        _hasMore = page.length == _pageSize;
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
      final page = await _fetch(_items.length);
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _hasMore = page.length == _pageSize;
      });
    } catch (e) {
      if (mounted) showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversion history')),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              GoldButton(label: 'Try again', onPressed: _loadFirstPage),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text('No saved conversions yet',
                  style: TextStyle(
                      color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('Convert an amount on the home screen and tap “Save conversion”.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.forestGreen,
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
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
          final item = _items[i];
          return ConversionTile(item: item, onTap: () => Navigator.pop(context, item));
        },
      ),
    );
  }
}
