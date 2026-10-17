import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/automation.dart';
import '../../core/models/product.dart';
import '../../core/models/sale.dart';
import '../../core/models/stock_movement.dart';
import '../../core/providers/app_providers.dart';

/// Caisse simple : recherche produit, panier, total, encaissement.
class SalesPage extends ConsumerStatefulWidget {
  const SalesPage({super.key});
  @override
  ConsumerState<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends ConsumerState<SalesPage> {
  final List<SaleLine> _cart = [];
  final _search = TextEditingController();
  String _payment = 'Especes';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  double get _total => _cart.fold(0, (s, e) => s + e.total);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.sales)),
      body: Row(
        children: [
          // Catalogue
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: t.search,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: productsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (products) {
                      final q = _search.text.toLowerCase();
                      final list = q.isEmpty
                          ? products
                          : products
                              .where((e) =>
                                  e.name.toLowerCase().contains(q) ||
                                  e.sku.toLowerCase().contains(q))
                              .toList();
                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 1.4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final p = list[i];
                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _addToCart(p),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(p.sku,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(p.sellPrice.toStringAsFixed(2),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                            'x${p.quantity.toStringAsFixed(0)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Panier
          SizedBox(
            width: 340,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text(t.newSale,
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed:
                            _cart.isEmpty ? null : () => setState(_cart.clear),
                        child: const Text('Vider'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Text('Panier vide.'))
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (ctx, i) {
                            final l = _cart[i];
                            return ListTile(
                              dense: true,
                              title: Text(l.productName),
                              subtitle: Text(
                                  '${l.quantity} x ${l.unitPrice.toStringAsFixed(2)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(l.total.toStringAsFixed(2)),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () =>
                                        setState(() => _cart.removeAt(i)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _payment,
                        items: const [
                          DropdownMenuItem(
                              value: 'Especes', child: Text('Especes')),
                          DropdownMenuItem(
                              value: 'Mobile Money',
                              child: Text('Mobile Money')),
                          DropdownMenuItem(
                              value: 'Carte', child: Text('Carte')),
                          DropdownMenuItem(
                              value: 'Virement', child: Text('Virement')),
                          DropdownMenuItem(
                              value: 'Credit', child: Text('Credit')),
                        ],
                        onChanged: (v) =>
                            setState(() => _payment = v ?? 'Especes'),
                        decoration:
                            const InputDecoration(labelText: 'Paiement'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(t.total,
                              style: Theme.of(context).textTheme.titleLarge),
                          Text(_total.toStringAsFixed(2),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _cart.isEmpty ? null : _checkout,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check),
                              SizedBox(width: 8),
                              Text('Encaisser'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Product p) {
    final i = _cart.indexWhere((e) => e.productId == p.id);
    setState(() {
      if (i >= 0) {
        final old = _cart[i];
        _cart[i] = SaleLine(
          productId: old.productId,
          productName: old.productName,
          quantity: old.quantity + 1,
          unitPrice: old.unitPrice,
        );
      } else {
        _cart.add(SaleLine(
          productId: p.id,
          productName: p.name,
          quantity: 1,
          unitPrice: p.sellPrice,
        ));
      }
    });
  }

  Future<void> _checkout() async {
    final settings = ref.read(settingsProvider);
    final number = 'V-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final linesJson = jsonEncode(_cart.map((e) => e.toMap()).toList());

    await AppDatabase.instance.insertSale({
      'id': const Uuid().v4(),
      'number': number,
      'date': DateTime.now().toIso8601String(),
      'customer_id': null,
      'customer_name': '',
      'lines': linesJson,
      'discount': 0,
      'tax': 0,
      'currency': settings.currency,
      'rate': 1,
      'payment_method': _payment,
      'notes': '',
    });

    // Sorties de stock + automatisations.
    final engine = ref.read(automationEngineProvider);
    for (final l in _cart) {
      await AppDatabase.instance.addMovement(StockMovement(
        productId: l.productId,
        type: MovementType.out,
        quantity: l.quantity,
        unitPrice: l.unitPrice,
        reference: number,
        reason: 'Vente',
      ));
      final products = await AppDatabase.instance.allProducts();
      final prod = products.where((e) => e.id == l.productId).firstOrNull;
      if (prod != null) {
        if (prod.isOutOfStock) {
          await engine.fire(AutoTrigger.outOfStock, product: prod);
        } else if (prod.isLowStock) {
          await engine.fire(AutoTrigger.stockLow, product: prod);
        }
      }
    }
    await engine.fire(AutoTrigger.saleCreated);

    setState(_cart.clear);
    ref.invalidate(productsProvider);
    ref.invalidate(salesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vente $number enregistree.')),
      );
    }
  }
}
