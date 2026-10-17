import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/stock_movement.dart';

class PurchasesPage extends ConsumerStatefulWidget {
  const PurchasesPage({super.key});
  @override
  ConsumerState<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends ConsumerState<PurchasesPage> {
  List<Map<String, Object?>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _rows =
        await AppDatabase.instance.db.query('purchases', orderBy: 'date DESC');
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.purchases),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Nouvel achat'),
              onPressed: _newPurchase,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const Center(child: Text('Aucun achat.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rows.length,
                  itemBuilder: (ctx, i) {
                    final r = _rows[i];
                    final status = r['status'] as String? ?? 'draft';
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          status == 'received'
                              ? Icons.check_circle
                              : Icons.pending_outlined,
                          color: status == 'received'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        title: Text(
                            '${r['number']} — ${r['supplier_name'] ?? ''}'),
                        subtitle: Text(
                            '${r['date']} · ${r['notes'] ?? ''} · $status'),
                        trailing: status == 'received'
                            ? null
                            : FilledButton.tonal(
                                onPressed: () => _receive(r),
                                child: const Text('Receptionner'),
                              ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _newPurchase() async {
    final products = await AppDatabase.instance.allProducts();
    if (products.isEmpty || !mounted) return;
    String? pid = products.first.id;
    final qty = TextEditingController(text: '10');
    final supp = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvel achat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: pid,
              items: products
                  .map((e) => DropdownMenuItem(
                      value: e.id, child: Text('${e.name} (${e.sku})')))
                  .toList(),
              onChanged: (v) => pid = v,
              decoration: const InputDecoration(labelText: 'Produit'),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantite')),
            const SizedBox(height: 12),
            TextField(
                controller: supp,
                decoration: const InputDecoration(labelText: 'Fournisseur')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer')),
        ],
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
    // Reconstitue les lignes (format simple) et fait les entrees.
    final raw = r['lines'] as String? ?? '[]';
    final re = RegExp(r'"product_id"\s*:\s*"([^"]+)"[^0-9]*([0-9.]+)');
    for (final m in re.allMatches(raw)) {
      await AppDatabase.instance.addMovement(StockMovement(
        productId: m.group(1)!,
        type: MovementType.in_,
        quantity: double.tryParse(m.group(2)!) ?? 0,
        reference: r['number'] as String?,
        reason: 'Achat',
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
        const SnackBar(content: Text('Achat receptionne, stock mis a jour.')),
      );
    }
  }
}
