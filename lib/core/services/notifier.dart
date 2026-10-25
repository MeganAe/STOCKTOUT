import 'dart:async';

import 'package:flutter/material.dart';

import 'expiry_service.dart';

/// Clé du ScaffoldMessenger racine : permet d'afficher un message depuis
/// n'importe où (moteur d'automatisation, tâches de démarrage).
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Notification d'une règle d'automatisation :
/// - message à l'écran (toutes plateformes) ;
/// - notification système sur Android (si la permission est accordée).
class AppNotifier {
  static void show(String title, String body) {
    final messenger = rootMessengerKey.currentState;
    if (messenger != null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('$title — $body'),
          duration: const Duration(seconds: 6),
        ));
    }
    unawaited(ExpiryNotifier.showNow(title, body));
  }
}
