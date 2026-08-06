import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:et_calculator/widgets/summary_card.dart';
import 'package:et_calculator/widgets/production_input_fields.dart';

void main() {
  testWidgets('SummaryCard renders title and value correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 150,
            child: SummaryCard(
              title: 'Total Tested',
              value: '1,234',
              subtitle: '8.57 grs',
              icon: Icons.inventory,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Total Tested'), findsOneWidget);
    expect(find.text('1,234'), findsOneWidget);
    expect(find.text('8.57 grs'), findsOneWidget);
  });

  testWidgets('ProductionInputFields renders GOOD, REJ, Q.C, SAMPLES text fields', (WidgetTester tester) async {
    final goodCtrl = TextEditingController(text: '1000');
    final rejectCtrl = TextEditingController(text: '50');
    final qaCtrl = TextEditingController(text: '10');
    final sampleCtrl = TextEditingController(text: '5');

    final goodFocus = FocusNode();
    final rejectFocus = FocusNode();
    final qaFocus = FocusNode();
    final sampleFocus = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 200,
            child: ProductionInputFields(
              goodController: goodCtrl,
              rejectController: rejectCtrl,
              qaController: qaCtrl,
              sampleController: sampleCtrl,
              goodFocusNode: goodFocus,
              rejectFocusNode: rejectFocus,
              qaFocusNode: qaFocus,
              sampleFocusNode: sampleFocus,
              onSubmitted: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('GOOD'), findsOneWidget);
    expect(find.text('REJ'), findsOneWidget);
    expect(find.text('Q.C'), findsOneWidget);
    expect(find.text('SAMPLES'), findsOneWidget);

    expect(find.text('1000'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });
}
