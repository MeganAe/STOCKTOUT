import '../database/database.dart';
import '../l10n/app_localizations.dart';
import '../models/product.dart';

/// Jeux de produits d'exemple pour decouvrir l'app.
/// N'ecrit rien si des produits existent deja.
/// Les libelles suivent la langue de l'interface.
class DemoSeeder {
  static Future<int> seedIfEmpty(AppLocalizations t) async {
    final db = AppDatabase.instance;
    if ((await db.allProducts()).isNotEmpty) return 0;

    final food = t.category;
    final demo = <Product>[
      _p('DEMO-001', t.demoRice, food, 'bag', 18, 22.5, 40, 10),
      _p('DEMO-002', t.demoOil, food, 'bottle', 2.1, 2.8, 36, 12),
      _p('DEMO-003', t.demoSugar, food, 'pack', 1.1, 1.5, 50, 15),
      _p('DEMO-004', t.demoSalt, food, 'pack', 0.5, 0.8, 60, 20),
      _p('DEMO-005', t.demoSoap, t.demoHygiene, 'pc', 0.6, 1, 24, 10),
      _p('DEMO-006', t.demoFlour, food, 'bag', 9, 11.5, 14, 6),
      _p('DEMO-007', t.demoWater, t.demoDrinks, 'bottle', 0.2, 0.4, 120, 30),
      _p('DEMO-008', t.demoBiscuits, food, 'pack', 0.7, 1.1, 3, 10),
    ];
    for (final p in demo) {
      await db.upsertProduct(p);
    }
    return demo.length;
  }

  static Product _p(String sku, String name, String category, String unit,
      double buy, double sell, double qty, double min) {
    return Product(
      sku: sku,
      name: name,
      category: category,
      unit: unit,
      buyPrice: buy,
      sellPrice: sell,
      quantity: qty,
      minStock: min,
    );
  }
}
