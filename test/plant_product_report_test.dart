import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/models/production.dart';
import 'package:et_calculator/services/calculation_service.dart';

void main() {
  group('Plant & Product Code Report Tests', () {
    test('computes exact Good Gross and Q.C Gross values for PlantProductReport', () {
      final records = [
        Production(
          machine: 'A1',
          plant: 'TTK',
          productCode: 'N53RM',
          good: 1000,
          reject: 50,
          qa: 95,
          sample: 5,
        ),
      ];

      final summary = CalculationService.computePlantProductReport(records);

      expect(summary.plantGroups.length, equals(1));
      final group = summary.plantGroups.first;

      expect(group.plant, equals('TTK'));
      expect(group.rows.length, equals(1));

      final row = group.rows.first;
      expect(row.productCode, equals('N53RM'));
      expect(row.testedGross, equals(7.95)); // 1145 / 144 = 7.95
      expect(row.goodGross, equals(6.94)); // 1000 / 144 = 6.94
      expect(row.rejectionGross, equals(0.34)); // 50 / 144 = 0.34
      expect(row.totalQCGross, equals(0.65)); // 95 / 144 = 0.65
      expect(row.rejectionPercentage, equals(4.36)); // (50 / 1145) * 100 = 4.36%

      expect(group.goodGross, equals(6.94));
      expect(group.totalQCGross, equals(0.65));

      expect(summary.goodGross, equals(6.94));
      expect(summary.totalQCGross, equals(0.65));
    });
  });
}
