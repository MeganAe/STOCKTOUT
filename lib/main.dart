import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/database/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SQLite via FFI sur toutes les plateformes (dont Android).
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Bureau : fenetre dimensionnee, centree sur l'ecran, barre de titre
  // integree. On affiche seulement une fois le contenu pret, pour eviter
  // le saut de fenetre au demarrage.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    const options = WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(1024, 640),
      center: true,
      title: 'StockTout',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await _centerOnScreen();
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await AppDatabase.instance.init();

  runApp(const ProviderScope(child: StockToutApp()));
}

/// Recentre la fenetre dans l'ecran visible.
/// Apres le dimensionnement, `center()` gere les multi-ecrans et les
/// barres systeme mieux qu'un simple placement par defaut.
Future<void> _centerOnScreen() async {
  try {
    await windowManager.center();
  } catch (_) {
    // Si la plateforme refuse, la fenetre reste centree par `center: true`.
  }
}
