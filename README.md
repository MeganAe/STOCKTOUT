# StockTout

Logiciel de gestion de stock pour tout type de commerce : boutique, depot, pharmacie, quincaillerie, alimentation, PME.

Fonctionne **hors-ligne**. Vos donnees restent sur votre machine (base SQLite locale).

Windows, macOS et Linux. Intel/AMD et ARM.

## Ce que fait le logiciel

- **Produits** : reference, code-barres, categorie, prix d'achat / vente, seuil mini.
- **Stock** : entrees, sorties, ajustements, pertes, historique par produit.
- **Ventes** : caisse simple et rapide, ticket, moyens de paiement.
- **Achats** : commandes fournisseurs, reception, mise a jour auto du stock.
- **Clients & fournisseurs** : carnet d'adresses.
- **Rapports** : valeur du stock, ventes, export CSV / PDF, impression.
- **Automatisations** : alerte stock bas, brouillon de commande en rupture, rapport quotidien, regles perso.
- **27 langues** : francais, anglais, espagnol, allemand, italien, portugais, neerlandais, russe, chinois, japonais, coreen, arabe, hindi, turc, polonais, suedois, danois, norvegien, finnois, grec, tcheque, roumain, hongrois, indonesien, swahili, lingala, ukrainien.
- **Devises** : USD, EUR, CDF (FC), XAF / XOF (FCFA) incluses. Taux modifiables, devises perso ajoutables.

## Telechargement

Allez dans **Releases** sur GitHub et prenez le fichier pour votre systeme :

| Systeme | Fichier |
|---|---|
| Windows x64 | `stocktout-windows-x64-VERSION.zip` |
| macOS Intel | `stocktout-macos-x64-VERSION.zip` |
| macOS Silicon | `stocktout-macos-arm64-VERSION.zip` |
| Linux x64 | `stocktout-linux-x64-VERSION.tar.gz` |

> Non inclus pour l'instant : Windows ARM64 (le runner ARM n'a que
> VS2026, non reconnu par Flutter 3.24) et Linux ARM64 (pas de SDK
> officiel). A re-essayer apres montee de version Flutter.

Installation : voir [docs/BUILD.md](docs/BUILD.md).

## Lancer en dev

```bash
flutter pub get
flutter run -d windows   # ou macos / linux
```

Genere les dossiers natifs s'ils manquent :

```bash
flutter create --platforms=windows,macos,linux .
```

## Compiler une release (manuel)

Tout se fait depuis GitHub, sans rien installer :

1. Poussez le code sur `main`.
2. Onglet **Actions** > **Release** > **Run workflow**.
3. Choisissez les plateformes, lancez.
4. La release est publiee directement avec les 4 fichiers (ou en
   brouillon si vous avez mis `draft: true` — a publier dans l'onglet
   Releases).

Detail : [docs/BUILD.md](docs/BUILD.md).

## Docs

- [Guide utilisateur (FR)](docs/USER_GUIDE_FR.md)
- [User guide (EN)](docs/USER_GUIDE_EN.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Automatisations](docs/AUTOMATIONS.md)
- [Devises](docs/CURRENCIES.md)
- [Compilation & releases](docs/BUILD.md)

## Technique

Flutter + Dart (Material 3), SQLite local, Riverpod.
Module de calcul `packages/stocktout_engine` en pur Dart (testable partout).
Scripts outillage en Python (`scripts/`).

## Licence

Voir [LICENSE](LICENSE).
