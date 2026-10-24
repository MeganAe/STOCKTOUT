# StockTout V5 — journal des changements

## ⚠️ À lire d'abord : ce qui a été vérifié, et ce qui ne l'a PAS été

Flutter ne peut pas être installé dans l'environnement où ce travail a été fait
(le SDK et les paquets pub.dev sont inaccessibles). **Aucune de ces commandes n'a
donc été exécutée : `flutter pub get`, `flutter analyze`, `flutter test`,
`flutter build apk`.** Le code des écrans (UI) n'a jamais été compilé.

Ce qui a réellement été exécuté :
- `dart format` sur tout `lib/` et `test/` : aucune erreur de syntaxe.
- **41 tests Dart purs** (`test/logic_test.dart`, `test/backup_archive_test.dart`) : tous passent.
  Ils couvrent la logique métier (voir plus bas). Ils ont tourné avec un petit lanceur
  maison à la place de `flutter_test`, avec les vraies versions de `archive` 3.6.1 et `crypto`.
- La migration SQL v1 → v2 a été rejouée avec SQLite (Python) : tables créées, colonnes
  ajoutées, données conservées, relance idempotente, `VACUUM INTO` fonctionnel.
- Contrôles par script : toutes les clés de texte `t.xxx` existent, imports de textes présents,
  aucun import inutilisé dans les fichiers touchés.

**Première chose à faire de votre côté :**
```
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```
Si `flutter analyze` signale des erreurs, elles viendront presque sûrement de l'UI
(signatures de paquets non vérifiées) : envoyez-moi la sortie et je corrige.

## Points de risque connus (à vérifier en priorité)
1. **Nouvelles dépendances** (versions choisies pour Flutter 3.24.3, non résolues) :
   `image_picker ^1.1.2`, `mobile_scanner ^5.2.3`, `local_auth ^2.3.0`,
   `flutter_local_notifications ^17.2.2`, `app_settings ^5.1.1`, plus `archive ^3.6.1` et
   `crypto ^3.0.3` (déjà présents dans `pubspec.lock`). Appels à valider à la compilation :
   `MobileScanner(errorBuilder:)`, `MobileScannerException.errorCode`, `periodicallyShow(androidScheduleMode:)`,
   `AuthenticationOptions`.
2. **Android** : `build.gradle` (desugaring, requis par flutter_local_notifications),
   `MainActivity` passe à `FlutterFragmentActivity` (requis par local_auth), les deux
   `styles.xml` passent à un thème `Theme.AppCompat.*.NoActionBar` (requis par l'empreinte).
   Si le build Android échoue, c'est la première piste ; l'empreinte est facultative.
3. `Excel.decodeBytes` (paquet `excel`) n'était jamais utilisé avant : lecture vérifiée dans
   son code source, mais pas exécutée.

## Fonctionnalités

### 1. Sauvegarde automatique et restauration
- Format `.zip` : `stocktout.db` (copie cohérente via `VACUUM INTO`) + `product_images/`.
- Quotidienne au démarrage et au retour au premier plan, 7 sauvegardes conservées
  (`stocktout-backup-AAAAMMJJ-HHMMSS.zip` dans `<documents>/stocktout/backups/`). Interrupteur dans Réglages.
- Sauvegarde manuelle, partage (WhatsApp/e-mail/Drive), restauration depuis la liste ou un fichier.
- La restauration valide le fichier, **crée d'abord une copie « avant restauration »**, remplace base + photos,
  rouvre la base (une ancienne base v1 est migrée) et recharge tous les providers.
- Les anciens `.db` bruts restent restaurables.
- Fichiers : `backup_archive.dart` (zip, testé), `backup_service.dart`, `backup_logic.dart` (rotation, testée).

### 2. Dettes clients et paiements partiels
- Tables `payments` ; colonne `sales.paid`. Migration : ventes non « crédit » = payées en totalité, « crédit » = 0 payé.
- Caisse : sélecteur de client (recherche + création rapide), champ « payé maintenant » en crédit, cash partiel
  (reste dû affiché). Une vente non soldée **exige un client**.
- Écran Dettes (menu Plus / menu latéral) : débiteurs triés, détail par client, encaissement réparti sur les
  ventes les plus anciennes d'abord, historique, rappel à partager. Carte « Dettes » sur le tableau de bord.
- Annuler une vente supprime aussi ses paiements.
- **Écart avec le prompt** : le code utilise `kind = 'customer'` (et non « client »), conformément à l'existant.

### 3. Import CSV / Excel
- Écran Produits → icône d'import. Séparateur auto (`,` `;` tabulation), BOM, guillemets, virgule décimale,
  association automatique des colonnes (fr/en), modèle CSV téléchargeable, choix « mettre à jour / ignorer »
  pour les doublons (référence ou code-barres), aperçu avec erreurs par ligne, import par lots avec progression.
- Référence et code-barres générés comme dans le formulaire (code partagé : `product_codes.dart`).
- `.xls` (ancien Excel) non géré : `.csv` et `.xlsx` seulement.

### 4. Bénéfice et statistiques
- `SaleLine.cost` enregistré à la vente. Anciennes ventes sans coût : repli sur le prix d'achat actuel du produit.
- Rapports : périodes (aujourd'hui / 7 j / 30 j / mois / personnalisée), CA, coût, bénéfice brut et marge,
  dépenses, bénéfice net, nombre de ventes, panier moyen, remises, courbe du CA, top 10 (quantité ou bénéfice),
  produits dormants (30 j). Toutes les devises converties dans la devise par défaut.

### 5. Code PIN
- 4 à 6 chiffres, hash SHA-256 salé (jamais en clair), pavé numérique, blocage progressif après 5 erreurs
  (30 s, 1 min, 5 min, 15 min, 1 h), verrouillage auto (immédiat / 1 / 5 / 15 min), empreinte facultative,
  option « masquer dans les récents » (FLAG_SECURE).
- « PIN oublié » = **réinitialisation complète** avec double confirmation (le PIN n'est pas récupérable).
- Limite connue : le blocage s'appuie sur l'horloge de l'appareil.

### 6. Scan de codes-barres
- Caméra (caisse en mode rafale, fiche produit, liste des produits) + lecteur USB/Bluetooth (touche Entrée
  dans la recherche de la caisse). Recherche exacte, anti-rebond 2 s, vibration + clic système, lampe, permission
  refusée → bouton vers les réglages, code inconnu → proposition de créer le produit.

### 7. Dépenses
- Écran Dépenses (catégories prédéfinies + libre, devise, date), total mensuel, déduit du bénéfice net.

### 8. Péremption
- Date de péremption dans la fiche produit, pastille orange/rouge dans la liste, cartes « Expire bientôt »
  et « Périmés » (touchables) sur le tableau de bord, confirmation à la vente d'un produit périmé,
  délai réglable (7–90 j), déclenchement de l'automatisation `productExpiry` une fois par jour.
- Notification quotidienne facultative (Android, `periodicallyShow`) : **son texte est calculé à l'ouverture
  de l'application**, il peut donc être un peu en retard.

### 9. Photos des produits
- Caméra ou galerie (800 px max, qualité 80), stockées dans `product_images/<id>.jpg`, incluses dans les
  sauvegardes, miniatures dans la liste et la caisse, suppression du fichier avec le produit. La photo
  choisie n'est enregistrée qu'au « Enregistrer » (annuler ne change rien).

## Correction au passage
- Le formulaire produit **effaçait** fournisseur, emplacement et notes à chaque modification : ils sont désormais conservés.

## Changements notables d'architecture
- Base en **version 2** (`schema.dart`) ; une installation neuve passe par le même chemin que la mise à jour.
- Nouveau dossier `lib/core/logic/` : logique pure (sans Flutter), testable.
- Textes : `lib/core/l10n/v5_strings.dart` (français + anglais ; les autres langues retombent sur l'anglais).
- `test/widget_test.dart` : ajout d'une attente réelle de 500 ms (l'écran de verrouillage lit la base au démarrage).
- Les fichiers touchés ont été passés à `dart format`, d'où des diffs plus larges que les changements réels.
