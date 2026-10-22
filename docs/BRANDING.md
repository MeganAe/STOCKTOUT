# Identite visuelle — StockTout

## Logo

Trois couches empilees (blanc, bleu clair, bleu nuit) sur fond bleu roi :
le stock, bien range, en un clin d'oeil.

- Fichier maitre : `assets/icons/icon_master.png` (icone creee par
  l'auteur, 512 px — ne pas la redessiner, la remplacer si besoin)
- Scripts : `scripts/gen_icons.py` (bureau + in-app) et
  `scripts/gen_android_icons.py` (Android). Relancer apres remplacement
  du maitre, commiter les fichiers generes.
- In-app : `assets/images/logo.png` (A propos, tutoriel)

## Couleurs

| Role | Nom | Hex |
|---|---|---|
| Fond icone / splash | Bleu roi | `#1D4ED8` |
| Couche basse logo | Bleu nuit | `#0B1F4D` env. |
| Texte clair | Blanc | `#FFFFFF` |

Le theme de l'app (`lib/core/theme/app_theme.dart`) utilise le bleu
comme couleur source Material 3.

## Icones systeme

| OS | Fichier | Genere par |
|---|---|---|
| Windows | `windows/runner/resources/app_icon.ico` | `gen_icons.py` |
| macOS | `macos/.../AppIcon.appiconset/app_icon_*.png` | `gen_icons.py` |
| Linux | `assets/icons/png/appicon_*.png` + `packaging/linux/stocktout.desktop` | `gen_icons.py` |
| Android | `android/.../res/mipmap-*/ic_launcher*` + splash | `gen_android_icons.py` |

## Regles d'usage

- Ne pas etirer, ne pas changer les couleurs, ne pas ajouter d'ombre portee.
- Taille mini : 16 px (le dessin reste lisible).
- Le logo seul (sans texte) sert d'icone ; avec le nom "StockTout" a cote
  dans l'app (menu lateral, A propos).
