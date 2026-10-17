import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/database/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop : SQLite via FFI + taille fenetre correcte.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(1024, 640),
        center: true,
        title: 'StockPro',
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  await AppDatabase.instance.init();

  runApp(const ProviderScope(child: StockProApp()));
}
