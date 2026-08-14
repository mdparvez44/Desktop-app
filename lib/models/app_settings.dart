/// Model representing persistent application settings.
library;

const Object _sentinel = Object();

class GoodOption {
  final String value;
  final bool enabled;

  GoodOption({
    required this.value,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'enabled': enabled,
    };
  }

  factory GoodOption.fromJson(Map<String, dynamic> json) {
    return GoodOption(
      value: json['value'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  GoodOption copyWith({
    String? value,
    bool? enabled,
  }) {
    return GoodOption(
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
    );
  }
}

class AppSettings {
  final String? exportSaveLocation;
  final bool automaticExport;
  final bool isDarkMode;
  final List<String>? machines;
  final List<String>? productCodes;
  final List<String>? plants;
  final List<String>? rejectionOptions;
  final List<GoodOption>? goodOptions;
  final double? qcConstant;

  AppSettings({
    this.exportSaveLocation,
    this.automaticExport = true,
    this.isDarkMode = false,
    this.machines,
    this.productCodes,
    this.plants,
    this.rejectionOptions,
    this.goodOptions,
    this.qcConstant,
  });

  Map<String, dynamic> toJson() {
    return {
      'exportSaveLocation': exportSaveLocation,
      'automaticExport': automaticExport,
      'isDarkMode': isDarkMode,
      'machines': machines,
      'productCodes': productCodes,
      'plants': plants,
      'rejectionOptions': rejectionOptions,
      'goodOptions': goodOptions?.map((e) => e.toJson()).toList(),
      'qcConstant': qcConstant,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      exportSaveLocation: json['exportSaveLocation'] as String?,
      automaticExport: json['automaticExport'] as bool? ?? true,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      machines: (json['machines'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      productCodes: (json['productCodes'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      plants: (json['plants'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      rejectionOptions: (json['rejectionOptions'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      goodOptions: (json['goodOptions'] as List<dynamic>?)
          ?.map((e) => GoodOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      qcConstant: (json['qcConstant'] as num?)?.toDouble(),
    );
  }

  AppSettings copyWith({
    Object? exportSaveLocation = _sentinel,
    bool? automaticExport,
    bool? isDarkMode,
    List<String>? machines,
    List<String>? productCodes,
    List<String>? plants,
    List<String>? rejectionOptions,
    List<GoodOption>? goodOptions,
    double? qcConstant,
  }) {
    return AppSettings(
      exportSaveLocation: identical(exportSaveLocation, _sentinel)
          ? this.exportSaveLocation
          : exportSaveLocation as String?,
      automaticExport: automaticExport ?? this.automaticExport,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      machines: machines ?? this.machines,
      productCodes: productCodes ?? this.productCodes,
      plants: plants ?? this.plants,
      rejectionOptions: rejectionOptions ?? this.rejectionOptions,
      goodOptions: goodOptions ?? this.goodOptions,
      qcConstant: qcConstant ?? this.qcConstant,
    );
  }
}
