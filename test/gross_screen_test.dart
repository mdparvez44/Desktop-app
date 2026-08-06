import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/models/production.dart';
import 'package:et_calculator/services/calculation_service.dart';
import 'package:et_calculator/utils/constants.dart';

void main() {
  group('Machine-Wise Gross Unit Tests (Section 18)', () {
    test('Calculates Machine-wise Tested & Gross for all 26 machine series A1..M2 in exact order', () {
      final records = [
        Production(
          machine: 'A1',
          plant: 'TTK',
          productCode: 'N53RM',
          good: 1000,
          reject: 50,
          qa: 95,
          sample: 5,
          tested: 1145,
          shift: 'Night',
          createdAt: DateTime.now(),
        ),
        Production(
          machine: 'A1',
          plant: 'TTK',
          productCode: 'N53RM',
          good: 2000,
          reject: 100,
          qa: 190,
          sample: 5,
          tested: 2290,
          shift: 'Night',
          createdAt: DateTime.now(),
        ),
        Production(
          machine: 'B1',
          plant: 'TTK',
          productCode: 'N53RM',
          good: 500,
          reject: 25,
          qa: 95,
          sample: 5,
          tested: 620,
          shift: 'Night',
          createdAt: DateTime.now(),
        ),
      ];

      final summary = CalculationService.computeMachineGrossReport(records);

      // Verify all 26 default machines are present
      expect(summary.rows.length, equals(AppConstants.defaultMachines.length));

      // Verify exact machine ordering A1, A2, B1, B2, ..., M1, M2
      for (int i = 0; i < AppConstants.defaultMachines.length; i++) {
        expect(summary.rows[i].machine, equals(AppConstants.defaultMachines[i]));
      }

      // Verify A1 values
      final a1Row = summary.rows.firstWhere((r) => r.machine == 'A1');
      expect(a1Row.totalTested, equals(3435.0));
      // 3435 / 144 = 23.854166... -> 23.85
      expect(a1Row.totalTestedGross, equals(23.85));

      // Verify B1 values
      final b1Row = summary.rows.firstWhere((r) => r.machine == 'B1');
      expect(b1Row.totalTested, equals(620.0));
      // 620 / 144 = 4.3055... -> 4.30
      expect(b1Row.totalTestedGross, equals(4.30));

      // Verify zero-data machine (e.g. A2)
      final a2Row = summary.rows.firstWhere((r) => r.machine == 'A2');
      expect(a2Row.totalTested, equals(0.0));
      expect(a2Row.totalTestedGross, equals(0.0));

      // Overall Total
      expect(summary.overallTotalTested, equals(4055.0));
      // 4055 / 144 = 28.1597... -> 28.15
      expect(summary.overallTestedGross, equals(28.15));
    });
  });
}
