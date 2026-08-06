import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/models/production.dart';
import 'package:et_calculator/services/excel_service.dart';

void main() {
  group('Import UI Lifecycle & Success Validation Tests', () {
    test('verifies import returns valid records and success state for Excel file', () {
      final records = [
        Production(
          machine: 'A1',
          plant: 'TTK',
          productCode: 'N53RM',
          good: 100,
          reject: 5,
          qa: 10,
          sample: 0,
        ),
      ];
      final bytes = ExcelService.exportToBytes(records);
      expect(bytes, isNotNull);

      final importResult = ExcelService.importFromBytes(bytes!);
      expect(importResult.hasErrors, isFalse);
      expect(importResult.validRecords.length, equals(1));
    });
  });
}
