import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/extra_strings.dart';
import '../../core/models/automation.dart';
import '../../core/models/product.dart';
import '../../core/models/sale.dart';
import '../../core/models/stock_movement.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/feature_tour.dart';
import 'sale_detail.dart';

/// Moyens de paiement : code stable en base, libelle traduit a l'ecran.
const _paymentCodes = ['cash', 'mobile', 'card', 'transfer', 'credit'];

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
  final _discount = TextEditingController();
  final _received = TextEditingController();
  final _customer = TextEditingController();
  bool _discountPercent = false;
  String _payment = 'cash';
  String? _notice;
  StateSetter? _sheetSet;
  final kSearch = GlobalKey();
  final kCart = GlobalKey();
  final kTotals = GlobalKey();

  @override
  void dispose() {
    _search.dispose();
    _discount.dispose();
    _received.dispose();
    _customer.dispose();
    super.dispose();
  }

  /// Met a jour la page ET le panier ouvert en feuille modale (mobile).
  void _refresh([VoidCallback? fn]) {
    setState(() {
      _notice = null;
      fn?.call();
    });
    _sheetSet?.call(() {});
  }

  static double _parse(String v) => double.tryParse(v.replaceAll(',', '.')) ?? 0;

  double get _subTotal => _cart.fold(0, (s, e) => s + e.total);

  /// Remise globale en montant (calculee depuis le % si besoin).
  double get _discountValue {
    final v = _parse(_discount.text);
    if (v <= 0) return 0;
    final d = _discountPercent ? _subTotal * (v > 100 ? 100 : v) / 100 : v;
    return d > _subTotal ? _subTotal : d;
  }

  double get _total => _subTotal - _discountValue;

  Product? _product(String id) => (ref.read(productsProvider).value ??
          const <Product>[])
      .firstWhereOrNull((e) => e.id == id);

  static String _q(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

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
    final text = Theme.of(context).textTheme;
    final cur = ref.read(settingsProvider).currency;
    final disc = _discountValue;
    final received = _parse(_received.text);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(t.newSale, style: text.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: _cart.isEmpty
                    ? null
                    : () => _refresh(() {
                          _cart.clear();
                          _discount.clear();
                          _received.clear();
                        }),
                child: Text(t.clear),
              ),
            ],
          ),
        ),
        Expanded(
          child: KeyedSubtree(
            key: kCart,
            child: ListView(
              controller: ctrl,
              children: _cart.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(child: Text(t.emptyCart)),
                      ),
                    ]
                  : [
                      for (var i = 0; i < _cart.length; i++) _cartLine(i),
                      const Divider(height: 24),
                      Padding(
                        key: const ValueKey('sale-options'),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            Row(children: [
                              Expanded(
                                child: TextField(
                                  controller: _discount,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.,]')),
                                  ],
                                  onChanged: (_) => _refresh(),
                                  decoration: InputDecoration(
                                    labelText: t.discount,
                                    prefixIcon:
                                        const Icon(Icons.local_offer_outlined),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SegmentedButton<bool>(
                                showSelectedIcon: false,
                                segments: [
                                  ButtonSegment(
                                      value: false, label: Text(cur)),
                                  const ButtonSegment(
                                      value: true, label: Text('%')),
                                ],
                                selected: {_discountPercent},
                                onSelectionChanged: (v) =>
                                    _refresh(() => _discountPercent = v.first),
                              ),
                            ]),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _payment,
                              items: _paymentCodes
                                  .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(paymentLabel(t, c))))
                                  .toList(),
                              onChanged: (v) =>
                                  _refresh(() => _payment = v ?? 'cash'),
                              decoration: InputDecoration(
                                labelText: t.payment,
                                prefixIcon: const Icon(Icons.payments_outlined),
                              ),
                            ),
                            if (_payment == 'cash') ...[
                              const SizedBox(height: 10),
                              TextField(
                                controller: _received,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.,]')),
                                ],
                                onChanged: (_) => _refresh(),
                                decoration: InputDecoration(
                                  labelText: t.amountReceived,
                                  prefixIcon: const Icon(Icons.attach_money),
                                ),
                              ),
                              if (received > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(t.changeDue),
                                      Text(
                                        (received - _total).toStringAsFixed(2),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: received >= _total
                                              ? Colors.green
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            const SizedBox(height: 10),
                            TextField(
                              controller: _customer,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: t.customerName,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
            ),
          ),
        ),
        const Divider(height: 1),
        KeyedSubtree(
          key: kTotals,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_notice != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(_notice!,
                        style: const TextStyle(color: Colors.orange)),
                  ),
                if (disc > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.subtotal),
                      Text(_subTotal.toStringAsFixed(2)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.discount),
                      Text('−${disc.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.total, style: text.titleLarge),
                    Text(_total.toStringAsFixed(2),
                        style: text.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _cart.isEmpty ? null : _checkout,
                    icon: const Icon(Icons.check),
                    label: Text(t.checkout),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Ligne du panier : toucher le nom pour modifier prix / remise.
  Widget _cartLine(int i) {
    final l = _cart[i];
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _editLine(i),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${l.unitPrice.toStringAsFixed(2)}'
                    '${l.discount > 0 ? '  −${l.discount.toStringAsFixed(2)}' : ''}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _changeQty(i, -1),
          ),
          SizedBox(
            width: 30,
            child: Center(child: Text(_q(l.quantity))),
          ),
          IconButton(
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _changeQty(i, 1),
          ),
          SizedBox(
            width: 70,
            child: Text(l.total.toStringAsFixed(2),
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => _refresh(() => _cart.removeAt(i)),
          ),
        ],
      ),
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          _sheetSet = setSheet;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (_, c) => _buildCartPanel(c),
            ),
          );
        },
      ),
    ).whenComplete(() => _sheetSet = null);
  }

  void _warnStock(Product p) {
    final t = AppLocalizations.of(context);
    final msg =
        '${t.notEnoughStock} : ${p.name} (${_q(p.quantity)})';
    _refresh(() => _notice = msg);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _addToCart(Product p) {
    final i = _cart.indexWhere((e) => e.productId == p.id);
    final current = i >= 0 ? _cart[i].quantity : 0.0;
    if (current + 1 > p.quantity) {
      _warnStock(p);
      return;
    }
    _refresh(() {
      if (i >= 0) {
        _cart[i] = _cart[i].copyWith(quantity: current + 1);
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

  void _changeQty(int i, double delta) {
    final l = _cart[i];
    final q = l.quantity + delta;
    if (q <= 0) {
      _refresh(() => _cart.removeAt(i));
      return;
    }
    final p = _product(l.productId);
    if (p != null && q > p.quantity) {
      _warnStock(p);
      return;
    }
    _refresh(() => _cart[i] = l.copyWith(quantity: q));
  }

  Future<void> _editLine(int i) async {
    final l = _cart[i];
    final res = await showDialog<SaleLine>(
      context: context,
      builder: (_) => _LineEditDialog(line: l, product: _product(l.productId)),
    );
    if (res != null) _refresh(() => _cart[i] = res);
  }

  Future<void> _checkout() async {
    final t = AppLocalizations.of(context);
    final settings = ref.read(settingsProvider);
    final customer = _customer.text.trim();
    if (_payment == 'credit' && customer.isEmpty) {
      _refresh(() => _notice = t.customerRequired);
      return;
    }

    final number = 'V-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final linesJson = jsonEncode(_cart.map((e) => e.toMap()).toList());
    final lines = List<SaleLine>.of(_cart);
    final discount = _discountValue;

    final row = <String, Object?>{
      'id': const Uuid().v4(),
      'number': number,
      'date': DateTime.now().toIso8601String(),
      'customer_id': null,
      'customer_name': customer,
      'lines': linesJson,
      'discount': discount,
      'tax': 0,
      'currency': settings.currency,
      'rate': 1,
      'payment_method': _payment,
      'notes': '',
    };
    await AppDatabase.instance.insertSale(row);

    final engine = ref.read(automationEngineProvider);
    for (final l in lines) {
      await AppDatabase.instance.addMovement(StockMovement(
        productId: l.productId,
        type: MovementType.out,
        quantity: l.quantity,
        unitPrice: l.quantity > 0 ? l.total / l.quantity : l.unitPrice,
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

    if (!mounted) return;
    final sheetWasOpen = _sheetSet != null;
    _refresh(() {
      _cart.clear();
      _discount.clear();
      _received.clear();
      _customer.clear();
      _discountPercent = false;
    });
    ref.invalidate(productsProvider);
    ref.invalidate(salesProvider);
    if (sheetWasOpen) Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(t.saleSaved(number)),
          action: SnackBarAction(
            label: t.receipt,
            onPressed: () => showSaleDetail(context, ref, row),
          ),
        ),
      );
  }
}

/// Modification d'une ligne : quantite, prix unitaire, remise sur la ligne.
class _LineEditDialog extends StatefulWidget {
  final SaleLine line;
  final Product? product;
  const _LineEditDialog({required this.line, this.product});

  @override
  State<_LineEditDialog> createState() => _LineEditDialogState();
}

class _LineEditDialogState extends State<_LineEditDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _qty;
  late final TextEditingController _price;
  late final TextEditingController _disc;

  static String _f(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    _qty = TextEditingController(text: _f(widget.line.quantity));
    _price = TextEditingController(text: _f(widget.line.unitPrice));
    _disc = TextEditingController(
        text: widget.line.discount > 0 ? _f(widget.line.discount) : '');
  }

  @override
  void dispose() {
    _qty.dispose();
    _price.dispose();
    _disc.dispose();
    super.dispose();
  }

  double _n(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  bool get _belowCost {
    final p = widget.product;
    final q = _n(_qty);
    if (p == null || q <= 0) return false;
    return (_n(_price) * q - _n(_disc)) / q < p.buyPrice;
  }

  Widget _field(TextEditingController c, String label,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onChanged: (_) => setState(() {}),
      onTap: () =>
          c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length),
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final stock = widget.product?.quantity;
    return AlertDialog(
      title: Text(widget.line.productName),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_qty, t.quantity, validator: (v) {
                final q = double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0;
                if (q <= 0) return t.required;
                if (stock != null && q > stock) return t.notEnoughStock;
                return null;
              }),
              const SizedBox(height: 12),
              _field(_price, t.sellPrice),
              const SizedBox(height: 12),
              _field(_disc, t.lineDiscount),
              if (_belowCost)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(t.belowCost,
                          style: const TextStyle(color: Colors.orange)),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              widget.line.copyWith(
                quantity: _n(_qty),
                unitPrice: _n(_price),
                discount: _n(_disc),
              ),
            );
          },
          child: Text(t.confirm),
        ),
      ],
    );
  }
}
