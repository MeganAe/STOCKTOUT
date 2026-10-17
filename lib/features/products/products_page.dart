import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/product.dart';
import '../../core/models/stock_movement.dart';
import '../../core/providers/app_providers.dart';
import 'product_dialog.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.products),
        actions: [
          SizedBox(
            width: 280,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: t.search,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) =>
                    ref.read(productSearchProvider.notifier).state = v,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(t.newProduct),
              onPressed: () => _openEditor(context, ref, null),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 48),
                  const SizedBox(height: 12),
                  const Text('Aucun produit. Ajoutez votre premier article.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _openEditor(context, ref, null),
                    child: Text(t.add),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 140),
              child: DataTable(
                columns: [
                  DataColumn(label: Text(t.sku)),
                  DataColumn(label: Text(t.productName)),
                  DataColumn(label: Text(t.category)),
                  DataColumn(label: Text(t.quantity), numeric: true),
                  DataColumn(label: Text(t.buyPrice), numeric: true),
                  DataColumn(label: Text(t.sellPrice), numeric: true),
                  const DataColumn(label: Text('')),
                ],
                rows: products.map((p) {
                  final low = p.isLowStock;
                  return DataRow(
                    cells: [
                      DataCell(Text(p.sku)),
                      DataCell(Row(
                        children: [
                          Text(p.name),
                          if (low) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.warning_amber,
                                size: 16, color: Colors.orange),
                          ],
                        ],
                      )),
                      DataCell(Text(p.category ?? '—')),
                      DataCell(Text(p.quantity.toString())),
                      DataCell(Text(p.buyPrice.toStringAsFixed(2))),
                      DataCell(Text(p.sellPrice.toStringAsFixed(2))),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Entree / sortie',
                            icon: const Icon(Icons.swap_vert),
                            onPressed: () => _moveStock(context, ref, p),
                          ),
                          IconButton(
                            tooltip: t.edit,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _openEditor(context, ref, p),
                          ),
                          IconButton(
                            tooltip: t.delete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(context, ref, p),
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
      BuildContext context, WidgetRef ref, Product? p) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ProductDialog(product: p),
    );
    if (saved == true) ref.invalidate(productsProvider);
  }

  Future<void> _moveStock(
      BuildContext context, WidgetRef ref, Product p) async {
    final qtyCtrl = TextEditingController();
    MovementType type = MovementType.in_;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${p.name} — entree / sortie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<MovementType>(
              value: type,
              items: const [
                DropdownMenuItem(
                    value: MovementType.in_, child: Text('Entree')),
                DropdownMenuItem(
                    value: MovementType.out, child: Text('Sortie')),
                DropdownMenuItem(
                    value: MovementType.adjustment,
                    child: Text('Ajustement (definir)')),
                DropdownMenuItem(
                    value: MovementType.loss, child: Text('Perte / casse')),
              ],
              onChanged: (v) => type = v ?? MovementType.in_,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantite'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Valider')),
        ],
      ),
    );
    if (ok == true) {
      final q = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 0;
      if (q <= 0) return;
      await AppDatabase.instance.addMovement(StockMovement(
        productId: p.id,
        type: type,
        quantity: q,
        reason: 'Saisie manuelle',
      ));
      ref.invalidate(productsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock mis a jour.')),
        );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('${p.name} (${p.sku}) sera supprime.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      await AppDatabase.instance.deleteProduct(p.id);
      ref.invalidate(productsProvider);
    }
  }
}
