# Guide utilisateur — StockTout

## Demarrer

1. Ouvrez l'application.
2. Allez dans **Parametres** : choisissez votre langue et votre devise.
3. Ajoutez vos produits dans **Produits** > **Nouveau produit**.
4. Faites vos ventes dans **Ventes** (caisse).

Au premier lancement, un tutoriel en 5 ecrans vous guide. Chargez les
produits d'exemple pour explorer sans risque (dont un en stock bas,
pour voir l'alerte). Rejouable dans **Parametres** > **Tutoriel**.

## Produits

- **Reference (SKU)** : votre code interne. Genere auto si vide.
- **Prix d'achat / vente** : servent a la marge et a la valeur du stock.
- **Stock mini** : seuil d'alerte. En dessous, le produit est signale.
- **Entree / sortie** (icone echange) : corriger le stock sans passer par une vente.

## Ventes (caisse)

1. Cliquez sur les produits pour les mettre dans le panier.
2. Choisissez le moyen de paiement.
3. **Encaisser**. Le stock est decremente tout seul.

## Achats

1. **Achats** > **Nouvel achat** : produit, quantite, fournisseur.
2. A reception : **Receptionner**. Le stock augmente tout seul.
3. Les ruptures peuvent creer des brouillons auto (voir Automatisations).

## Inventaire

Liste des produits a gauche, historique des mouvements a droite.
Chaque entree/sortie/ajustement est trace avec date et motif.

## Rapports

- **Export CSV** : ouvre dans Excel.
- **PDF / Imprimer** : etat du stock.
- **Valeur par categorie** : ou dort votre argent.

## Automatisations

Regles installees par defaut :

- Alerte quand un produit passe sous le seuil.
- Brouillon de commande en cas de rupture.
- Export des ventes du jour.

Vous pouvez en creer : declencheur (stock bas, vente, rapport...) + actions
(notifier, brouillon commande, export...). Detail : [AUTOMATIONS.md](AUTOMATIONS.md).

## Devises

USD, EUR, CDF, XAF, XOF deja presentes. Changez les taux dans
**Parametres** > **Devise**, ajoutez vos propres monnaies.
Detail : [CURRENCIES.md](CURRENCIES.md).

## Sauvegarde

**Parametres** > **Sauvegarder** : choisissez un dossier (cle USB, disque...).
**Restaurer** : reprenez un fichier `.db` sauvegarde, redemarrez l'app.
Faites une sauvegarde par semaine, minimum.

## Questions frequentes

**Ca marche sans internet ?** Oui, tout est local.

**Ou sont mes donnees ?** Dans `<Documents>/stocktout/stocktout.db`.

**Je change d'ordinateur ?** Sauvegardez, installez l'app sur le nouveau,
restaurez le fichier.

**Multi-utilisateur ?** Pas encore. Une personne a la fois par machine.
