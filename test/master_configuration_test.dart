import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:et_calculator/models/app_settings.dart';
import 'package:et_calculator/providers/settings_provider.dart';
import 'package:et_calculator/services/calculation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Master Configuration Management Unit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Default initialization returns initial configuration options', () {
      final provider = SettingsProvider(prefs);

      expect(provider.machines, contains('A1'));
      expect(provider.machines.length, equals(26));
      expect(provider.productCodes, contains('N53PM'));
      expect(provider.plants, contains('TTK'));
      expect(provider.rejectionOptions, equals(['0.21', '3', '3.4', 'CSTM']));
      expect(provider.goodOptions.map((e) => e.value).toList(), equals(['0.1', 'CSTM']));
      expect(provider.qcConstant, equals(95.0));
    });

    test('Machine Management: Add, Remove, Duplicate prevention', () async {
      final provider = SettingsProvider(prefs);

      final added = await provider.addMachine('D1');
      expect(added, isTrue);
      expect(provider.machines, contains('D1'));

      final duplicate = await provider.addMachine('d1');
      expect(duplicate, isFalse); // Case-insensitive duplicate check

      final removed = await provider.removeMachine('D1');
      expect(removed, isTrue);
      expect(provider.machines.contains('D1'), isFalse);
    });

    test('Product Code Management: Add, Remove, Duplicate prevention', () async {
      final provider = SettingsProvider(prefs);

      final added = await provider.addProductCode('N60PM');
      expect(added, isTrue);
      expect(provider.productCodes, contains('N60PM'));

      final duplicate = await provider.addProductCode('n60pm');
      expect(duplicate, isFalse);

      final removed = await provider.removeProductCode('N60PM');
      expect(removed, isTrue);
      expect(provider.productCodes.contains('N60PM'), isFalse);
    });

    test('Plant Management: Add, Remove, Duplicate prevention', () async {
      final provider = SettingsProvider(prefs);

      final added = await provider.addPlant('H');
      expect(added, isTrue);
      expect(provider.plants, contains('H'));

      final duplicate = await provider.addPlant('h');
      expect(duplicate, isFalse);

      final removed = await provider.removePlant('H');
      expect(removed, isTrue);
      expect(provider.plants.contains('H'), isFalse);
    });

    test('Rejection Options: Add, Remove, Custom value support', () async {
      final provider = SettingsProvider(prefs);

      expect(provider.rejectionOptions, containsAll(['0.21', '3', '3.4', 'CSTM']));

      final added = await provider.addRejectionOption('4.5');
      expect(added, isTrue);
      expect(provider.rejectionOptions, contains('4.5'));

      final removed = await provider.removeRejectionOption('4.5');
      expect(removed, isTrue);
      expect(provider.rejectionOptions.contains('4.5'), isFalse);
    });

    test('Good Options: Add, Toggle enable/disable, Remove', () async {
      final provider = SettingsProvider(prefs);

      final added = await provider.addGoodOption('0.5');
      expect(added, isTrue);
      expect(provider.goodOptions.map((e) => e.value), contains('0.5'));

      final toggled = await provider.toggleGoodOption('0.5', false);
      expect(toggled, isTrue);
      expect(provider.goodOptions.firstWhere((e) => e.value == '0.5').enabled, isFalse);

      final removed = await provider.removeGoodOption('0.5');
      expect(removed, isTrue);
      expect(provider.goodOptions.any((e) => e.value == '0.5'), isFalse);
    });

    test('Q.C Constant: Change from 95 to 100 updates global calculation multiplier', () async {
      final provider = SettingsProvider(prefs);
      expect(provider.qcConstant, equals(95.0));

      final updated = await provider.setQCConstant(100.0);
      expect(updated, isTrue);
      expect(provider.qcConstant, equals(100.0));

      // Test calculation using updated Q.C constant (e.g. 2 x 100 = 200)
      final qaInput = 2.0;
      final savedQA = qaInput * provider.qcConstant;
      expect(savedQA, equals(200.0));

      final tested = CalculationService.calculateTested(good: 100, reject: 5, qa: savedQA);
      expect(tested, equals(305.0));
    });

    test('AppSettings JSON serialization and deserialization preserves all master settings', () {
      final settings = AppSettings(
        machines: ['A1', 'B1', 'D1'],
        productCodes: ['N53PM', 'N60PM'],
        plants: ['TTK', 'H'],
        rejectionOptions: ['0.21', '3', '3.4', 'CSTM', '4.5'],
        goodOptions: [
          GoodOption(value: '0.1', enabled: true),
          GoodOption(value: 'CSTM', enabled: true),
          GoodOption(value: '0.5', enabled: false),
        ],
        qcConstant: 100.0,
      );

      final json = settings.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.machines, equals(['A1', 'B1', 'D1']));
      expect(restored.productCodes, equals(['N53PM', 'N60PM']));
      expect(restored.plants, equals(['TTK', 'H']));
      expect(restored.rejectionOptions, equals(['0.21', '3', '3.4', 'CSTM', '4.5']));
      expect(restored.goodOptions?.length, equals(3));
      expect(restored.goodOptions?[2].enabled, isFalse);
      expect(restored.qcConstant, equals(100.0));
    });
  });
}
