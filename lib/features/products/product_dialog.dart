import 'dart:io';

import 'package:app_settings/app_settings.dart' as sys;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/v5_strings.dart';
import '../../core/logic/product_codes.dart';
import '../../core/logic/product_lookup.dart';
import '../../core/models/product.dart';
import '../../core/services/image_service.dart';
import '../../widgets/lock_gate.dart';
import '../../widgets/product_thumb.dart';
import 'scanner_page.dart';

/// Formulaire produit pense pour aller vite :
/// - le nom suffit ; reference et code-barres sont generes automatiquement,
/// - categorie et unite se choisissent d'un tap (puces) et sont memorisees,
/// - le prix de vente se calcule tout seul a partir du prix d'achat.
class ProductDialog extends StatefulWidget {
  final Product? product;

  /// Code-barres pré-rempli (produit inconnu rencontré au scan).
  final String? initialBarcode;
  const ProductDialog({super.key, this.product, this.initialBarcode});

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
  List<Product> _all = [];
  late final String _pid;
  DateTime? _expiry;
  String? _imagePath; // photo enregistrée
  String? _pendingImage; // nouvelle photo pas encore enregistrée
  bool _imageRemoved = false;
  String? _barcodeWarning;
  bool _sellTouched = false;
  bool get _isEdit => widget.product != null;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    // Identifiant fixé dès l'ouverture : la photo est nommée <id>.jpg.
    _pid = p?.id ?? const Uuid().v4();
    _expiry = p?.expiryDate;
    _imagePath = p?.imagePath;
    _sku = TextEditingController(text: p?.sku ?? '');
    _name = TextEditingController(text: p?.name ?? '');
    _barcode =
        TextEditingController(text: p?.barcode ?? widget.initialBarcode ?? '');
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
      nextSku = nextSkuFor(all);
      final prefs = await SharedPreferences.getInstance();
      lastCat = prefs.getString('last_category');
      lastUnit = prefs.getString('last_unit');
    }
    if (!mounted) return;
    setState(() {
      _all = all;
      _categories = cats.take(8).toList();
      if (nextSku != null && _sku.text.isEmpty) _sku.text = nextSku;
      if (lastCat != null && _category.text.isEmpty) _category.text = lastCat;
      if (lastUnit != null && lastUnit.isNotEmpty) _unit.text = lastUnit;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _sku,
      _name,
      _barcode,
      _category,
      _unit,
      _buy,
      _sell,
      _qty,
      _min,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  /// Prochaine référence libre (logique partagée avec l'import).
  static String nextSkuFor(List<Product> all) => nextSku(all.map((e) => e.sku));

  String _generateEan13() => generateEan13();

  Future<void> _scanBarcode() async {
    final t = AppLocalizations.of(context);
    String? code;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ScannerPage(onCode: (c) => code = c),
    ));
    final c = code;
    if (c == null || !mounted) return;
    final dup = findProductByCode(_all, c);
    setState(() {
      _barcode.text = c;
      _barcodeWarning =
          (dup != null && dup.id != _pid) ? t.barcodeExists(dup.name) : null;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final t = AppLocalizations.of(context);
    try {
      final path = await LockGuard.external(
          () => ImageService.pickPending(source, _pid));
      if (path == null || !mounted) return;
      PaintingBinding.instance.imageCache.clear();
      setState(() {
        _pendingImage = path;
        _imageRemoved = false;
      });
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t.cameraDenied),
        action: SnackBarAction(
            label: t.openSettings,
            onPressed: () => sys.AppSettings.openAppSettings()),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.photoError)));
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15),
    );
    if (d != null) setState(() => _expiry = d);
  }

  String _dateText(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _cancel() async {
    await ImageService.delete(_pendingImage);
    if (mounted) Navigator.pop(context, false);
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ProductThumb(
                        path: _imageRemoved
                            ? null
                            : (_pendingImage ?? _imagePath),
                        size: 72,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (Platform.isAndroid || Platform.isIOS)
                              OutlinedButton.icon(
                                onPressed: () => _pickPhoto(ImageSource.camera),
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: Text(t.takePhoto),
                              ),
                            OutlinedButton.icon(
                              onPressed: () => _pickPhoto(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(t.chooseGallery),
                            ),
                            if ((_pendingImage ?? _imagePath) != null &&
                                !_imageRemoved)
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _imageRemoved = true;
                                  _pendingImage = null;
                                }),
                                icon: const Icon(Icons.delete_outline),
                                label: Text(t.removePhoto),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                      child:
                          _numField(_buy, t.buyPrice, onChanged: _onBuyChanged),
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
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickExpiry,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: t.expiryDate,
                        prefixIcon: const Icon(Icons.event_busy_outlined),
                        suffixIcon: _expiry == null
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() => _expiry = null),
                              ),
                      ),
                      child: Text(
                          _expiry == null ? t.noExpiry : _dateText(_expiry!)),
                    ),
                  ),
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
                              onChanged: (_) {
                                if (_barcodeWarning != null) {
                                  setState(() => _barcodeWarning = null);
                                }
                              },
                              decoration: InputDecoration(
                                labelText: t.barcode,
                                helperText: _barcodeWarning,
                                helperStyle:
                                    const TextStyle(color: Colors.orange),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (Platform.isAndroid || Platform.isIOS)
                                      IconButton(
                                        tooltip: t.scanBarcode,
                                        icon: const Icon(Icons.qr_code_scanner),
                                        onPressed: _scanBarcode,
                                      ),
                                    IconButton(
                                      tooltip: t.barcode,
                                      icon: const Icon(Icons.auto_awesome),
                                      onPressed: () => setState(() =>
                                          _barcode.text = _generateEan13()),
                                    ),
                                  ],
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
                      TextButton(onPressed: _cancel, child: Text(t.cancel)),
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

    // Photo : promue de « temporaire » à <id>.jpg, ou supprimée.
    String? image = _imagePath;
    if (_imageRemoved) {
      await ImageService.delete(_imagePath);
      image = null;
    } else if (_pendingImage != null) {
      image = await ImageService.commit(_pendingImage!, _pid);
    }

    final p = Product(
      id: _pid,
      sku: sku,
      name: _name.text.trim(),
      barcode: barcode.isEmpty ? null : barcode,
      category: cat.isEmpty ? null : cat,
      unit: unit,
      buyPrice: _num(_buy),
      sellPrice: _num(_sell),
      quantity: _num(_qty),
      minStock: _num(_min),
      // Champs que le formulaire n'édite pas : on les conserve.
      supplierId: existing?.supplierId,
      location: existing?.location,
      notes: existing?.notes,
      expiryDate: _expiry,
      imagePath: image,
      createdAt: existing?.createdAt,
    );
    final t = AppLocalizations.of(context);
    // Produit + mouvement de stock (entrée initiale / ajustement) ensemble.
    await AppDatabase.instance.saveProductWithStock(
      p,
      quantityEdited:
          existing == null || (_num(_qty) - existing.quantity).abs() > 1e-9,
      reasonInitial: t.stockInitial,
      reasonAdjust: t.stockManualAdjust,
    );

    // Memorise categorie / unite pour le prochain produit.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_category', cat);
    await prefs.setString('last_unit', unit);

    if (mounted) Navigator.pop(context, true);
  }
}
