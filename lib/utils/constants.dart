/// Constants and default configuration for ET Calculator.
library;

class AppConstants {
  static const String appName = 'ET Calculator';
  static const String appSubtitle = 'Production Calculator & Reporting System';

  /// Centralized 26 Machine Series (A1..M2)
  static final List<String> defaultMachines = [
    'A1', 'A2',
    'B1', 'B2',
    'C1', 'C2',
    'D1', 'D2',
    'E1', 'E2',
    'F1', 'F2',
    'G1', 'G2',
    'H1', 'H2',
    'I1', 'I2',
    'J1', 'J2',
    'K1', 'K2',
    'L1', 'L2',
    'M1', 'M2',
  ];

  /// Pre-configured Plants
  static const List<String> defaultPlants = [
    'TTK',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
  ];

  /// Pre-configured Product Codes (30 unique entries)
  static const List<String> productCodes = [
    'N53PM',
    'N53RM',
    'N40UM',
    'N56TCFM',
    'N56CFM',
    'R53DRM',
    'N58PM',
    'N53CM',
    'N53FCM',
    'N53FM',
    'N53THM',
    'N53TM',
    'N53DM',
    'N53CDM',
    'N53PCM',
    'Y53PM',
    'O53PM',
    'BULK',
    '190MM',
    'N49ISM',
    'N49PM',
    'R53PM',
    'P53PM',
    'P53CM',
    'R53CM',
    'U49PM',
    'U53PM',
    'E49PM',
    'B53PM',
    'Y49PM',
  ];

  /// Available Shifts
  static const List<String> shifts = [
    'All Shifts',
    'Day',
    'Night',
  ];

  /// Default Rejection Options
  static const List<String> defaultRejectionOptions = [
    '0.21',
    '3',
    '3.4',
    'CSTM',
  ];

  /// Default Good Options
  static const List<String> defaultGoodOptions = [
    '0.1',
    'CSTM',
  ];

  /// Default Q.C Constant
  static const double defaultQCConstant = 95.0;
}
