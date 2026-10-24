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
    // AppShell relit 'tips_enabled' au démarrage et écraserait
    // TourSession.enabled = false : on le désactive aussi dans les réglages.
    SharedPreferences.setMockInitialValues(
        {'onboarding_done': true, 'tips_enabled': false});
    // Écran de bureau assez grand (Linux = mise en page bureau) : évite les
    // débordements (RenderFlex overflow) qui font échouer le test.
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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
    // Les fournisseurs (réglages, verrou, produits, ventes) lisent la base :
    // on alterne vraie attente et images pour qu'ils aient tous répondu.
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Tableau de bord'), findsWidgets);
    // Purge les timers internes des packages (disposal differe...).
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(minutes: 10));
  });
}
