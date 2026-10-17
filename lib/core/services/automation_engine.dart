import '../database/database.dart';
import '../models/automation.dart';
import '../models/product.dart';

/// Moteur de regles simple et extensible.
/// Chaque evenement (vente, stock bas, rapport planifie...) passe ici.
class AutomationEngine {
  final AppDatabase db;
  final void Function(String title, String body)? onNotify;

  AutomationEngine(this.db, {this.onNotify});

  Future<List<String>> fire(AutoTrigger trigger, {Product? product}) async {
    final rules = await db.allAutomations();
    final fired = <String>[];
    for (final r in rules) {
      if (!r.enabled || r.trigger != trigger) continue;
      for (final a in r.actions) {
        switch (a) {
          case AutoAction.notify:
            final msg = _messageFor(trigger, product);
            onNotify?.call(r.name, msg);
            fired.add('${r.name}: $msg');
            break;
          case AutoAction.createPurchaseDraft:
            if (product != null) {
              await _createPurchaseDraft(product);
              fired.add('${r.name}: brouillon commande ${product.sku}');
            }
            break;
          case AutoAction.exportCsv:
            fired.add('${r.name}: export planifie');
            break;
          case AutoAction.printReport:
            fired.add('${r.name}: impression planifiee');
            break;
          case AutoAction.adjustPrice:
          case AutoAction.webhook:
            fired.add('${r.name}: action ${a.value} (voir logs)');
            break;
        }
      }
    }
    return fired;
  }

  String _messageFor(AutoTrigger t, Product? p) {
    switch (t) {
      case AutoTrigger.stockLow:
        return p != null
            ? '${p.name} passe sous le seuil (${p.quantity} restants).'
            : 'Un produit passe sous le seuil.';
      case AutoTrigger.outOfStock:
        return p != null ? '${p.name} est en rupture.' : 'Rupture de stock.';
      case AutoTrigger.saleCreated:
        return 'Nouvelle vente enregistree.';
      case AutoTrigger.productExpiry:
        return p != null
            ? '${p.name} approche de sa date limite.'
            : 'Produit proche peremption.';
      case AutoTrigger.dailyReport:
        return 'Rapport du jour pret.';
      case AutoTrigger.scheduled:
        return 'Tache planifiee executee.';
    }
  }

  Future<void> _createPurchaseDraft(Product p) async {
    final qty = (p.minStock * 2 - p.quantity).clamp(1, 1000000).toDouble();
    await db.db.insert('purchases', {
      'id': 'draft-${DateTime.now().millisecondsSinceEpoch}-${p.id}',
      'number': 'CMD-BROUILLON',
      'date': DateTime.now().toIso8601String(),
      'supplier_id': p.supplierId,
      'supplier_name': '',
      'lines': '[{"product_id":"${p.id}","qty":$qty}]',
      'status': 'draft',
      'currency': 'USD',
      'rate': 1,
      'notes': 'Genere automatiquement (rupture ${p.name})',
    });
  }
}
