/// Génération de références (SKU) et de codes-barres internes.
/// Logique partagée entre le formulaire produit et l'import CSV/Excel.

final RegExp _skuRe = RegExp(r'^P-(\d+)$');

/// Plus grand numéro N parmi les références de la forme `P-0001`.
int maxSkuNumber(Iterable<String> skus) {
  var maxN = 0;
  for (final s in skus) {
    final m = _skuRe.firstMatch(s);
    if (m != null) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n > maxN) maxN = n;
    }
  }
  return maxN;
}

/// Référence formatée pour le numéro [n] : `P-0007`.
String skuForNumber(int n) => 'P-${n.toString().padLeft(4, '0')}';

/// Prochaine référence libre.
String nextSku(Iterable<String> existing) =>
    skuForNumber(maxSkuNumber(existing) + 1);

/// Code-barres interne EAN-13 valide (préfixe 200 = usage en magasin).
/// [seed] vaut en général `DateTime.now().millisecondsSinceEpoch`.
String generateEan13([int? seed]) {
  final ms = (seed ?? DateTime.now().millisecondsSinceEpoch) % 1000000000;
  final base = '200${ms.toString().padLeft(9, '0')}';
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final d = int.parse(base[i]);
    sum += i.isEven ? d : d * 3;
  }
  return '$base${(10 - sum % 10) % 10}';
}

/// Vérifie la clé de contrôle d'un EAN-13.
bool isValidEan13(String code) {
  if (code.length != 13 || int.tryParse(code) == null) return false;
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final d = int.parse(code[i]);
    sum += i.isEven ? d : d * 3;
  }
  return (10 - sum % 10) % 10 == int.parse(code[12]);
}
