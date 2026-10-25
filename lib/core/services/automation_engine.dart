import 'dart:io';

import 'package:path/path.dart' as p;

import '../database/database.dart';
import '../l10n/app_localizations.dart';
import '../l10n/v5_strings.dart';
import '../models/automation.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import 'report_service.dart';

/// Moteur de règles. Chaque événement (vente, stock bas, péremption,
/// rapport quotidien...) passe ici.
///
/// Actions implémentées : notify, createPurchaseDraft, exportCsv.
/// Les autres actions (printReport, adjustPrice, webhook) et le déclencheur
/// `scheduled` ne sont pas implémentés : ils sont ignorés ici et désactivés
/// dans l'interface (voir [AutoAction.available]).
class AutomationEngine {
  final AppDatabase db;
  final AppLocalizations t;
  final void Function(String title, String body)? onNotify;

  AutomationEngine(this.db, this.t, {this.onNotify});

  /// Envoie une notification (si un destinataire est branché).
  void emit(String title, String body) => onNotify?.call(title, body);

  /// Les noms des règles prédéfinies sont stockés comme codes.
  String _ruleTitle(String name) {
    switch (name) {
      case 'preset_low':
        return t.presetLowName;
      case 'preset_draft':
        return t.presetDraftName;
      case 'preset_report':
        return t.presetReportName;
      case 'preset_expiry':
        return t.presetExpiryName;
      default:
        return name;
    }
  }

  /// Exécute les règles actives de [trigger]. Avec [notify] = false, l'action
  /// « notifier » est sautée (l'appelant regroupe les notifications).
  Future<List<String>> fire(
    AutoTrigger trigger, {
    Product? product,
    bool notify = true,
  }) async {
    if (!trigger.available) return const [];
    final rules = await db.allAutomations();
    final fired = <String>[];
    for (final r in rules) {
      if (!r.enabled || r.trigger != trigger) continue;
      final details = <String>[];
      var wantsNotify = false;
      for (final a in r.actions) {
        if (!a.available) continue;
        switch (a) {
          case AutoAction.notify:
            wantsNotify = true;
          case AutoAction.createPurchaseDraft:
            if (product != null) {
              await _createPurchaseDraft(product);
              fired.add('${r.name}: ${t.actDraft} ${product.sku}');
              details.add(t.actDraft);
            }
          case AutoAction.exportCsv:
            final file = await _exportCsv();
            if (file != null) {
              fired.add('${r.name}: ${t.actExport} ${p.basename(file)}');
              details.add('${t.actExport}: ${p.basename(file)}');
            }
          case AutoAction.printReport:
          case AutoAction.adjustPrice:
          case AutoAction.webhook:
            break;
        }
      }
      if (wantsNotify && notify) {
        final msg = [_messageFor(trigger, product), ...details].join(' · ');
        emit(_ruleTitle(r.name), msg);
        fired.add('${r.name}: $msg');
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

  /// Écrit le stock actuel en CSV dans <documents>/stocktout/exports/.
  /// Retourne le chemin du fichier (null en cas d'échec).
  Future<String?> _exportCsv() async {
    try {
      final csv = '\uFEFF${await ReportService(db).productsCsv(t)}';
      final dir = Directory(p.join((await db.dataDir()).path, 'exports'));
      if (!await dir.exists()) await dir.create(recursive: true);
      final d = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final file = File(p.join(
          dir.path, 'stock_${d.year}-${two(d.month)}-${two(d.day)}.csv'));
      await file.writeAsString(csv);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Brouillon de commande au nouveau format : fournisseur du produit,
  /// devise par défaut, quantité pour revenir à 2 x le stock minimum,
  /// coût unitaire = prix d'achat actuel.
  Future<void> _createPurchaseDraft(Product prod) async {
    final qty =
        (prod.minStock * 2 - prod.quantity).clamp(1, 1000000).toDouble();
    final currency = await db.getSetting('currency') ?? 'USD';
    var supplierName = '';
    final sid = prod.supplierId;
    if (sid != null && sid.isNotEmpty) {
      final rows = await db.db
          .query('partners', where: 'id = ?', whereArgs: [sid], limit: 1);
      if (rows.isNotEmpty) supplierName = '${rows.first['name'] ?? ''}';
    }
    await db.insertPurchase(Purchase(
      number: 'CMD-${DateTime.now().millisecondsSinceEpoch % 1000000}',
      supplierId: (sid == null || sid.isEmpty) ? null : sid,
      supplierName: supplierName,
      lines: [
        PurchaseLine(
          productId: prod.id,
          productName: prod.name,
          quantity: qty,
          unitCost: prod.buyPrice > 0 ? prod.buyPrice : null,
        ),
      ],
      currency: currency,
      notes: '${t.autoDraft} (${prod.name})',
    ));
  }
}
