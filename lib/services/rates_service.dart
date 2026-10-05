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

/// Daily reference rates from Frankfurter's blended official-source feed.
class RatesService {
  RatesService._();

  static const String _base = 'https://api.frankfurter.dev/v2';

  /// Must match the active rows in the backend `currencies` table
  /// (run sql/migration_home_redesign.sql to add the new ones).
  static const Map<String, CurrencyInfo> _info = {
    'USD': CurrencyInfo('USD', 'United States Dollar', r'$', '🇺🇸'),
    'EUR': CurrencyInfo('EUR', 'Euro', '€', '🇪🇺'),
    'GBP': CurrencyInfo('GBP', 'British Pound', '£', '🇬🇧'),
    'JPY': CurrencyInfo('JPY', 'Japanese Yen', '¥', '🇯🇵'),
    'CAD': CurrencyInfo('CAD', 'Canadian Dollar', r'$', '🇨🇦'),
    'AUD': CurrencyInfo('AUD', 'Australian Dollar', r'$', '🇦🇺'),
    'INR': CurrencyInfo('INR', 'Indian Rupee', '₹', '🇮🇳'),
    'NGN': CurrencyInfo('NGN', 'Nigerian Naira', '₦', '🇳🇬'),
    'CHF': CurrencyInfo('CHF', 'Swiss Franc', 'CHF ', '🇨🇭'),
    'CNY': CurrencyInfo('CNY', 'Chinese Yuan', '¥', '🇨🇳'),
    'SGD': CurrencyInfo('SGD', 'Singapore Dollar', r'$', '🇸🇬'),
    'ZAR': CurrencyInfo('ZAR', 'South African Rand', 'R', '🇿🇦'),
    'MXN': CurrencyInfo('MXN', 'Mexican Peso', r'$', '🇲🇽'),
    'BRL': CurrencyInfo('BRL', 'Brazilian Real', r'R$', '🇧🇷'),
    'NZD': CurrencyInfo('NZD', 'New Zealand Dollar', r'$', '🇳🇿'),
    'SEK': CurrencyInfo('SEK', 'Swedish Krona', 'kr ', '🇸🇪'),
    'NOK': CurrencyInfo('NOK', 'Norwegian Krone', 'kr ', '🇳🇴'),
    'HKD': CurrencyInfo('HKD', 'Hong Kong Dollar', r'$', '🇭🇰'),
    'KRW': CurrencyInfo('KRW', 'South Korean Won', '₩', '🇰🇷'),
  };

  static List<String> get supported => _info.keys.toList(growable: false);

  static bool isSupported(String code) => _info.containsKey(code);

  static CurrencyInfo info(String code) =>
      _info[code] ?? CurrencyInfo(code, code, code, '🏳️');

  /// The user's registration currency if we have rates for it, otherwise USD.
  static String startingBase(String? userCurrency) =>
      (userCurrency != null && isSupported(userCurrency)) ? userCurrency : 'USD';

  /// Quick-convert target: the saved one, else USD (EUR when the base is already USD).
  static String defaultTarget(String from, String? preferred) {
    if (preferred != null && preferred != from && isSupported(preferred)) return preferred;
    return from == 'USD' ? 'EUR' : 'USD';
  }

  static Future<RateSnapshot> latest(String base) async {
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

  /// Daily closing rates for the last [days] working days, oldest first.
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
