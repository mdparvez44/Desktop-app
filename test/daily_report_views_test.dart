import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/models/production.dart';
import 'package:et_calculator/services/calculation_service.dart';

void main() {
  group('Daily Report Plant Wise & Product Code Wise Views Tests', () {
    test('computePlantWiseDailyReport aggregates by Plant + Product Code', () {
      final date = DateTime(2026, 8, 3);
      final records = [
        Production(machine: 'A1', plant: 'A', productCode: 'N53RM', good: 1000, reject: 50, qa: 95, sample: 0, createdAt: date),
        Production(machine: 'A2', plant: 'A', productCode: 'N53RM', good: 500, reject: 25, qa: 95, sample: 0, createdAt: date),
        Production(machine: 'B1', plant: 'B', productCode: 'N53RM', good: 1000, reject: 50, qa: 95, sample: 0, createdAt: date),
      ];

      final rows = CalculationService.computePlantWiseDailyReport(records);

      expect(rows.length, equals(2));

      final rowA = rows.firstWhere((r) => r.plant == 'A' && r.productCode == 'N53RM');
      expect(rowA.goodGross, equals(10.41)); // 1500 / 144 = 10.41
      expect(rowA.rejectionGross, equals(0.52)); // 75 / 144 = 0.52
      expect(rowA.totalQCGross, equals(1.31)); // 190 / 144 = 1.31
      expect(rowA.testedGross, equals(12.25)); // 1765 / 144 = 12.25
      expect(rowA.rejectionPercentage, equals(4.24)); // (0.52 / 12.25) * 100 = 4.24%

      final rowB = rows.firstWhere((r) => r.plant == 'B' && r.productCode == 'N53RM');
      expect(rowB.goodGross, equals(6.94));
    });

    test('TEST 1: Company plants A and B with same product N53PM merge into single row', () {
      final date = DateTime(2026, 8, 3);
      final records = [
        Production(machine: 'A1', plant: 'A', productCode: 'N53PM', good: 100, reject: 0, qa: 0, sample: 0, createdAt: date),
        Production(machine: 'B1', plant: 'B', productCode: 'N53PM', good: 200, reject: 0, qa: 0, sample: 0, createdAt: date),
      ];

      final rows = CalculationService.computeProductWiseDailyReport(records);

      expect(rows.length, equals(1));
      expect(rows.first.displayProductCode, equals('N53PM'));
      expect(rows.first.goodGross, equals(2.08)); // 300 / 144 = 2.08
    });

    test('TEST 2: Company plants A and B merge, TTK remains separate row with "TTK N53PM" label', () {
      final date = DateTime(2026, 8, 3);
      final records = [
        Production(machine: 'A1', plant: 'A', productCode: 'N53PM', good: 100, reject: 0, qa: 0, sample: 0, createdAt: date),
        Production(machine: 'B1', plant: 'B', productCode: 'N53PM', good: 200, reject: 0, qa: 0, sample: 0, createdAt: date),
        Production(machine: 'T1', plant: 'TTK', productCode: 'N53PM', good: 300, reject: 0, qa: 0, sample: 0, createdAt: date),
      ];

      final rows = CalculationService.computeProductWiseDailyReport(records);

      expect(rows.length, equals(2));

      final companyRow = rows.firstWhere((r) => r.displayProductCode == 'N53PM');
      expect(companyRow.goodGross, equals(2.08)); // 300 / 144 = 2.08

      final ttkRow = rows.firstWhere((r) => r.displayProductCode == 'TTK N53PM');
      expect(ttkRow.goodGross, equals(2.08)); // 300 / 144 = 2.08
    });

    test('TEST 3: Company plants A, B, C merge into 350, TTK remains separate at 400', () {
      final date = DateTime(2026, 8, 3);
      final records = [
        Production(machine: 'A1', plant: 'A', productCode: 'N53PM', good: 100, reject: 0, qa: 0, sample: 0, createdAt: date),
        Production(machine: 'B1', plant: 'B', productCode: 'N53PM', good: 200, reject: 0, qa: 0, sample: 0, createdAt: date),
        Production(machine: 'C1', plant: 'C', productCode: 'N53PM', good: 50, reject: 0, qa: 0, sample: 0, createdAt: date),
        Production(machine: 'T1', plant: 'TTK', productCode: 'N53PM', good: 400, reject: 0, qa: 0, sample: 0, createdAt: date),
      ];

      final rows = CalculationService.computeProductWiseDailyReport(records);

      expect(rows.length, equals(2));

      final companyRow = rows.firstWhere((r) => r.displayProductCode == 'N53PM');
      expect(companyRow.goodGross, equals(2.43)); // 350 / 144 = 2.43

      final ttkRow = rows.firstWhere((r) => r.displayProductCode == 'TTK N53PM');
      expect(ttkRow.goodGross, equals(2.77)); // 400 / 144 = 2.77
    });

    test('TEST 4: Company plants A and G merge N40UM to 300, TTK N40UM stays separate at 50', () {
      final date = DateTime(2026, 8, 3);
      final records = [
        Production(machine: 'A1', plant: 'A', productCode: 'N40UM', good: 100, reject: 0, qa: 0, sample: 0, createdAt: date),
        Production(machine: 'G1', plant: 'G', productCode: 'N40UM', good: 200, reject: 0, qa: 0, sample: 0, createdAt: date),
        Production(machine: 'T1', plant: 'TTK', productCode: 'N40UM', good: 50, reject: 0, qa: 0, sample: 0, createdAt: date),
      ];

      final rows = CalculationService.computeProductWiseDailyReport(records);

      expect(rows.length, equals(2));

      final companyRow = rows.firstWhere((r) => r.displayProductCode == 'N40UM');
      expect(companyRow.goodGross, equals(2.08)); // 300 / 144 = 2.08

      final ttkRow = rows.firstWhere((r) => r.displayProductCode == 'TTK N40UM');
      expect(ttkRow.goodGross, equals(0.34)); // 50 / 144 = 0.34
    });
  });
}
