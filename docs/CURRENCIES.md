# Devises

## Devises incluses

| Code | Symbole | Nom |
|---|---|---|
| USD | $ | Dollar americain |
| EUR | € | Euro |
| CDF | FC | Franc congolais |
| XAF | FCFA | Franc CFA (CEMAC) |
| XOF | FCFA | Franc CFA (UEMOA) |

## Devise de la boutique

**Parametres** > **Devise** > bouton **Defaut** sur la monnaie voulue.
C'est elle qui sert de base pour les taux et l'affichage.

## Taux

Le taux = valeur d'**une unite de la devise de base** dans cette monnaie... non.
Plus simple, avec un exemple :

- Base = USD.
- 1 USD = 2 850 CDF -> taux CDF = **2850**.
- 1 USD = 0,92 EUR -> taux EUR = **0.92**.

Conversion : `montant / tauxDepart * tauxArrivee`.

Mettez vos taux a jour quand le marche bouge : crayon a cote de la devise.

## Ajouter une monnaie

**Parametres** > **Devise** > **Devise** : code (NGN, KES, GHS...),
symbole, nom, taux. Elle est utilisable partout aussitot.

## Affichage

CDF, XAF, XOF : zero decimale (on ne paie pas en centimes de franc).
USD, EUR : deux decimales. Modifiable dans le code (`decimals`).
