# StockTout — Phase 0 (correctifs de fond)

Commit séparé, par-dessus le commit « V5 ». Mêmes réserves que pour la V5 :
**Flutter n'a pas pu être installé ici**, donc `flutter pub get / analyze / test / build apk`
n'ont PAS été exécutés et le code des écrans n'a jamais été compilé. Vérifié par exécution :
`dart format` sans erreur, **45 tests Dart purs** qui passent (dont 4 nouveaux sur les achats),
contrôles par script (clés de texte, doublons, imports).

> Le « fichier de spécification mis à jour » cité dans votre message n'était pas joint
> (seul `PROMPT_STOCKTOUT_9_FONCTIONNALITES.md` du 23/10 est présent). J'ai travaillé
> d'après le texte de votre message ; renvoyez le fichier si d'autres exigences y figurent.

## Point 1 — valeurs de `partners.kind`
**Fait.** Le code n'utilise que `'customer'` et `'supplier'` : sélecteur client/fournisseur
(`customer_picker.dart`, `database.dart`), écran Partenaires, table des dettes (via les ventes,
qui portent `customer_id`). Aucune occurrence de « client » / « fournisseur » comme valeur.

## Statut des points de la phase 0

| Point | Statut | Détail |
|---|---|---|
| Sauvegarde / restauration | **Fait** (non compilé) | Voir ci-dessous |
| Automatisations — notifications | **Fait** (non compilé) | `onNotify` branché |
| Automatisations — `productExpiry`, `dailyReport` | **Fait** (non compilé) | déclenchés 1×/jour au démarrage |
| Automatisations — actions | **Partiel** | `exportCsv` implémentée ; `printReport`, `adjustPrice`, `webhook` désactivées dans l'UI |
| Automatisations — déclencheur `scheduled` | **Non fait (désactivé)** | pas de planificateur ni d'horaire ; masqué dans l'UI |
| Mouvements de stock | **Fait** (non compilé) | création, modification, import |
| Achats | **Fait**, sauf annulation d'un achat déjà reçu | voir ci-dessous |
| Partenaires | **Fait** (non compilé) | confirmation de suppression + modification |

### Sauvegarde / restauration — fait
Ces défauts étaient déjà traités par la V5 (`backup_service.dart`, `v5_settings_cards.dart`) :
- plus d'écriture dans un dossier choisi : la sauvegarde va dans le dossier privé de l'application
  (aucune permission, fonctionne sur Android 11+) puis se **partage** (WhatsApp, e-mail, Drive) ;
- restauration : validation du fichier (zip contenant `stocktout.db`, ou `.db` SQLite contenant la
  table `products`), copie de sécurité « avant restauration », **fermeture** de la base, remplacement,
  **réouverture** (migration v1→v2 automatique), invalidation de tous les providers.
Limite : je n'ai pas pu tester la restauration sur un appareil.

### Automatisations
- `onNotify` est fourni (`automationEngineProvider`) : message à l'écran (SnackBar, toutes
  plateformes) + notification système sur Android (permission demandée une fois si besoin).
- `productExpiry` : une fois par jour au démarrage ; une seule notification groupée (pas 30). Une règle
  « Alerte péremption » est ajoutée une fois, y compris aux installations existantes.
- `dailyReport` : une fois par jour au démarrage (pas d'exécution en arrière-plan : l'application doit
  être ouverte).
- `exportCsv` : écrit `stock_AAAA-MM-JJ.csv` dans `<documents>/stocktout/exports/` et l'indique dans la notification.
- Désactivés clairement (case grisée « Non disponible pour le moment », et avertissement sur les
  règles concernées) : `printReport`, `adjustPrice`, `webhook` (aucun réglage ni exécution possible
  aujourd'hui) et le déclencheur `scheduled`. Le moteur les ignore.
- Le brouillon d'achat automatique utilise désormais le nouveau format d'achat (fournisseur du produit,
  devise par défaut, coût = prix d'achat).

### Mouvements de stock — fait
`saveProductWithStock` (une transaction) : création avec quantité > 0 → entrée « Stock initial » ;
modification de la quantité → ajustement « Correction manuelle (ancien → nouveau) ». Si la quantité
n'est pas touchée dans le formulaire, la quantité actuelle de la base est conservée (une vente
intermédiaire n'est plus écrasée). L'import CSV/Excel enregistre aussi ses entrées/ajustements.

### Achats — refaits
- Plusieurs lignes, JSON propre (`jsonDecode`, plus de regex ; l'ancien format `qty` est relu).
- Coût unitaire par ligne ; devise = devise par défaut ; fournisseur choisi dans `partners`
  (`kind = 'supplier'`, création rapide).
- Réception : transaction unique ; le passage `draft → received` est une requête conditionnelle faite
  **en premier**, donc un double appui ou une seconde réception ne fait rien. `buy_price` du produit
  mis à jour (coût converti dans la devise par défaut si besoin). Confirmation avant réception.
- Annulation : **brouillons seulement** (sans effet sur le stock). L'annulation d'un achat déjà
  reçu n'est pas faite (elle imposerait de défaire le stock, parfois déjà vendu) : utiliser un ajustement.
- Anciens achats sans coût : leur réception n'altère pas le prix d'achat.

### Partenaires — fait
Confirmation avant suppression (avec nombre de ventes/achats liés, et avertissement si le client a
une dette : elle reste due et visible), modification d'un contact existant (nom, téléphone, e-mail,
adresse, notes).

## Pour tester côté Flutter
`flutter pub get`, `dart format lib test`, `flutter analyze --no-fatal-infos`, `flutter test`.
