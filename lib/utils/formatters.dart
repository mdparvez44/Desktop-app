/// Formatters for dates and numeric displays.
library;

import 'package:intl/intl.dart';
import 'truncate_utils.dart';

class AppFormatters {
  static final DateFormat dateFormat = DateFormat('dd/MM/yy');
  static final DateFormat fullDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat displayDateTimeFormat = DateFormat('dd/MM/yyyy hh:mm a');

  static String formatDate(DateTime dt) => dateFormat.format(dt);
  static String formatFullDate(DateTime dt) => fullDateFormat.format(dt);
  static String formatDisplayDateTime(DateTime dt) => displayDateTimeFormat.format(dt);

  /// Format a double value with truncated 2 decimals
  static String formatGross(double value) {
    return formatTruncated2(value);
  }

  /// Format an integer value with thousands separator
  static String formatNumber(num value) {
    final formatter = NumberFormat('#,##0.##');
    return formatter.format(value);
  }
}
