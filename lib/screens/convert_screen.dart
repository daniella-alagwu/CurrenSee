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
import 'package:currensee/screens/home/widgets/header_actions.dart';
import 'package:currensee/screens/home/conversion_history_screen.dart';
import 'package:currensee/screens/home/widgets/conversion_tile.dart';

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({
    super.key,
    required this.onOpenMenu,
    required this.onOpenProfile,
  });

  final VoidCallback onOpenMenu;
  final VoidCallback onOpenProfile;

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  final _amountCtrl = TextEditingController(text: '100');
  String _from = 'USD';
  String _to = 'EUR';
  RateSnapshot? _snapshot;
  List<Map<String, dynamic>> _recent = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();

    _amountCtrl.addListener(() => setState(() {}));

    Future.microtask(() async {
      final store = UserStore.instance;

      await store.load();

      if (!mounted) return;

      _from = RatesService.startingBase(store.baseCurrency);
      _to = RatesService.defaultTarget(_from, store.targetCurrency);

      await Future.wait([
        _loadRates(),
        _loadRecent(),
      ]);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    final id = ++_request;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final s = await RatesService.latest(_from);

      if (mounted && id == _request) {
        setState(() => _snapshot = s);
      }
    } catch (e) {
      if (mounted && id == _request) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted && id == _request) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadRecent() async {
    try {
      final data = await ApiClient.getConversionHistory(limit: 5);

      final items = (data['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();

      if (mounted) {
        setState(() => _recent = items);
      }
    } catch (_) {}
  }

  double? get _amount => double.tryParse(_amountCtrl.text.trim());

  double? get _rate {
    if (_from == _to) return 1;

    final s = _snapshot;

    if (s == null || s.base != _from) return null;

    return s.rates[_to];
  }

  void _setPair(String from, String to) {
    final fromChanged = from != _from;

    setState(() {
      _from = from;
      _to = to;
    });

    if (fromChanged) _loadRates();
  }

  Future<void> _save() async {
    final amount = _amount;
    final rate = _rate;

    if (amount == null || amount <= 0) {
      showAuthError(context, 'Enter an amount greater than zero.');
      return;
    }

    if (_from == _to) {
      showAuthError(
        context,
        'Pick two different currencies to save a conversion.',
      );
      return;
    }

    if (rate == null) {
      showAuthError(
        context,
        'Live rates have not loaded yet. Pull down to retry.',
      );
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

      await _loadRecent();

      if (mounted) {
        toast(context, 'Conversion saved to your history.');
      }
    } catch (e) {
      if (mounted) showAuthError(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reuse(Map<String, dynamic> item) {
    final from = '${item['fromCode']}'.toUpperCase();
    final to = '${item['toCode']}'.toUpperCase();
    final amount = double.tryParse('${item['amount']}');

    if (!RatesService.isSupported(from) ||
        !RatesService.isSupported(to)) {
      return;
    }

    if (amount != null) {
      _amountCtrl.text = trimZeros(amount.toStringAsFixed(4));
    }

    _setPair(from, to);
  }

  Future<void> _openHistory() async {
    final picked = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const ConversionHistoryScreen(),
      ),
    );

    if (picked != null) _reuse(picked);
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    final rate = _rate;
    final result =
        (amount != null && rate != null) ? amount * rate : null;
    final toInfo = RatesService.info(_to);
    final others =
        RatesService.supported.where((c) => c != _from).toList();

    return Scaffold(
      backgroundColor: AppColors.surfaceSlate,
      appBar: AppBar(
        title: const Text(
          'Convert',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          HeaderActions(
            onOpenMenu: widget.onOpenMenu,
            onOpenProfile: widget.onOpenProfile,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.forestGreen,
        onRefresh: () async {
          await Future.wait([
            _loadRates(),
            _loadRecent(),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,14}\.?\d{0,4}'),
                      ),
                    ],
                    cursorColor: AppColors.forestGreen,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText:
                          '${RatesService.info(_from).symbol} ',
                      filled: true,
                      fillColor: AppColors.surfaceSlate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CurrencyDropdown(
                          label: 'From',
                          value: _from,
                          onChanged: (c) =>
                              _setPair(c, c == _to ? _from : _to),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        child: IconButton.filledTonal(
                          tooltip: 'Swap currencies',
                          onPressed: () => _setPair(_to, _from),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.mintTint,
                            foregroundColor: AppColors.forestGreen,
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded),
                        ),
                      ),
                      Expanded(
                        child: CurrencyDropdown(
                          label: 'To',
                          value: _to,
                          onChanged: (c) =>
                              _setPair(c == _from ? _to : _from, c),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_error != null && rate == null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.negativeRed,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AuthLink(
                      label: 'Retry',
                      onPressed: _loadRates,
                    ),
                  ] else ...[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        result == null
                            ? (_loading ? 'Fetching live rate…' : '—')
                            : '${toInfo.symbol}${formatNumber(result, decimals: decimalsFor(_to))} $_to',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rate == null
                          ? ' '
                          : '1 $_from = ${formatRate(rate)} $_to'
                              '${_snapshot != null && _from != _to ? '  ·  ${_snapshot!.date}' : ''}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  GoldButton(
                    label: 'Save conversion',
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_snapshot != null &&
                _snapshot!.base == _from &&
                amount != null)
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trimZeros(amount.toStringAsFixed(4))} $_from in other currencies',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final code in others)
                      Builder(
                        builder: (_) {
                          final info = RatesService.info(code);
                          final r = _snapshot!.rates[code];

                          return InkWell(
                            onTap: () => _setPair(_from, code),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 9,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    info.flag,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '$code  ·  ${info.name}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textDark,
                                        fontWeight: code == _to
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    r == null
                                        ? '—'
                                        : '${info.symbol}${formatNumber(amount * r, decimals: decimalsFor(code))}',
                                    style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Recent conversions',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (_recent.isNotEmpty)
                        AuthLink(
                          label: 'See all',
                          onPressed: _openHistory,
                        ),
                    ],
                  ),
                  if (_recent.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(2, 10, 2, 2),
                      child: Text(
                        'Nothing saved yet. Tap “Save conversion” to keep one here.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < _recent.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ConversionTile(
                        item: _recent[i],
                        onTap: () => _reuse(_recent[i]),
                      ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSlate),
        ),
        child: child,
      );
}