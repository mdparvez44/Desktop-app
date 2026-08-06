/// Provider managing application settings with offline persistent JSON file storage.
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';
import '../services/excel_service.dart';

class SettingsProvider with ChangeNotifier {
  AppSettings _settings = AppSettings();
  bool _isLoaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _isLoaded;
  String? get customSaveLocation => _settings.exportSaveLocation;
  bool get automaticExport => _settings.automaticExport;
  bool get isDarkMode => _settings.isDarkMode;
  ThemeMode get themeMode => _settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;

  SettingsProvider() {
    loadSettings();
  }

  Future<File> _getSettingsFile() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(appDocDir.path, 'ET_Calculator', 'et_calculator_settings.json'));
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    return file;
  }

  Future<void> loadSettings() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonMap = jsonDecode(content) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(jsonMap);
      }
    } catch (_) {}
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      final file = await _getSettingsFile();
      await file.writeAsString(jsonEncode(_settings.toJson()));
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setExportSaveLocation(String? path) async {
    _settings = _settings.copyWith(exportSaveLocation: path);
    await _saveSettings();
  }

  Future<void> setAutomaticExport(bool value) async {
    _settings = _settings.copyWith(automaticExport: value);
    await _saveSettings();
  }

  Future<void> setDarkMode(bool value) async {
    _settings = _settings.copyWith(isDarkMode: value);
    await _saveSettings();
  }

  /// Returns effective export location: configured location if set & valid, else system Downloads
  Future<String> getEffectiveSaveLocation() async {
    if (_settings.exportSaveLocation != null && _settings.exportSaveLocation!.isNotEmpty) {
      final customDir = Directory(_settings.exportSaveLocation!);
      if (await customDir.exists()) {
        return customDir.path;
      }
    }
    return await ExcelService.getDownloadsDirectoryPath();
  }
}
