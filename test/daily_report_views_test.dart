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

    test('computeProductWiseDailyReport aggregates across all plants per Product Code', () {
      final date = DateTime(2026, 8, 3);
      final records = [
        Production(machine: 'A1', plant: 'A', productCode: 'N53RM', good: 1000, reject: 50, qa: 95, sample: 0, createdAt: date),
        Production(machine: 'B1', plant: 'B', productCode: 'N53RM', good: 1000, reject: 50, qa: 95, sample: 0, createdAt: date),
        Production(machine: 'C1', plant: 'C', productCode: 'N40UM', good: 500, reject: 25, qa: 95, sample: 0, createdAt: date),
      ];

      final rows = CalculationService.computeProductWiseDailyReport(records);

      expect(rows.length, equals(2));

      final rowN53RM = rows.firstWhere((r) => r.productCode == 'N53RM');
      expect(rowN53RM.goodGross, equals(13.88)); // 2000 / 144 = 13.88
      expect(rowN53RM.rejectionGross, equals(0.69)); // 100 / 144 = 0.69
      expect(rowN53RM.totalQCGross, equals(1.31)); // 190 / 144 = 1.31
      expect(rowN53RM.testedGross, equals(15.90)); // 2290 / 144 = 15.90
      expect(rowN53RM.rejectionPercentage, equals(4.33)); // (0.69 / 15.90) * 100 = 4.33%

      final rowN40UM = rows.firstWhere((r) => r.productCode == 'N40UM');
      expect(rowN40UM.goodGross, equals(3.47));
    });
  });
}
