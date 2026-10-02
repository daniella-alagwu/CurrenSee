import 'package:flutter_test/flutter_test.dart';
import 'package:currensee/utils/format.dart';

void main() {
  test('formatNumber groups thousands', () {
    expect(formatNumber(1234567.891), '1,234,567.89');
    expect(formatNumber(-42.5), '-42.50');
  });

  test('trimZeros removes trailing zeros', () {
    expect(trimZeros('100.0000'), '100');
    expect(trimZeros('0.87658000'), '0.87658');
  });
}
