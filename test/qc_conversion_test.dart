import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/services/calculation_service.dart';

void main() {
  group('Q.C x 95 Conversion Unit Tests', () {
    test('Entered Q.C = 1 converts to Saved Q.C = 95', () {
      const enteredQC = 1.0;
      final savedQC = enteredQC * 95.0;
      expect(savedQC, equals(95.0));

      final tested = CalculationService.calculateTested(
        good: 1000,
        reject: 50,
        qa: savedQC,
      );
      expect(tested, equals(1145.0));
    });

    test('Entered Q.C = 2 converts to Saved Q.C = 190', () {
      const enteredQC = 2.0;
      final savedQC = enteredQC * 95.0;
      expect(savedQC, equals(190.0));

      final tested = CalculationService.calculateTested(
        good: 2000,
        reject: 100,
        qa: savedQC,
      );
      expect(tested, equals(2290.0));
    });

    test('Entered Q.C = 10 converts to Saved Q.C = 950', () {
      const enteredQC = 10.0;
      final savedQC = enteredQC * 95.0;
      expect(savedQC, equals(950.0));
    });
  });
}
