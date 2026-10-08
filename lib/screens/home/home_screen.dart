import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:currensee/auth/auth_widgets.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/api_client.dart';
import 'package:currensee/services/rates_service.dart';
import 'package:currensee/services/user_store.dart';
import 'package:currensee/utils/format.dart';
import 'package:currensee/utils/toast.dart';

import 'widgets/header_actions.dart';
import 'conversion_history_screen.dart';
import 'package:currensee/screens/news/news_screen.dart';
import 'widgets/rate_sparkline.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenMenu,
    required this.onGoToTab,
    required this.onOpenProfile,
  });

  final VoidCallback onOpenMenu;
  final ValueChanged<int> onGoToTab;
  final VoidCallback onOpenProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _amountCtrl = TextEditingController(text: '100');

  bool _ready = false;
  String _from = 'USD';
  String _to = 'EUR';

  RateSnapshot? _snapshot;
  List<double> _trend = const [];

  bool _ratesLoading = false;
  String? _ratesError;
  int _rateRequest = 0;
  bool _saving = false;

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
    final store = UserStore.instance;

    await store.load();

    if (!mounted) return;

    final from = RatesService.startingBase(store.baseCurrency);

    setState(() {
      _from = from;
      _to = RatesService.defaultTarget(from, store.targetCurrency);
      _ready = true;
    });

    await _loadRates();
  }

  Future<void> _refreshAll() async {
    await UserStore.instance.load(force: true);
    await _loadRates();
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
      } catch (_) {}

      if (!mounted || id != _rateRequest) return;

      setState(() {
        _snapshot = snapshot;
        _trend = trend;
      });
    } catch (e) {
      if (mounted && id == _rateRequest) {
        setState(() => _ratesError = e.toString());
      }
    } finally {
      if (mounted && id == _rateRequest) {
        setState(() => _ratesLoading = false);
      }
    }
  }

  Future<void> _loadTrend() async {
    final id = ++_rateRequest;

    try {
      final trend = await RatesService.trend(_from, _to);

      if (!mounted || id != _rateRequest) return;

      setState(() => _trend = trend);
    } catch (_) {
      if (mounted && id == _rateRequest) {
        setState(() => _trend = const []);
      }
    }
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

    if (fromChanged) {
      _loadRates();
    } else {
      _loadTrend();
    }
  }

  void _pickFrom(String code) {
    _setPair(code, code == _to ? _from : _to);
  }

  void _pickTo(String code) {
    _setPair(code == _from ? _to : _from, code);
  }

  void _swap() {
    _setPair(_to, _from);
  }

  Future<void> _convertNow() async {
    final amount = _amount;

    if (amount == null || amount <= 0) {
      showAuthError(context, 'Enter an amount greater than zero.');
      return;
    }

    if (_from == _to) {
      showAuthError(context, 'Pick two different currencies.');
      return;
    }

    setState(() => _saving = true);

    try {
      await _loadRates();

      final rate = _rate;

      if (rate == null) {
        if (mounted) {
          showAuthError(
            context,
            'Live rates have not loaded yet. Pull down to retry.',
          );
        }

        return;
      }

      await ApiClient.saveConversion(
        fromCode: _from,
        toCode: _to,
        amount: amount.toStringAsFixed(4),
        rateUsed: rate.toStringAsFixed(8),
      );

      if (mounted) {
        final sym = RatesService.info(_to).symbol;

        toast(
          context,
          'Saved: ${trimZeros(amount.toStringAsFixed(4))} $_from = '
          '$sym${formatNumber(
            amount * rate,
            decimals: decimalsFor(_to),
          )} $_to',
        );
      }
    } catch (e) {
      if (mounted) {
        showAuthError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _saveAsDefault() async {
    try {
      await ApiClient.updatePreferences({
        'defaultBaseCurrency': _from,
        'defaultTargetCurrency': _to,
      });

      await UserStore.instance.load(force: true);

      if (mounted) {
        toast(context, '$_from → $_to is now your default pair.');
      }
    } catch (e) {
      if (mounted) {
        showAuthError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: AppColors.surfaceSlate,
        child: RefreshIndicator(
          color: AppColors.forestGreen,
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 230 + top,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.brandBackground,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(42),
                        bottomRight: Radius.circular(42),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    top + 12,
                    16,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _topBar(),
                      const SizedBox(height: 20),
                      // _welcome(),
                      const SizedBox(height: 18),

                      if (UserStore.instance.error != null &&
                          !UserStore.instance.loaded) ...[
                        _Banner(
                          message: UserStore.instance.error!,
                          onRetry: _refreshAll,
                        ),
                        const SizedBox(height: 16),
                      ],

                      _ready
                          ? _converterCard()
                          : const _LoadingCard(),

                      if (_ready) ...[
                        const SizedBox(height: 16),
                        _trendCard(),
                      ],

                      const SizedBox(height: 24),
                      _quickActions(),

                      const SizedBox(height: 24),
                      _popular(),

                      const SizedBox(height: 22),
                      const Center(
                        child: Text(
                          'Rates: daily reference rates from central banks and official sources.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final hour = DateTime.now().hour;

    String greeting;

    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
return Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Expanded(
      child: ListenableBuilder(
        listenable: UserStore.instance,
        builder: (_, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                UserStore.instance.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                margin: const EdgeInsets.only(top: 10), // margin top
                alignment: Alignment.center,            // center horizontally
                child: const Text(
                  'Here\'s your currency snapshot for today.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
    HeaderActions(
      onOpenProfile: widget.onOpenProfile,
      iconColor: AppColors.white,
      avatarBackground: AppColors.emeraldGlow,
    ),
  ],
);

  }


  Widget _converterCard() {
    final amount = _amount;
    final rate = _rate;

    final result = (amount != null && rate != null)
        ? amount * rate
        : null;

    final toInfo = RatesService.info(_to);

    return _Card(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.mintTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.currency_exchange_rounded,
                  color: AppColors.forestGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Currency converter',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _currencyBox(
                  code: _from,
                  onChanged: _pickFrom,
                  field: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSlate,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.borderSlate,
                      ),
                    ),
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
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
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
              Expanded(
                child: _currencyBox(
                  code: _to,
                  onChanged: _pickTo,
                  field: Container(
                    height: 50,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.mintTint.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.mintTint,
                      ),
                    ),
                    child: _ratesLoading && result == null
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.forestGreen,
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              result == null
                                  ? '—'
                                  : '${toInfo.symbol}${formatNumber(
                                      result,
                                      decimals: decimalsFor(_to),
                                    )}',
                              style: const TextStyle(
                                color: AppColors.emeraldBg,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_ratesError != null && rate == null)
            _Banner(
              message: _ratesError!,
              onRetry: _loadRates,
            )
          else
            Text(
              rate == null
                  ? ' '
                  : '1 $_from = ${formatRate(rate)} $_to'
                      '${_snapshot != null && _from != _to ? '   ·   ${_snapshot!.date}' : ''}',
              style: const TextStyle(
                color: AppColors.emeraldBg,
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _saving ? null : _convertNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldWarm,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.textDark,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Convert'),
                      SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 6),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _from == _to ? null : _saveAsDefault,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.mintTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 17,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Make $_from → $_to my default',
                      style: const TextStyle(
                        color: AppColors.emeraldBg,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencyBox({
    required String code,
    required ValueChanged<String> onChanged,
    required Widget field,
  }) {
    final info = RatesService.info(code);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderSlate,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Flag(info.flag),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: code,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: AppColors.white,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                    ),
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                    selectedItemBuilder: (_) => [
                      for (final c in RatesService.supported)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(c),
                        ),
                    ],
                    items: [
                      for (final c in RatesService.supported)
                        DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${RatesService.info(c).flag}  $c',
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        onChanged(v);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              info.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          field,
        ],
      ),
    );
  }

  Widget _trendCard() {
    if (_from == _to) {
      return const SizedBox.shrink();
    }

    final hasTrend = _trend.length >= 2;
    final change =
        hasTrend ? (_trend.last / _trend.first - 1) * 100 : 0.0;
    final up = change >= 0;
    final rate = _rate;
    final sym = RatesService.info(_to).symbol;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.emeraldBg,
            AppColors.emeraldDeep,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: AppColors.positiveMint,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '7-day trend',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _Pill(
                label: 'Details',
                dark: true,
                onTap: () => widget.onGoToTab(1),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$_from → $_to',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          rate == null
                              ? '—'
                              : '$sym${formatRate(rate)}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    if (hasTrend) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              up
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 13,
                              color: up
                                  ? AppColors.positiveMint
                                  : const Color(0xFFFCA5A5),
                            ),
                            Text(
                              '${change.abs().toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: up
                                    ? AppColors.positiveMint
                                    : const Color(0xFFFCA5A5),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 58,
                  child: hasTrend
                      ? RateSparkline(
                          values: _trend,
                          color: up
                              ? AppColors.positiveMint
                              : const Color(0xFFFCA5A5),
                        )
                      : Center(
                          child: Text(
                            _ratesLoading
                                ? 'Loading…'
                                : 'No trend',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Quick actions',
          onSeeAll: null,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 10) / 2;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: _ActionTile(
                    icon: Icons.currency_exchange_rounded,
                    label: 'Converter',
                    subtitle: 'Convert currencies',
                    gold: false,
                    onTap: () => widget.onGoToTab(2),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _ActionTile(
                    icon: Icons.show_chart_rounded,
                    label: 'Rate Trends',
                    subtitle: 'Track market movement',
                    gold: true,
                    onTap: () => widget.onGoToTab(1),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _ActionTile(
                    icon: Icons.bookmark_outline_rounded,
                    label: 'Saved Pairs',
                    subtitle: 'View your history',
                    gold: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ConversionHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _ActionTile(
                    icon: Icons.article_outlined,
                    label: 'Market News',
                    subtitle: 'Currency news & insights',
                    gold: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NewsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _popular() {
    const wanted = [
      'USD',
      'EUR',
      'GBP',
      'INR',
      'JPY',
      'CAD',
      'AUD',
    ];

    final codes =
        wanted.where(RatesService.isSupported).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Popular currencies',
          onSeeAll: () => widget.onGoToTab(1),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: codes.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final info = RatesService.info(codes[i]);
              final selected = codes[i] == _to;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _pickTo(codes[i]),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.mintTint
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? AppColors.forestGreen
                          : AppColors.borderSlate,
                    ),
                  ),
                  child: Row(
                    children: [
                      _Flag(info.flag),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.code,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              info.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
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
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.radius = 20,
  });

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldDeep.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      radius: 24,
      child: SizedBox(
        height: 240,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.forestGreen,
          ),
        ),
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag(this.emoji);

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceSlate,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.borderSlate,
        ),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 19),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.onTap,
    this.leading,
    this.dark = false,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? leading;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark
        ? AppColors.white
        : AppColors.emeraldBg;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.mintTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: fg,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
  });

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            child: const Row(
              children: [
                Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textDark,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gold,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool gold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = gold
        ? const Color(0xFFFEF7E5)
        : AppColors.white;

    final border = gold
        ? const Color(0xFFF4E2A9)
        : AppColors.borderSlate;

    final iconBackground = gold
        ? AppColors.goldWarm
        : AppColors.mintTint;

    final iconColor = gold
        ? AppColors.textDark
        : AppColors.forestGreen;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor:
            AppColors.mintTint.withValues(alpha: 0.45),
        highlightColor:
            AppColors.mintTint.withValues(alpha: 0.18),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 104,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: gold
                    ? AppColors.goldWarm
                    : AppColors.forestGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        10,
        6,
        10,
      ),
      decoration: BoxDecoration(
        color: AppColors.redTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.negativeRed,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.negativeRed,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

