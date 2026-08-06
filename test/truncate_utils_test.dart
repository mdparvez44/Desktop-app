import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/utils/truncate_utils.dart';

void main() {
  group('Truncation Utils Tests (Rule 12: Truncation NOT Rounding)', () {
    test('Truncates 87.8125 to 87.81', () {
      expect(truncateTo2(87.8125), equals(87.81));
    });

    test('Truncates 87.8165 to 87.81', () {
      expect(truncateTo2(87.8165), equals(87.81));
    });

    test('Truncates 87.8199 to 87.81', () {
      expect(truncateTo2(87.8199), equals(87.81));
    });

    test('Handles exact integers and whole numbers', () {
      expect(truncateTo2(100.0), equals(100.0));
      expect(truncateTo2(0.0), equals(0.0));
    });

    test('Format string truncates cleanly', () {
      expect(formatTruncated2(87.8199), equals('87.81'));
      expect(formatTruncated2(7.1789), equals('7.17'));
    });
  });
}
