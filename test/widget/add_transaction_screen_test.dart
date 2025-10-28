import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker_app/screens/add_transaction_screen.dart';

void main() {
  testWidgets('AddTransactionScreen form validation works',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AddTransactionScreen(),
        ),
      ),
    );

    // Tap on "Add" without entering anything
    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(find.text('Enter title'), findsOneWidget);
    expect(find.text('Enter amount'), findsOneWidget);

    // Fill the form
    await tester.enterText(find.byType(TextFormField).first, 'Test Title');
    await tester.enterText(find.byType(TextFormField).at(1), '150');
    await tester.pump();

    // Verify input is visible
    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
  });
}
