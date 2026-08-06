import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/models/app_settings.dart';
import 'package:et_calculator/services/excel_service.dart';

void main() {
  group('Settings Model & Custom Save Location Tests', () {
    test('AppSettings serializes and deserializes correctly including isDarkMode', () {
      final settings = AppSettings(
        exportSaveLocation: '/home/user/Documents/ET Reports',
        automaticExport: true,
        isDarkMode: true,
      );

      final jsonMap = settings.toJson();
      expect(jsonMap['exportSaveLocation'], equals('/home/user/Documents/ET Reports'));
      expect(jsonMap['automaticExport'], isTrue);
      expect(jsonMap['isDarkMode'], isTrue);

      final restored = AppSettings.fromJson(jsonMap);
      expect(restored.exportSaveLocation, equals('/home/user/Documents/ET Reports'));
      expect(restored.automaticExport, isTrue);
      expect(restored.isDarkMode, isTrue);
    });

    test('getUniqueExportFile uses custom directory path correctly', () {
      final tempDir = Directory.systemTemp.createTempSync('custom_export_');
      final date = DateTime(2026, 8, 3);

      final file1 = ExcelService.getUniqueExportFile(tempDir.path, 'First', date);
      expect(file1.path, equals('${tempDir.path}${Platform.pathSeparator}First_3-8-2026.xlsx'));

      file1.writeAsStringSync('dummy content');

      final file2 = ExcelService.getUniqueExportFile(tempDir.path, 'First', date);
      expect(file2.path, equals('${tempDir.path}${Platform.pathSeparator}First_3-8-2026 (1).xlsx'));

      tempDir.deleteSync(recursive: true);
    });
  });
}
