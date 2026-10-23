import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/product.dart';

/// Formulaire produit pense pour aller vite :
/// - le nom suffit ; reference et code-barres sont generes automatiquement,
/// - categorie et unite se choisissent d'un tap (puces) et sont memorisees,
/// - le prix de vente se calcule tout seul a partir du prix d'achat.
class ProductDialog extends StatefulWidget {
  final Product? product;
  const ProductDialog({super.key, this.product});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  static const _defaultMargin = 0.30; // 30 % de marge proposee
  static const _units = ['pc', 'kg', 'L', 'm', 'box'];

  final _form = GlobalKey<FormState>();
  late final TextEditingController _sku;
  late final TextEditingController _name;
  late final TextEditingController _barcode;
  late final TextEditingController _category;
  late final TextEditingController _unit;
  late final TextEditingController _buy;
  late final TextEditingController _sell;
  late final TextEditingController _qty;
  late final TextEditingController _min;

  List<String> _categories = [];
  bool _sellTouched = false;
  bool get _isEdit => widget.product != null;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _sku = TextEditingController(text: p?.sku ?? '');
    _name = TextEditingController(text: p?.name ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _unit = TextEditingController(text: p?.unit ?? 'pc');
    _buy = TextEditingController(text: p != null ? _fmt(p.buyPrice) : '0');
    _sell = TextEditingController(text: p != null ? _fmt(p.sellPrice) : '0');
    _qty = TextEditingController(text: p != null ? _fmt(p.quantity) : '0');
    _min = TextEditingController(text: p != null ? _fmt(p.minStock) : '5');
    _sellTouched = _isEdit;
    _loadHints();
  }

  /// Prepare les valeurs automatiques : reference suivante, categories
  /// deja utilisees, derniere categorie / unite choisies.
  Future<void> _loadHints() async {
    final all = await AppDatabase.instance.allProducts();
    final cats = <String>{
      for (final e in all)
        if ((e.category ?? '').trim().isNotEmpty) e.category!.trim(),
    }.toList()
      ..sort();

    String? nextSku;
    String? lastCat;
    String? lastUnit;
    if (!_isEdit) {
      var maxN = 0;
      final re = RegExp(r'^P-(\d+)$');
      for (final e in all) {
        final m = re.firstMatch(e.sku);
        if (m != null) {
          final n = int.tryParse(m.group(1)!) ?? 0;
          if (n > maxN) maxN = n;
        }
      }
      nextSku = 'P-${(maxN + 1).toString().padLeft(4, '0')}';
      final prefs = await SharedPreferences.getInstance();
      lastCat = prefs.getString('last_category');
      lastUnit = prefs.getString('last_unit');
    }
    if (!mounted) return;
    setState(() {
      _categories = cats.take(8).toList();
      if (nextSku != null && _sku.text.isEmpty) _sku.text = nextSku;
      if (lastCat != null && _category.text.isEmpty) _category.text = lastCat;
      if (lastUnit != null && lastUnit.isNotEmpty) _unit.text = lastUnit;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _sku, _name, _barcode, _category, _unit, _buy, _sell, _qty, _min,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  /// Code-barres interne EAN-13 valide (prefixe 200 = usage en magasin).
  String _generateEan13() {
    final ms = DateTime.now().millisecondsSinceEpoch % 1000000000;
    final base = '200${ms.toString().padLeft(9, '0')}';
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      final d = int.parse(base[i]);
      sum += i.isEven ? d : d * 3;
    }
    return '$base${(10 - sum % 10) % 10}';
  }

  void _onBuyChanged(String _) {
    if (_sellTouched) return;
    final buy = _num(_buy);
    _sell.text = buy > 0 ? _fmt((buy * (1 + _defaultMargin))) : '0';
  }

  Widget _numField(
    TextEditingController c,
    String label, {
    ValueChanged<String>? onChanged,
    bool last = false,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onChanged: onChanged,
      // Un tap selectionne tout : plus besoin d'effacer le "0".
      onTap: () => c.selection =
          TextSelection(baseOffset: 0, extentOffset: c.text.length),
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _chips(List<String> values, TextEditingController c) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final v in values)
            ChoiceChip(
              label: Text(v),
              selected: c.text.trim() == v,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => setState(() => c.text = v),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isEdit ? t.edit : t.newProduct,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _name,
                    autofocus: !_isEdit,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t.productName,
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? t.required : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _category,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: t.category,
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                  ),
                  _chips(_categories, _category),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _unit,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: t.unitHint,
                      prefixIcon: const Icon(Icons.straighten),
                    ),
                  ),
                  _chips(_units, _unit),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _numField(_buy, t.buyPrice,
                          onChanged: _onBuyChanged),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numField(_sell, t.sellPrice,
                          onChanged: (_) => _sellTouched = true),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _numField(_qty, t.quantity)),
                    const SizedBox(width: 12),
                    Expanded(child: _numField(_min, t.minStock, last: true)),
                  ]),
                  const SizedBox(height: 4),
                  // Reference et code-barres : automatiques, modifiables.
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      initiallyExpanded: _isEdit,
                      leading: const Icon(Icons.qr_code_2),
                      title: Text('${t.sku} / ${t.barcode}'),
                      children: [
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sku,
                              decoration: InputDecoration(labelText: t.sku),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _barcode,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: t.barcode,
                                suffixIcon: IconButton(
                                  tooltip: t.barcode,
                                  icon: const Icon(Icons.auto_awesome),
                                  onPressed: () => setState(
                                      () => _barcode.text = _generateEan13()),
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(t.cancel)),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check),
                        label: Text(t.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final existing = widget.product;
    final sku = _sku.text.trim().isEmpty
        ? 'P-${DateTime.now().millisecondsSinceEpoch % 100000}'
        : _sku.text.trim();
    var barcode = _barcode.text.trim();
    if (barcode.isEmpty && !_isEdit) barcode = _generateEan13();
    final cat = _category.text.trim();
    final unit = _unit.text.trim().isEmpty ? 'pc' : _unit.text.trim();

    final p = Product(
      id: existing?.id,
      sku: sku,
      name: _name.text.trim(),
      barcode: barcode.isEmpty ? null : barcode,
      category: cat.isEmpty ? null : cat,
      unit: unit,
      buyPrice: _num(_buy),
      sellPrice: _num(_sell),
      quantity: _num(_qty),
      minStock: _num(_min),
      createdAt: existing?.createdAt,
    );
    await AppDatabase.instance.upsertProduct(p);

    // Memorise categorie / unite pour le prochain produit.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_category', cat);
    await prefs.setString('last_unit', unit);

    if (mounted) Navigator.pop(context, true);
  }
}
