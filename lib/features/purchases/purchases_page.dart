import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/stock_movement.dart';
import '../../widgets/feature_tour.dart';

class PurchasesPage extends ConsumerStatefulWidget {
  const PurchasesPage({super.key});
  @override
  ConsumerState<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends ConsumerState<PurchasesPage> {
  List<Map<String, Object?>> _rows = [];
  bool _loading = true;
  final kAction = GlobalKey();
  final kList = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows =
        await AppDatabase.instance.db.query('purchases', orderBy: 'date DESC');
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GuidedTour(
      id: 'purchases',
      steps: [
        TourStep(target: kAction, title: t.gsAction, body: t.gsActionB),
        TourStep(target: kList, title: t.gsList, body: t.gsListB),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.purchases),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: KeyedSubtree(
                key: kAction,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(t.newPurchase),
                  onPressed: _newPurchase,
                ),
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _rows.isEmpty
                ? Center(child: Text(t.noPurchases))
                : KeyedSubtree(
                    key: kList,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rows.length,
                      itemBuilder: (ctx, i) {
                        final r = _rows[i];
                        final status = r['status'] as String? ?? 'draft';
                        final received = status == 'received';
                        final date = DateTime.tryParse('${r['date']}');
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              received
                                  ? Icons.check_circle
                                  : Icons.pending_outlined,
                              color: received ? Colors.green : Colors.orange,
                            ),
                            title: Text(
                                '${r['number']} — ${r['supplier_name'] ?? ''}'),
                            subtitle: Text(
                                '${date != null ? '${date.day}/${date.month}/${date.year}' : ''}'
                                ' · ${received ? t.received : t.draft}'),
                            trailing: received
                                ? null
                                : FilledButton.tonal(
                                    onPressed: () => _receive(r),
                                    child: Text(t.receive),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Future<void> _newPurchase() async {
    final t = AppLocalizations.of(context);
    final products = await AppDatabase.instance.allProducts();
    if (products.isEmpty || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.addFirstProduct)));
      }
      return;
    }
    String? pid = products.first.id;
    final qty = TextEditingController(text: '10');
    final supp = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(t.newPurchase),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: pid,
                items: products
                    .map((e) => DropdownMenuItem(
                        value: e.id, child: Text('${e.name} (${e.sku})')))
                    .toList(),
                onChanged: (v) => setState(() => pid = v),
                decoration: InputDecoration(labelText: t.products),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t.quantity)),
              const SizedBox(height: 12),
              TextField(
                  controller: supp,
                  decoration: InputDecoration(labelText: t.supplier)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(t.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
          ],
        ),
      ),
    );
    if (ok == true && pid != null) {
      final q = double.tryParse(qty.text.replaceAll(',', '.')) ?? 0;
      await AppDatabase.instance.db.insert('purchases', {
        'id': 'p-${DateTime.now().millisecondsSinceEpoch}',
        'number': 'A-${DateTime.now().millisecondsSinceEpoch % 1000000}',
        'date': DateTime.now().toIso8601String(),
        'supplier_id': null,
        'supplier_name': supp.text,
        'lines': '[{"product_id":"$pid","qty":$q}]',
        'status': 'draft',
        'currency': 'USD',
        'rate': 1,
        'notes': '',
      });
      _load();
    }
  }

  Future<void> _receive(Map<String, Object?> r) async {
    final t = AppLocalizations.of(context);
    final raw = r['lines'] as String? ?? '[]';
    final re = RegExp(r'"product_id"\s*:\s*"([^"]+)"[^0-9]*([0-9.]+)');
    for (final m in re.allMatches(raw)) {
      await AppDatabase.instance.addMovement(StockMovement(
        productId: m.group(1)!,
        type: MovementType.in_,
        quantity: double.tryParse(m.group(2)!) ?? 0,
        reference: r['number'] as String?,
        reason: t.purchases,
      ));
    }
    await AppDatabase.instance.db.update(
      'purchases',
      {'status': 'received'},
      where: 'id = ?',
      whereArgs: [r['id']],
    );
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.purchaseReceived)),
      );
    }
  }
}
