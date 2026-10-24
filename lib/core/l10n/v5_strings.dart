import 'app_localizations.dart';

/// Textes de la version 5 (dettes, dépenses, import, scan, PIN, sauvegarde...).
/// Français et anglais ; les autres langues retombent sur l'anglais.
const _v5 = <String, Map<String, String>>{
  'debts': {'en': 'Customer debts', 'fr': 'Dettes clients'},
  'noDebts': {
    'en': 'No outstanding debts. Credit or partly paid sales will appear here.',
    'fr':
        'Aucune dette en cours. Les ventes à crédit ou payées en partie apparaîtront ici.'
  },
  'totalOwed': {'en': 'Total owed', 'fr': 'Total dû'},
  'debtors': {'en': '{0} debtor(s)', 'fr': '{0} client(s) débiteur(s)'},
  'openSales': {'en': '{0} unpaid sale(s)', 'fr': '{0} vente(s) impayée(s)'},
  'since': {'en': 'since {0}', 'fr': 'depuis le {0}'},
  'unpaidSales': {'en': 'Unpaid sales', 'fr': 'Ventes impayées'},
  'paymentHistory': {'en': 'Payment history', 'fr': 'Historique des paiements'},
  'recordPayment': {'en': 'Record a payment', 'fr': 'Encaisser un paiement'},
  'sendReminder': {'en': 'Send a reminder', 'fr': 'Envoyer un rappel'},
  'reminderMessage': {
    'en':
        'Hello {0}, a quick reminder: you still owe {1} to the shop. Thank you!',
    'fr':
        'Bonjour {0}, petit rappel : il vous reste {1} à régler à la boutique. Merci !'
  },
  'remainingDue': {'en': 'Remaining due: {0}', 'fr': 'Reste dû : {0}'},
  'amountPaid': {'en': 'Amount paid', 'fr': 'Montant payé'},
  'paymentTooHigh': {
    'en': 'Amount exceeds the debt ({0})',
    'fr': 'Le montant dépasse la dette ({0})'
  },
  'paymentSaved': {
    'en': 'Payment saved: {0}',
    'fr': 'Paiement enregistré : {0}'
  },
  'saleTotalPaid': {'en': 'total {0}, paid {1}', 'fr': 'total {0}, payé {1}'},
  'noteOptional': {'en': 'Note (optional)', 'fr': 'Note (facultatif)'},
  'paidNow': {'en': 'Amount paid now', 'fr': 'Montant payé maintenant'},
  'chooseCustomer': {'en': 'Choose a customer', 'fr': 'Choisir un client'},
  'partialDebtHint': {
    'en': 'Remaining: {0} — will be recorded as customer debt',
    'fr': 'Reste dû : {0} — sera enregistré comme dette du client'
  },
  'searchCustomer': {'en': 'Search a customer…', 'fr': 'Rechercher un client…'},
  'noCustomerFound': {'en': 'No customer found', 'fr': 'Aucun client trouvé'},
  'customerNameLabel': {'en': 'Customer name', 'fr': 'Nom du client'},
  'phoneOptional': {'en': 'Phone (optional)', 'fr': 'Téléphone (facultatif)'},
  'debtsTourTotal': {'en': 'Total debts', 'fr': 'Total des dettes'},
  'debtsTourTotalB': {
    'en': 'What your customers owe you in total, in the default currency.',
    'fr': 'Ce que vos clients vous doivent au total, dans la devise par défaut.'
  },
  'debtsTourList': {'en': 'Debtors list', 'fr': 'Liste des débiteurs'},
  'debtsTourListB': {
    'en':
        'Tap a customer to see unpaid sales, record a payment or send a reminder.',
    'fr':
        'Touchez un client pour voir ses ventes impayées, encaisser un paiement ou envoyer un rappel.'
  },
  'expenses': {'en': 'Expenses', 'fr': 'Dépenses'},
  'addExpense': {'en': 'Add an expense', 'fr': 'Ajouter une dépense'},
  'amount': {'en': 'Amount', 'fr': 'Montant'},
  'dateLabel': {'en': 'Date', 'fr': 'Date'},
  'customCategory': {
    'en': 'Other category (optional)',
    'fr': 'Autre catégorie (facultatif)'
  },
  'deleteExpenseAsk': {
    'en': 'Delete this expense?',
    'fr': 'Supprimer cette dépense ?'
  },
  'monthExpenses': {'en': 'Expenses this month', 'fr': 'Dépenses du mois'},
  'noExpenses': {
    'en': 'No expenses this month',
    'fr': 'Aucune dépense ce mois-ci'
  },
  'expensesTourTotal': {'en': 'Monthly expenses', 'fr': 'Dépenses du mois'},
  'expensesTourTotalB': {
    'en': 'Total for the displayed month. Use the arrows to change month.',
    'fr': 'Total du mois affiché. Utilisez les flèches pour changer de mois.'
  },
  'expensesTourAddB': {
    'en':
        'Record each expense (transport, rent…): it is deducted from your net profit.',
    'fr':
        'Notez chaque dépense (transport, loyer…) : elle sera déduite de votre bénéfice net.'
  },
  'profitStats': {
    'en': 'Profit and statistics',
    'fr': 'Bénéfice et statistiques'
  },
  'periodToday': {'en': 'Today', 'fr': 'Aujourd\'hui'},
  'period7': {'en': '7 days', 'fr': '7 jours'},
  'period30': {'en': '30 days', 'fr': '30 jours'},
  'periodMonth': {'en': 'This month', 'fr': 'Ce mois'},
  'periodCustom': {'en': 'Custom', 'fr': 'Personnalisée'},
  'revenue': {'en': 'Revenue', 'fr': 'Chiffre d\'affaires'},
  'costOfGoods': {'en': 'Cost of goods sold', 'fr': 'Coût des produits vendus'},
  'grossProfit': {'en': 'Gross profit', 'fr': 'Bénéfice brut'},
  'margin': {'en': 'Margin', 'fr': 'Marge'},
  'netProfit': {'en': 'Net profit', 'fr': 'Bénéfice net'},
  'salesCount': {'en': 'Number of sales', 'fr': 'Nombre de ventes'},
  'avgBasket': {'en': 'Average basket', 'fr': 'Panier moyen'},
  'discountsGiven': {'en': 'Discounts given', 'fr': 'Remises accordées'},
  'revenueEvolution': {
    'en': 'Revenue over time',
    'fr': 'Évolution du chiffre d\'affaires'
  },
  'topProducts': {'en': 'Top products', 'fr': 'Top produits'},
  'byQuantity': {'en': 'Quantity', 'fr': 'Quantité'},
  'byProfit': {'en': 'Profit', 'fr': 'Bénéfice'},
  'sold': {'en': 'Sold', 'fr': 'Vendu'},
  'dormantProducts': {
    'en': 'Dormant products: {0}',
    'fr': 'Produits dormants : {0}'
  },
  'dormantHint': {
    'en': 'In stock but not sold for 30 days',
    'fr': 'En stock mais sans vente depuis 30 jours'
  },
  'importProducts': {'en': 'Import products', 'fr': 'Importer des produits'},
  'importStep1': {'en': '1. Choose the file', 'fr': '1. Choisir le fichier'},
  'importStep2': {
    'en': '2. Match the columns',
    'fr': '2. Associer les colonnes'
  },
  'importStep3': {
    'en': '3. Check then import',
    'fr': '3. Vérifier puis importer'
  },
  'importHelp': {
    'en':
        'CSV or Excel (.xlsx) file. The first row must contain column names. Only the product name is required.',
    'fr':
        'Fichier CSV ou Excel (.xlsx). La première ligne doit contenir les noms des colonnes. Seul le nom du produit est obligatoire.'
  },
  'chooseFile': {'en': 'Choose a file', 'fr': 'Choisir un fichier'},
  'downloadTemplate': {
    'en': 'Download the template',
    'fr': 'Télécharger le modèle'
  },
  'rowsCount': {'en': '{0} row(s)', 'fr': '{0} ligne(s)'},
  'notImported': {'en': '— Do not import —', 'fr': '— Ne pas importer —'},
  'ifExists': {
    'en': 'If the product already exists (same SKU or barcode)',
    'fr': 'Si le produit existe déjà (même référence ou code-barres)'
  },
  'dupUpdate': {
    'en': 'Update the existing product',
    'fr': 'Mettre à jour le produit existant'
  },
  'dupSkip': {'en': 'Skip the row', 'fr': 'Ignorer la ligne'},
  'preview': {'en': 'Preview', 'fr': 'Aperçu'},
  'importNeedName': {
    'en': 'Match at least the “Product name” column.',
    'fr': 'Associez au moins la colonne « Nom du produit ».'
  },
  'importSummary': {
    'en': '{0} to create · {1} to update · {2} skipped · {3} error(s)',
    'fr': '{0} à créer · {1} à mettre à jour · {2} ignoré(s) · {3} erreur(s)'
  },
  'importNow': {'en': 'Import now', 'fr': 'Importer maintenant'},
  'importDone': {'en': 'Import finished', 'fr': 'Import terminé'},
  'importEmptyFile': {'en': 'The file is empty.', 'fr': 'Le fichier est vide.'},
  'importReadError': {
    'en': 'Unable to read this file. Make sure it is a CSV or .xlsx.',
    'fr':
        'Impossible de lire ce fichier. Vérifiez qu\'il s\'agit d\'un CSV ou d\'un .xlsx.'
  },
  'importLine': {'en': 'Row {0}', 'fr': 'Ligne {0}'},
  'importErrMissingName': {'en': 'missing name', 'fr': 'nom manquant'},
  'importErrBadNumber': {'en': 'unreadable number', 'fr': 'nombre illisible'},
  'importErrNegative': {'en': 'negative number', 'fr': 'nombre négatif'},
  'importErrDuplicate': {
    'en': 'duplicate in the file',
    'fr': 'doublon dans le fichier'
  },
  'andMore': {'en': '… and {0} more', 'fr': '… et {0} autre(s)'},
  'scanBarcode': {'en': 'Scan a barcode', 'fr': 'Scanner un code-barres'},
  'torch': {'en': 'Torch', 'fr': 'Lampe'},
  'switchCamera': {'en': 'Switch camera', 'fr': 'Changer de caméra'},
  'scanDone': {'en': 'Done ({0})', 'fr': 'Terminer ({0})'},
  'unknownCode': {'en': 'Unknown code: {0}', 'fr': 'Code inconnu : {0}'},
  'createProduct': {'en': 'Create product', 'fr': 'Créer le produit'},
  'scanUnsupported': {
    'en':
        'Camera scanning is not available on this device. Use a USB/Bluetooth barcode reader: the code is typed into the search field.',
    'fr':
        'Le scan par caméra n\'est pas disponible sur cet appareil. Utilisez un lecteur de codes-barres USB/Bluetooth : le code s\'écrit dans le champ de recherche.'
  },
  'cameraDenied': {
    'en': 'Camera access was denied. Allow it in the device settings.',
    'fr':
        'L\'accès à la caméra est refusé. Autorisez-le dans les réglages de l\'appareil.'
  },
  'cameraError': {
    'en': 'Unable to start the camera.',
    'fr': 'Impossible de démarrer la caméra.'
  },
  'openSettings': {'en': 'Open settings', 'fr': 'Ouvrir les réglages'},
  'barcodeExists': {
    'en': 'This barcode already exists: {0}',
    'fr': 'Ce code-barres existe déjà : {0}'
  },
  'takePhoto': {'en': 'Take a photo', 'fr': 'Prendre une photo'},
  'chooseGallery': {'en': 'Gallery', 'fr': 'Galerie'},
  'removePhoto': {'en': 'Remove photo', 'fr': 'Supprimer la photo'},
  'photoError': {
    'en': 'Unable to save the photo.',
    'fr': 'Impossible d\'enregistrer la photo.'
  },
  'expiryDate': {'en': 'Expiry date', 'fr': 'Date de péremption'},
  'noExpiry': {'en': 'None', 'fr': 'Aucune'},
  'expiringSoon': {'en': 'Expiring soon', 'fr': 'Expire bientôt'},
  'expired': {'en': 'Expired', 'fr': 'Périmés'},
  'withinDays': {'en': 'within {0} days', 'fr': 'sous {0} jours'},
  'expiredProducts': {'en': 'Expired products', 'fr': 'Produits périmés'},
  'expiringSoonProducts': {
    'en': 'Products expiring within {0} days',
    'fr': 'Produits qui expirent sous {0} jours'
  },
  'expiredDaysAgo': {'en': 'expired {0} d ago', 'fr': 'périmé depuis {0} j'},
  'inDays': {'en': 'in {0} d', 'fr': 'dans {0} j'},
  'expiredSaleTitle': {'en': 'Expired product', 'fr': 'Produit périmé'},
  'expiredSaleBody': {
    'en': '“{0}” is expired. Do you really want to sell it?',
    'fr': '« {0} » est périmé. Voulez-vous vraiment le vendre ?'
  },
  'sellAnyway': {'en': 'Sell anyway', 'fr': 'Vendre quand même'},
  'expirySettings': {'en': 'Expiry dates', 'fr': 'Péremption'},
  'expiryDelayHint': {
    'en': 'Delay for “expiring soon”',
    'fr': 'Délai pour « expire bientôt »'
  },
  'daysShort': {'en': '{0} d', 'fr': '{0} j'},
  'expiryNotifOption': {
    'en': 'Daily notification',
    'fr': 'Notification quotidienne'
  },
  'expiryNotifHint': {
    'en':
        'Reminder of expiring products. The text is refreshed each time the app is opened.',
    'fr':
        'Rappel des produits qui expirent. Le texte est mis à jour à chaque ouverture de l\'application.'
  },
  'expiryNotifTitle': {'en': 'Product expiry', 'fr': 'Péremption des produits'},
  'expiryNotifBody': {
    'en': '{0} product(s) expiring soon, {1} already expired.',
    'fr': '{0} produit(s) expirent bientôt, {1} déjà périmé(s).'
  },
  'notifDenied': {
    'en': 'Notifications denied: allow them in the device settings.',
    'fr':
        'Notifications refusées : autorisez-les dans les réglages de l\'appareil.'
  },
  'autoBackup': {'en': 'Automatic backup', 'fr': 'Sauvegarde automatique'},
  'autoBackupHint': {
    'en': 'Once a day, the 7 latest backups are kept on the device.',
    'fr': 'Une fois par jour, 7 sauvegardes conservées sur l\'appareil.'
  },
  'backupNow': {'en': 'Back up now', 'fr': 'Sauvegarder maintenant'},
  'backupDoneMsg': {'en': 'Backup created', 'fr': 'Sauvegarde créée'},
  'backupFailed': {'en': 'Backup failed', 'fr': 'Échec de la sauvegarde'},
  'noBackupYet': {
    'en': 'No backup yet',
    'fr': 'Aucune sauvegarde pour le moment'
  },
  'lastBackup': {'en': 'Last backup: {0}', 'fr': 'Dernière sauvegarde : {0}'},
  'savedBackups': {
    'en': 'Backups on this device',
    'fr': 'Sauvegardes sur cet appareil'
  },
  'shareBackup': {
    'en': 'Share (WhatsApp, email, Drive…)',
    'fr': 'Partager (WhatsApp, e-mail, Drive…)'
  },
  'restoreFromFile': {
    'en': 'Restore from a file',
    'fr': 'Restaurer depuis un fichier'
  },
  'restoreConfirmTitle': {
    'en': 'Restore this backup?',
    'fr': 'Restaurer cette sauvegarde ?'
  },
  'restoreConfirmBody': {
    'en':
        'All current data (products, sales, debts, photos…) will be REPLACED by the backup. A copy of the current state is made just before.',
    'fr':
        'Toutes les données actuelles (produits, ventes, dettes, photos…) seront REMPLACÉES par celles de la sauvegarde. Une copie de l\'état actuel est faite juste avant.'
  },
  'restoreInvalid': {
    'en': 'This file is not a valid StockTout backup.',
    'fr': 'Ce fichier n\'est pas une sauvegarde StockTout valide.'
  },
  'restoreFailed': {
    'en': 'The restore failed.',
    'fr': 'La restauration a échoué.'
  },
  'security': {'en': 'Security', 'fr': 'Sécurité'},
  'securityHint': {
    'en': 'Protect the app with a 4–6 digit PIN.',
    'fr': 'Protégez l\'application par un code PIN de 4 à 6 chiffres.'
  },
  'enablePin': {'en': 'Enable PIN', 'fr': 'Activer le code PIN'},
  'changePin': {'en': 'Change PIN', 'fr': 'Changer le PIN'},
  'disablePin': {'en': 'Disable PIN', 'fr': 'Désactiver le PIN'},
  'autoLock': {'en': 'Auto-lock', 'fr': 'Verrouillage automatique'},
  'lockImmediately': {'en': 'Immediately', 'fr': 'Immédiatement'},
  'afterMinutes': {'en': 'After {0} min', 'fr': 'Après {0} min'},
  'useFingerprint': {
    'en': 'Unlock with fingerprint',
    'fr': 'Déverrouiller avec l\'empreinte digitale'
  },
  'hideInRecents': {
    'en': 'Hide in recent apps',
    'fr': 'Masquer dans les applications récentes'
  },
  'hideInRecentsHint': {
    'en': 'Also blocks screenshots.',
    'fr': 'Bloque aussi les captures d’écran.'
  },
  'pinLabel': {'en': 'PIN', 'fr': 'Code PIN'},
  'pinConfirm': {'en': 'Confirm PIN', 'fr': 'Confirmer le PIN'},
  'pinChooseNew': {'en': 'Choose a PIN', 'fr': 'Choisissez un code PIN'},
  'pinEnterCurrent': {
    'en': 'Enter your current PIN',
    'fr': 'Entrez votre PIN actuel'
  },
  'pinFormat': {'en': '4 to 6 digits', 'fr': '4 à 6 chiffres'},
  'pinMismatch': {
    'en': 'The two codes do not match',
    'fr': 'Les deux codes sont différents'
  },
  'pinEnabledMsg': {'en': 'PIN enabled', 'fr': 'Code PIN activé'},
  'pinChangedMsg': {'en': 'PIN changed', 'fr': 'Code PIN modifié'},
  'pinDisabledMsg': {'en': 'PIN disabled', 'fr': 'Code PIN désactivé'},
  'pinEnter': {'en': 'Enter your PIN', 'fr': 'Entrez votre code PIN'},
  'pinWrong': {
    'en': 'Wrong code — {0} attempt(s) before lock',
    'fr': 'Code incorrect — {0} essai(s) avant blocage'
  },
  'pinLockedFor': {
    'en': 'Too many attempts. Try again in {0}',
    'fr': 'Trop d’essais. Réessayez dans {0}'
  },
  'pinUnlockReason': {
    'en': 'Unlock StockTout',
    'fr': 'Déverrouiller StockTout'
  },
  'pinForgot': {'en': 'Forgot PIN?', 'fr': 'PIN oublié ?'},
  'pinForgotTitle': {'en': 'Forgot PIN', 'fr': 'PIN oublié'},
  'pinForgotBody': {
    'en':
        'The PIN cannot be recovered. The only option is to RESET the app: all local data will be erased. If you have a backup, you can restore it afterwards.',
    'fr':
        'Le PIN ne peut pas être récupéré. La seule solution est de RÉINITIALISER l\'application : toutes les données locales seront effacées. Si vous avez une sauvegarde, vous pourrez la restaurer ensuite.'
  },
  'pinResetContinue': {'en': 'Continue', 'fr': 'Continuer'},
  'pinResetFinalTitle': {'en': 'Erase everything?', 'fr': 'Tout effacer ?'},
  'pinResetFinalBody': {
    'en':
        'This is permanent: products, sales, debts and photos will be deleted from this device.',
    'fr':
        'Cette action est définitive : produits, ventes, dettes et photos seront supprimés de cet appareil.'
  },
  'pinResetDo': {'en': 'Erase everything', 'fr': 'Tout effacer'},
  'cat_transport': {'en': 'Transport', 'fr': 'Transport'},
  'cat_rent': {'en': 'Rent', 'fr': 'Loyer'},
  'cat_electricity': {'en': 'Electricity', 'fr': 'Électricité'},
  'cat_salary': {'en': 'Salaries', 'fr': 'Salaires'},
  'cat_supplies': {'en': 'Supplies', 'fr': 'Fournitures'},
  'cat_other': {'en': 'Other', 'fr': 'Autre'},
};

extension V5Strings on AppLocalizations {
  String _v(String k) => _v5[k]?[locale.languageCode] ?? _v5[k]?['en'] ?? k;

  String get debts => _v('debts');
  String get noDebts => _v('noDebts');
  String get totalOwed => _v('totalOwed');
  String debtors(int a0) => _v('debtors').replaceAll('{0}', '$a0');
  String openSales(int a0) => _v('openSales').replaceAll('{0}', '$a0');
  String since(String a0) => _v('since').replaceAll('{0}', '$a0');
  String get unpaidSales => _v('unpaidSales');
  String get paymentHistory => _v('paymentHistory');
  String get recordPayment => _v('recordPayment');
  String get sendReminder => _v('sendReminder');
  String reminderMessage(String a0, String a1) =>
      _v('reminderMessage').replaceAll('{0}', '$a0').replaceAll('{1}', '$a1');
  String remainingDue(String a0) => _v('remainingDue').replaceAll('{0}', '$a0');
  String get amountPaid => _v('amountPaid');
  String paymentTooHigh(String a0) =>
      _v('paymentTooHigh').replaceAll('{0}', '$a0');
  String paymentSaved(String a0) => _v('paymentSaved').replaceAll('{0}', '$a0');
  String saleTotalPaid(String a0, String a1) =>
      _v('saleTotalPaid').replaceAll('{0}', '$a0').replaceAll('{1}', '$a1');
  String get noteOptional => _v('noteOptional');
  String get paidNow => _v('paidNow');
  String get chooseCustomer => _v('chooseCustomer');
  String partialDebtHint(String a0) =>
      _v('partialDebtHint').replaceAll('{0}', '$a0');
  String get searchCustomer => _v('searchCustomer');
  String get noCustomerFound => _v('noCustomerFound');
  String get customerNameLabel => _v('customerNameLabel');
  String get phoneOptional => _v('phoneOptional');
  String get debtsTourTotal => _v('debtsTourTotal');
  String get debtsTourTotalB => _v('debtsTourTotalB');
  String get debtsTourList => _v('debtsTourList');
  String get debtsTourListB => _v('debtsTourListB');
  String get expenses => _v('expenses');
  String get addExpense => _v('addExpense');
  String get amount => _v('amount');
  String get dateLabel => _v('dateLabel');
  String get customCategory => _v('customCategory');
  String get deleteExpenseAsk => _v('deleteExpenseAsk');
  String get monthExpenses => _v('monthExpenses');
  String get noExpenses => _v('noExpenses');
  String get expensesTourTotal => _v('expensesTourTotal');
  String get expensesTourTotalB => _v('expensesTourTotalB');
  String get expensesTourAddB => _v('expensesTourAddB');
  String expenseCategory(String code) => _v('cat_$code');
  String get profitStats => _v('profitStats');
  String get periodToday => _v('periodToday');
  String get period7 => _v('period7');
  String get period30 => _v('period30');
  String get periodMonth => _v('periodMonth');
  String get periodCustom => _v('periodCustom');
  String get revenue => _v('revenue');
  String get costOfGoods => _v('costOfGoods');
  String get grossProfit => _v('grossProfit');
  String get margin => _v('margin');
  String get netProfit => _v('netProfit');
  String get salesCount => _v('salesCount');
  String get avgBasket => _v('avgBasket');
  String get discountsGiven => _v('discountsGiven');
  String get revenueEvolution => _v('revenueEvolution');
  String get topProducts => _v('topProducts');
  String get byQuantity => _v('byQuantity');
  String get byProfit => _v('byProfit');
  String get sold => _v('sold');
  String dormantProducts(int a0) =>
      _v('dormantProducts').replaceAll('{0}', '$a0');
  String get dormantHint => _v('dormantHint');
  String get importProducts => _v('importProducts');
  String get importStep1 => _v('importStep1');
  String get importStep2 => _v('importStep2');
  String get importStep3 => _v('importStep3');
  String get importHelp => _v('importHelp');
  String get chooseFile => _v('chooseFile');
  String get downloadTemplate => _v('downloadTemplate');
  String rowsCount(int a0) => _v('rowsCount').replaceAll('{0}', '$a0');
  String get notImported => _v('notImported');
  String get ifExists => _v('ifExists');
  String get dupUpdate => _v('dupUpdate');
  String get dupSkip => _v('dupSkip');
  String get preview => _v('preview');
  String get importNeedName => _v('importNeedName');
  String importSummary(int a0, int a1, int a2, int a3) => _v('importSummary')
      .replaceAll('{0}', '$a0')
      .replaceAll('{1}', '$a1')
      .replaceAll('{2}', '$a2')
      .replaceAll('{3}', '$a3');
  String get importNow => _v('importNow');
  String get importDone => _v('importDone');
  String get importEmptyFile => _v('importEmptyFile');
  String get importReadError => _v('importReadError');
  String importLine(int a0) => _v('importLine').replaceAll('{0}', '$a0');
  String get importErrMissingName => _v('importErrMissingName');
  String get importErrBadNumber => _v('importErrBadNumber');
  String get importErrNegative => _v('importErrNegative');
  String get importErrDuplicate => _v('importErrDuplicate');
  String andMore(int a0) => _v('andMore').replaceAll('{0}', '$a0');
  String get scanBarcode => _v('scanBarcode');
  String get torch => _v('torch');
  String get switchCamera => _v('switchCamera');
  String scanDone(int a0) => _v('scanDone').replaceAll('{0}', '$a0');
  String unknownCode(String a0) => _v('unknownCode').replaceAll('{0}', '$a0');
  String get createProduct => _v('createProduct');
  String get scanUnsupported => _v('scanUnsupported');
  String get cameraDenied => _v('cameraDenied');
  String get cameraError => _v('cameraError');
  String get openSettings => _v('openSettings');
  String barcodeExists(String a0) =>
      _v('barcodeExists').replaceAll('{0}', '$a0');
  String get takePhoto => _v('takePhoto');
  String get chooseGallery => _v('chooseGallery');
  String get removePhoto => _v('removePhoto');
  String get photoError => _v('photoError');
  String get expiryDate => _v('expiryDate');
  String get noExpiry => _v('noExpiry');
  String get expiringSoon => _v('expiringSoon');
  String get expired => _v('expired');
  String withinDays(int a0) => _v('withinDays').replaceAll('{0}', '$a0');
  String get expiredProducts => _v('expiredProducts');
  String expiringSoonProducts(int a0) =>
      _v('expiringSoonProducts').replaceAll('{0}', '$a0');
  String expiredDaysAgo(int a0) =>
      _v('expiredDaysAgo').replaceAll('{0}', '$a0');
  String inDays(int a0) => _v('inDays').replaceAll('{0}', '$a0');
  String get expiredSaleTitle => _v('expiredSaleTitle');
  String expiredSaleBody(String a0) =>
      _v('expiredSaleBody').replaceAll('{0}', '$a0');
  String get sellAnyway => _v('sellAnyway');
  String get expirySettings => _v('expirySettings');
  String get expiryDelayHint => _v('expiryDelayHint');
  String daysShort(int a0) => _v('daysShort').replaceAll('{0}', '$a0');
  String get expiryNotifOption => _v('expiryNotifOption');
  String get expiryNotifHint => _v('expiryNotifHint');
  String get expiryNotifTitle => _v('expiryNotifTitle');
  String expiryNotifBody(int a0, int a1) =>
      _v('expiryNotifBody').replaceAll('{0}', '$a0').replaceAll('{1}', '$a1');
  String get notifDenied => _v('notifDenied');
  String get autoBackup => _v('autoBackup');
  String get autoBackupHint => _v('autoBackupHint');
  String get backupNow => _v('backupNow');
  String get backupDoneMsg => _v('backupDoneMsg');
  String get backupFailed => _v('backupFailed');
  String get noBackupYet => _v('noBackupYet');
  String lastBackup(String a0) => _v('lastBackup').replaceAll('{0}', '$a0');
  String get savedBackups => _v('savedBackups');
  String get shareBackup => _v('shareBackup');
  String get restoreFromFile => _v('restoreFromFile');
  String get restoreConfirmTitle => _v('restoreConfirmTitle');
  String get restoreConfirmBody => _v('restoreConfirmBody');
  String get restoreInvalid => _v('restoreInvalid');
  String get restoreFailed => _v('restoreFailed');
  String get security => _v('security');
  String get securityHint => _v('securityHint');
  String get enablePin => _v('enablePin');
  String get changePin => _v('changePin');
  String get disablePin => _v('disablePin');
  String get autoLock => _v('autoLock');
  String get lockImmediately => _v('lockImmediately');
  String afterMinutes(int a0) => _v('afterMinutes').replaceAll('{0}', '$a0');
  String get useFingerprint => _v('useFingerprint');
  String get hideInRecents => _v('hideInRecents');
  String get hideInRecentsHint => _v('hideInRecentsHint');
  String get pinLabel => _v('pinLabel');
  String get pinConfirm => _v('pinConfirm');
  String get pinChooseNew => _v('pinChooseNew');
  String get pinEnterCurrent => _v('pinEnterCurrent');
  String get pinFormat => _v('pinFormat');
  String get pinMismatch => _v('pinMismatch');
  String get pinEnabledMsg => _v('pinEnabledMsg');
  String get pinChangedMsg => _v('pinChangedMsg');
  String get pinDisabledMsg => _v('pinDisabledMsg');
  String get pinEnter => _v('pinEnter');
  String pinWrong(int a0) => _v('pinWrong').replaceAll('{0}', '$a0');
  String pinLockedFor(String a0) => _v('pinLockedFor').replaceAll('{0}', '$a0');
  String get pinUnlockReason => _v('pinUnlockReason');
  String get pinForgot => _v('pinForgot');
  String get pinForgotTitle => _v('pinForgotTitle');
  String get pinForgotBody => _v('pinForgotBody');
  String get pinResetContinue => _v('pinResetContinue');
  String get pinResetFinalTitle => _v('pinResetFinalTitle');
  String get pinResetFinalBody => _v('pinResetFinalBody');
  String get pinResetDo => _v('pinResetDo');
}
