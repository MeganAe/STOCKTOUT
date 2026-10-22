import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stocktout/widgets/feature_tour.dart';

void main() {
  testWidgets('la visite guidee s ouvre sur la cible puis se ferme',
      (tester) async {
    TourSession.enabled = true;
    TourSession.resetAll();
    final k = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: GuidedTour(
          id: 'test_screen',
          steps: [
            TourStep(target: k, title: 'Title', body: 'Body text'),
          ],
          child: Scaffold(
            body: Center(
              child: SizedBox(
                key: k,
                width: 120,
                height: 40,
                child: const Text('target'),
              ),
            ),
          ),
        ),
      ),
    );

    // Delai d'ouverture (600 ms) + transition de la feuille.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Body text'), findsOneWidget);

    // Fermeture par "Skip" (libelle anglais par defaut ici).
    await tester.tap(find.text('Skip tour'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
  });
}
