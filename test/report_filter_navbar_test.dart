import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/services/excel_service.dart';

void main() {
  group('Excel Service Filename Metadata Parsing Tests', () {
    test('parses shift and date correctly from Shift_name-Date.xlsx format', () {
      final res1 = ExcelService.parseShiftAndDateFromFileName('First_3-8-2026.xlsx');
      expect(res1, isNotNull);
      expect(res1!['shift'], equals('First'));
      expect(res1['date'], equals(DateTime(2026, 8, 3)));

      final res2 = ExcelService.parseShiftAndDateFromFileName('Second_03-08-2026.xlsx');
      expect(res2, isNotNull);
      expect(res2!['shift'], equals('Second'));
      expect(res2['date'], equals(DateTime(2026, 8, 3)));

      final res3 = ExcelService.parseShiftAndDateFromFileName('Night_5-8-2026.xlsx');
      expect(res3, isNotNull);
      expect(res3!['shift'], equals('Night'));
      expect(res3['date'], equals(DateTime(2026, 8, 5)));
    });

    test('returns null for invalid or non-matching filenames', () {
      expect(ExcelService.parseShiftAndDateFromFileName('random_file.xlsx'), isNull);
      expect(ExcelService.parseShiftAndDateFromFileName('InvalidShift_3-8-2026.xlsx'), isNull);
    });
  });
}
