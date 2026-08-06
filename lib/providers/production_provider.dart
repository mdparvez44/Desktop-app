/// ChangeNotifier provider for state management of production data.
library;

import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/production.dart';
import '../services/excel_service.dart';

class ProductionProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Production> _records = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter criteria
  DateTime? _filterDate;
  String? _filterShift;
  String? _filterPlant;
  String? _filterMachine;
  String? _filterProductCode;

  List<Production> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DateTime? get filterDate => _filterDate;
  String? get filterShift => _filterShift;
  String? get filterPlant => _filterPlant;
  String? get filterMachine => _filterMachine;
  String? get filterProductCode => _filterProductCode;

  /// Returns production records filtered by selected search criteria
  List<Production> get filteredRecords {
    return _records.where((p) {
      if (_filterDate != null) {
        final sameDate = p.createdAt.year == _filterDate!.year &&
            p.createdAt.month == _filterDate!.month &&
            p.createdAt.day == _filterDate!.day;
        if (!sameDate) return false;
      }
      if (_filterShift != null && _filterShift != 'All Shifts' && _filterShift!.isNotEmpty) {
        if (p.shift != _filterShift) return false;
      }
      if (_filterPlant != null && _filterPlant!.isNotEmpty) {
        if (p.plant != _filterPlant) return false;
      }
      if (_filterMachine != null && _filterMachine!.isNotEmpty) {
        if (p.machine != _filterMachine) return false;
      }
      if (_filterProductCode != null && _filterProductCode!.isNotEmpty) {
        if (p.productCode != _filterProductCode) return false;
      }
      return true;
    }).toList();
  }

  Future<void> loadProductions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _records = await _db.getAllProductions();
    } catch (e) {
      _errorMessage = 'Failed to load production records: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduction(Production record) async {
    try {
      final id = await _db.insertProduction(record);
      final newRecord = record.copyWith(id: id);
      _records.insert(0, newRecord);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error adding production: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduction(Production record) async {
    try {
      await _db.updateProduction(record);
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = record;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating production: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduction(int id) async {
    try {
      await _db.deleteProduction(id);
      _records.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting production: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAllProductions() async {
    try {
      await _db.clearAllProductions();
      _records.clear();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting all production records: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> importRecords(List<Production> records) async {
    for (final rec in records) {
      await _db.insertProduction(rec);
    }
    await loadProductions();
  }

  Future<ExcelImportResult> importExcel(List<int> bytes, {String? fileName}) async {
    _isLoading = true;
    notifyListeners();

    String? overrideShift;
    DateTime? overrideDate;
    if (fileName != null && fileName.isNotEmpty) {
      final parsed = ExcelService.parseShiftAndDateFromFileName(fileName);
      if (parsed != null) {
        overrideShift = parsed['shift'] as String;
        overrideDate = parsed['date'] as DateTime;
      }
    }

    final result = ExcelService.importFromBytes(
      bytes,
      overrideShift: overrideShift,
      overrideDate: overrideDate,
    );

    if (result.validRecords.isNotEmpty) {
      for (final rec in result.validRecords) {
        await _db.insertProduction(rec);
      }
      await loadProductions();
    } else {
      _isLoading = false;
      notifyListeners();
    }
    return result;
  }

  Future<bool> exportExcel(String filePath) async {
    try {
      await ExcelService.exportToFile(filteredRecords, filePath);
      return true;
    } catch (e) {
      _errorMessage = 'Export failed: $e';
      notifyListeners();
      return false;
    }
  }

  // Filter setters
  void setFilterDate(DateTime? date) {
    _filterDate = date;
    notifyListeners();
  }

  void setFilterShift(String? shift) {
    _filterShift = shift;
    notifyListeners();
  }

  void setFilterPlant(String? plant) {
    _filterPlant = plant;
    notifyListeners();
  }

  void setFilterMachine(String? machine) {
    _filterMachine = machine;
    notifyListeners();
  }

  void setFilterProductCode(String? code) {
    _filterProductCode = code;
    notifyListeners();
  }

  void clearFilters() {
    _filterDate = null;
    _filterShift = null;
    _filterPlant = null;
    _filterMachine = null;
    _filterProductCode = null;
    notifyListeners();
  }
}
