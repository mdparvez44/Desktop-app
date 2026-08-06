import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/models/production.dart';
import 'package:et_calculator/services/calculation_service.dart';

void main() {
  group('Daily Report Machine-Wise Grouping Tests', () {
    test('computes exact Daily Report row values using Rejection Gross / Tested Gross formula', () {
      final aug3 = DateTime(2026, 8, 3);
      final records = [
        Production(
          machine: 'A1',
          plant: 'TTK',
          productCode: 'N53RM',
          good: 1000,
          reject: 50,
          qa: 95, // Saved Q.C (1 input x 95)
          sample: 5,
          hold: 0,
          createdAt: aug3,
        ),
      ];

      final summary = CalculationService.computeDailyReportSummary(records);

      expect(summary.rows.length, equals(1));
      final row = summary.rows.first;

      expect(row.machine, equals('A1'));
      expect(row.productCode, equals('N53RM'));
      expect(row.testedGross, equals(7.95)); // 1145 / 144 = 7.95
      expect(row.goodGross, equals(6.94)); // 1000 / 144 = 6.94
      expect(row.rejectionGross, equals(0.34)); // 50 / 144 = 0.34
      expect(row.totalQCGross, equals(0.65)); // 95 / 144 = 0.65
      expect(row.rejectionPercentage, equals(4.27)); // (0.34 / 7.95) * 100 = 4.27%
    });

    test('combines multiple product codes for the same machine into single row with combined Product Code cell', () {
      final aug3 = DateTime(2026, 8, 3);
      final records = [
        Production(
          machine: 'D1',
          plant: 'A',
          productCode: 'N53PM',
          good: 1000,
          reject: 50,
          qa: 95,
          sample: 5,
          hold: 1,
          createdAt: aug3,
        ),
        Production(
          machine: 'D1',
          plant: 'A',
          productCode: 'R53DRM',
          good: 500,
          reject: 25,
          qa: 95,
          sample: 5,
          hold: 2,
          createdAt: aug3,
        ),
      ];

      final summary = CalculationService.computeDailyReportSummary(records);

      // Verify D1 appears exactly ONCE
      expect(summary.rows.length, equals(1));
      final row = summary.rows.first;

      expect(row.machine, equals('D1'));
      expect(row.productCode, equals('N53PM, R53DRM'));
      expect(row.totalGood, equals(1500));
      expect(row.totalReject, equals(75));
      expect(row.totalQA, equals(190));
      expect(row.totalHold, equals(3.0));
      expect(row.totalTested, equals(1765));
    });

    test('combines three or more product codes for the same machine', () {
      final aug3 = DateTime(2026, 8, 3);
      final records = [
        Production(machine: 'D1', plant: 'A', productCode: 'N53PM', good: 100, reject: 5, qa: 95, sample: 0, createdAt: aug3),
        Production(machine: 'D1', plant: 'A', productCode: 'R53DRM', good: 100, reject: 5, qa: 95, sample: 0, createdAt: aug3),
        Production(machine: 'D1', plant: 'A', productCode: 'N40UM', good: 100, reject: 5, qa: 95, sample: 0, createdAt: aug3),
      ];

      final summary = CalculationService.computeDailyReportSummary(records);

      expect(summary.rows.length, equals(1));
      expect(summary.rows[0].machine, equals('D1'));
      expect(summary.rows[0].productCode, equals('N40UM, N53PM, R53DRM'));
    });

    test('sorts machine series naturally A1..M2 with each machine appearing once', () {
      final aug3 = DateTime(2026, 8, 3);
      final records = [
        Production(machine: 'B1', plant: 'TTK', productCode: 'N40UM', good: 100, reject: 5, qa: 95, sample: 0, createdAt: aug3),
        Production(machine: 'A1', plant: 'TTK', productCode: 'N53RM', good: 100, reject: 5, qa: 95, sample: 0, createdAt: aug3),
        Production(machine: 'A1', plant: 'TTK', productCode: 'N40UM', good: 100, reject: 5, qa: 95, sample: 0, createdAt: aug3),
      ];

      final summary = CalculationService.computeDailyReportSummary(records);

      expect(summary.rows.length, equals(2));
      expect(summary.rows[0].machine, equals('A1'));
      expect(summary.rows[0].productCode, equals('N40UM, N53RM'));
      expect(summary.rows[1].machine, equals('B1'));
      expect(summary.rows[1].productCode, equals('N40UM'));
    });
  });
}
