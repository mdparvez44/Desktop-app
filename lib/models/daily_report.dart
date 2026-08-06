/// Data models for the Daily Report screen, including Plant Wise and Product Code Wise aggregations.
library;

import '../utils/truncate_utils.dart';

class DailyReportRow {
  final String machine;
  final String productCode;
  final double totalGood;
  final double totalReject;
  final double totalQA;
  final double totalSample;
  final double totalHold;

  DailyReportRow({
    required this.machine,
    required this.productCode,
    required this.totalGood,
    required this.totalReject,
    required this.totalQA,
    required this.totalSample,
    required this.totalHold,
  });

  /// Raw total tested = Good + Reject + QA
  double get totalTested => totalGood + totalReject + totalQA;

  /// Gross calculations: Quantity / 144 (Truncated to 2 decimal places)
  double get testedGross => truncateTo2(totalTested / 144.0);
  double get goodGross => truncateTo2(totalGood / 144.0);
  double get rejectionGross => truncateTo2(totalReject / 144.0);
  double get totalQCGross => truncateTo2(totalQA / 144.0);
  double get hold => totalHold;

  /// Rejection percentage calculation: (Rejection Gross ÷ Tested Gross) × 100
  double get rejectionPercentage {
    if (testedGross <= 0) return 0.0;
    return truncateTo2((rejectionGross / testedGross) * 100.0);
  }
}

class DailyReportSummary {
  final List<DailyReportRow> rows;
  final double totalGood;
  final double totalReject;
  final double totalQA;
  final double totalSample;
  final double totalHold;

  DailyReportSummary({
    required this.rows,
    required this.totalGood,
    required this.totalReject,
    required this.totalQA,
    required this.totalSample,
    required this.totalHold,
  });

  /// Overall raw total tested
  double get totalTested => totalGood + totalReject + totalQA;

  /// Gross sums matching Daily Report totals requirement
  double get totalTestedGross => rows.fold(0.0, (sum, r) => truncateTo2(sum + r.testedGross));
  double get totalGoodGross => rows.fold(0.0, (sum, r) => truncateTo2(sum + r.goodGross));
  double get totalRejectionGross => rows.fold(0.0, (sum, r) => truncateTo2(sum + r.rejectionGross));
  double get totalQCGross => rows.fold(0.0, (sum, r) => truncateTo2(sum + r.totalQCGross));
  double get totalHoldValue => totalHold;

  /// Overall rejection percentage calculated using (Total Rejection Gross ÷ Total Tested Gross) × 100
  double get totalRejectionPercentage {
    if (totalTestedGross <= 0) return 0.0;
    return truncateTo2((totalRejectionGross / totalTestedGross) * 100.0);
  }
}

/// Plant Wise aggregated row model
class PlantWiseDailyReportRow {
  final String plant;
  final String productCode;
  final double testedGross;
  final double goodGross;
  final double rejectionGross;
  final double totalQCGross;

  PlantWiseDailyReportRow({
    required this.plant,
    required this.productCode,
    required this.testedGross,
    required this.goodGross,
    required this.rejectionGross,
    required this.totalQCGross,
  });

  double get rejectionPercentage {
    if (testedGross <= 0) return 0.0;
    return truncateTo2((rejectionGross / testedGross) * 100.0);
  }
}

/// Product Code Wise aggregated row model
class ProductWiseDailyReportRow {
  final String productCode;
  final double testedGross;
  final double goodGross;
  final double rejectionGross;
  final double totalQCGross;

  ProductWiseDailyReportRow({
    required this.productCode,
    required this.testedGross,
    required this.goodGross,
    required this.rejectionGross,
    required this.totalQCGross,
  });

  double get rejectionPercentage {
    if (testedGross <= 0) return 0.0;
    return truncateTo2((rejectionGross / testedGross) * 100.0);
  }
}
