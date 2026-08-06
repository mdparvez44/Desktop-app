import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/utils/natural_sort.dart';

void main() {
  group('Natural Machine Ordering Tests (Section 10)', () {
    test('Sorts machine codes naturally: A1, A2, A10, B1, B2', () {
      final machines = ['B2', 'A10', 'A1', 'B1', 'A2', 'A11', 'A3'];
      machines.sortNaturally();

      expect(
        machines,
        equals(['A1', 'A2', 'A3', 'A10', 'A11', 'B1', 'B2']),
      );
    });

    test('Verifies A1 < A2 < A10', () {
      expect(compareNatural('A1', 'A2'), lessThan(0));
      expect(compareNatural('A2', 'A10'), lessThan(0));
      expect(compareNatural('A10', 'A11'), lessThan(0));
      expect(compareNatural('A11', 'B1'), lessThan(0));
    });
  });
}
