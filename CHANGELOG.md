# Changelog

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
