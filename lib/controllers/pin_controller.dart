import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lit_reader/classes/content_privacy.dart';

abstract interface class PinStorage {
  Future<String?> readPin();

  Future<void> writePin(String pin);

  Future<void> deletePin();
}

class SecurePinStorage implements PinStorage {
  static const _pinKey = 'app_lock_pin';
  final FlutterSecureStorage _storage;

  SecurePinStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(aOptions: AndroidOptions());

  @override
  Future<String?> readPin() => _storage.read(key: _pinKey);

  @override
  Future<void> writePin(String pin) => _storage.write(key: _pinKey, value: pin);

  @override
  Future<void> deletePin() => _storage.delete(key: _pinKey);
}

class PinController extends ChangeNotifier {
  PinController({PinStorage? storage, ContentProtection? contentProtection})
      : _storage = storage ?? SecurePinStorage(),
        _contentProtection = contentProtection ?? PlatformContentProtection();

  final PinStorage _storage;
  final ContentProtection _contentProtection;

  String? _pin;
  bool _isLocked = false;
  bool _isInitialized = false;

  bool get isEnabled => _pin != null;
  bool get isLocked => isEnabled && _isLocked;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _pin = await _storage.readPin();
    _isLocked = _pin != null;
    _isInitialized = true;

    await _contentProtection.setPrivacyEnabled(isEnabled);
    await _contentProtection.setContentVisible(!isLocked);
    notifyListeners();
  }

  bool isValidPinFormat(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);

  Future<void> setPin(String pin) async {
    if (!isValidPinFormat(pin)) {
      throw ArgumentError.value(pin, 'pin', 'PIN must contain exactly four digits');
    }

    await _storage.writePin(pin);
    _pin = pin;
    _isLocked = false;
    await _contentProtection.setPrivacyEnabled(true);
    await _contentProtection.setContentVisible(true);
    notifyListeners();
  }

  Future<void> removePin() async {
    await _storage.deletePin();
    _pin = null;
    _isLocked = false;
    await _contentProtection.setPrivacyEnabled(false);
    await _contentProtection.setContentVisible(true);
    notifyListeners();
  }

  bool verifyPin(String pin) => isValidPinFormat(pin) && pin == _pin;

  Future<bool> unlock(String pin) async {
    if (!verifyPin(pin)) {
      return false;
    }

    _isLocked = false;
    notifyListeners();
    await _contentProtection.setContentVisible(true);
    return true;
  }

  void lock() {
    if (!isEnabled) {
      return;
    }

    final wasLocked = _isLocked;
    _isLocked = true;
    _contentProtection.setContentVisible(false);
    if (!wasLocked) {
      notifyListeners();
    }
  }
}
