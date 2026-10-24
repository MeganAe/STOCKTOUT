import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/v5_strings.dart';
import '../../core/logic/expiry.dart';
import '../../core/models/product.dart';
import '../../core/models/stock_movement.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/feature_tour.dart';
import '../../widgets/product_thumb.dart';
import 'import_page.dart';
import 'product_dialog.dart';
import 'scanner_page.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _search = TextEditingController();
  final kSearch = GlobalKey();
  final kAction = GlobalKey();
  final kList = GlobalKey();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final productsAsync = ref.watch(productsProvider);

    return GuidedTour(
      id: 'products',
      steps: [
        TourStep(target: kSearch, title: t.search, body: t.gsSearchB),
        TourStep(target: kAction, title: t.gsAction, body: t.gsActionB),
        TourStep(target: kList, title: t.gsList, body: t.gsListB),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.products),
          actions: [
            IconButton(
              tooltip: t.scanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _scan(context, ref),
            ),
            IconButton(
              tooltip: t.importProducts,
              icon: const Icon(Icons.upload_file),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const ImportPage()));
                ref.invalidate(productsProvider);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: KeyedSubtree(
                key: kAction,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(t.newProduct),
                  onPressed: () => _openEditor(context, ref, null),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: KeyedSubtree(
                key: kSearch,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: t.search,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) =>
                      ref.read(productSearchProvider.notifier).state = v,
                ),
              ),
            ),
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (products) {
                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(t.noProducts),
                          const SizedBox(height: 4),
                          Text(t.addFirstProduct,
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => _openEditor(context, ref, null),
                            child: Text(t.add),
                          ),
                        ],
                      ),
                    );
                  }
                  return KeyedSubtree(
                    key: kList,
                    child: LayoutBuilder(
                      builder: (ctx, c) {
                        if (c.maxWidth >= 760) {
                          return _table(context, ref, t, products);
                        }
                        return _cards(context, ref, t, products);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _table(BuildContext context, WidgetRef ref, AppLocalizations t,
      List<Product> products) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
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
            return DataRow(
              cells: [
                DataCell(Text(p.sku)),
                DataCell(Row(
                  children: [
                    Flexible(child: Text(p.name)),
                    if (p.isLowStock) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.warning_amber,
                          size: 16, color: Colors.orange),
                    ],
                  ],
                )),
                DataCell(Text(p.category ?? '—')),
                DataCell(Text(p.quantity.toStringAsFixed(0))),
                DataCell(Text(p.buyPrice.toStringAsFixed(2))),
                DataCell(Text(p.sellPrice.toStringAsFixed(2))),
                DataCell(_actions(context, ref, t, p)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _cards(BuildContext context, WidgetRef ref, AppLocalizations t,
      List<Product> products) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: products.length,
      itemBuilder: (ctx, i) {
        final p = products[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(p.name),
            subtitle: Text(
                '${p.sku} · ${t.quantity}: ${p.quantity.toStringAsFixed(0)} · '
                '${p.sellPrice.toStringAsFixed(2)}'),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                ProductThumb(
                  path: p.imagePath,
                  size: 44,
                  fallback: p.isLowStock
                      ? Icons.warning_amber
                      : Icons.inventory_2_outlined,
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: _expiryDot(ref, p),
                ),
              ],
            ),
            trailing: _actions(context, ref, t, p),
            onTap: () => _openEditor(context, ref, p),
          ),
        );
      },
    );
  }

  /// Pastille : rouge = périmé, orange = expire bientôt.
  Widget _expiryDot(WidgetRef ref, Product p) {
    final st = classifyExpiry(p.expiryDate, DateTime.now(),
        soonDays: ref.read(settingsProvider).expiryDays);
    if (st != ExpiryStatus.soon && st != ExpiryStatus.expired) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: st == ExpiryStatus.expired ? Colors.red : Colors.orange,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  /// Scan : ouvre la fiche du produit trouvé, ou propose d'en créer un.
  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    final all = await AppDatabase.instance.allProducts();
    if (!context.mounted) return;
    Product? found;
    String? unknown;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ScannerPage(
        products: all,
        onProduct: (p) async {
          found = p;
          return true;
        },
        onUnknown: (code) async {
          unknown = code;
          Navigator.of(context).pop();
        },
      ),
    ));
    if (!context.mounted) return;
    if (found != null) {
      await _openEditor(context, ref, found);
    } else if (unknown != null) {
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) => ProductDialog(initialBarcode: unknown),
      );
      if (saved == true) ref.invalidate(productsProvider);
    }
  }

  Widget _actions(
      BuildContext context, WidgetRef ref, AppLocalizations t, Product p) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: t.enterExit,
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
    final t = AppLocalizations.of(context);
    final qtyCtrl = TextEditingController();
    MovementType type = MovementType.in_;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('${p.name} — ${t.enterExit}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MovementType>(
                value: type,
                items: [
                  DropdownMenuItem(
                      value: MovementType.in_, child: Text(t.movementIn)),
                  DropdownMenuItem(
                      value: MovementType.out, child: Text(t.movementOut)),
                  DropdownMenuItem(
                      value: MovementType.adjustment,
                      child: Text(t.adjustment)),
                  DropdownMenuItem(
                      value: MovementType.loss, child: Text(t.loss)),
                ],
                onChanged: (v) => setState(() => type = v ?? MovementType.in_),
                decoration: InputDecoration(labelText: t.movement),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: t.quantity),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(t.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(t.validate)),
          ],
        ),
      ),
    );
    if (ok == true) {
      final q = double.tryParse(qtyCtrl.text.replaceAll(',', '.')) ?? 0;
      if (q <= 0) return;
      await AppDatabase.instance.addMovement(StockMovement(
        productId: p.id,
        type: type,
        quantity: q,
        reason: t.manualEntry,
      ));
      ref.invalidate(productsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.stockUpdated)),
        );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Product p) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteQ),
        content: Text(t.deleteBody(p.name, p.sku)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok == true) {
      await AppDatabase.instance.deleteProduct(p.id);
      ref.invalidate(productsProvider);
    }
  }
}
