/// Data models for Plant and Product Code-wise aggregation reports and Monthly Totals.
library;

import '../utils/truncate_utils.dart';

class PlantProductReportRow {
  final String plant;
  final String productCode;
  final double totalGood;
  final double totalReject;
  final double totalQA;
  final double totalSample;

  const PlantProductReportRow({
    required this.plant,
    required this.productCode,
    required this.totalGood,
    required this.totalReject,
    required this.totalQA,
    required this.totalSample,
  });

  /// Tested = Good + Reject + Q.C
  double get totalTested => totalGood + totalReject + totalQA;

  /// Gross calculations: Quantity / 144 (truncated to 2 decimals)
  double get testedGross => truncateTo2(totalTested / 144.0);
  double get goodGross => truncateTo2(totalGood / 144.0);
  double get rejectionGross => truncateTo2(totalReject / 144.0);
  double get totalQCGross => truncateTo2(totalQA / 144.0);

  /// Rejection % = (totalReject / totalTested) * 100 (truncated to 2 decimals)
  double get rejectionPercentage =>
      totalTested > 0 ? truncateTo2((totalReject / totalTested) * 100.0) : 0.0;
}

class PlantReportGroup {
  final String plant;
  final List<PlantProductReportRow> rows;

  const PlantReportGroup({
    required this.plant,
    required this.rows,
  });

  double get totalGood => rows.fold(0.0, (sum, r) => sum + r.totalGood);
  double get totalReject => rows.fold(0.0, (sum, r) => sum + r.totalReject);
  double get totalQA => rows.fold(0.0, (sum, r) => sum + r.totalQA);
  double get totalSample => rows.fold(0.0, (sum, r) => sum + r.totalSample);
  double get totalTested => totalGood + totalReject + totalQA;

  double get testedGross => truncateTo2(totalTested / 144.0);
  double get goodGross => truncateTo2(totalGood / 144.0);
  double get rejectionGross => truncateTo2(totalReject / 144.0);
  double get totalQCGross => truncateTo2(totalQA / 144.0);

  double get rejectionPercentage =>
      totalTested > 0 ? truncateTo2((totalReject / totalTested) * 100.0) : 0.0;
}

/// Helper model for Overall, IML, and TTK Totals
class ReportTotalGroup {
  final String label;
  final double totalGood;
  final double totalReject;
  final double totalQA;
  final double totalSample;

  const ReportTotalGroup({
    required this.label,
    required this.totalGood,
    required this.totalReject,
    required this.totalQA,
    required this.totalSample,
  });

  double get totalTested => totalGood + totalReject + totalQA;

  double get testedGross => truncateTo2(totalTested / 144.0);
  double get goodGross => truncateTo2(totalGood / 144.0);
  double get rejectionGross => truncateTo2(totalReject / 144.0);
  double get totalQCGross => truncateTo2(totalQA / 144.0);

  double get rejectionPercentage =>
      totalTested > 0 ? truncateTo2((totalReject / totalTested) * 100.0) : 0.0;
}

class OverallReportSummary {
  final List<PlantReportGroup> plantGroups;

  const OverallReportSummary({
    required this.plantGroups,
  });

  double get totalGood => plantGroups.fold(0.0, (sum, g) => sum + g.totalGood);
  double get totalReject => plantGroups.fold(0.0, (sum, g) => sum + g.totalReject);
  double get totalQA => plantGroups.fold(0.0, (sum, g) => sum + g.totalQA);
  double get totalSample => plantGroups.fold(0.0, (sum, g) => sum + g.totalSample);
  double get totalTested => totalGood + totalReject + totalQA;

  double get testedGross => truncateTo2(totalTested / 144.0);
  double get goodGross => truncateTo2(totalGood / 144.0);
  double get rejectionGross => truncateTo2(totalReject / 144.0);
  double get totalQCGross => truncateTo2(totalQA / 144.0);

  double get rejectionPercentage =>
      totalTested > 0 ? truncateTo2((totalReject / totalTested) * 100.0) : 0.0;

  /// TOTAL 1 - Overall Total (Complete production total)
  ReportTotalGroup get overallTotal => ReportTotalGroup(
        label: 'Overall Total',
        totalGood: totalGood,
        totalReject: totalReject,
        totalQA: totalQA,
        totalSample: totalSample,
      );

  /// TOTAL 2 - IML Total (Excluding TTK)
  ReportTotalGroup get imlTotal {
    final imlGroups = plantGroups.where((g) => g.plant.toUpperCase() != 'TTK');
    final good = imlGroups.fold(0.0, (sum, g) => sum + g.totalGood);
    final reject = imlGroups.fold(0.0, (sum, g) => sum + g.totalReject);
    final qa = imlGroups.fold(0.0, (sum, g) => sum + g.totalQA);
    final sample = imlGroups.fold(0.0, (sum, g) => sum + g.totalSample);

    return ReportTotalGroup(
      label: 'IML Total',
      totalGood: good,
      totalReject: reject,
      totalQA: qa,
      totalSample: sample,
    );
  }

  /// TOTAL 3 - TTK Total (Only TTK)
  ReportTotalGroup get ttkTotal {
    final ttkGroups = plantGroups.where((g) => g.plant.toUpperCase() == 'TTK');
    final good = ttkGroups.fold(0.0, (sum, g) => sum + g.totalGood);
    final reject = ttkGroups.fold(0.0, (sum, g) => sum + g.totalReject);
    final qa = ttkGroups.fold(0.0, (sum, g) => sum + g.totalQA);
    final sample = ttkGroups.fold(0.0, (sum, g) => sum + g.totalSample);

    return ReportTotalGroup(
      label: 'TTK Total',
      totalGood: good,
      totalReject: reject,
      totalQA: qa,
      totalSample: sample,
    );
  }
}
