import 'dart:io';

import 'package:flutter/services.dart';

/// Android : FLAG_SECURE (masque le contenu dans les applications récentes
/// et bloque les captures d'écran). Ne fait rien ailleurs.
class SecureScreen {
  static const _channel = MethodChannel('stocktout/secure');

  static Future<void> set(bool on) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'secure': on});
    } catch (_) {
      // Canal absent (tests) : sans effet.
    }
  }
}
