import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget_mobile/widgets/primary_button.dart';

void main() {
  testWidgets('loading button is disabled and displays progress', (
    tester,
  ) async {
    var pressCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Kaydet',
            isLoading: true,
            onPressed: () => pressCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));

    expect(pressCount, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('disabled button does not invoke callback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PrimaryButton(label: 'Kaydet', onPressed: null)),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
