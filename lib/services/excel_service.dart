/// Excel Import and Export Service using package:excel with cross-platform file saving.
library;

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;

import '../models/daily_report.dart';
import '../models/plant_product_report.dart';
import '../models/production.dart';
import '../utils/formatters.dart';
import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.js_interop) 'file_saver_web.dart';

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

  /// Handles duplicate filenames safely on target platform
  static dynamic getUniqueExportFile(String savePath, String shift, DateTime date) {
    return getUniqueExportFileImpl(savePath, shift, date);
  }

  /// Resolves system Downloads directory path on Desktop/Mobile, or returns placeholder on Web
  static Future<String> getDownloadsDirectoryPath() async {
    return await getDownloadsDirectoryPathImpl();
  }

  /// Automatically exports production data to configured location or downloads folder
  static Future<String?> exportProductionData({
    required String shift,
    required DateTime date,
    required List<Production> records,
    String? targetDirectory,
  }) async {
    final fileName = generateExportFileName(shift, date);
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

    return await saveAndDownloadFile(
      bytes: bytes,
      fileName: fileName,
      targetDirectory: targetDirectory,
    );
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

  /// Export records directly to a target file path or browser download
  static Future<String?> exportToFile(
    List<Production> records,
    String filePath, {
    String? sheetName,
  }) async {
    final bytes = exportToBytes(records, sheetName: sheetName);
    if (bytes != null) {
      final fileName = p.basename(filePath);
      return await saveAndDownloadFile(
        bytes: bytes,
        fileName: fileName,
        targetDirectory: p.dirname(filePath),
      );
    } else {
      throw Exception('Failed to generate Excel file bytes.');
    }
  }

  static String _extractCellString(Data? cell) {
    if (cell == null || cell.value == null) return '';
    final val = cell.value;
    if (val is TextCellValue) {
      return val.value.text?.trim() ?? '';
    }
    if (val is IntCellValue) {
      return val.value.toString().trim();
    }
    if (val is DoubleCellValue) {
      return val.value.toString().trim();
    }
    final str = val.toString();
    final match = RegExp(r'^(?:TextCellValue|IntCellValue|DoubleCellValue|SharedStringCellValue)\((.*)\)$').firstMatch(str);
    if (match != null) {
      return match.group(1)?.trim() ?? '';
    }
    return str.trim();
  }

  static double _extractCellDouble(Data? cell) {
    if (cell == null || cell.value == null) return 0.0;
    final val = cell.value;
    if (val is DoubleCellValue) {
      return val.value;
    }
    if (val is IntCellValue) {
      return val.value.toDouble();
    }
    if (val is TextCellValue) {
      final t = val.value.text?.trim() ?? '';
      return double.tryParse(t) ?? 0.0;
    }
    final str = _extractCellString(cell);
    return double.tryParse(str) ?? 0.0;
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

    // Auto-detect header row index and metadata rows (Shift: X, Date: Y)
    int headerRowIndex = -1;
    String? sheetShift;
    DateTime? sheetDate;

    for (int i = 0; i < table.maxRows && i < 10; i++) {
      final row = table.rows[i];
      if (row.isEmpty) continue;

      for (final cell in row) {
        final val = _extractCellString(cell);
        final valLower = val.toLowerCase();

        if (valLower.startsWith('shift:')) {
          final s = val.substring(6).trim().toLowerCase();
          if (s == 'first') sheetShift = 'First';
          if (s == 'second') sheetShift = 'Second';
          if (s == 'night') sheetShift = 'Night';
        } else if (valLower.startsWith('date:')) {
          final dStr = val.substring(5).trim();
          final parts = dStr.split('-');
          if (parts.length >= 3) {
            final day = int.tryParse(parts[0].trim());
            final month = int.tryParse(parts[1].trim());
            final year = int.tryParse(parts[2].trim());
            if (day != null && month != null && year != null) {
              sheetDate = DateTime(year, month, day);
            }
          }
        }

        if (valLower.contains('m.no') || valLower.contains('machine') || valLower.contains('product code')) {
          headerRowIndex = i;
          break;
        }
      }
      if (headerRowIndex >= 0) break;
    }

    if (headerRowIndex < 0) {
      headerRowIndex = 0;
    }

    final effectiveShift = overrideShift ?? sheetShift;
    final effectiveDate = overrideDate ?? sheetDate;

    // Dynamic column mapping based on header names
    int machineCol = -1;
    int plantCol = -1;
    int productCol = -1;
    int goodCol = -1;
    int rejectCol = -1;
    int qaCol = -1;
    int sampleCol = -1;
    int shiftCol = -1;
    int dateCol = -1;

    if (headerRowIndex < table.maxRows) {
      final headerRow = table.rows[headerRowIndex];
      for (int c = 0; c < headerRow.length; c++) {
        final colName = _extractCellString(headerRow[c]).toLowerCase();
        if (colName.contains('m.no') || colName.contains('machine')) {
          machineCol = c;
        } else if (colName.contains('plant')) {
          plantCol = c;
        } else if (colName.contains('product')) {
          productCol = c;
        } else if (colName.contains('good')) {
          goodCol = c;
        } else if (colName.contains('rej')) {
          rejectCol = c;
        } else if (colName.contains('q.c') || colName.contains('qa') || colName.contains('q.a')) {
          qaCol = c;
        } else if (colName.contains('sample')) {
          sampleCol = c;
        } else if (colName.contains('shift')) {
          shiftCol = c;
        } else if (colName.contains('date') || colName.contains('time')) {
          dateCol = c;
        }
      }
    }

    // Fallbacks if columns were not mapped by header names
    int offset = 0;
    if (machineCol == -1) {
      if (headerRowIndex < table.maxRows && table.rows[headerRowIndex].isNotEmpty) {
        final col0Name = _extractCellString(table.rows[headerRowIndex][0]).toLowerCase();
        if (col0Name == 'id' || int.tryParse(col0Name) != null) offset = 1;
      }
      machineCol = 0 + offset;
      plantCol = 1 + offset;
      productCol = 2 + offset;
      goodCol = 3 + offset;
      rejectCol = 4 + offset;
      qaCol = 5 + offset;
      sampleCol = 6 + offset;
      shiftCol = 8 + offset;
      dateCol = 9 + offset;
    }

    // Process each row skipping headers up to headerRowIndex
    for (int i = headerRowIndex + 1; i < table.maxRows; i++) {
      final row = table.rows[i];
      if (row.isEmpty) continue;

      String getCellString(int colIdx) {
        if (colIdx < 0 || colIdx >= row.length) return '';
        return _extractCellString(row[colIdx]);
      }

      double getCellDouble(int colIdx) {
        if (colIdx < 0 || colIdx >= row.length) return 0.0;
        return _extractCellDouble(row[colIdx]);
      }

      final machine = getCellString(machineCol);
      final plant = getCellString(plantCol);
      final productCode = getCellString(productCol);
      final good = getCellDouble(goodCol);
      final reject = getCellDouble(rejectCol);
      final qa = getCellDouble(qaCol);
      final sample = getCellDouble(sampleCol);
      final shiftStr = getCellString(shiftCol);
      final shift = effectiveShift ?? (shiftStr.isEmpty ? 'Night' : shiftStr);
      final dateStr = getCellString(dateCol);

      if (machine.isEmpty) {
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

      DateTime parsedDate = effectiveDate ?? DateTime.now();
      if (effectiveDate == null && dateStr.isNotEmpty) {
        final parts = dateStr.split('-');
        if (parts.length >= 3) {
          final d = int.tryParse(parts[0].trim());
          final m = int.tryParse(parts[1].trim());
          final y = int.tryParse(parts[2].trim());
          if (d != null && m != null && y != null) {
            parsedDate = DateTime(y, m, d);
          }
        } else {
          parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
        }
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
}

/// Helper function to access getDownloadsDirectoryPath implementation
Future<String> getDownloadsDirectoryPathImpl() async {
  return await getDownloadsDirectoryPath();
}
