import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stocktout/app.dart';
import 'package:stocktout/core/database/database.dart';
import 'package:stocktout/widgets/feature_tour.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;
}

void main() {
  testWidgets('StockTout demarre et affiche le tableau de bord',
      (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    PathProviderPlatform.instance = FakePathProviderPlatform();
    // Les astuces d'ouverture ne doivent pas s'inviter dans les tests.
    TourSession.enabled = false;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Travail SQLite reel : hors de la fausse horloge des tests.
    await tester.runAsync(() => AppDatabase.instance.init());

    await tester.pumpWidget(const ProviderScope(child: StockToutApp()));
    // L'écran de verrouillage lit la base (E/S réelles) : on lui laisse
    // le temps de répondre hors de la fausse horloge des tests.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Tableau de bord'), findsWidgets);
    // Purge les timers internes des packages (disposal differe...).
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(minutes: 10));
  });
}
