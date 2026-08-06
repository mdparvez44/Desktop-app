import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/services/calculation_service.dart';
import 'package:et_calculator/utils/natural_sort.dart';

void main() {
  group('Input Entry UI Workflow Tests', () {
    test('Calculates Tested = Good + Reject + QA (Samples NOT included)', () {
      final tested = CalculationService.calculateTested(
        good: 1000,
        reject: 50,
        qa: 10,
      );
      expect(tested, equals(1060.0));
    });

    test('Next machine button respects natural machine ordering', () {
      final machines = ['A1', 'A2', 'A3', 'A10', 'B1'];
      machines.sortNaturally();

      int currentIndex = machines.indexOf('A2');
      String nextMachine = machines[currentIndex + 1];
      expect(nextMachine, equals('A3'));

      currentIndex = machines.indexOf('A3');
      nextMachine = machines[currentIndex + 1];
      expect(nextMachine, equals('A10'));
    });
  });
}
