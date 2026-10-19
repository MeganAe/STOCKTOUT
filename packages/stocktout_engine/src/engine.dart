/// Moteur de calcul pur Dart : marges, valorisation, seuils, devises.
/// Sans dependance Flutter : utilisable dans l'app, les tests, des scripts.
library;

double stockValue(double quantity, double buyPrice) => quantity * buyPrice;

double margin(double sellPrice, double buyPrice) => sellPrice - buyPrice;

double marginRate(double sellPrice, double buyPrice) {
  if (buyPrice == 0) return 0;
  return (sellPrice - buyPrice) / buyPrice * 100;
}

bool isLowStock(double quantity, double minStock) => quantity <= minStock;
bool isOutOfStock(double quantity) => quantity <= 0;

/// Quantite a commander : remonter a 2x le seuil.
double reorderQty(double quantity, double minStock) {
  final target = minStock * 2;
  final need = target - quantity;
  return need < 1 ? 1 : need;
}

/// Conversion : taux exprimes par rapport a la devise de base.
double convert(double amount, double fromRate, double toRate) {
  if (fromRate == 0 || toRate == 0) return amount;
  return amount / fromRate * toRate;
}

/// Total d'une vente : lignes (qte x prix - remise) - remise globale + taxe.
double saleTotal(
  List<({double qty, double price, double discount})> lines, {
  double discount = 0,
  double tax = 0,
}) {
  final sub = lines.fold<double>(
      0, (s, l) => s + l.qty * l.price - l.discount);
  return sub - discount + tax;
}
