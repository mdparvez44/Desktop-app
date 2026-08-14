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

    test('Plant Performance Table groups each Plant + Product Code into separate rows', () {
      final records = [
        Production(machine: 'D1', plant: 'D', productCode: 'N53CM', good: 100, reject: 0, qa: 0, sample: 0),
        Production(machine: 'D2', plant: 'D', productCode: 'N53PM', good: 200, reject: 0, qa: 0, sample: 0),
        Production(machine: 'D3', plant: 'D', productCode: 'N53CM', good: 50, reject: 0, qa: 0, sample: 0),
        Production(machine: 'A1', plant: 'A', productCode: 'N53PM', good: 300, reject: 0, qa: 0, sample: 0),
      ];

      final summary = CalculationService.computePlantProductReport(records);

      expect(summary.plantGroups.length, equals(2)); // A and D

      final groupA = summary.plantGroups.firstWhere((g) => g.plant == 'A');
      expect(groupA.rows.length, equals(1));
      expect(groupA.rows[0].productCode, equals('N53PM'));
      expect(groupA.rows[0].goodGross, equals(2.08)); // 300 / 144 = 2.08

      final groupD = summary.plantGroups.firstWhere((g) => g.plant == 'D');
      expect(groupD.rows.length, equals(2)); // N53CM and N53PM are separate rows
      expect(groupD.rows[0].productCode, equals('N53CM'));
      expect(groupD.rows[0].goodGross, equals(1.04)); // (100 + 50) / 144 = 1.04
      expect(groupD.rows[1].productCode, equals('N53PM'));
      expect(groupD.rows[1].goodGross, equals(1.38)); // 200 / 144 = 1.38
    });
  });
}
