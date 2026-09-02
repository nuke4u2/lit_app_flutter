import 'package:flutter/services.dart';

abstract interface class ContentProtection {
  Future<void> setPrivacyEnabled(bool enabled);

  Future<void> setContentVisible(bool visible);
}

class PlatformContentProtection implements ContentProtection {
  static const _channel = MethodChannel('com.example.lit_reader/privacy');

  @override
  Future<void> setPrivacyEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setPrivacyEnabled', {'enabled': enabled});
    } on MissingPluginException {
      // Allows controller and widget tests to run without an Android host.
    }
  }

  @override
  Future<void> setContentVisible(bool visible) async {
    try {
      await _channel.invokeMethod<void>('setContentVisible', {'visible': visible});
    } on MissingPluginException {
      // Allows controller and widget tests to run without an Android host.
    }
  }
}
