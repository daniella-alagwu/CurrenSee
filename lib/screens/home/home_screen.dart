import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/assets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/api_client.dart';
import 'package:currensee/services/rates_service.dart';
import 'package:currensee/utils/format.dart';
import 'conversion_history_screen.dart';
import 'widgets/conversion_tile.dart';
import 'widgets/rate_sparkline.dart';

/// Signed-in dashboard: quick converter with live rates, 7-day trend,
/// other-currency rates, recent saved conversions and notification settings.
/// Backed by: GET /users/me, GET+POST /users/conversions, PATCH /users/preferences.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _amountCtrl = TextEditingController(text: '100');

  String _from = 'USD';
  String _to = 'EUR';

  // profile + preferences (from the backend)
  String? _name;
  String? _countryName;
  bool _push = true;
  bool _alerts = true;
  List<Map<String, dynamic>> _recent = const [];
  bool _profileLoading = true;
  String? _profileError;

  
  RateSnapshot? _snapshot;
  List<double> _trend = const [];
  bool _ratesLoading = false;
  String? _ratesError;
  int _rateRequest = 0;

  bool _saving = false;
  bool _prefsBusy = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() => setState(() {}));
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

 

  Future<void> _bootstrap() async {
    await _loadProfile();
    await _loadRates();
  }

  Future<void> _refreshAll() async {
    await _loadProfile();
    await _loadRates();
  }

  static bool _asBool(Object? v, bool fallback) {
    if (v is bool) return v;
    if (v is num) return v != 0; 
    return fallback;
  }

  Future<void> _loadProfile() async {
    setState(() {
      _profileLoading = true;
      _profileError = null;
    });
    try {
      final results = await Future.wait([
        ApiClient.getCurrentUser(),
        ApiClient.getConversionHistory(limit: 5),
      ]);
      final user = (results[0]['user'] as Map<String, dynamic>?) ?? const {};
      final prefs = (user['preferences'] as Map<String, dynamic>?) ?? const {};
      final items = (results[1]['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (!mounted) return;

      final base = (prefs['defaultBaseCurrency'] as String?)?.toUpperCase();
      final target = (prefs['defaultTargetCurrency'] as String?)?.toUpperCase();
      setState(() {
        _name = user['name'] as String?;
        _countryName = user['countryName'] as String?;
        _push = _asBool(prefs['pushEnabled'], true);
        _alerts = _asBool(prefs['alertNotificationsEnabled'], true);
        _recent = items;
        // Start on the user's saved default pair (first load only).
        if (_snapshot == null &&
            base != null &&
            target != null &&
            base != target &&
            RatesService.isSupported(base) &&
            RatesService.isSupported(target)) {
          _from = base;
          _to = target;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _profileError = e.toString());
    } finally {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  Future<void> _loadRates() async {
    final id = ++_rateRequest;
    setState(() {
      _ratesLoading = true;
      _ratesError = null;
    });
    try {
      final snapshot = await RatesService.latest(_from);
      var trend = const <double>[];
      try {
        trend = await RatesService.trend(_from, _to);
      } catch (_) {
        
      }
      if (!mounted || id != _rateRequest) return;
      setState(() {
        _snapshot = snapshot;
        _trend = trend;
      });
    } catch (e) {
      if (mounted && id == _rateRequest) setState(() => _ratesError = e.toString());
    } finally {
      if (mounted && id == _rateRequest) setState(() => _ratesLoading = false);
    }
  }

  Future<void> _loadTrend() async {
    final id = ++_rateRequest;
    try {
      final trend = await RatesService.trend(_from, _to);
      if (!mounted || id != _rateRequest) return;
      setState(() => _trend = trend);
    } catch (_) {
      if (mounted && id == _rateRequest) setState(() => _trend = const []);
    }
  }

  Future<void> _refreshRecent() async {
    final data = await ApiClient.getConversionHistory(limit: 5);
    final items = (data['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (mounted) setState(() => _recent = items);
  }

 

  double? get _amount => double.tryParse(_amountCtrl.text.trim());

  double? get _rate {
    if (_from == _to) return 1;
    final s = _snapshot;
    if (s == null || s.base != _from) return null;
    return s.rates[_to];
  }

  void _toast(String message, {bool error = false}) {
    if (error) {
      showAuthError(context, message);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
        content: Text(message, style: const TextStyle(color: AppColors.white)),
      ));
  }

  void _setPair(String from, String to) {
    final fromChanged = from != _from;
    setState(() {
      _from = from;
      _to = to;
    });
    if (fromChanged) {
      _loadRates();
    } else {
      _loadTrend();
    }
  }

  void _pickFrom(String code) => _setPair(code, code == _to ? _from : _to);

  void _pickTo(String code) => _setPair(code == _from ? _to : _from, code);

  void _swap() => _setPair(_to, _from);

  Future<void> _save() async {
    final amount = _amount;
    final rate = _rate;
    if (amount == null || amount <= 0) {
      _toast('Enter an amount greater than zero.', error: true);
      return;
    }
    if (_from == _to) {
      _toast('Pick two different currencies to save a conversion.', error: true);
      return;
    }
    if (rate == null) {
      _toast('Live rates have not loaded yet. Pull down to retry.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiClient.saveConversion(
        fromCode: _from,
        toCode: _to,
        amount: amount.toStringAsFixed(4),
        rateUsed: rate.toStringAsFixed(8),
      );
      await _refreshRecent();
      if (mounted) _toast('Conversion saved to your history.');
    } catch (e) {
      if (mounted) _toast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAsDefault() async {
    try {
      await ApiClient.updatePreferences({
        'defaultBaseCurrency': _from,
        'defaultTargetCurrency': _to,
      });
      if (mounted) _toast('$_from → $_to is now your default pair.');
    } catch (e) {
      if (mounted) _toast(e.toString(), error: true);
    }
  }

  Future<void> _togglePref(String key, bool value) async {
    final oldPush = _push;
    final oldAlerts = _alerts;
    setState(() {
      if (key == 'pushEnabled') {
        _push = value;
      } else {
        _alerts = value;
      }
      _prefsBusy = true;
    });
    try {
      await ApiClient.updatePreferences({key: value});
    } catch (e) {
      if (mounted) {
        setState(() {
          _push = oldPush;
          _alerts = oldAlerts;
        });
        _toast(e.toString(), error: true);
      }
    } finally {
      if (mounted) setState(() => _prefsBusy = false);
    }
  }

  void _reuse(Map<String, dynamic> item) {
    final from = '${item['fromCode']}'.toUpperCase();
    final to = '${item['toCode']}'.toUpperCase();
    final amount = double.tryParse('${item['amount']}');
    if (!RatesService.isSupported(from) || !RatesService.isSupported(to)) return;
    if (amount != null) _amountCtrl.text = trimZeros(amount.toStringAsFixed(4));
    _setPair(from, to);
  }

  Future<void> _openHistory() async {
    final picked = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const ConversionHistoryScreen()),
    );
    if (picked != null) _reuse(picked);
  }



  String get _displayName {
    final n = _name?.trim();
    if (n != null && n.isNotEmpty) return n.split(' ').first;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final local = email.split('@').first;
    if (local.isEmpty) return 'there';
    return local[0].toUpperCase() + local.substring(1);
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        titleSpacing: 16,
        title: Image.asset(AppAssets.logoFull, height: 34, fit: BoxFit.contain),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.forestGreen,
        onRefresh: _refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            _header(),
            if (_profileError != null) ...[
              const SizedBox(height: 14),
              _Banner(message: _profileError!, onRetry: _loadProfile),
            ],
            const SizedBox(height: 18),
            _converterCard(),
            const SizedBox(height: 16),
            _trendCard(),
            const SizedBox(height: 16),
            _ratesStrip(),
            const SizedBox(height: 16),
            _recentCard(),
            const SizedBox(height: 16),
            _settingsCard(),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Rates: European Central Bank reference rates, published each working day.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final country = _countryName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting, $_displayName',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          country == null || country.isEmpty
              ? 'Here is your money at a glance.'
              : 'Based in $country  ·  pull down to refresh',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
      ],
    );
  }

  Widget _converterCard() {
    final amount = _amount;
    final rate = _rate;
    final result = (amount != null && rate != null) ? amount * rate : null;
    final toInfo = RatesService.info(_to);
    final fromInfo = RatesService.info(_from);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(icon: Icons.currency_exchange_rounded, title: 'Quick convert'),
          const SizedBox(height: 14),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,14}\.?\d{0,4}')),
            ],
            cursorColor: AppColors.forestGreen,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '${fromInfo.symbol} ',
              filled: true,
              fillColor: AppColors.surfaceSlate,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _picker('From', _from, _pickFrom),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: IconButton.filledTonal(
                  tooltip: 'Swap currencies',
                  onPressed: _swap,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.mintTint,
                    foregroundColor: AppColors.forestGreen,
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded),
                ),
              ),
              _picker('To', _to, _pickTo),
            ],
          ),
          const SizedBox(height: 18),
          if (_ratesError != null && rate == null)
            _Banner(message: _ratesError!, onRetry: _loadRates)
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    result == null
                        ? (_ratesLoading ? 'Fetching live rate…' : '—')
                        : '${toInfo.symbol}${formatNumber(result, decimals: decimalsFor(_to))} $_to',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_ratesLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.forestGreen,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              rate == null
                  ? ' '
                  : '1 $_from = ${formatRate(rate)} $_to'
                      '${_snapshot != null && _from != _to ? '  ·  ${_snapshot!.date}' : ''}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 18),
          GoldButton(label: 'Save conversion', isLoading: _saving, onPressed: _save),
          Align(
            alignment: Alignment.center,
            child: AuthLink(
              label: 'Make $_from → $_to my default pair',
              onPressed: _from == _to ? () {} : _saveAsDefault,
            ),
          ),
        ],
      ),
    );
  }

  Widget _picker(String label, String value, ValueChanged<String> onChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSlate,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSlate),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: AppColors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  for (final code in RatesService.supported)
                    DropdownMenuItem(
                      value: code,
                      child: Text('${RatesService.info(code).flag}  $code'),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendCard() {
    if (_from == _to) return const SizedBox.shrink();
    final hasTrend = _trend.length >= 2;
    final change = hasTrend ? (_trend.last / _trend.first - 1) * 100 : 0.0;
    final up = change >= 0;
    final color = up ? AppColors.positiveMint : AppColors.negativeRed;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  icon: Icons.show_chart_rounded,
                  title: '7-day trend  ·  $_from → $_to',
                ),
              ),
              if (hasTrend)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: up ? AppColors.mintTint : AppColors.redTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 14, color: color),
                      const SizedBox(width: 2),
                      Text(
                        '${change.abs().toStringAsFixed(2)}%',
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasTrend)
            RateSparkline(values: _trend, color: color)
          else
            SizedBox(
              height: 72,
              child: Center(
                child: Text(
                  _ratesLoading ? 'Loading trend…' : 'Trend is not available right now.',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ratesStrip() {
    final snapshot = _snapshot;
    if (snapshot == null || snapshot.base != _from) return const SizedBox.shrink();
    final codes = RatesService.supported.where((c) => c != _from).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: Icons.public_rounded, title: '1 $_from today'),
        const SizedBox(height: 10),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: codes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final code = codes[i];
              final value = snapshot.rates[code];
              final selected = code == _to;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _pickTo(code),
                child: Container(
                  width: 112,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.mintTint : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.forestGreen : AppColors.borderSlate,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${RatesService.info(code).flag}  $code',
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        value == null ? '—' : formatRate(value),
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _recentCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(icon: Icons.history_rounded, title: 'Recent conversions'),
              ),
              if (_recent.isNotEmpty)
                AuthLink(label: 'See all', onPressed: _openHistory),
            ],
          ),
          if (_profileLoading && _recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.forestGreen),
              ),
            )
          else if (_recent.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Text(
                'Nothing saved yet. Convert an amount above and tap “Save conversion” to keep it here.',
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
            )
          else
            for (var i = 0; i < _recent.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              ConversionTile(item: _recent[i], onTap: () => _reuse(_recent[i])),
            ],
        ],
      ),
    );
  }

  Widget _settingsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(icon: Icons.notifications_none_rounded, title: 'Notifications'),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Push notifications',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Updates from CurrenSee on this device'),
            value: _push,
            onChanged: _prefsBusy ? null : (v) => _togglePref('pushEnabled', v),
          ),
          const Divider(height: 1),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rate alerts',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Get notified about rate movements'),
            value: _alerts,
            onChanged: _prefsBusy ? null : (v) => _togglePref('alertNotificationsEnabled', v),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- helpers

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSlate),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.forestGreen),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.redTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.negativeRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.negativeRed),
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
