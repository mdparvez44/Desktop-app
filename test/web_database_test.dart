/// Web Database & Persistence unit test suite verifying schema, CRUD, calculations, and natural sorting.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:et_calculator/database/database_helper.dart';
import 'package:et_calculator/models/production.dart';
import 'package:et_calculator/services/calculation_service.dart';
import 'package:et_calculator/utils/truncate_utils.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Initialize FFI for test environment
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseHelper.instance.clearAllProductions();
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearAllProductions();
  });

  group('Phase 2 — Web Local Database Layer Tests', () {
    test('1. Insert & Retrieve Production Record with exact Q.C x 95 conversion', () async {
      final now = DateTime.now();
      const enteredGood = 100.0;
      const enteredReject = 5.0;
      const enteredQCInput = 1.0;
      const enteredSample = 2.0;
      const savedQA = enteredQCInput * 95.0; // 95.0
      final calculatedTested = CalculationService.calculateTested(
        good: enteredGood,
        reject: enteredReject,
        qa: savedQA,
      ); // 100 + 5 + 95 = 200.0 (Samples 2.0 NOT included)

      final record = Production(
        machine: 'A1',
        plant: 'TTK',
        productCode: 'N53PM',
        good: enteredGood,
        reject: enteredReject,
        qa: savedQA,
        sample: enteredSample,
        tested: calculatedTested,
        shift: 'First',
        createdAt: now,
        updatedAt: now,
      );

      final id = await DatabaseHelper.instance.insertProduction(record);
      expect(id, greaterThan(0));

      final fetched = await DatabaseHelper.instance.getProductionById(id);
      expect(fetched, isNotNull);
      expect(fetched!.id, equals(id));
      expect(fetched.machine, equals('A1'));
      expect(fetched.plant, equals('TTK'));
      expect(fetched.productCode, equals('N53PM'));
      expect(fetched.good, equals(100.0));
      expect(fetched.reject, equals(5.0));
      expect(fetched.qa, equals(95.0));
      expect(fetched.sample, equals(2.0));
      expect(fetched.hold, equals(0.0));
      expect(fetched.tested, equals(200.0)); // Good (100) + Reject (5) + Q.C (95)
      expect(fetched.shift, equals('First'));
    });

    test('2. Update Production Record (Good: 100 -> 150)', () async {
      final record = Production(
        machine: 'A1',
        plant: 'TTK',
        productCode: 'N53PM',
        good: 100.0,
        reject: 5.0,
        qa: 95.0,
        sample: 2.0,
        tested: 200.0,
        shift: 'First',
      );

      final id = await DatabaseHelper.instance.insertProduction(record);
      final inserted = await DatabaseHelper.instance.getProductionById(id);
      expect(inserted!.good, equals(100.0));

      // Update Good to 150
      const updatedGood = 150.0;
      final updatedTested = CalculationService.calculateTested(
        good: updatedGood,
        reject: inserted.reject,
        qa: inserted.qa,
      ); // 150 + 5 + 95 = 250.0

      final updatedRecord = inserted.copyWith(
        good: updatedGood,
        tested: updatedTested,
        updatedAt: DateTime.now(),
      );

      final updatedCount = await DatabaseHelper.instance.updateProduction(updatedRecord);
      expect(updatedCount, equals(1));

      final refetched = await DatabaseHelper.instance.getProductionById(id);
      expect(refetched, isNotNull);
      expect(refetched!.good, equals(150.0));
      expect(refetched.tested, equals(250.0));
    });

    test('3. Delete Production Record', () async {
      final rec1 = Production(machine: 'A1', plant: 'TTK', productCode: 'N53PM', good: 100, reject: 5, qa: 95, sample: 2);
      final rec2 = Production(machine: 'A2', plant: 'TTK', productCode: 'N53RM', good: 200, reject: 10, qa: 190, sample: 4);

      final id1 = await DatabaseHelper.instance.insertProduction(rec1);
      final id2 = await DatabaseHelper.instance.insertProduction(rec2);

      var list = await DatabaseHelper.instance.getAllProductions();
      expect(list.length, equals(2));

      // Delete rec2
      final deletedCount = await DatabaseHelper.instance.deleteProduction(id2);
      expect(deletedCount, equals(1));

      list = await DatabaseHelper.instance.getAllProductions();
      expect(list.length, equals(1));
      expect(list.first.id, equals(id1));
      expect(await DatabaseHelper.instance.getProductionById(id2), isNull);
    });

    test('4. clearAllProductions wipes all records', () async {
      await DatabaseHelper.instance.insertProduction(Production(machine: 'A1', plant: 'TTK', productCode: 'N53PM', good: 100, reject: 5, qa: 95, sample: 2));
      await DatabaseHelper.instance.insertProduction(Production(machine: 'A2', plant: 'TTK', productCode: 'N53RM', good: 200, reject: 10, qa: 190, sample: 4));

      var list = await DatabaseHelper.instance.getAllProductions();
      expect(list.length, equals(2));

      await DatabaseHelper.instance.clearAllProductions();

      list = await DatabaseHelper.instance.getAllProductions();
      expect(list.isEmpty, isTrue);
    });

    test('5. Natural Machine Ordering (A1, A2, A10, B1, C1)', () async {
      final now = DateTime.now();
      final records = [
        Production(machine: 'B1', plant: 'A', productCode: 'N40UM', good: 100, reject: 0, qa: 0, sample: 0, createdAt: now),
        Production(machine: 'A10', plant: 'TTK', productCode: 'N53PM', good: 100, reject: 0, qa: 0, sample: 0, createdAt: now),
        Production(machine: 'A1', plant: 'TTK', productCode: 'N53PM', good: 100, reject: 0, qa: 0, sample: 0, createdAt: now),
        Production(machine: 'C1', plant: 'B', productCode: 'N56CFM', good: 100, reject: 0, qa: 0, sample: 0, createdAt: now),
        Production(machine: 'A2', plant: 'TTK', productCode: 'N53RM', good: 100, reject: 0, qa: 0, sample: 0, createdAt: now),
      ];

      for (final r in records) {
        await DatabaseHelper.instance.insertProduction(r);
      }

      final fetched = await DatabaseHelper.instance.getAllProductions();
      expect(fetched.length, equals(5));

      final machineOrder = fetched.map((r) => r.machine).toList();
      expect(machineOrder, equals(['A1', 'A2', 'A10', 'B1', 'C1']));
    });

    test('6. Report Aggregations on Database Records', () async {
      final records = [
        Production(machine: 'A1', plant: 'TTK', productCode: 'N53PM', good: 1440, reject: 144, qa: 0, sample: 10, shift: 'First'),
        Production(machine: 'A2', plant: 'TTK', productCode: 'N53RM', good: 2880, reject: 288, qa: 144, sample: 20, shift: 'First'),
        Production(machine: 'B1', plant: 'A', productCode: 'N40UM', good: 1440, reject: 144, qa: 144, sample: 10, shift: 'Second'),
      ];

      for (final r in records) {
        await DatabaseHelper.instance.insertProduction(r);
      }

      final allDbRecords = await DatabaseHelper.instance.getAllProductions();
      final summary = CalculationService.computeSummary(allDbRecords);
      final dailyReport = CalculationService.computeDailyReportSummary(allDbRecords);
      final plantReport = CalculationService.computePlantProductReport(allDbRecords);

      expect(summary.totalGood, equals(5760.0));
      expect(summary.totalReject, equals(576.0));
      expect(summary.totalQA, equals(288.0));
      expect(summary.totalTested, equals(6624.0)); // 5760 + 576 + 288

      expect(dailyReport.rows.length, equals(3));
      expect(plantReport.plantGroups.length, equals(2)); // Plant 'A' and Plant 'TTK'
      expect(plantReport.overallTotal.testedGross, equals(truncateTo2(6624.0 / 144.0))); // 46.00 grs
    });

    test('7. Truncation Rule (87.8199 -> 87.81)', () {
      expect(truncateTo2(87.8199), equals(87.81));
      expect(truncateTo2(87.8125), equals(87.81));
      expect(truncateTo2(87.8165), equals(87.81));
    });
  });
}
