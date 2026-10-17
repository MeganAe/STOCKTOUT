import 'package:flutter/material.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/product.dart';

class ProductDialog extends StatefulWidget {
  final Product? product;
  const ProductDialog({super.key, this.product});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
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

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _sku = TextEditingController(text: p?.sku ?? '');
    _name = TextEditingController(text: p?.name ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _unit = TextEditingController(text: p?.unit ?? 'piece');
    _buy = TextEditingController(text: p != null ? '${p.buyPrice}' : '0');
    _sell = TextEditingController(text: p != null ? '${p.sellPrice}' : '0');
    _qty = TextEditingController(text: p != null ? '${p.quantity}' : '0');
    _min = TextEditingController(text: p != null ? '${p.minStock}' : '5');
  }

  @override
  void dispose() {
    _sku.dispose();
    _name.dispose();
    _barcode.dispose();
    _category.dispose();
    _unit.dispose();
    _buy.dispose();
    _sell.dispose();
    _qty.dispose();
    _min.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isEdit = widget.product != null;

    return Dialog(
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
                  Text(isEdit ? t.edit : t.newProduct,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: TextFormField(
                            controller: _sku,
                            decoration: InputDecoration(labelText: t.sku))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: TextFormField(
                            controller: _barcode,
                            decoration: const InputDecoration(
                                labelText: 'Code-barres'))),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: t.productName),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: TextFormField(
                            controller: _category,
                            decoration:
                                InputDecoration(labelText: t.category))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: TextFormField(
                            controller: _unit,
                            decoration: const InputDecoration(
                                labelText: 'Unite (piece, kg, L...)'))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: TextFormField(
                            controller: _buy,
                            keyboardType: TextInputType.number,
                            decoration:
                                InputDecoration(labelText: t.buyPrice))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: TextFormField(
                            controller: _sell,
                            keyboardType: TextInputType.number,
                            decoration:
                                InputDecoration(labelText: t.sellPrice))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: TextFormField(
                            controller: _qty,
                            keyboardType: TextInputType.number,
                            decoration:
                                InputDecoration(labelText: t.quantity))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: TextFormField(
                            controller: _min,
                            keyboardType: TextInputType.number,
                            decoration:
                                InputDecoration(labelText: t.minStock))),
                  ]),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(t.cancel)),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _save,
                        child: Text(t.save),
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
    final p = Product(
      id: existing?.id,
      sku: _sku.text.trim().isEmpty
          ? 'P-${DateTime.now().millisecondsSinceEpoch % 100000}'
          : _sku.text.trim(),
      name: _name.text.trim(),
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      unit: _unit.text.trim(),
      buyPrice: _num(_buy),
      sellPrice: _num(_sell),
      quantity: _num(_qty),
      minStock: _num(_min),
      createdAt: existing?.createdAt,
    );
    await AppDatabase.instance.upsertProduct(p);
    if (mounted) Navigator.pop(context, true);
  }
}
