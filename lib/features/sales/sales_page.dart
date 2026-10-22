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
import '../../widgets/feature_tour.dart';

/// Moyens de paiement : code stable en base, libelle traduit a l'ecran.
const _paymentCodes = ['cash', 'mobile', 'card', 'transfer', 'credit'];

String _paymentLabel(AppLocalizations t, String code) {
  switch (code) {
    case 'cash':
      return t.cash;
    case 'mobile':
      return t.mobileMoney;
    case 'card':
      return t.card;
    case 'transfer':
      return t.transfer;
    case 'credit':
      return t.credit;
    default:
      return code;
  }
}

/// Caisse : catalogue + panier. Sur ecran large, panier lateral ;
/// sur mobile, barre du bas + panier en feuille modale.
class SalesPage extends ConsumerStatefulWidget {
  const SalesPage({super.key});
  @override
  ConsumerState<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends ConsumerState<SalesPage> {
  final List<SaleLine> _cart = [];
  final _search = TextEditingController();
  String _payment = 'cash';
  final kSearch = GlobalKey();
  final kCart = GlobalKey();
  final kTotals = GlobalKey();

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

    return GuidedTour(
      id: 'sales',
      steps: [
        TourStep(target: kSearch, title: t.search, body: t.gsSearchB),
        TourStep(target: kCart, title: t.cart, body: t.gsCartB),
        TourStep(target: kTotals, title: t.gsTotals, body: t.gsTotalsB),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(t.sales)),
        body: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (products) => LayoutBuilder(
            builder: (ctx, c) {
              if (c.maxWidth >= 720) {
                return Row(
                  children: [
                    Expanded(flex: 3, child: _buildCatalog(products)),
                    const VerticalDivider(width: 1),
                    SizedBox(width: 340, child: _buildCartPanel(null)),
                  ],
                );
              }
              return Column(
                children: [
                  Expanded(child: _buildCatalog(products)),
                  _buildMobileBar(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCatalog(List<Product> products) {
    final t = AppLocalizations.of(context);
    final q = _search.text.toLowerCase();
    final list = q.isEmpty
        ? products
        : products
            .where((e) =>
                e.name.toLowerCase().contains(q) ||
                e.sku.toLowerCase().contains(q))
            .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: KeyedSubtree(
            key: kSearch,
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: t.search,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(child: Text(t.noProducts))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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
                        borderRadius: BorderRadius.circular(14),
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
                                  style: Theme.of(context).textTheme.bodySmall),
                              const Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(p.sellPrice.toStringAsFixed(2),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  Text('×${p.quantity.toStringAsFixed(0)}',
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
                ),
        ),
      ],
    );
  }

  Widget _buildCartPanel(ScrollController? ctrl) {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(t.newSale, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: _cart.isEmpty ? null : () => setState(_cart.clear),
                child: Text(t.clear),
              ),
            ],
          ),
        ),
        Expanded(
          child: KeyedSubtree(
            key: kCart,
            child: _cart.isEmpty
                ? Center(child: Text(t.emptyCart))
                : ListView.builder(
                    controller: ctrl,
                    itemCount: _cart.length,
                    itemBuilder: (ctx, i) {
                      final l = _cart[i];
                      return ListTile(
                        dense: true,
                        title: Text(l.productName),
                        subtitle: Text(
                            '${l.quantity} × ${l.unitPrice.toStringAsFixed(2)}'),
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
        ),
        const Divider(height: 1),
        KeyedSubtree(
          key: kTotals,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _payment,
                  items: _paymentCodes
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(_paymentLabel(t, c))))
                      .toList(),
                  onChanged: (v) => setState(() => _payment = v ?? 'cash'),
                  decoration: InputDecoration(labelText: t.payment),
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
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _cart.isEmpty ? null : _checkout,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check),
                          const SizedBox(width: 8),
                          Text(t.checkout),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBar() {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${t.cart} (${_cart.length})',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(_total.toStringAsFixed(2),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.shopping_cart),
              label: Text(t.cart),
              onPressed: _cart.isEmpty ? null : _openCartSheet,
            ),
          ],
        ),
      ),
    );
  }

  void _openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, ctrl) => _buildCartPanel(ctrl),
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
    final t = AppLocalizations.of(context);
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

    final engine = ref.read(automationEngineProvider);
    for (final l in _cart) {
      await AppDatabase.instance.addMovement(StockMovement(
        productId: l.productId,
        type: MovementType.out,
        quantity: l.quantity,
        unitPrice: l.unitPrice,
        reference: number,
        reason: t.sales,
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
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.saleSaved(number))),
      );
    }
  }
}
