import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/models/production.dart';
import 'package:et_calculator/services/calculation_service.dart';

void main() {
  group('Monthly Report Totals Tests (Overall, IML, TTK)', () {
    test('verifies Overall = IML + TTK relationship for Tested, Good, Rejection, and Q.C', () {
      final records = [
        Production(
          machine: 'A1',
          plant: 'A',
          productCode: 'N53RM',
          good: 1000,
          reject: 50,
          qa: 95,
          sample: 5,
        ),
        Production(
          machine: 'B1',
          plant: 'B',
          productCode: 'N40UM',
          good: 800,
          reject: 40,
          qa: 95,
          sample: 0,
        ),
        Production(
          machine: 'C1',
          plant: 'TTK',
          productCode: 'N53PM',
          good: 500,
          reject: 25,
          qa: 95,
          sample: 0,
        ),
      ];

      final summary = CalculationService.computePlantProductReport(records);

      final overall = summary.overallTotal;
      final iml = summary.imlTotal;
      final ttk = summary.ttkTotal;

      // Check mathematical relationship Overall = IML + TTK
      expect(overall.totalGood, equals(iml.totalGood + ttk.totalGood));
      expect(overall.totalReject, equals(iml.totalReject + ttk.totalReject));
      expect(overall.totalQA, equals(iml.totalQA + ttk.totalQA));
      expect(overall.totalTested, equals(iml.totalTested + ttk.totalTested));

      // IML contains plant A and plant B
      expect(iml.totalGood, equals(1800));
      expect(iml.totalReject, equals(90));
      expect(iml.totalQA, equals(190));

      // TTK contains plant TTK
      expect(ttk.totalGood, equals(500));
      expect(ttk.totalReject, equals(25));
      expect(ttk.totalQA, equals(95));

      // Rejection Percentages
      expect(overall.rejectionPercentage, equals(4.25)); // (115 / 2700) * 100 = 4.25%
      expect(iml.rejectionPercentage, equals(4.32)); // (90 / 2080) * 100 = 4.32%
      expect(ttk.rejectionPercentage, equals(4.03)); // (25 / 620) * 100 = 4.03%
    });
  });
}
