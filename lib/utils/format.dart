/// 1234567.891 -> "1,234,567.89"
String formatNumber(double value, {int decimals = 2}) {
  final fixed = value.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  final sign = value < 0 ? '-' : '';
  final fraction = decimals > 0 ? '.${parts[1]}' : '';
  return '$sign$buffer$fraction';
}

/// JPY has no minor unit; everything else in the supported list uses 2.
int decimalsFor(String currencyCode) => currencyCode == 'JPY' ? 0 : 2;

/// "100.0000" -> "100", "0.87658000" -> "0.87658"
String trimZeros(String value) {
  if (!value.contains('.')) return value;
  var out = value.replaceFirst(RegExp(r'0+$'), '');
  if (out.endsWith('.')) out = out.substring(0, out.length - 1);
  return out;
}

String formatRate(double rate) => formatNumber(rate, decimals: rate >= 100 ? 2 : 4);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "28 Sep, 14:05"
String shortDateTime(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${_months[d.month - 1]}, $hh:$mm';
}
