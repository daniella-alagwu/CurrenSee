import 'package:flutter/material.dart';
import 'package:currensee/constants/colors.dart';
import 'package:currensee/services/rates_service.dart';

const List<String> _popular = [
  'USD', 'EUR', 'GBP', 'NGN', 'AED', 'INR', 'CAD', 'JPY', 'ZAR', 'CNY',
];

/// Ranked search over code, name and symbol. Empty query returns everything.
List<String> searchCurrencies(String query, {String? exclude}) {
  final q = query.trim().toLowerCase();
  final all = RatesService.supported.where((c) => c != exclude).toList();
  if (q.isEmpty) return all;

  final hits = <(int, String)>[];
  for (final c in all) {
    final info = RatesService.info(c);
    final code = c.toLowerCase();
    final name = info.name.toLowerCase();
    final sym = info.symbol.trim().toLowerCase();
    int? score;
    if (code == q) {
      score = 0;
    } else if (code.startsWith(q)) {
      score = 1;
    } else if (name.startsWith(q)) {
      score = 2;
    } else if (name.split(' ').any((w) => w.startsWith(q))) {
      score = 3;
    } else if (name.contains(q)) {
      score = 4;
    } else if (sym == q) {
      score = 5;
    }
    if (score != null) hits.add((score, c));
  }
  hits.sort((a, b) {
    final d = a.$1.compareTo(b.$1);
    return d != 0 ? d : a.$2.compareTo(b.$2);
  });
  return [for (final h in hits) h.$2];
}

/// Opens the picker. Returns the chosen code, or null if dismissed.
Future<String?> showCurrencyPicker(
  BuildContext context, {
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: _CurrencyPickerSheet(selected: selected),
      ),
    ),
  );
}

class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet({required this.selected});
  final String selected;

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pick(String code) => Navigator.of(context).pop(code);

  @override
  Widget build(BuildContext context) {
    final selectedInfo = RatesService.info(widget.selected);
    final searching = _query.trim().isNotEmpty;
    final results = searchCurrencies(_query);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        color: AppColors.surfaceSlate,
        child: Column(
          children: [
            // ── Header: brand gradient, oversized flag, pinned search ──
            Container(
              width: double.infinity,
              decoration:
                  const BoxDecoration(gradient: AppColors.brandBackground),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Stack(
                children: [
                  Positioned(
                    right: -6,
                    top: 14,
                    child: Opacity(
                      opacity: 0.22,
                      child: Text(selectedInfo.flag,
                          style: const TextStyle(fontSize: 96)),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Choose a currency',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${RatesService.supported.length} currencies  ·  now: ${widget.selected}',
                        style: const TextStyle(
                            color: AppColors.goldLight, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _controller,
                        onChanged: (v) => setState(() => _query = v),
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Search code, name or symbol',
                          hintStyle:
                              const TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.white,
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.forestGreen),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: AppColors.textMuted),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: searching
                  ? _buildResults(results)
                  : _buildBrowse(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(List<String> results) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 44, color: AppColors.textMuted),
              const SizedBox(height: 10),
              Text(
                'No currency matches “${_query.trim()}”',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Try the 3-letter code, a country, or part of the name.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _CurrencyRow(
        code: results[i],
        selected: results[i] == widget.selected,
        onTap: () => _pick(results[i]),
      ),
    );
  }

  Widget _buildBrowse() {
    final popular = _popular.where(RatesService.isSupported).toList();
    final byName = RatesService.supported.toList()
      ..sort((a, b) =>
          RatesService.info(a).name.compareTo(RatesService.info(b).name));

    // Flatten into: popular strip, then letter headers + rows.
    final items = <Object>['__popular__'];
    String? letter;
    for (final c in byName) {
      final l = RatesService.info(c).name[0].toUpperCase();
      if (l != letter) {
        letter = l;
        items.add(l);
      }
      items.add(c);
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i] as String;
        if (item == '__popular__') return _popularStrip(popular);
        if (item.length == 1) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
            child: Text(
              item,
              style: const TextStyle(
                color: AppColors.forestGreen,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _CurrencyRow(
            code: item,
            selected: item == widget.selected,
            onTap: () => _pick(item),
          ),
        );
      },
    );
  }

  Widget _popularStrip(List<String> codes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'POPULAR',
            style: TextStyle(
              color: AppColors.goldDeep,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: codes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final code = codes[i];
              final isSel = code == widget.selected;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _pick(code),
                child: Container(
                  width: 78,
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.mintTint : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSel
                          ? AppColors.forestGreen
                          : AppColors.borderSlate,
                      width: isSel ? 1.6 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(RatesService.info(code).flag,
                          style: const TextStyle(fontSize: 36)),
                      const SizedBox(height: 6),
                      Text(
                        code,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
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

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = RatesService.info(code);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.mintTint : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.forestGreen : AppColors.borderSlate,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceSlate,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(info.flag, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    info.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSlate,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSlate),
              ),
              child: Text(
                info.symbol.trim(),
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.forestGreen),
            ],
          ],
        ),
      ),
    );
  }
}