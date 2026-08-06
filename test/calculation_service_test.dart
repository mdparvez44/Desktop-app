import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/models/production.dart';
import 'package:et_calculator/services/calculation_service.dart';

void main() {
  group('Calculation Service Tests (Section 6, 11, 12)', () {
    test('Calculates Tested = Good + Reject + QA', () {
      final tested = CalculationService.calculateTested(
        good: 1000.0,
        reject: 50.0,
        qa: 10.0,
      );
      expect(tested, equals(1060.0));
    });

    test('Calculates Production Gross = Quantity / 144 (Truncated)', () {
      // 1000 / 144 = 6.94444... -> 6.94
      final gross = CalculationService.calculateGross(1000.0);
      expect(gross, equals(6.94));
    });

    test('Calculates Rejection % = (Rejection / Tested) * 100 (Truncated)', () {
      // 50 / 1060 * 100 = 4.71698... -> 4.71
      final rejPct = CalculationService.calculateRejectionPercentage(
        reject: 50.0,
        tested: 1060.0,
      );
      expect(rejPct, equals(4.71));
    });

    test('Computes aggregate DailySummary correctly', () {
      final records = [
        Production(
          machine: 'A1',
          plant: 'TTK',
          productCode: 'N53PM',
          good: 1000,
          reject: 50,
          qa: 10,
          sample: 5,
        ),
        Production(
          machine: 'A2',
          plant: 'TTK',
          productCode: 'N53RM',
          good: 500,
          reject: 20,
          qa: 5,
          sample: 2,
        ),
      ];

      final summary = CalculationService.computeSummary(records);

      expect(summary.totalGood, equals(1500.0));
      expect(summary.totalReject, equals(70.0));
      expect(summary.totalQA, equals(15.0));
      expect(summary.totalTested, equals(1585.0));
      // Total tested gross: 1585 / 144 = 11.00694... -> 11.00
      expect(summary.totalTestedGross, equals(11.00));
    });
  });
}
