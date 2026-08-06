/// Model representing a single production entry.
library;

import '../utils/truncate_utils.dart';

class Production {
  final int? id;
  final String machine;
  final String plant;
  final String productCode;
  final double good;
  final double reject;
  final double qa;
  final double sample;
  final double hold;
  final double tested;
  final String shift;
  final DateTime createdAt;
  final DateTime updatedAt;

  Production({
    this.id,
    required this.machine,
    required this.plant,
    required this.productCode,
    required this.good,
    required this.reject,
    required this.qa,
    required this.sample,
    this.hold = 0.0,
    double? tested,
    this.shift = 'Night',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : tested = tested ?? (good + reject + qa),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Calculate tested automatically: Good + Reject + QA (Hold does not affect tested)
  double get calculatedTested => good + reject + qa;

  /// Production Gross calculation: Quantity / 144 (Truncated to 2 decimal places)
  double get goodGross => truncateTo2(good / 144.0);
  double get rejectGross => truncateTo2(reject / 144.0);
  double get qaGross => truncateTo2(qa / 144.0);
  double get sampleGross => truncateTo2(sample / 144.0);
  double get holdGross => truncateTo2(hold / 144.0);
  double get testedGross => truncateTo2(tested / 144.0);

  /// Rejection percentage calculation: (Rejection / Tested) * 100
  double get rejectionPercentage {
    if (tested <= 0) return 0.0;
    return truncateTo2((reject / tested) * 100.0);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'machine': machine,
      'plant': plant,
      'productCode': productCode,
      'good': good,
      'reject': reject,
      'qa': qa,
      'sample': sample,
      'hold': hold,
      'tested': tested,
      'shift': shift,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Production.fromMap(Map<String, dynamic> map) {
    return Production(
      id: map['id'] as int?,
      machine: map['machine'] as String? ?? '',
      plant: map['plant'] as String? ?? '',
      productCode: map['productCode'] as String? ?? '',
      good: (map['good'] as num?)?.toDouble() ?? 0.0,
      reject: (map['reject'] as num?)?.toDouble() ?? 0.0,
      qa: (map['qa'] as num?)?.toDouble() ?? 0.0,
      sample: (map['sample'] as num?)?.toDouble() ?? 0.0,
      hold: (map['hold'] as num?)?.toDouble() ?? 0.0,
      tested: (map['tested'] as num?)?.toDouble() ?? 0.0,
      shift: map['shift'] as String? ?? 'Night',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Production copyWith({
    int? id,
    String? machine,
    String? plant,
    String? productCode,
    double? good,
    double? reject,
    double? qa,
    double? sample,
    double? hold,
    double? tested,
    String? shift,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Production(
      id: id ?? this.id,
      machine: machine ?? this.machine,
      plant: plant ?? this.plant,
      productCode: productCode ?? this.productCode,
      good: good ?? this.good,
      reject: reject ?? this.reject,
      qa: qa ?? this.qa,
      sample: sample ?? this.sample,
      hold: hold ?? this.hold,
      tested: tested ?? this.tested,
      shift: shift ?? this.shift,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
