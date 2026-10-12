import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:currensee/data/currency_catalog.dart';

// Keeps existing `import rates_service.dart` + CurrencyInfo usages working.
export 'package:currensee/data/currency_catalog.dart' show CurrencyInfo;

class RatesException implements Exception {
  RatesException(this.message);
  final String message;
  @override
  String toString() => message;
}

class RateSnapshot {
  const RateSnapshot({required this.base, required this.date, required this.rates});
  final String base;
  final String date;  
  final Map<String, double> rates;
}
class RatesService {
  RatesService._();

  static const String _base = 'https://api.frankfurter.dev/v2';

  static List<String> _supported = List.of(kLaunchCurrencies);
  static Set<String> _supportedSet = Set.of(kLaunchCurrencies);
  static Future<void>? _loading;

  static List<String> get supported => _supported;

  static bool isSupported(String code) => _supportedSet.contains(code);

  static CurrencyInfo info(String code) =>
      kCurrencyCatalog[code] ?? CurrencyInfo(code, code, code, '🏳️');

  /// Intersects our catalog with what the rates API really serves, so we never
  /// offer a currency that would make a rates request fail. Never throws; on
  /// failure the launch set stays in place and the next call retries.
  static Future<void> ensureSupported() => _loading ??= _loadSupported();

  static Future<void> _loadSupported() async {
    try {
      final rows =
          await _getJson(Uri.parse('$_base/currencies')) as List<dynamic>? ??
              const [];
      final served = <String>{
        for (final row in rows.whereType<Map<String, dynamic>>())
          if (row['iso_code'] is String)
            (row['iso_code'] as String).toUpperCase(),
      };
      final list = [
        for (final code in kCurrencyCatalog.keys)
          if (served.contains(code)) code,
      ];
      if (list.isNotEmpty && served.contains('USD')) {
        _supported = list;
        _supportedSet = Set.of(list);
      } else {
        _loading = null;
      }
    } catch (_) {
      _loading = null;
    }
  }

  static String startingBase(String? userCurrency) =>
      (userCurrency != null && isSupported(userCurrency)) ? userCurrency : 'USD';

  
  static String defaultTarget(String from, String? preferred) {
    if (preferred != null && preferred != from && isSupported(preferred)) return preferred;
    return from == 'USD' ? 'EUR' : 'USD';
  }

  static Future<RateSnapshot> latest(String base) async {
    await ensureSupported();
    final targets = supported.where((c) => c != base).join(',');
    final uri = Uri.parse('$_base/rates').replace(queryParameters: {
      'base': base,
      'quotes': targets,
    });
    final rows = await _getJson(uri) as List<dynamic>? ?? const [];
    final rates = <String, double>{};
    var date = '';
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      final quote = row['quote'] as String?;
      final value = row['rate'];
      if (quote != null && value is num) {
        rates[quote.toUpperCase()] = value.toDouble();
        date = date.isEmpty ? (row['date'] as String? ?? '') : date;
      }
    }
    return RateSnapshot(
      base: base,
      date: date,
      rates: rates,
    );
  }


  static Future<List<double>> trend(String base, String target, {int days = 7}) async {
    if (base == target) return const [];
    final start = DateTime.now().toUtc().subtract(Duration(days: days + 6));
    final y = start.year.toString().padLeft(4, '0');
    final m = start.month.toString().padLeft(2, '0');
    final d = start.day.toString().padLeft(2, '0');
    final uri = Uri.parse('$_base/rates').replace(queryParameters: {
      'base': base,
      'quotes': target,
      'from': '$y-$m-$d',
    });
    final rows = await _getJson(uri) as List<dynamic>? ?? const [];
    final points = <MapEntry<String, double>>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      final date = row['date'];
      final quote = row['quote'];
      final rate = row['rate'];
      if (date is String && quote == target && rate is num) {
        points.add(MapEntry(date, rate.toDouble()));
      }
    }
    points.sort((a, b) => a.key.compareTo(b.key));
    final values = points.map((point) => point.value).toList();
    return values.length > days ? values.sublist(values.length - days) : values;
  }

  static Future<dynamic> _getJson(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw RatesException('Rates are unavailable right now (${response.statusCode}).');
      }
      return jsonDecode(response.body);
    } on RatesException {
      rethrow;
    } catch (_) {
      throw RatesException('Could not load live rates. Check your connection and try again.');
    }
  }
}