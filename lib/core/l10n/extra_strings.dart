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
  'currencyChangeTitle': {
    'en': 'Change default currency',
    'fr': 'Changer la devise par défaut',
  },
  'currencyChangeBody': {
    'en': 'Saved prices are plain numbers: they are not converted automatically.',
    'fr': 'Les prix déjà enregistrés sont de simples nombres : ils ne sont pas convertis automatiquement.',
  },
  'convertPrices': {'en': 'Convert prices', 'fr': 'Convertir les prix'},
  'keepPrices': {
    'en': 'Keep prices as they are',
    'fr': 'Garder les prix tels quels',
  },
  'setRateFirst': {
    'en': "To convert, first set the new currency's rate (pencil icon).",
    'fr': "Pour convertir, renseignez d'abord le taux de la nouvelle devise (icône crayon).",
  },
  'pricesConverted': {'en': 'Prices converted', 'fr': 'Prix convertis'},
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
  String get currencyChangeTitle => _x('currencyChangeTitle');
  String get currencyChangeBody => _x('currencyChangeBody');
  String get convertPrices => _x('convertPrices');
  String get keepPrices => _x('keepPrices');
  String get setRateFirst => _x('setRateFirst');
  String get pricesConverted => _x('pricesConverted');
}
