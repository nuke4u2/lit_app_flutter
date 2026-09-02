import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lit_reader/screens/pin/pin_keypad.dart';

void main() {
  testWidgets('PIN keypad submits exactly four digits', (tester) async {
    String? submittedPin;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PinKeypad(
            title: 'Enter PIN',
            onCompleted: (pin) => submittedPin = pin,
          ),
        ),
      ),
    );

    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }

    expect(submittedPin, '1234');
  });
}
