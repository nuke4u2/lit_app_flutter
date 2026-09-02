import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lit_reader/classes/content_privacy.dart';
import 'package:lit_reader/controllers/pin_controller.dart';
import 'package:lit_reader/screens/pin/app_lock_gate.dart';

class _SeededPinStorage implements PinStorage {
  _SeededPinStorage(this.pin);

  String? pin;

  @override
  Future<void> deletePin() async => pin = null;

  @override
  Future<String?> readPin() async => pin;

  @override
  Future<void> writePin(String value) async => pin = value;
}

class _NoopContentProtection implements ContentProtection {
  @override
  Future<void> setContentVisible(bool visible) async {}

  @override
  Future<void> setPrivacyEnabled(bool enabled) async {}
}

void main() {
  testWidgets('lock gate hides content, unlocks, and relocks on pause', (tester) async {
    final controller = PinController(
      storage: _SeededPinStorage('1234'),
      contentProtection: _NoopContentProtection(),
    );
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: AppLockGate(
          controller: controller,
          child: const Material(child: Center(child: Text('private story content'))),
        ),
      ),
    );

    expect(find.text('Lit Reader is locked'), findsOneWidget);
    expect(find.text('private story content'), findsNothing);

    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump();

    expect(find.text('private story content'), findsOneWidget);
    expect(find.text('Lit Reader is locked'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(find.text('Lit Reader is locked'), findsOneWidget);
    expect(find.text('private story content'), findsNothing);
  });
}
