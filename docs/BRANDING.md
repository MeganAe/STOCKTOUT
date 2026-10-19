# Identite visuelle — StockTout

## Logo

Blason bleu profond, cartons blancs empiles, un carton ambre au sommet :
le stock, bien range, qui rapporte.

- Fichier maitre : `assets/icons/logo_master_1024.png`
- Script source : `scripts/gen_icons.py` (relancer apres modif, le design
  est 100 % vectoriel-code, pas d'image externe)
- In-app : `assets/images/logo.png`

## Couleurs

| Role | Nom | Hex |
|---|---|---|
| Primaire | Bleu StockTout | `#1B4D8F` |
| Fonce (degrade logo) | Bleu nuit | `#13386E` |
| Accent | Ambre carton | `#F5A623` |
| Texte clair | Blanc | `#FFFFFF` |

Le theme de l'app (`lib/core/theme/app_theme.dart`) utilise le bleu
comme couleur source Material 3.

## Icones systeme

| OS | Fichier | Genere par |
|---|---|---|
| Windows | `windows/runner/resources/app_icon.ico` | `gen_icons.py` |
| macOS | `macos/.../AppIcon.appiconset/app_icon_*.png` | `gen_icons.py` |
| Linux | `assets/icons/png/appicon_*.png` + `packaging/linux/stocktout.desktop` | `gen_icons.py` |

## Regles d'usage

- Ne pas etirer, ne pas changer les couleurs, ne pas ajouter d'ombre portee.
- Taille mini : 16 px (le dessin reste lisible).
- Zone de protection : un demi-carton autour du blason.
- Le logo seul (sans texte) sert d'icone ; avec le nom "StockTout" a cote
  dans l'app (menu lateral, A propos).
