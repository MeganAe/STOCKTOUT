import '../database/database.dart';
import '../l10n/app_localizations.dart';
import '../models/automation.dart';
import '../models/product.dart';

/// Moteur de regles simple et extensible.
/// Chaque evenement (vente, stock bas, rapport planifie...) passe ici.
class AutomationEngine {
  final AppDatabase db;
  final AppLocalizations t;
  final void Function(String title, String body)? onNotify;

  AutomationEngine(this.db, this.t, {this.onNotify});

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
              fired.add('${r.name}: ${t.actDraft} ${product.sku}');
            }
            break;
          case AutoAction.exportCsv:
            fired.add('${r.name}: ${t.actExport}');
            break;
          case AutoAction.printReport:
            fired.add('${r.name}: ${t.actPrint}');
            break;
          case AutoAction.adjustPrice:
          case AutoAction.webhook:
            fired.add('${r.name}: ${t.actions} ${a.value}');
            break;
        }
      }
    }
    return fired;
  }

  String _messageFor(AutoTrigger trigger, Product? p) {
    switch (trigger) {
      case AutoTrigger.stockLow:
        return p != null ? '${p.name} — ${t.trgStockLow}' : t.trgStockLow;
      case AutoTrigger.outOfStock:
        return p != null ? '${p.name} — ${t.trgOutOfStock}' : t.trgOutOfStock;
      case AutoTrigger.saleCreated:
        return t.trgSale;
      case AutoTrigger.productExpiry:
        return p != null ? '${p.name} — ${t.trgExpiry}' : t.trgExpiry;
      case AutoTrigger.dailyReport:
        return t.trgDaily;
      case AutoTrigger.scheduled:
        return t.trgScheduled;
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
      'notes': '${t.autoDraft} (${p.name})',
    });
  }
}
