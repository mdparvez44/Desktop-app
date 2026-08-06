/// Utility for truncation (NOT rounding) according to ET Calculator requirements.
library;

/// Truncates a double value to [decimals] decimal places without rounding.
///
/// Examples:
/// 87.8125 -> 87.81
/// 87.8165 -> 87.81
/// 87.8199 -> 87.81
double truncateTo2(double value) {
  return truncateToNDecimals(value, 2);
}

/// Truncates a double value to [decimals] decimal places without rounding.
double truncateToNDecimals(double value, int decimals) {
  if (value.isNaN || value.isInfinite) return 0.0;
  
  // Format with high precision to avoid floating point noise, then cut at N decimals
  final str = value.toStringAsFixed(8);
  final parts = str.split('.');
  if (parts.length < 2 || decimals <= 0) {
    return double.parse(parts[0]);
  }
  
  final intPart = parts[0];
  final decPart = parts[1].substring(0, decimals);
  return double.parse('$intPart.$decPart');
}

/// Formats a double truncated to 2 decimals as String.
String formatTruncated2(double value) {
  final truncated = truncateTo2(value);
  return truncated.toStringAsFixed(2);
}
