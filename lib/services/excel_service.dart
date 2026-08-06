/// Excel Import and Export Service using package:excel.
library;

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/daily_report.dart';
import '../models/plant_product_report.dart';
import '../models/production.dart';
import '../utils/formatters.dart';

class ExcelImportResult {
  final List<Production> validRecords;
  final List<String> errors;

  ExcelImportResult({
    required this.validRecords,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
}

class ExcelService {
  /// Parse shift name and date from filename format: Shift_name-D-M-YYYY.xlsx
  /// Examples: First_3-8-2026.xlsx, Second_03-08-2026.xlsx, Night_5-8-2026.xlsx
  static Map<String, dynamic>? parseShiftAndDateFromFileName(String fileName) {
    try {
      final baseName = p.basenameWithoutExtension(fileName).trim();
      final parts = baseName.split('_');
      if (parts.length < 2) return null;

      final shiftRaw = parts[0].trim();
      final dateRaw = parts[1].trim();

      String? shift;
      final shiftLower = shiftRaw.toLowerCase();
      if (shiftLower == 'first') {
        shift = 'First';
      } else if (shiftLower == 'second') {
        shift = 'Second';
      } else if (shiftLower == 'night') {
        shift = 'Night';
      }

      if (shift == null) return null;

      final dateParts = dateRaw.split('-');
      if (dateParts.length < 3) return null;

      final day = int.tryParse(dateParts[0].trim());
      final month = int.tryParse(dateParts[1].trim());
      final year = int.tryParse(dateParts[2].trim());

      if (day == null || month == null || year == null) return null;

      final date = DateTime(year, month, day);
      return {
        'shift': shift,
        'date': date,
      };
    } catch (_) {
      return null;
    }
  }

  /// Generates exact export filename: Shift_D-M-YYYY.xlsx (without leading zeroes)
  static String generateExportFileName(String shift, DateTime date) {
    final dateStr = '${date.day}-${date.month}-${date.year}';
    return '${shift}_$dateStr.xlsx';
  }

  /// Resolves the user's system Downloads directory dynamically (Linux / Windows)
  static Future<String> getDownloadsDirectoryPath() async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null && await downloadsDir.exists()) {
        return downloadsDir.path;
      }
    } catch (_) {}

    // Dynamic system fallback for Linux ($HOME/Downloads) & Windows (%USERPROFILE%\Downloads)
    final userHome = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    if (userHome.isNotEmpty) {
      final fallbackDownloads = p.join(userHome, 'Downloads');
      final dir = Directory(fallbackDownloads);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir.path;
  }

  /// Handles duplicate filenames safely by auto-incrementing: Shift_D-M-YYYY (1).xlsx
  static File getUniqueExportFile(String savePath, String shift, DateTime date) {
    final baseName = '${shift}_${date.day}-${date.month}-${date.year}';
    String targetPath = p.join(savePath, '$baseName.xlsx');
    File file = File(targetPath);

    int counter = 1;
    while (file.existsSync()) {
      targetPath = p.join(savePath, '$baseName ($counter).xlsx');
      file = File(targetPath);
      counter++;
    }
    return file;
  }

  /// Automatically exports production data to configured or Downloads folder without save dialog
  static Future<File> exportProductionData({
    required String shift,
    required DateTime date,
    required List<Production> records,
    String? targetDirectory,
  }) async {
    final savePath = (targetDirectory != null && targetDirectory.isNotEmpty && Directory(targetDirectory).existsSync())
        ? targetDirectory
        : await getDownloadsDirectoryPath();

    if (!Directory(savePath).existsSync()) {
      throw Exception('Export Save Location Unavailable: The configured folder "$savePath" does not exist.');
    }

    final file = getUniqueExportFile(savePath, shift, date);

    final shiftRecords = records.where((r) => r.shift.toLowerCase() == shift.toLowerCase()).toList();
    final exportRecords = shiftRecords.isNotEmpty ? shiftRecords : records;

    final bytes = exportProductionDataToBytes(
      records: exportRecords,
      shift: shift,
      date: date,
    );

    if (bytes == null) {
      throw Exception('Failed to generate Excel file bytes.');
    }

    await file.writeAsBytes(bytes);
    return file;
  }

  /// Export Production Data Sheet records with shift & date metadata header rows
  static List<int>? exportProductionDataToBytes({
    required List<Production> records,
    required String shift,
    required DateTime date,
  }) {
    final excel = Excel.createExcel();
    final dateStr = '${date.day}-${date.month}-${date.year}';
    final sheetName = '${shift}_$dateStr';
    final Sheet sheet = excel[sheetName];
    if (sheetName != 'Sheet1') {
      excel.delete('Sheet1');
    }

    // Metadata Header Rows
    sheet.appendRow([TextCellValue('ET Calculator Production Data')]);
    sheet.appendRow([TextCellValue('Shift: $shift')]);
    sheet.appendRow([TextCellValue('Date: $dateStr')]);
    sheet.appendRow([TextCellValue('')]); // Empty spacing row

    // Table Header Row matching Production Data Sheet columns (No Shift, No Good Gross, No Rejection Gross)
    sheet.appendRow([
      TextCellValue('M.No'),
      TextCellValue('Plant'),
      TextCellValue('Product Code'),
      TextCellValue('Good'),
      TextCellValue('Rej'),
      TextCellValue('Q.C'),
      TextCellValue('Samples'),
      TextCellValue('Tested'),
      TextCellValue('Date/Time'),
    ]);

    // Data rows
    for (final p in records) {
      sheet.appendRow([
        TextCellValue(p.machine),
        TextCellValue(p.plant),
        TextCellValue(p.productCode),
        DoubleCellValue(p.good),
        DoubleCellValue(p.reject),
        DoubleCellValue(p.qa),
        DoubleCellValue(p.sample),
        DoubleCellValue(p.tested),
        TextCellValue(AppFormatters.formatDate(p.createdAt)),
      ]);
    }

    return excel.save();
  }

  /// Export Daily Report summary to Excel bytes with exact required column ordering
  static List<int>? exportDailyReportToBytes(DailyReportSummary summary, DateTime date) {
    final excel = Excel.createExcel();
    final dateStr = '${date.day}-${date.month}-${date.year}';
    final sheetName = 'DailyReport_$dateStr';
    final Sheet sheet = excel[sheetName];
    if (sheetName != 'Sheet1') {
      excel.delete('Sheet1');
    }

    // Table Header Row matching exact required column order
    sheet.appendRow([
      TextCellValue('Machine Series'),
      TextCellValue('Product Code'),
      TextCellValue('Tested Gross'),
      TextCellValue('Good Gross'),
      TextCellValue('Rejection Gross'),
      TextCellValue('Hold'),
      TextCellValue('Q.C'),
      TextCellValue('Rejection Percentage'),
    ]);

    for (final row in summary.rows) {
      sheet.appendRow([
        TextCellValue(row.machine),
        TextCellValue(row.productCode),
        DoubleCellValue(row.testedGross),
        DoubleCellValue(row.goodGross),
        DoubleCellValue(row.rejectionGross),
        TextCellValue(''), // Hold is left completely blank
        DoubleCellValue(row.totalQCGross),
        TextCellValue('${row.rejectionPercentage}%'),
      ]);
    }

    // Totals Row
    sheet.appendRow([
      TextCellValue('TOTAL'),
      TextCellValue(''),
      DoubleCellValue(summary.totalTestedGross),
      DoubleCellValue(summary.totalGoodGross),
      DoubleCellValue(summary.totalRejectionGross),
      TextCellValue(''), // Hold is left completely blank
      DoubleCellValue(summary.totalQCGross),
      TextCellValue('${summary.totalRejectionPercentage}%'),
    ]);

    return excel.save();
  }

  /// Export production records to an Excel (.xlsx) file with custom sheet name
  static List<int>? exportToBytes(List<Production> records, {String? sheetName}) {
    final excel = Excel.createExcel();
    final name = (sheetName != null && sheetName.isNotEmpty) ? sheetName : 'Sheet1';
    final Sheet sheet = excel[name];
    if (name != 'Sheet1') {
      excel.delete('Sheet1');
    }

    // Header row
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Machine'),
      TextCellValue('Plant'),
      TextCellValue('Product Code'),
      TextCellValue('Good'),
      TextCellValue('Reject'),
      TextCellValue('QA'),
      TextCellValue('Sample'),
      TextCellValue('Tested'),
      TextCellValue('Shift'),
      TextCellValue('Date'),
    ]);

    for (final p in records) {
      sheet.appendRow([
        IntCellValue(p.id ?? 0),
        TextCellValue(p.machine),
        TextCellValue(p.plant),
        TextCellValue(p.productCode),
        DoubleCellValue(p.good),
        DoubleCellValue(p.reject),
        DoubleCellValue(p.qa),
        DoubleCellValue(p.sample),
        DoubleCellValue(p.tested),
        TextCellValue(p.shift),
        TextCellValue(p.createdAt.toIso8601String()),
      ]);
    }

    return excel.save();
  }

  /// Export Plant & Product Code-wise report to Excel bytes
  static List<int>? exportPlantProductReportToBytes(OverallReportSummary summary) {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Plant_Product_Report'];

    // Header row
    sheet.appendRow([
      TextCellValue('Plant'),
      TextCellValue('Product Code'),
      TextCellValue('Tested Gross'),
      TextCellValue('Good Gross'),
      TextCellValue('Rejection Gross'),
      TextCellValue('Q.C Gross'),
      TextCellValue('Rejection %'),
    ]);

    for (final group in summary.plantGroups) {
      for (final row in group.rows) {
        sheet.appendRow([
          TextCellValue(row.plant),
          TextCellValue(row.productCode),
          DoubleCellValue(row.testedGross),
          DoubleCellValue(row.goodGross),
          DoubleCellValue(row.rejectionGross),
          DoubleCellValue(row.totalQCGross),
          TextCellValue('${row.rejectionPercentage}%'),
        ]);
      }
      // Subtotal row for Plant
      sheet.appendRow([
        TextCellValue('${group.plant} TOTAL'),
        TextCellValue(''),
        DoubleCellValue(group.testedGross),
        DoubleCellValue(group.goodGross),
        DoubleCellValue(group.rejectionGross),
        DoubleCellValue(group.totalQCGross),
        TextCellValue('${group.rejectionPercentage}%'),
      ]);
    }

    // Overall Total
    sheet.appendRow([
      TextCellValue('OVERALL TOTAL'),
      TextCellValue(''),
      DoubleCellValue(summary.testedGross),
      DoubleCellValue(summary.goodGross),
      DoubleCellValue(summary.rejectionGross),
      DoubleCellValue(summary.totalQCGross),
      TextCellValue('${summary.rejectionPercentage}%'),
    ]);

    return excel.save();
  }

  /// Export records directly to a target file path
  static Future<void> exportToFile(
    List<Production> records,
    String filePath, {
    String? sheetName,
  }) async {
    final bytes = exportToBytes(records, sheetName: sheetName);
    if (bytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
    } else {
      throw Exception('Failed to generate Excel file bytes.');
    }
  }

  /// Import production records from Excel bytes with strict validation and optional filename date/shift metadata
  static ExcelImportResult importFromBytes(
    List<int> bytes, {
    String? overrideShift,
    DateTime? overrideDate,
  }) {
    final excel = Excel.decodeBytes(bytes);
    final List<Production> validRecords = [];
    final List<String> errors = [];

    if (excel.tables.isEmpty) {
      return ExcelImportResult(
        validRecords: [],
        errors: ['Excel file contains no tables or sheets.'],
      );
    }

    final table = excel.tables.values.first;
    if (table.maxRows <= 1) {
      return ExcelImportResult(
        validRecords: [],
        errors: ['Excel sheet is empty or contains header only.'],
      );
    }

    // Process each row skipping header (row 0)
    for (int i = 1; i < table.maxRows; i++) {
      final row = table.rows[i];
      if (row.isEmpty) continue;

      String getCellString(int index) {
        if (index >= row.length || row[index] == null) return '';
        final val = row[index]?.value;
        if (val == null) return '';
        return val.toString().trim();
      }

      double getCellDouble(int index) {
        if (index >= row.length || row[index] == null) return 0.0;
        final val = row[index]?.value;
        if (val == null) return 0.0;
        if (val is DoubleCellValue) return val.value;
        if (val is IntCellValue) return val.value.toDouble();
        final str = val.toString().trim();
        return double.tryParse(str) ?? 0.0;
      }

      int offset = 0;
      final col0 = getCellString(0);
      if (int.tryParse(col0) != null) {
        offset = 1;
      }

      final machine = getCellString(0 + offset);
      final plant = getCellString(1 + offset);
      final productCode = getCellString(2 + offset);
      final good = getCellDouble(3 + offset);
      final reject = getCellDouble(4 + offset);
      final qa = getCellDouble(5 + offset);
      final sample = getCellDouble(6 + offset);
      final shift = overrideShift ??
          (getCellString(8 + offset).isEmpty ? 'Night' : getCellString(8 + offset));
      final dateStr = getCellString(9 + offset);

      if (machine.isEmpty) {
        errors.add('Row ${i + 1}: Missing machine name.');
        continue;
      }
      if (plant.isEmpty) {
        errors.add('Row ${i + 1}: Missing plant name.');
        continue;
      }
      if (productCode.isEmpty) {
        errors.add('Row ${i + 1}: Missing product code.');
        continue;
      }

      DateTime parsedDate = overrideDate ?? DateTime.now();
      if (overrideDate == null && dateStr.isNotEmpty) {
        parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
      }

      final record = Production(
        machine: machine,
        plant: plant,
        productCode: productCode,
        good: good,
        reject: reject,
        qa: qa,
        sample: sample,
        shift: shift,
        createdAt: parsedDate,
        updatedAt: parsedDate,
      );

      validRecords.add(record);
    }

    return ExcelImportResult(
      validRecords: validRecords,
      errors: errors,
    );
  }

  /// Import records from a local file path with automatic filename shift/date extraction
  static Future<ExcelImportResult> importFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return ExcelImportResult(
        validRecords: [],
        errors: ['File does not exist at: $filePath'],
      );
    }
    final bytes = await file.readAsBytes();
    final parsed = parseShiftAndDateFromFileName(p.basename(filePath));
    final overrideShift = parsed != null ? parsed['shift'] as String : null;
    final overrideDate = parsed != null ? parsed['date'] as DateTime : null;

    return importFromBytes(
      bytes,
      overrideShift: overrideShift,
      overrideDate: overrideDate,
    );
  }
}
