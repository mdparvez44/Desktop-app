/// Central calculation service for production gross, plant reports, machine gross stats, and daily reports.
library;

import '../models/daily_report.dart';
import '../models/machine_gross_report.dart';
import '../models/plant_product_report.dart';
import '../models/production.dart';
import '../utils/constants.dart';
import '../utils/natural_sort.dart';
import '../utils/truncate_utils.dart';

class CalculationService {
  /// Calculate Tested = Good + Reject + QA (Samples NOT included)
  static double calculateTested({
    required double good,
    required double reject,
    required double qa,
  }) {
    return good + reject + qa;
  }

  /// Calculate Gross = Quantity / 144 (Truncated to 2 decimal places)
  static double calculateGross(double quantity) {
    return truncateTo2(quantity / 144.0);
  }

  /// Calculate Rejection Percentage = (Rejection / Tested) * 100 (Truncated to 2 decimal places)
  static double calculateRejectionPercentage({
    required double reject,
    required double tested,
  }) {
    if (tested <= 0) return 0.0;
    return truncateTo2((reject / tested) * 100.0);
  }

  /// Compute product code gross summary from list of production records
  static Map<String, double> computeProductGrossSummary(List<Production> records) {
    final Map<String, double> result = {};
    for (final record in records) {
      final code = record.productCode;
      result[code] = (result[code] ?? 0.0) + record.testedGross;
    }
    // Truncate each entry to 2 decimal places
    result.forEach((key, value) {
      result[key] = truncateTo2(value);
    });
    return result;
  }

  /// Compute machine series gross summary from list of production records (A1..M2)
  static MachineGrossSummary computeMachineGrossSummary(List<Production> records) {
    final Map<String, double> map = {};

    for (final machine in AppConstants.defaultMachines) {
      map[machine] = 0.0;
    }

    for (final r in records) {
      map[r.machine] = (map[r.machine] ?? 0.0) + r.tested;
    }

    final List<MachineGrossReportRow> rows = [];
    for (final machine in AppConstants.defaultMachines) {
      rows.add(
        MachineGrossReportRow(
          machine: machine,
          totalTested: map[machine] ?? 0.0,
        ),
      );
    }

    return MachineGrossSummary(rows: rows);
  }

  /// Alias for computeMachineGrossSummary
  static MachineGrossSummary computeMachineGrossReport(List<Production> records) {
    return computeMachineGrossSummary(records);
  }

  /// Compute overall summary (Totals) from list of production records
  static ProductionSummary computeSummary(List<Production> records) {
    double totalGood = 0;
    double totalReject = 0;
    double totalQA = 0;
    double totalSample = 0;

    for (final record in records) {
      totalGood += record.good;
      totalReject += record.reject;
      totalQA += record.qa;
      totalSample += record.sample;
    }

    final totalTested = calculateTested(good: totalGood, reject: totalReject, qa: totalQA);

    return ProductionSummary(
      totalGood: totalGood,
      totalReject: totalReject,
      totalQA: totalQA,
      totalSample: totalSample,
      totalTested: totalTested,
    );
  }

  /// Compute Daily Report Summary grouping by Machine Series (combining product codes for each machine into one cell)
  static DailyReportSummary computeDailyReportSummary(List<Production> records) {
    final Map<String, _DailyAccWithProducts> map = {};
    double overallGood = 0.0;
    double overallReject = 0.0;
    double overallQA = 0.0;
    double overallSample = 0.0;
    double overallHold = 0.0;

    for (final r in records) {
      overallGood += r.good;
      overallReject += r.reject;
      overallQA += r.qa;
      overallSample += r.sample;
      overallHold += r.hold;

      final acc = map.putIfAbsent(r.machine, () => _DailyAccWithProducts());
      acc.productCodes.add(r.productCode);
      acc.good += r.good;
      acc.reject += r.reject;
      acc.qa += r.qa;
      acc.sample += r.sample;
      acc.hold += r.hold;
    }

    // Sort machine keys using natural machine ordering
    final sortedMachines = map.keys.toList()..sort(compareNatural);
    final List<DailyReportRow> rows = [];

    for (final machine in sortedMachines) {
      final acc = map[machine]!;
      final sortedProducts = acc.productCodes.toList()..sort();
      final combinedProductCodes = sortedProducts.join(', ');

      rows.add(
        DailyReportRow(
          machine: machine,
          productCode: combinedProductCodes,
          totalGood: acc.good,
          totalReject: acc.reject,
          totalQA: acc.qa,
          totalSample: acc.sample,
          totalHold: acc.hold,
        ),
      );
    }

    return DailyReportSummary(
      rows: rows,
      totalGood: overallGood,
      totalReject: overallReject,
      totalQA: overallQA,
      totalSample: overallSample,
      totalHold: overallHold,
    );
  }

  /// Compute Plant Wise Daily Report grouping by Plant + Product Code
  static List<PlantWiseDailyReportRow> computePlantWiseDailyReport(List<Production> records) {
    final Map<String, Map<String, _DailyAcc>> map = {};

    for (final r in records) {
      map.putIfAbsent(r.plant, () => {});
      final plantMap = map[r.plant]!;
      final acc = plantMap.putIfAbsent(r.productCode, () => _DailyAcc());

      acc.good += r.good;
      acc.reject += r.reject;
      acc.qa += r.qa;
    }

    final sortedPlants = map.keys.toList()..sort(compareNatural);
    final List<PlantWiseDailyReportRow> rows = [];

    for (final plant in sortedPlants) {
      final plantMap = map[plant]!;
      final sortedProducts = plantMap.keys.toList()..sort(compareNatural);

      for (final prod in sortedProducts) {
        final acc = plantMap[prod]!;
        final testedQty = acc.good + acc.reject + acc.qa;
        rows.add(
          PlantWiseDailyReportRow(
            plant: plant,
            productCode: prod,
            testedGross: truncateTo2(testedQty / 144.0),
            goodGross: truncateTo2(acc.good / 144.0),
            rejectionGross: truncateTo2(acc.reject / 144.0),
            totalQCGross: truncateTo2(acc.qa / 144.0),
          ),
        );
      }
    }

    return rows;
  }

  /// Compute Product Code Wise Daily Report grouping by Product Code only
  static List<ProductWiseDailyReportRow> computeProductWiseDailyReport(List<Production> records) {
    final Map<String, _DailyAcc> map = {};

    for (final r in records) {
      final acc = map.putIfAbsent(r.productCode, () => _DailyAcc());
      acc.good += r.good;
      acc.reject += r.reject;
      acc.qa += r.qa;
    }

    final sortedProducts = map.keys.toList()..sort(compareNatural);
    final List<ProductWiseDailyReportRow> rows = [];

    for (final prod in sortedProducts) {
      final acc = map[prod]!;
      final testedQty = acc.good + acc.reject + acc.qa;
      rows.add(
        ProductWiseDailyReportRow(
          productCode: prod,
          testedGross: truncateTo2(testedQty / 144.0),
          goodGross: truncateTo2(acc.good / 144.0),
          rejectionGross: truncateTo2(acc.reject / 144.0),
          totalQCGross: truncateTo2(acc.qa / 144.0),
        ),
      );
    }

    return rows;
  }

  /// Group records by Plant and Product Code with raw quantity aggregation
  static OverallReportSummary computePlantProductReport(List<Production> records) {
    final Map<String, Map<String, _RawProductAcc>> map = {};

    for (final r in records) {
      final plant = r.plant;
      final product = r.productCode;

      map.putIfAbsent(plant, () => {});
      final plantMap = map[plant]!;
      final acc = plantMap.putIfAbsent(product, () => _RawProductAcc());
      acc.good += r.good;
      acc.reject += r.reject;
      acc.qa += r.qa;
      acc.sample += r.sample;
    }

    final sortedPlants = map.keys.toList()..sort(compareNatural);
    final List<PlantReportGroup> plantGroups = [];

    for (final plant in sortedPlants) {
      final plantMap = map[plant]!;
      final sortedProducts = plantMap.keys.toList()..sort(compareNatural);

      final List<PlantProductReportRow> rows = [];
      for (final prod in sortedProducts) {
        final acc = plantMap[prod]!;
        rows.add(
          PlantProductReportRow(
            plant: plant,
            productCode: prod,
            totalGood: acc.good,
            totalReject: acc.reject,
            totalQA: acc.qa,
            totalSample: acc.sample,
          ),
        );
      }

      plantGroups.add(
        PlantReportGroup(
          plant: plant,
          rows: rows,
        ),
      );
    }

    return OverallReportSummary(plantGroups: plantGroups);
  }
}

class _DailyAccWithProducts {
  final Set<String> productCodes = {};
  double good = 0.0;
  double reject = 0.0;
  double qa = 0.0;
  double sample = 0.0;
  double hold = 0.0;
}

class _DailyAcc {
  double good = 0.0;
  double reject = 0.0;
  double qa = 0.0;
  double sample = 0.0;
  double hold = 0.0;
}

class _RawProductAcc {
  double good = 0.0;
  double reject = 0.0;
  double qa = 0.0;
  double sample = 0.0;
}

class ProductionSummary {
  final double totalGood;
  final double totalReject;
  final double totalQA;
  final double totalSample;
  final double totalTested;

  ProductionSummary({
    required this.totalGood,
    required this.totalReject,
    required this.totalQA,
    required this.totalSample,
    required this.totalTested,
  });

  /// Gross calculations: Quantity / 144 (Truncated to 2 decimal places)
  double get totalGoodGross => truncateTo2(totalGood / 144.0);
  double get totalRejectionGross => truncateTo2(totalReject / 144.0);
  double get totalQCGross => truncateTo2(totalQA / 144.0);
  double get totalSampleGross => truncateTo2(totalSample / 144.0);
  double get totalTestedGross => truncateTo2(totalTested / 144.0);

  /// Rejection percentage calculation: (Total Reject / Total Tested) * 100 (Truncated to 2 decimal places)
  double get rejectionPercentage {
    if (totalTested <= 0) return 0.0;
    return truncateTo2((totalReject / totalTested) * 100.0);
  }
}
