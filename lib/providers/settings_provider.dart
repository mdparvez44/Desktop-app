/// Provider managing application settings with offline persistent storage (SharedPreferences).
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

import '../utils/constants.dart';

class SettingsProvider with ChangeNotifier {
  static const String _keySettingsJson = 'et_calculator_settings_json';
  SharedPreferences? _prefs;
  AppSettings _settings = AppSettings();
  bool _isLoaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _isLoaded;
  String? get customSaveLocation => _settings.exportSaveLocation;
  bool get automaticExport => _settings.automaticExport;
  bool get isDarkMode => _settings.isDarkMode;
  ThemeMode get themeMode => _settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Master Configuration Getters (with automatic fallback to AppConstants defaults)
  List<String> get machines => _settings.machines ?? List<String>.from(AppConstants.defaultMachines);
  List<String> get productCodes => _settings.productCodes ?? List<String>.from(AppConstants.productCodes);
  List<String> get plants => _settings.plants ?? List<String>.from(AppConstants.defaultPlants);
  List<String> get rejectionOptions => _settings.rejectionOptions ?? List<String>.from(AppConstants.defaultRejectionOptions);
  List<GoodOption> get goodOptions =>
      _settings.goodOptions ??
      AppConstants.defaultGoodOptions
          .map((v) => GoodOption(value: v, enabled: true))
          .toList();
  double get qcConstant => _settings.qcConstant ?? AppConstants.defaultQCConstant;

  SettingsProvider([SharedPreferences? prefs]) {
    if (prefs != null) {
      _prefs = prefs;
      _loadFromPrefs(prefs);
    } else {
      loadSettings();
    }
  }

  void _loadFromPrefs(SharedPreferences prefs) {
    try {
      final content = prefs.getString(_keySettingsJson);
      if (content != null && content.isNotEmpty) {
        final jsonMap = jsonDecode(content) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(jsonMap);
      } else {
        // Individual key fallback
        final exportLoc = prefs.getString('exportSaveLocation');
        final autoExport = prefs.getBool('automaticExport') ?? true;
        final darkMode = prefs.getBool('isDarkMode') ?? false;
        _settings = AppSettings(
          exportSaveLocation: exportLoc,
          automaticExport: autoExport,
          isDarkMode: darkMode,
        );
      }
    } catch (e) {
      debugPrint('Error decoding settings JSON: $e');
    }
    _isLoaded = true;
  }

  Future<void> loadSettings() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (_prefs != null) {
        _loadFromPrefs(_prefs!);
      }
    } catch (e) {
      debugPrint('Error initializing SharedPreferences: $e');
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (_prefs != null) {
        final jsonStr = jsonEncode(_settings.toJson());
        await _prefs!.setString(_keySettingsJson, jsonStr);
        if (_settings.exportSaveLocation != null) {
          await _prefs!.setString('exportSaveLocation', _settings.exportSaveLocation!);
        } else {
          await _prefs!.remove('exportSaveLocation');
        }
        await _prefs!.setBool('automaticExport', _settings.automaticExport);
        await _prefs!.setBool('isDarkMode', _settings.isDarkMode);
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
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

  // --- MACHINE MANAGEMENT ---
  Future<bool> addMachine(String machine) async {
    final trimmed = machine.trim();
    if (trimmed.isEmpty) return false;
    final current = List<String>.from(machines);
    if (current.any((m) => m.toLowerCase() == trimmed.toLowerCase())) {
      return false; // Duplicate
    }
    current.add(trimmed);
    _settings = _settings.copyWith(machines: current);
    await _saveSettings();
    return true;
  }

  Future<bool> removeMachine(String machine) async {
    final current = List<String>.from(machines);
    current.removeWhere((m) => m.toLowerCase() == machine.trim().toLowerCase());
    _settings = _settings.copyWith(machines: current);
    await _saveSettings();
    return true;
  }

  // --- PRODUCT CODE MANAGEMENT ---
  Future<bool> addProductCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return false;
    final current = List<String>.from(productCodes);
    if (current.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
      return false; // Duplicate
    }
    current.add(trimmed);
    _settings = _settings.copyWith(productCodes: current);
    await _saveSettings();
    return true;
  }

  Future<bool> removeProductCode(String code) async {
    final current = List<String>.from(productCodes);
    current.removeWhere((c) => c.toLowerCase() == code.trim().toLowerCase());
    _settings = _settings.copyWith(productCodes: current);
    await _saveSettings();
    return true;
  }

  // --- PLANT MANAGEMENT ---
  Future<bool> addPlant(String plant) async {
    final trimmed = plant.trim();
    if (trimmed.isEmpty) return false;
    final current = List<String>.from(plants);
    if (current.any((p) => p.toLowerCase() == trimmed.toLowerCase())) {
      return false; // Duplicate
    }
    current.add(trimmed);
    _settings = _settings.copyWith(plants: current);
    await _saveSettings();
    return true;
  }

  Future<bool> removePlant(String plant) async {
    final current = List<String>.from(plants);
    current.removeWhere((p) => p.toLowerCase() == plant.trim().toLowerCase());
    _settings = _settings.copyWith(plants: current);
    await _saveSettings();
    return true;
  }

  // --- REJECTION OPTIONS MANAGEMENT ---
  Future<bool> addRejectionOption(String option) async {
    final trimmed = option.trim();
    if (trimmed.isEmpty) return false;
    final current = List<String>.from(rejectionOptions);
    if (current.any((o) => o.toLowerCase() == trimmed.toLowerCase())) {
      return false; // Duplicate
    }
    current.add(trimmed);
    _settings = _settings.copyWith(rejectionOptions: current);
    await _saveSettings();
    return true;
  }

  Future<bool> removeRejectionOption(String option) async {
    final current = List<String>.from(rejectionOptions);
    current.removeWhere((o) => o.toLowerCase() == option.trim().toLowerCase());
    _settings = _settings.copyWith(rejectionOptions: current);
    await _saveSettings();
    return true;
  }

  // --- GOOD OPTIONS MANAGEMENT ---
  Future<bool> addGoodOption(String option) async {
    final trimmed = option.trim();
    if (trimmed.isEmpty) return false;
    final current = List<GoodOption>.from(goodOptions);
    if (current.any((o) => o.value.toLowerCase() == trimmed.toLowerCase())) {
      return false; // Duplicate
    }
    current.add(GoodOption(value: trimmed, enabled: true));
    _settings = _settings.copyWith(goodOptions: current);
    await _saveSettings();
    return true;
  }

  Future<bool> removeGoodOption(String option) async {
    final current = List<GoodOption>.from(goodOptions);
    current.removeWhere((o) => o.value.toLowerCase() == option.trim().toLowerCase());
    _settings = _settings.copyWith(goodOptions: current);
    await _saveSettings();
    return true;
  }

  Future<bool> toggleGoodOption(String option, bool enabled) async {
    final current = List<GoodOption>.from(goodOptions);
    final index = current.indexWhere((o) => o.value.toLowerCase() == option.trim().toLowerCase());
    if (index != -1) {
      current[index] = current[index].copyWith(enabled: enabled);
      _settings = _settings.copyWith(goodOptions: current);
      await _saveSettings();
      return true;
    }
    return false;
  }

  // --- Q.C CONSTANT MANAGEMENT ---
  Future<bool> setQCConstant(double value) async {
    if (value <= 0) return false;
    _settings = _settings.copyWith(qcConstant: value);
    await _saveSettings();
    return true;
  }

  /// Returns effective export location display text: configured location if set, else platform default.
  Future<String> getEffectiveSaveLocation() async {
    if (_settings.exportSaveLocation != null && _settings.exportSaveLocation!.isNotEmpty) {
      return _settings.exportSaveLocation!;
    }
    if (kIsWeb) {
      return 'Browser Downloads (Automatic)';
    }
    return 'Default System Downloads';
  }
}
