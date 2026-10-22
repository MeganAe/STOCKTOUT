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

  try {
    await AppDatabase.instance.init();
  } catch (e, st) {
    // Affiche l'erreur au lieu de rester bloque sur le splashscreen.
    runApp(_StartupError(error: '$e\n\n$st'));
    return;
  }

  runApp(const ProviderScope(child: StockToutApp()));
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: SelectableText(
                'Erreur au demarrage de StockTout :\n\n$error',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
