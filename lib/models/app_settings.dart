/// Model representing persistent application settings.
library;

class AppSettings {
  final String? exportSaveLocation;
  final bool automaticExport;
  final bool isDarkMode;

  AppSettings({
    this.exportSaveLocation,
    this.automaticExport = true,
    this.isDarkMode = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'exportSaveLocation': exportSaveLocation,
      'automaticExport': automaticExport,
      'isDarkMode': isDarkMode,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      exportSaveLocation: json['exportSaveLocation'] as String?,
      automaticExport: json['automaticExport'] as bool? ?? true,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
    );
  }

  AppSettings copyWith({
    String? exportSaveLocation,
    bool? automaticExport,
    bool? isDarkMode,
  }) {
    return AppSettings(
      exportSaveLocation: exportSaveLocation ?? this.exportSaveLocation,
      automaticExport: automaticExport ?? this.automaticExport,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}
