import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/models/production.dart';
import 'package:et_calculator/services/excel_service.dart';

void main() {
  group('Shift-Based XLSX Export & Date Formatting Tests', () {
    test('generateExportFileName formats shift and D-M-YYYY without leading zeroes', () {
      final aug3 = DateTime(2026, 8, 3);
      final aug1 = DateTime(2026, 8, 1);
      final aug15 = DateTime(2026, 8, 15);
      final dec31 = DateTime(2026, 12, 31);

      expect(
        ExcelService.generateExportFileName('First', aug3),
        equals('First_3-8-2026.xlsx'),
      );
      expect(
        ExcelService.generateExportFileName('Second', aug3),
        equals('Second_3-8-2026.xlsx'),
      );
      expect(
        ExcelService.generateExportFileName('Night', aug3),
        equals('Night_3-8-2026.xlsx'),
      );

      expect(
        ExcelService.generateExportFileName('First', aug1),
        equals('First_1-8-2026.xlsx'),
      );
      expect(
        ExcelService.generateExportFileName('First', aug15),
        equals('First_15-8-2026.xlsx'),
      );
      expect(
        ExcelService.generateExportFileName('First', dec31),
        equals('First_31-12-2026.xlsx'),
      );
    });

    test('getUniqueExportFile handles duplicate filenames safely', () {
      final tempDir = Directory.systemTemp.createTempSync('export_test_');
      final aug3 = DateTime(2026, 8, 3);

      final file1 = ExcelService.getUniqueExportFile(tempDir.path, 'First', aug3);
      expect(file1.path, endsWith('First_3-8-2026.xlsx'));
      file1.writeAsStringSync('dummy');

      final file2 = ExcelService.getUniqueExportFile(tempDir.path, 'First', aug3);
      expect(file2.path, endsWith('First_3-8-2026 (1).xlsx'));
      file2.writeAsStringSync('dummy');

      final file3 = ExcelService.getUniqueExportFile(tempDir.path, 'First', aug3);
      expect(file3.path, endsWith('First_3-8-2026 (2).xlsx'));

      tempDir.deleteSync(recursive: true);
    });

    test('exportProductionDataToBytes produces valid Excel workbook bytes with metadata', () {
      final aug3 = DateTime(2026, 8, 3);
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
          shift: 'First',
          createdAt: aug3,
        ),
      ];

      final bytes = ExcelService.exportProductionDataToBytes(
        records: records,
        shift: 'First',
        date: aug3,
      );

      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(0));
    });
  });
}
