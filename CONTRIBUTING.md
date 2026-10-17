# Contribuer

## En bref

1. Fork + branche (`git checkout -b ma-fonction`).
2. `flutter pub get`, codez, `dart format lib test`, `flutter analyze`, `flutter test`.
3. Pull request vers `develop` avec une description claire.

## Regles

- Un ecran = un dossier dans `lib/features/`.
- Pas de texte en dur en francais/anglais dans l'UI : passez par `AppLocalizations`
  (ajoutez la cle dans `scripts/gen_l10n.py`, relancez le script).
- Toute modif de la base : monter `version` dans `AppDatabase` + migration `onUpgrade`.
- L'auteur n'est mentionne que dans l'ecran A propos.

## Traductions

Editez `scripts/gen_l10n.py`, lancez `python3 scripts/gen_l10n.py`.
Ca regenere le Dart + les 27 fichiers ARB d'un coup.
