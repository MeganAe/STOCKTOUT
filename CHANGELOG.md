# Changelog

## 1.3.0 — 2026-10-19

- Installeur Windows (Setup.exe, Inno Setup, sans admin, FR/EN).
- Images disque macOS (DMG glisser-deposer) Intel + Silicon.
- ZIP et archives conserves en plus.

## 1.2.0 — 2026-10-19

- Identite visuelle : logo StockTout, icones Windows/macOS/Linux.
- Menu lateral pliable (icones seules / icones + textes), memorise.
- Tutoriel de premier lancement (5 ecrans) + produits d'exemple.
- A propos : logo + auteur.

## 1.1.0 — 2026-10-19

- Renommage : StockPro devient StockTout (app, binaires, paquet).
- Barre de titre integree facon apps modernes (glisser, double-clic,
  boutons Windows/Linux, feux macOS conserves).
- A propos : auteur Metoushela Walker.
- Release : publication directe par defaut (draft en option).
- Note : nouveau fichier de donnees stocktout.db (pas de migration
  de l'ancien stockpro.db).

## 1.0.4 — 2026-10-19

- Fix workflow invalide : `publish` ne depend plus du job supprime.
- Workflow Release re-ecrit au propre (4 builds : win-x64, mac-x64,
  mac-arm64, linux-x64, runners epingles).

## 1.0.3 — 2026-10-18

- Fix windows-x64 : runner epingle windows-2022 (VS2026 non reconnu).
- Fix macos-x64 : macos-13 retire -> macos-15-intel.
- Fix macos-arm64 : macos-14 -> macos-15 (retrait nov. 2026).
- Fix linux-x64 : deps natives inutilisees retirees (tray_manager...).
- Retrait windows-arm64 (VS2026 uniquement sur ce runner).

## 1.0.2 — 2026-10-18

- Fix Release : vrais dossiers natifs windows/macos/linux (flutter create).
- Fix windows-arm64 : SDK x64 (le seul publie), build ARM64 natif.
- Retrait linux-arm64 : pas de SDK Linux ARM64 officiel.
- macOS : app renommee StockPro.app.

## 1.0.1 — 2026-10-18

- Fix CI : formatage, fichier de traductions regenere correctement.
- Fix analyse : import inutile, variable inutile, `CardTheme` compatible.
- Retrait de la regle `require_trailing_commas` (bruit).

## 1.0.0 — 2026-10-18

- Produits, stock, caisse, achats, clients/fournisseurs.
- Rapports CSV / PDF / impression.
- Automatisations (stock bas, rupture, rapport jour) + regles perso.
- 27 langues, 5 devises de base + devises perso.
- Windows / macOS / Linux, x64 + ARM64 via workflow manuel.
- Sauvegarde / restauration locale.
