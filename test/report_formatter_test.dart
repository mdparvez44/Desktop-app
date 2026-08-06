import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/models/production.dart';
import 'package:et_calculator/services/report_formatter_service.dart';

void main() {
  group('WhatsApp Report Formatting Tests', () {
    test('generateWhatsAppReport creates exact requested format', () {
      final testDate = DateTime(2026, 8, 3);
      final records = [
        Production(
          machine: 'A1',
          plant: 'A',
          productCode: 'N53RM',
          good: 2000,
          reject: 150,
          qa: 95,
          sample: 0,
          createdAt: testDate,
        ),
        Production(
          machine: 'A2',
          plant: 'TTK',
          productCode: 'N53PM',
          good: 1000,
          reject: 40,
          qa: 95,
          sample: 0,
          createdAt: testDate,
        ),
      ];

      final report = ReportFormatterService.generateWhatsAppReport(
        records: records,
        date: testDate,
        shift: 'Second',
        binHoldCount: 2,
        reworkDetails: [
          'D1 - Bubble with leak on T.A',
          'E1 - Leak on B.B',
        ],
      );

      expect(report, contains('*03/08/26*'));
      expect(report, contains('ET total tested Qty in Second shift is'));
      expect(report, contains('Rejection%='));
      expect(report, contains('(TTK) N53PM='));
      expect(report, contains(' *ET rejection% details (plant wise )*'));
      expect(report, contains('A='));
      expect(report, contains('(N53RM)'));
      expect(report, contains('TTK='));
      expect(report, contains('(N53PM)'));
      expect(report, contains('*Rework*'));
      expect(report, contains('2- bin hold due to '));
      expect(report, contains('D1 - Bubble with leak on T.A'));
      expect(report, contains('E1 - Leak on B.B'));
    });
  });
}
