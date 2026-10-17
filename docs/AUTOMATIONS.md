# Automatisations

## Principe

Une regle = **un declencheur** + **une ou plusieurs actions**.
Quand l'evenement arrive, le moteur (`AutomationEngine`) execute les actions
des regles actives.

## Declencheurs

| Code | Quand |
|---|---|
| `stock_low` | Un produit passe sous son seuil mini |
| `out_of_stock` | Un produit tombe a zero |
| `sale_created` | Une vente est encaisee |
| `product_expiry` | Un produit approche sa date limite |
| `daily_report` | Rapport quotidien (a brancher sur un planificateur) |
| `scheduled` | Tache planifiee generique |

## Actions

| Code | Effet |
|---|---|
| `notify` | Message dans l'application |
| `create_purchase_draft` | Brouillon de commande pour le produit concerne |
| `export_csv` | Export des ventes (rapport du jour) |
| `print_report` | Impression / PDF |
| `adjust_price` | Reserve (regles de prix, a venir) |
| `webhook` | Reserve (appel HTTP, a venir) |

## Regles par defaut

1. **Alerte stock bas** : `stock_low` -> `notify`.
2. **Brouillon commande auto** : `out_of_stock` -> `create_purchase_draft` + `notify`.
3. **Rapport quotidien 18h** : `daily_report` -> `export_csv`.

## Creer une regle

**Automatisations** > **Nouvelle regle** : nom, declencheur, actions.
Activer / couper avec l'interrupteur.

## Ajouter un declencheur (dev)

1. Ajoutez une valeur a `AutoTrigger` dans `lib/core/models/automation.dart`.
2. Appelez `engine.fire(MonTrigger.nouveau, product: p)` a l'endroit voulu.
3. C'est tout, les regles existantes continuent de marcher.
