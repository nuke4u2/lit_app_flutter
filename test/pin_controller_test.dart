import 'package:flutter_test/flutter_test.dart';
import 'package:lit_reader/classes/content_privacy.dart';
import 'package:lit_reader/controllers/pin_controller.dart';

class _MemoryPinStorage implements PinStorage {
  _MemoryPinStorage([this.pin]);

  String? pin;

  @override
  Future<void> deletePin() async => pin = null;

  @override
  Future<String?> readPin() async => pin;

  @override
  Future<void> writePin(String value) async => pin = value;
}

class _RecordingContentProtection implements ContentProtection {
  final enabledValues = <bool>[];
  final visibleValues = <bool>[];

  @override
  Future<void> setContentVisible(bool visible) async => visibleValues.add(visible);

  @override
  Future<void> setPrivacyEnabled(bool enabled) async => enabledValues.add(enabled);
}

void main() {
  test('initializes unlocked when no PIN exists', () async {
    final protection = _RecordingContentProtection();
    final controller = PinController(
      storage: _MemoryPinStorage(),
      contentProtection: protection,
    );

    await controller.initialize();

    expect(controller.isInitialized, isTrue);
    expect(controller.isEnabled, isFalse);
    expect(controller.isLocked, isFalse);
    expect(protection.enabledValues, [false]);
    expect(protection.visibleValues, [true]);
  });

  test('an existing PIN starts locked and only the correct PIN unlocks it', () async {
    final protection = _RecordingContentProtection();
    final controller = PinController(
      storage: _MemoryPinStorage('1234'),
      contentProtection: protection,
    );
    await controller.initialize();

    expect(controller.isEnabled, isTrue);
    expect(controller.isLocked, isTrue);
    expect(await controller.unlock('0000'), isFalse);
    expect(controller.isLocked, isTrue);
    expect(await controller.unlock('1234'), isTrue);
    expect(controller.isLocked, isFalse);
    expect(protection.visibleValues, [false, true]);
  });

  test('leaving the app relocks an enabled PIN', () async {
    final controller = PinController(
      storage: _MemoryPinStorage('1234'),
      contentProtection: _RecordingContentProtection(),
    );
    await controller.initialize();
    await controller.unlock('1234');

    controller.lock();

    expect(controller.isLocked, isTrue);
  });

  test('setting and removing a PIN updates secure storage and protection', () async {
    final storage = _MemoryPinStorage();
    final protection = _RecordingContentProtection();
    final controller = PinController(storage: storage, contentProtection: protection);
    await controller.initialize();

    await controller.setPin('9876');
    expect(storage.pin, '9876');
    expect(controller.verifyPin('9876'), isTrue);
    expect(controller.isEnabled, isTrue);

    await controller.removePin();
    expect(storage.pin, isNull);
    expect(controller.isEnabled, isFalse);
    expect(protection.enabledValues, [false, true, false]);
  });

  test('rejects PINs that are not exactly four digits', () async {
    final controller = PinController(
      storage: _MemoryPinStorage(),
      contentProtection: _RecordingContentProtection(),
    );

    await expectLater(controller.setPin('123'), throwsArgumentError);
    await expectLater(controller.setPin('12a4'), throwsArgumentError);
    await expectLater(controller.setPin('12345'), throwsArgumentError);
  });
}
