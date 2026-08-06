/// Service to generate WhatsApp-formatted daily production reports.
library;

import 'package:intl/intl.dart';
import '../models/production.dart';
import '../utils/natural_sort.dart';
import '../utils/truncate_utils.dart';
import 'calculation_service.dart';

class ReportFormatterService {
  /// Generate WhatsApp report string from production records matching exact format specifications
  static String generateWhatsAppReport({
    required List<Production> records,
    required DateTime date,
    String shift = 'Second',
    int binHoldCount = 2,
    List<String>? reworkDetails,
  }) {
    final summary = CalculationService.computeSummary(records);
    final dateStr = DateFormat('dd/MM/yy').format(date);
    final totalTestedGrossStr = formatTruncated2(summary.totalTestedGross);
    final rejPctStr = formatTruncated2(summary.rejectionPercentage);

    final buffer = StringBuffer();
    // 1. Date Header
    buffer.writeln('*$dateStr*');

    // 2. Tested Qty and Rejection % Header
    buffer.writeln('ET total tested Qty in $shift shift is ${totalTestedGrossStr}grs');
    buffer.writeln('Rejection%= $rejPctStr%');

    // 3. Product Code Rejection % Breakdown
    final Map<String, _ProductStats> productMap = {};
    for (final r in records) {
      final stats = productMap.putIfAbsent(r.productCode, () => _ProductStats());
      stats.tested += r.tested;
      stats.reject += r.reject;
      stats.plants.add(r.plant);
    }

    final sortedProducts = productMap.keys.toList()..sort(compareNatural);
    for (final prod in sortedProducts) {
      final stats = productMap[prod]!;
      final prodRejPct = stats.tested > 0 ? truncateTo2((stats.reject / stats.tested) * 100.0) : 0.0;
      final isTTK = stats.plants.length == 1 && stats.plants.contains('TTK');
      final prefix = isTTK ? '(TTK) ' : '';
      buffer.writeln('$prefix$prod= ${formatTruncated2(prodRejPct)}%');
    }

    // 4. Plant-wise Rejection % Header (with leading space before *ET)
    buffer.writeln(' *ET rejection% details (plant wise )*');

    // 5. Plant-wise Breakdown per (Plant, Product Code)
    final Map<String, Map<String, _GroupStats>> plantGroupMap = {};
    for (final r in records) {
      plantGroupMap.putIfAbsent(r.plant, () => {});
      final plantMap = plantGroupMap[r.plant]!;
      final stats = plantMap.putIfAbsent(r.productCode, () => _GroupStats());
      stats.tested += r.tested;
      stats.reject += r.reject;
    }

    final sortedPlants = plantGroupMap.keys.toList()..sort(compareNatural);
    for (final plant in sortedPlants) {
      final plantMap = plantGroupMap[plant]!;
      final sortedGroupProducts = plantMap.keys.toList()..sort(compareNatural);
      for (final prod in sortedGroupProducts) {
        final stats = plantMap[prod]!;
        final groupRejPct = stats.tested > 0 ? truncateTo2((stats.reject / stats.tested) * 100.0) : 0.0;
        buffer.writeln('$plant= ${formatTruncated2(groupRejPct)}%($prod)');
      }
    }

    // 6. Rework Section
    buffer.writeln('*Rework*');
    buffer.writeln('$binHoldCount- bin hold due to ');

    final defaultReworks = [
      'D1 - Bubble with leak on T.A',
      'E1 - Leak on B.B',
    ];
    final activeReworks = (reworkDetails != null && reworkDetails.isNotEmpty)
        ? reworkDetails
        : defaultReworks;

    for (final item in activeReworks) {
      if (item.trim().isNotEmpty) {
        buffer.writeln(item.trim());
      }
    }

    return buffer.toString().trim();
  }
}

class _ProductStats {
  double tested = 0.0;
  double reject = 0.0;
  final Set<String> plants = {};
}

class _GroupStats {
  double tested = 0.0;
  double reject = 0.0;
}
