# Briques open source utilisees

StockTout s'appuie sur des projets eprouves, pas de code exotique :

| Besoin | Projet | Licence |
|---|---|---|
| Framework UI | Flutter (Google) | BSD-3 |
| Etat | Riverpod | MIT |
| Base locale | sqflite_common_ffi / sqlite3 (SQLite) | MIT / Public domain |
| Formats dates/monnaies | intl | BSD-3 |
| Export CSV | csv | MIT |
| Export PDF | pdf / printing | Apache-2.0 |
| Export Excel | excel | MIT |
| Fichiers | file_picker, path_provider, path | MIT / BSD |
| Fenetre desktop | window_manager | MIT |
| Infos version | package_info_plus | BSD-3 |
| Partage | share_plus | BSD-3 |
| IDs | uuid | MIT |
| CI | subosito/flutter-action, softprops/action-gh-release | MIT |

Tout est declare dans `pubspec.yaml`. `flutter pub get` suffit.
