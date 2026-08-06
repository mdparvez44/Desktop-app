/// Data models for Machine-Wise Gross reports (A1..M2).
library;

import '../utils/truncate_utils.dart';

class MachineGrossReportRow {
  final String machine;
  final double totalTested;

  const MachineGrossReportRow({
    required this.machine,
    required this.totalTested,
  });

  /// Total Tested Gross = Total Tested / 144 (truncated to 2 decimals)
  double get totalTestedGross => truncateTo2(totalTested / 144.0);
}

class MachineGrossSummary {
  final List<MachineGrossReportRow> rows;

  const MachineGrossSummary({
    required this.rows,
  });

  double get overallTotalTested => rows.fold(0.0, (sum, r) => sum + r.totalTested);

  double get overallTestedGross => truncateTo2(overallTotalTested / 144.0);
}
