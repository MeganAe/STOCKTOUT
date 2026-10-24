import '../models/product.dart';

/// Recherche EXACTE par code-barres ou référence (insensible à la casse,
/// espaces ignorés). Sert au scan caméra et au lecteur clavier (Entrée).
/// Retourne null si le code est vide ou inconnu.
Product? findProductByCode(Iterable<Product> products, String raw) {
  final code = raw.trim().toLowerCase();
  if (code.isEmpty) return null;
  for (final p in products) {
    if ((p.barcode ?? '').trim().toLowerCase() == code) return p;
  }
  for (final p in products) {
    if (p.sku.trim().toLowerCase() == code) return p;
  }
  return null;
}
