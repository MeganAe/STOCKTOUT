# Architecture

## Vue d'ensemble

```
lib/
  main.dart          # init SQLite + fenetre + runApp
  app.dart           # MaterialApp, theme, locales
  core/
    theme/           # Material 3 clair/sombre
    database/        # SQLite (sqflite_common_ffi), DAO + seed
    models/          # Product, Sale, Movement, Currency, Automation
    services/        # devises, automatisations, rapports, sauvegarde
    providers/       # Riverpod : reglages, services, donnees
    l10n/            # 27 langues (genere par scripts/gen_l10n.py)
  features/          # un dossier par ecran
  widgets/           # coquille (NavigationRail)
```

## Choix techniques

- **Flutter + Dart** : un seul code pour Windows, macOS, Linux.
- **Material 3** : composants standards, pas de design custom fragile.
- **SQLite local** : pas de serveur, marche sans internet, sauvegarde = copie d'un fichier.
- **Riverpod** : etat simple et testable.
- **Traductions embarquees** : pas de codegen, 27 langues dans un seul fichier genere.
  Source de verite : `scripts/gen_l10n.py`.

## Base de donnees

Fichier : `<Documents>/stocktout/stocktout.db`

Tables : `products`, `movements`, `sales`, `purchases`, `partners`,
`currencies`, `automations`, `settings`.

Les quantites sont recalculees a chaque mouvement dans `addMovement()`.
Les ventes stockent leurs lignes en JSON (simple, suffisant a cette echelle).

## Module `packages/stocktout_engine`

Logique de calcul pure Dart, sans Flutter : marges, valorisation, seuils,
conversion de devises. Utilisable dans l'app, dans les tests, ou dans un futur
service serveur. Voir `packages/stocktout_engine/`.

## Evolutions prevues

- Roles utilisateurs + mot de passe.
- Synchro optionnelle (serveur ou dossier partage).
- Etiquettes code-barres + impression thermique.
- Paquet `.deb` / `.msix` signes.
- API REST locale pour connecter une boutique en ligne.
