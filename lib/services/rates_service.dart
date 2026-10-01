import 'dart:convert';
import 'package:http/http.dart' as http;

class RatesException implements Exception {
  RatesException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CurrencyInfo {
  const CurrencyInfo(this.code, this.name, this.symbol, this.flag);
  final String code;
  final String name;
  final String symbol;
  final String flag;
}

class RateSnapshot {
  const RateSnapshot({required this.base, required this.date, required this.rates});
  final String base;
  final String date; // YYYY-MM-DD, the rate's publication day
  final Map<String, double> rates;
}

/// Live reference rates (European Central Bank data via Frankfurter: free,
/// no API key). The backend has no rates endpoint yet, so the app reads rates
/// directly and then saves each conversion through the CurrenSee backend.
/// When the backend grows a /rates route, only this file needs to change.
class RatesService {
  RatesService._();

  static const String _base = 'https://api.frankfurter.dev/v1';

  /// Must match the active rows in the backend `currencies` table.
  static const Map<String, CurrencyInfo> _info = {
    'USD': CurrencyInfo('USD', 'US Dollar', r'$', '🇺🇸'),
    'EUR': CurrencyInfo('EUR', 'Euro', '€', '🇪🇺'),
    'GBP': CurrencyInfo('GBP', 'British Pound', '£', '🇬🇧'),
    'JPY': CurrencyInfo('JPY', 'Japanese Yen', '¥', '🇯🇵'),
    'CAD': CurrencyInfo('CAD', 'Canadian Dollar', r'$', '🇨🇦'),
    'AUD': CurrencyInfo('AUD', 'Australian Dollar', r'$', '🇦🇺'),
    'INR': CurrencyInfo('INR', 'Indian Rupee', '₹', '🇮🇳'),
  };

  static List<String> get supported => _info.keys.toList(growable: false);

  static bool isSupported(String code) => _info.containsKey(code);

  static CurrencyInfo info(String code) =>
      _info[code] ?? CurrencyInfo(code, code, code, '🏳️');

  static Future<RateSnapshot> latest(String base) async {
    final targets = supported.where((c) => c != base).join(',');
    final uri = Uri.parse('$_base/latest')
        .replace(queryParameters: {'base': base, 'symbols': targets});
    final json = await _getJson(uri);
    final raw = json['rates'] as Map<String, dynamic>? ?? const {};
    return RateSnapshot(
      base: base,
      date: json['date'] as String? ?? '',
      rates: raw.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  /// Daily closing rates for the last [days] working days, oldest first.
  static Future<List<double>> trend(String base, String target, {int days = 7}) async {
    if (base == target) return const [];
    final start = DateTime.now().toUtc().subtract(Duration(days: days + 6));
    final y = start.year.toString().padLeft(4, '0');
    final m = start.month.toString().padLeft(2, '0');
    final d = start.day.toString().padLeft(2, '0');
    final uri = Uri.parse('$_base/$y-$m-$d..')
        .replace(queryParameters: {'base': base, 'symbols': target});
    final json = await _getJson(uri);
    final byDay = json['rates'] as Map<String, dynamic>? ?? const {};
    final dates = byDay.keys.toList()..sort();
    final values = <double>[
      for (final day in dates)
        if ((byDay[day] as Map<String, dynamic>)[target] is num)
          ((byDay[day] as Map<String, dynamic>)[target] as num).toDouble(),
    ];
    return values.length > days ? values.sublist(values.length - days) : values;
  }

  static Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw RatesException('Rates are unavailable right now (${response.statusCode}).');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on RatesException {
      rethrow;
    } catch (_) {
      throw RatesException('Could not load live rates. Check your connection and try again.');
    }
  }
}
