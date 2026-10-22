# StockTout

Logiciel de gestion de stock pour tout type de commerce : boutique, depot, pharmacie, quincaillerie, alimentation, PME.

Fonctionne **hors-ligne**. Vos donnees restent sur votre machine (base SQLite locale).

Interface entierement traduite : menus, formulaires, dialogues, messages, exports et donnees d'exemple suivent la langue choisie. La fenetre s'ouvre centree sur l'ecran.

Windows, macOS, Linux et Android. Intel/AMD et ARM.

## Ce que fait le logiciel

- **Produits** : reference, code-barres, categorie, prix d'achat / vente, seuil mini.
- **Stock** : entrees, sorties, ajustements, pertes, historique par produit.
- **Ventes** : caisse simple et rapide, ticket, moyens de paiement.
- **Achats** : commandes fournisseurs, reception, mise a jour auto du stock.
- **Clients & fournisseurs** : carnet d'adresses.
- **Rapports** : valeur du stock, ventes, export CSV / PDF, impression.
- **Automatisations** : alerte stock bas, brouillon de commande en rupture, rapport quotidien, regles perso.
- **Typographie Inter** : police professionnelle embarquee (licence SIL OFL), tailles et interlignes regles pour la lecture ecran.
- **Visite guidee** : chaque ecran s'explique a la premiere ouverture (fleche, halo, Passer). Rejouable ou desactivable dans Parametres.
- **27 langues** : francais, anglais, espagnol, allemand, italien, portugais, neerlandais, russe, chinois, japonais, coreen, arabe, hindi, turc, polonais, suedois, danois, norvegien, finnois, grec, tcheque, roumain, hongrois, indonesien, swahili, lingala, ukrainien.
- **Devises** : USD, EUR, CDF (FC), XAF / XOF (FCFA) incluses. Taux modifiables, devises perso ajoutables.

## Telechargement

Allez dans **Releases** sur GitHub et prenez le fichier pour votre systeme :

| Systeme | Format | Fichier |
|---|---|---|
| Windows | Installeur (recommande) | `stocktout-windows-x64-VERSION-setup.exe` |
| Windows | Portable | `stocktout-windows-x64-VERSION.zip` |
| macOS Intel | DMG (recommande) | `stocktout-macos-x64-VERSION.dmg` |
| macOS Intel | ZIP | `stocktout-macos-x64-VERSION.zip` |
| macOS Silicon | DMG (recommande) | `stocktout-macos-arm64-VERSION.dmg` |
| macOS Silicon | ZIP | `stocktout-macos-arm64-VERSION.zip` |
| Linux | Archive | `stocktout-linux-x64-VERSION.tar.gz` |
| Linux | Paquet Ubuntu/Debian | `stocktout-linux-x64-VERSION-amd64.deb` |
| Android | APK | `stocktout-android-VERSION.apk` |
| Android | AAB Play Store (si keystore) | `stocktout-android-VERSION.aab` |

> Non inclus pour l'instant : Windows ARM64 (le runner ARM n'a que
> VS2026, non reconnu par Flutter 3.24) et Linux ARM64 (pas de SDK
> officiel). A re-essayer apres montee de version Flutter.

Installation : voir [docs/BUILD.md](docs/BUILD.md).

## Lancer en dev

```bash
flutter pub get
flutter run -d windows   # ou macos / linux / android (telephone ou emulateur)
```

Genere les dossiers natifs s'ils manquent :

```bash
flutter create --platforms=windows,macos,linux,android .
```

## Compiler une release (manuel)

Tout se fait depuis GitHub, sans rien installer :

1. Poussez le code sur `main`.
2. Onglet **Actions** > **Release** > **Run workflow**.
3. Choisissez les plateformes, lancez.
4. La release est publiee directement avec les 9 fichiers (setup,
   DMG, ZIP, archive, deb, APK — AAB en plus si keystore configure —
   ou en brouillon si `draft: true`).

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
