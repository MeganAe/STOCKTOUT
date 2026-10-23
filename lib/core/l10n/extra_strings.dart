import 'app_localizations.dart';

/// Textes ajoutes pour les remises, la monnaie et les recus.
/// Francais et anglais ; les autres langues retombent sur l'anglais.
const _xs = <String, Map<String, String>>{
  'discount': {'en': 'Discount', 'fr': 'Remise'},
  'subtotal': {'en': 'Subtotal', 'fr': 'Sous-total'},
  'lineDiscount': {'en': 'Line discount', 'fr': 'Remise sur la ligne'},
  'amountReceived': {'en': 'Amount received', 'fr': 'Montant reçu'},
  'changeDue': {'en': 'Change due', 'fr': 'Monnaie à rendre'},
  'customerName': {'en': 'Customer (optional)', 'fr': 'Client (optionnel)'},
  'customerRequired': {
    'en': 'Customer name required for a credit sale',
    'fr': 'Nom du client requis pour une vente à crédit',
  },
  'belowCost': {
    'en': 'Below purchase price (loss)',
    'fr': "Sous le prix d'achat (perte)",
  },
  'notEnoughStock': {'en': 'Not enough stock', 'fr': 'Stock insuffisant'},
  'receipt': {'en': 'Receipt', 'fr': 'Reçu'},
  'shareReceipt': {'en': 'Share receipt', 'fr': 'Partager le reçu'},
  'cancelSale': {'en': 'Cancel sale', 'fr': 'Annuler la vente'},
  'cancelSaleAsk': {
    'en': 'Cancel this sale and put the items back in stock?',
    'fr': 'Annuler cette vente et remettre les articles en stock ?',
  },
  'saleCancelled': {'en': 'Sale cancelled', 'fr': 'Vente annulée'},
  'todaySales': {'en': "Today's sales", 'fr': 'Ventes du jour'},
};

extension SalesStrings on AppLocalizations {
  String _x(String k) =>
      _xs[k]?[locale.languageCode] ?? _xs[k]?['en'] ?? k;

  String get discount => _x('discount');
  String get subtotal => _x('subtotal');
  String get lineDiscount => _x('lineDiscount');
  String get amountReceived => _x('amountReceived');
  String get changeDue => _x('changeDue');
  String get customerName => _x('customerName');
  String get customerRequired => _x('customerRequired');
  String get belowCost => _x('belowCost');
  String get notEnoughStock => _x('notEnoughStock');
  String get receipt => _x('receipt');
  String get shareReceipt => _x('shareReceipt');
  String get cancelSale => _x('cancelSale');
  String get cancelSaleAsk => _x('cancelSaleAsk');
  String get saleCancelled => _x('saleCancelled');
  String get todaySales => _x('todaySales');
}
