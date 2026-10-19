import '../database/database.dart';
import '../models/product.dart';

/// Jeux de produits d'exemple pour decouvrir l'app.
/// N'ecrit rien si des produits existent deja.
class DemoSeeder {
  static Future<int> seedIfEmpty() async {
    final db = AppDatabase.instance;
    if ((await db.allProducts()).isNotEmpty) return 0;

    final demos = [
      Product(
          sku: 'DEMO-001',
          name: 'Riz 25 kg',
          category: 'Alimentation',
          unit: 'sac',
          buyPrice: 18,
          sellPrice: 22.5,
          quantity: 40,
          minStock: 10),
      Product(
          sku: 'DEMO-002',
          name: 'Huile vegetale 1 L',
          category: 'Alimentation',
          unit: 'bouteille',
          buyPrice: 2.1,
          sellPrice: 2.8,
          quantity: 36,
          minStock: 12),
      Product(
          sku: 'DEMO-003',
          name: 'Sucre 1 kg',
          category: 'Alimentation',
          unit: 'paquet',
          buyPrice: 1.1,
          sellPrice: 1.5,
          quantity: 50,
          minStock: 15),
      Product(
          sku: 'DEMO-004',
          name: 'Sel 1 kg',
          category: 'Alimentation',
          unit: 'paquet',
          buyPrice: 0.5,
          sellPrice: 0.8,
          quantity: 60,
          minStock: 20),
      Product(
          sku: 'DEMO-005',
          name: 'Savon barre',
          category: 'Hygiene',
          unit: 'piece',
          buyPrice: 0.6,
          sellPrice: 1,
          quantity: 24,
          minStock: 10),
      Product(
          sku: 'DEMO-006',
          name: 'Farine 10 kg',
          category: 'Alimentation',
          unit: 'sac',
          buyPrice: 9,
          sellPrice: 11.5,
          quantity: 14,
          minStock: 6),
      Product(
          sku: 'DEMO-007',
          name: 'Eau 500 ml',
          category: 'Boissons',
          unit: 'bouteille',
          buyPrice: 0.2,
          sellPrice: 0.4,
          quantity: 120,
          minStock: 30),
      Product(
          sku: 'DEMO-008',
          name: 'Biscuits 200 g',
          category: 'Alimentation',
          unit: 'paquet',
          buyPrice: 0.7,
          sellPrice: 1.1,
          quantity: 3,
          minStock: 10),
    ];
    for (final p in demos) {
      await db.upsertProduct(p);
    }
    return demos.length;
  }
}
