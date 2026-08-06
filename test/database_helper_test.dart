import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:et_calculator/models/production.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Production model serialization and tested auto-calculation', () {
    final prod = Production(
      id: 1,
      machine: 'A1',
      plant: 'TTK',
      productCode: 'N53PM',
      good: 1000,
      reject: 50,
      qa: 10,
      sample: 5,
    );

    final map = prod.toMap();
    expect(map['machine'], equals('A1'));
    expect(map['plant'], equals('TTK'));
    expect(map['productCode'], equals('N53PM'));
    expect(map['good'], equals(1000.0));
    expect(map['reject'], equals(50.0));
    expect(map['qa'], equals(10.0));
    expect(map['tested'], equals(1060.0));

    final restored = Production.fromMap(map);
    expect(restored.id, equals(1));
    expect(restored.machine, equals('A1'));
    expect(restored.tested, equals(1060.0));
  });
}
