/// Phase 4 Excel Import/Export unit test suite verifying byte generation, metadata parsing, and cross-platform workflows.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:et_calculator/models/production.dart';
import 'package:et_calculator/services/calculation_service.dart';
import 'package:et_calculator/services/excel_service.dart';

void main() {
  group('Phase 4 — Excel Import/Export Byte Tests', () {
    test('1. parseShiftAndDateFromFileName parses shift & date correctly', () {
      final res1 = ExcelService.parseShiftAndDateFromFileName('First_3-8-2026.xlsx');
      expect(res1, isNotNull);
      expect(res1!['shift'], equals('First'));
      expect(res1['date'], equals(DateTime(2026, 8, 3)));

      final res2 = ExcelService.parseShiftAndDateFromFileName('Second_15-12-2025.xlsx');
      expect(res2, isNotNull);
      expect(res2!['shift'], equals('Second'));
      expect(res2['date'], equals(DateTime(2025, 12, 15)));

      final res3 = ExcelService.parseShiftAndDateFromFileName('Night_05-09-2024.xlsx');
      expect(res3, isNotNull);
      expect(res3!['shift'], equals('Night'));
      expect(res3['date'], equals(DateTime(2024, 9, 5)));
    });

    test('2. generateExportFileName creates exact Shift_D-M-YYYY.xlsx format', () {
      final fileName = ExcelService.generateExportFileName('First', DateTime(2026, 8, 3));
      expect(fileName, equals('First_3-8-2026.xlsx'));
    });

    test('3. exportProductionDataToBytes & importFromBytes roundtrip', () {
      final now = DateTime(2026, 8, 3);
      final records = [
        Production(machine: 'A1', plant: 'TTK', productCode: 'N53PM', good: 100, reject: 5, qa: 95, sample: 2, tested: 200, shift: 'First', createdAt: now),
        Production(machine: 'A2', plant: 'TTK', productCode: 'N53RM', good: 200, reject: 10, qa: 190, sample: 4, tested: 400, shift: 'First', createdAt: now),
      ];

      final bytes = ExcelService.exportProductionDataToBytes(
        records: records,
        shift: 'First',
        date: now,
      );

      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);

      final importResult = ExcelService.importFromBytes(
        bytes,
        overrideShift: 'First',
        overrideDate: now,
      );

      expect(importResult.hasErrors, isFalse);
      expect(importResult.validRecords.length, equals(2));
      expect(importResult.validRecords[0].machine, equals('A1'));
      expect(importResult.validRecords[0].plant, equals('TTK'));
      expect(importResult.validRecords[0].productCode, equals('N53PM'));
      expect(importResult.validRecords[0].good, equals(100.0));
      expect(importResult.validRecords[0].reject, equals(5.0));
      expect(importResult.validRecords[0].qa, equals(95.0));
      expect(importResult.validRecords[0].sample, equals(2.0));

      expect(importResult.validRecords[1].machine, equals('A2'));
      expect(importResult.validRecords[1].productCode, equals('N53RM'));
    });

    test('4. exportDailyReportToBytes produces non-empty Excel bytes', () {
      final date = DateTime(2026, 8, 3);
      final records = [
        Production(machine: 'A1', plant: 'TTK', productCode: 'N53PM', good: 1440, reject: 144, qa: 144, sample: 10, shift: 'First', createdAt: date),
      ];
      final summary = CalculationService.computeDailyReportSummary(records);

      final bytes = ExcelService.exportDailyReportToBytes(summary, date);
      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);
    });

    test('5. exportPlantProductReportToBytes produces non-empty Excel bytes', () {
      final date = DateTime(2026, 8, 3);
      final records = [
        Production(machine: 'A1', plant: 'TTK', productCode: 'N53PM', good: 1440, reject: 144, qa: 144, sample: 10, shift: 'First', createdAt: date),
      ];
      final summary = CalculationService.computePlantProductReport(records);

      final bytes = ExcelService.exportPlantProductReportToBytes(summary);
      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);
    });
  });
}
