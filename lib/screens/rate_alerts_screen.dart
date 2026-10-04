import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/api_client.dart';
import 'package:currensee/services/rates_service.dart';
import 'package:currensee/services/user_store.dart';
import 'package:currensee/utils/format.dart';
import 'package:currensee/utils/toast.dart';
import 'package:currensee/screens/home/widgets/currency_dropdown.dart';


class RateAlertsScreen extends StatefulWidget {
  const RateAlertsScreen({super.key});

  @override
  State<RateAlertsScreen> createState() => _RateAlertsScreenState();
}

class _RateAlertsScreenState extends State<RateAlertsScreen> {
  List<Map<String, dynamic>> _alerts = const [];
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
      final a = await ApiClient.getAlerts();
      if (mounted) setState(() => _alerts = a);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(int id) async {
    try {
      await ApiClient.deleteAlert(id);
      await _load();
    } catch (e) {
      if (mounted) showAuthError(context, e.toString());
    }
  }

  Future<void> _add() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _NewAlertSheet(),
    );
    if (created == true) {
      if (mounted) toast(context, 'Alert created. We will notify you when it is reached.');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(title: const Text('Rate alerts')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.goldWarm,
        foregroundColor: AppColors.textDark,
        onPressed: _add,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('New alert'),
      ),
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
    if (_alerts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No alerts yet. Create one and we will notify you when a rate reaches your target.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.forestGreen,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: _alerts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final a = _alerts[i];
          final active = a['isActive'] == true;
          final above = a['direction'] == 'ABOVE';
          final threshold = trimZeros('${a['threshold']}');
          return Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSlate),
            ),
            child: Row(
              children: [
                Icon(above ? Icons.north_east_rounded : Icons.south_east_rounded,
                    color: above ? AppColors.positiveMint : AppColors.negativeRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${a['baseCode']} → ${a['targetCode']}',
                          style: const TextStyle(
                              color: AppColors.textDark, fontWeight: FontWeight.w800)),
                      Text('${above ? 'At or above' : 'At or below'} $threshold',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? AppColors.mintTint : AppColors.surfaceSlate,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(active ? 'Active' : 'Reached',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active ? AppColors.forestGreen : AppColors.textMuted)),
                ),
                IconButton(
                  tooltip: 'Delete alert',
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
                  onPressed: () => _delete((a['id'] as num).toInt()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NewAlertSheet extends StatefulWidget {
  const _NewAlertSheet();

  @override
  State<_NewAlertSheet> createState() => _NewAlertSheetState();
}

class _NewAlertSheetState extends State<_NewAlertSheet> {
  final _thresholdCtrl = TextEditingController();
  late String _from = RatesService.startingBase(UserStore.instance.baseCurrency);
  late String _to = RatesService.defaultTarget(_from, UserStore.instance.targetCurrency);
  String _direction = 'ABOVE';
  Future<RateSnapshot>? _current;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _current = RatesService.latest(_from);
  }

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _thresholdCtrl.text.trim();
    final value = double.tryParse(text);
    if (value == null || value <= 0) {
      showAuthError(context, 'Enter a target rate greater than zero.');
      return;
    }
    if (_from == _to) {
      showAuthError(context, 'Pick two different currencies.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiClient.createAlert(
          baseCode: _from, targetCode: _to, threshold: text, direction: _direction);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showAuthError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New rate alert',
              style: TextStyle(
                  color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CurrencyDropdown(
                  label: 'From',
                  value: _from,
                  onChanged: (c) => setState(() {
                    _from = c;
                    if (_to == c) _to = RatesService.defaultTarget(c, null);
                    _current = RatesService.latest(c);
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CurrencyDropdown(
                  label: 'To',
                  value: _to,
                  onChanged: (c) => setState(() {
                    _to = c;
                    if (_from == c) {
                      _from = RatesService.defaultTarget(c, null);
                      _current = RatesService.latest(_from);
                    }
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<RateSnapshot>(
            future: _current,
            builder: (_, snap) {
              final r = snap.data?.rates[_to];
              return Text(
                r == null
                    ? (snap.hasError ? 'Current rate unavailable.' : 'Loading current rate…')
                    : 'Now: 1 $_from = ${formatRate(r)} $_to',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              );
            },
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'ABOVE', label: Text('Rises to'), icon: Icon(Icons.north_east_rounded)),
              ButtonSegment(value: 'BELOW', label: Text('Falls to'), icon: Icon(Icons.south_east_rounded)),
            ],
            selected: {_direction},
            onSelectionChanged: (s) => setState(() => _direction = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _thresholdCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,10}\.?\d{0,8}'))],
            cursorColor: AppColors.forestGreen,
            decoration: InputDecoration(labelText: 'Target rate ($_to per 1 $_from)'),
          ),
          const SizedBox(height: 16),
          GoldButton(label: 'Create alert', isLoading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}