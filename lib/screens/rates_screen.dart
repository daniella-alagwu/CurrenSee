import 'package:flutter/material.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/rates_service.dart';
import 'package:currensee/services/user_store.dart';
import 'package:currensee/utils/format.dart';
import 'package:currensee/screens/home/widgets/currency_dropdown.dart';
import 'package:currensee/screens/home/widgets/header_actions.dart';
import 'package:currensee/screens/home/widgets/rate_sparkline.dart';


class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key, required this.onOpenMenu});
  final VoidCallback onOpenMenu;

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  String _base = 'USD';
  RateSnapshot? _snapshot;
  bool _loading = true;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await UserStore.instance.load();
      if (!mounted) return;
      _base = RatesService.startingBase(UserStore.instance.baseCurrency);
      await _load();
    });
  }

  Future<void> _load() async {
    final id = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await RatesService.latest(_base);
      if (mounted && id == _request) setState(() => _snapshot = s);
    } catch (e) {
      if (mounted && id == _request) setState(() => _error = e.toString());
    } finally {
      if (mounted && id == _request) setState(() => _loading = false);
    }
  }

  void _showTrend(String code) {
    final rate = _snapshot?.rates[code];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: FutureBuilder<List<double>>(
          future: RatesService.trend(_base, code),
          builder: (context, snap) {
            final values = snap.data ?? const <double>[];
            final has = values.length >= 2;
            final change = has ? (values.last / values.first - 1) * 100 : 0.0;
            final up = change >= 0;
            final color = up ? AppColors.positiveMint : AppColors.negativeRed;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_base → $code  ·  7-day trend',
                    style: const TextStyle(
                        color: AppColors.textDark, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(rate == null ? '—' : formatRate(rate),
                        style: const TextStyle(
                            color: AppColors.textDark, fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    if (has)
                      Text('${up ? '+' : '-'}${change.abs().toStringAsFixed(2)}%',
                          style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 90,
                  child: has
                      ? RateSparkline(values: values, color: color)
                      : Center(
                          child: snap.connectionState == ConnectionState.done
                              ? const Text('Trend is not available right now.',
                                  style: TextStyle(color: AppColors.textMuted))
                              : const CircularProgressIndicator(color: AppColors.forestGreen)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _snapshot;
    final codes = RatesService.supported.where((c) => c != _base).toList();
    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(
        title: const Text('Rates', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [HeaderActions(onOpenMenu: widget.onOpenMenu)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: CurrencyDropdown(
              label: 'Base currency',
              value: _base,
              onChanged: (c) {
                setState(() => _base = c);
                _load();
              },
            ),
          ),
          if (s != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('1 $_base today  ·  ${s.date}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.forestGreen,
              onRefresh: _load,
              child: _body(s, codes),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(RateSnapshot? s, List<String> codes) {
    if (_loading && s == null) {
      return ListView(children: const [
        SizedBox(height: 120),
        Center(child: CircularProgressIndicator(color: AppColors.forestGreen)),
      ]);
    }
    if (_error != null && s == null) {
      return ListView(children: [
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Text(_error!,
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            GoldButton(label: 'Try again', onPressed: _load),
          ]),
        ),
      ]);
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: codes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final code = codes[i];
        final info = RatesService.info(code);
        final value = s?.rates[code];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTrend(code),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSlate),
            ),
            child: Row(
              children: [
                Text(info.flag, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(code,
                          style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      Text(info.name,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Text(value == null ? '—' : formatRate(value),
                    style: const TextStyle(
                        color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 17)),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }
}
