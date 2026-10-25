import '../models/purchase.dart';
import 'money.dart';

/// Effet d'une ligne d'achat à la réception.
class ReceiptEffect {
  final String productId;
  final double quantity;

  /// Nouveau prix d'achat du produit, dans la devise par défaut
  /// (null = ne pas modifier).
  final double? newBuyPrice;
  const ReceiptEffect(this.productId, this.quantity, this.newBuyPrice);
}

/// Plan de réception : une entrée de stock par ligne (quantités > 0) et la
/// mise à jour du prix d'achat quand le coût unitaire est connu et > 0.
/// Plusieurs lignes du même produit sont cumulées ; le dernier coût gagne.
/// Le coût est converti de la devise de l'achat vers [base].
List<ReceiptEffect> planReceipt(
  Purchase p,
  Rates rates,
  String base,
) {
  final qty = <String, double>{};
  final cost = <String, double?>{};
  final order = <String>[];
  for (final l in p.lines) {
    if (l.productId.isEmpty || l.quantity <= 0) continue;
    if (!qty.containsKey(l.productId)) order.add(l.productId);
    qty[l.productId] = (qty[l.productId] ?? 0) + l.quantity;
    final c = l.unitCost;
    if (c != null && c > 0) {
      cost[l.productId] = convertAmount(c, p.currency, base, rates);
    }
  }
  return [for (final id in order) ReceiptEffect(id, qty[id]!, cost[id])];
}

/// Un achat ne peut être reçu qu'une fois, et seulement s'il est en brouillon.
bool canReceive(String status) => status == PurchaseStatus.draft;

/// Seuls les brouillons s'annulent (un achat reçu a déjà modifié le stock).
bool canCancel(String status) => status == PurchaseStatus.draft;
