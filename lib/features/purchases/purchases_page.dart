import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/v5_strings.dart';
import '../../core/logic/money_format.dart';
import '../../core/logic/purchases.dart';
import '../../core/models/product.dart';
import '../../core/models/purchase.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/customer_picker.dart';
import '../../widgets/feature_tour.dart';

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class PurchasesPage extends ConsumerStatefulWidget {
  const PurchasesPage({super.key});
  @override
  ConsumerState<PurchasesPage> createState() => _PurchasesPageState();
}

class _PurchasesPageState extends ConsumerState<PurchasesPage> {
  List<Purchase> _rows = [];
  bool _loading = true;
  bool _busy = false;
  final kAction = GlobalKey();
  final kList = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await AppDatabase.instance.allPurchases();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _newPurchase() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PurchaseEditorPage()),
    );
    if (saved == true) await _load();
  }

  Future<void> _receive(Purchase p) async {
    final t = AppLocalizations.of(context);
    if (_busy) return; // protège contre un double appui
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.receivePurchaseTitle),
        content: Text(t.receivePurchaseAsk(p.number)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.receive)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final rates = await ref.read(ratesProvider.future);
      final base = ref.read(settingsProvider).currency;
      final done = await AppDatabase.instance.receivePurchase(
        p.id,
        rates: rates,
        base: base,
        reason: t.purchases,
      );
      ref.invalidate(productsProvider);
      await _load();
      if (mounted)
        _snack(done ? t.purchaseReceived : t.purchaseAlreadyReceived);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(Purchase p) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.cancelPurchaseTitle),
        content: Text(t.cancelPurchaseAsk(p.number)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(t.no)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(t.yes)),
        ],
      ),
    );
    if (ok != true) return;
    final done = await AppDatabase.instance.cancelPurchase(p.id);
    await _load();
    if (mounted) _snack(done ? t.purchaseCancelled : t.purchaseAlreadyReceived);
  }

  String _statusLabel(AppLocalizations t, String s) => switch (s) {
        PurchaseStatus.received => t.received,
        PurchaseStatus.cancelled => t.cancelledLabel,
        _ => t.draft,
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final fmt = MoneyFmt(ref.watch(currenciesProvider).valueOrNull ?? const []);
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
                        final p = _rows[i];
                        final isDraft = canReceive(p.status);
                        final color = switch (p.status) {
                          PurchaseStatus.received => Colors.green,
                          PurchaseStatus.cancelled => Colors.grey,
                          _ => Colors.orange,
                        };
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              switch (p.status) {
                                PurchaseStatus.received => Icons.check_circle,
                                PurchaseStatus.cancelled => Icons.cancel,
                                _ => Icons.pending_outlined,
                              },
                              color: color,
                            ),
                            title: Text(
                                '${p.number}${p.supplierName.isEmpty ? '' : ' — ${p.supplierName}'}'),
                            subtitle: Text(
                                '${_date(p.date)} · ${_statusLabel(t, p.status)} · ${t.linesCount(p.lines.length)}'
                                '${p.total > 0 ? ' · ${fmt(p.total, p.currency)}' : ''}'),
                            onTap: () => _showDetail(p, fmt),
                            trailing: isDraft
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: t.cancelPurchaseTitle,
                                        icon: const Icon(Icons.close),
                                        onPressed:
                                            _busy ? null : () => _cancel(p),
                                      ),
                                      FilledButton.tonal(
                                        onPressed:
                                            _busy ? null : () => _receive(p),
                                        child: Text(t.receive),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  void _showDetail(Purchase p, MoneyFmt fmt) {
    final t = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          children: [
            Text('${p.number} · ${_date(p.date)}',
                style: Theme.of(context).textTheme.titleMedium),
            if (p.supplierName.isNotEmpty) Text(p.supplierName),
            Text(_statusLabel(t, p.status)),
            const Divider(),
            if (p.lines.isEmpty) Text(t.noData),
            for (final l in p.lines)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title:
                    Text(l.productName.isEmpty ? l.productId : l.productName),
                subtitle: Text(
                    '${l.quantity.toStringAsFixed(l.quantity == l.quantity.roundToDouble() ? 0 : 2)}'
                    '${l.unitCost == null ? '' : ' × ${fmt(l.unitCost!, p.currency)}'}'),
                trailing:
                    l.unitCost == null ? null : Text(fmt(l.total, p.currency)),
              ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(fmt(p.total, p.currency),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if ((p.notes ?? '').isNotEmpty) Text(p.notes!),
          ],
        ),
      ),
    );
  }
}

/// Création d'un achat : fournisseur (liste des partenaires), plusieurs
/// lignes (produit, quantité, coût unitaire), devise par défaut.
class PurchaseEditorPage extends ConsumerStatefulWidget {
  const PurchaseEditorPage({super.key});

  @override
  ConsumerState<PurchaseEditorPage> createState() => _PurchaseEditorState();
}

class _PurchaseEditorState extends ConsumerState<PurchaseEditorPage> {
  final List<PurchaseLine> _lines = [];
  final _notes = TextEditingController();
  String? _supplierId;
  String _supplierName = '';
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  double get _total => _lines.fold<double>(0, (s, l) => s + l.total);

  Future<void> _pickSupplier() async {
    final c = await pickPartner(context, kind: 'supplier');
    if (c != null) {
      setState(() {
        _supplierId = c.id;
        _supplierName = c.name;
      });
    }
  }

  Future<void> _addLine() async {
    final products = await AppDatabase.instance.allProducts();
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    if (products.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.addFirstProduct)));
      return;
    }
    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProductSheet(products: products),
    );
    if (product == null || !mounted) return;
    final line = await showDialog<PurchaseLine>(
      context: context,
      builder: (_) => _LineDialog(
        line: PurchaseLine(
          productId: product.id,
          productName: product.name,
          quantity: 1,
          unitCost: product.buyPrice > 0 ? product.buyPrice : null,
        ),
      ),
    );
    if (line != null) setState(() => _lines.add(line));
  }

  Future<void> _editLine(int i) async {
    final line = await showDialog<PurchaseLine>(
      context: context,
      builder: (_) => _LineDialog(line: _lines[i]),
    );
    if (line != null) setState(() => _lines[i] = line);
  }

  Future<void> _save({required bool receiveNow}) async {
    final t = AppLocalizations.of(context);
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.purchaseNeedsLine)));
      return;
    }
    setState(() => _saving = true);
    try {
      final base = ref.read(settingsProvider).currency;
      final purchase = Purchase(
        number: 'A-${DateTime.now().millisecondsSinceEpoch % 1000000}',
        supplierId: _supplierId,
        supplierName: _supplierName,
        lines: List.of(_lines),
        currency: base, // devise par défaut, plus de 'USD' en dur
        notes: _notes.text.trim(),
      );
      await AppDatabase.instance.insertPurchase(purchase);
      if (receiveNow) {
        final rates = await ref.read(ratesProvider.future);
        await AppDatabase.instance.receivePurchase(purchase.id,
            rates: rates, base: base, reason: t.purchases);
        ref.invalidate(productsProvider);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final base = ref.watch(settingsProvider).currency;
    final fmt = MoneyFmt(ref.watch(currenciesProvider).valueOrNull ?? const []);
    return Scaffold(
      appBar: AppBar(title: Text(t.newPurchase)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickSupplier,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: t.supplier,
                prefixIcon: const Icon(Icons.local_shipping_outlined),
                suffixIcon: _supplierId == null
                    ? const Icon(Icons.arrow_drop_down)
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _supplierId = null;
                          _supplierName = '';
                        }),
                      ),
              ),
              child: Text(
                  _supplierName.isEmpty ? t.chooseSupplier : _supplierName),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: Text(t.purchaseLines,
                      style: Theme.of(context).textTheme.titleMedium)),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add),
                label: Text(t.addLine),
                onPressed: _addLine,
              ),
            ],
          ),
          if (_lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(t.purchaseNeedsLine)),
            ),
          for (var i = 0; i < _lines.length; i++)
            Card(
              child: ListTile(
                title: Text(_lines[i].productName),
                subtitle: Text(
                    '${_lines[i].quantity.toStringAsFixed(_lines[i].quantity == _lines[i].quantity.roundToDouble() ? 0 : 2)}'
                    '${_lines[i].unitCost == null ? '' : ' × ${fmt(_lines[i].unitCost!, base)}'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_lines[i].unitCost != null)
                      Text(fmt(_lines[i].total, base),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => _lines.removeAt(i)),
                    ),
                  ],
                ),
                onTap: () => _editLine(i),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            decoration: InputDecoration(labelText: t.noteOptional),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${t.total} : ${fmt(_total, base)}',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _saving ? null : () => _save(receiveNow: false),
                child: Text(t.saveDraft),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.inventory),
                label: Text(t.saveAndReceive),
                onPressed: _saving ? null : () => _save(receiveNow: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductSheet extends StatefulWidget {
  final List<Product> products;
  const _ProductSheet({required this.products});

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final q = _q.toLowerCase();
    final list = widget.products
        .where((p) =>
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q))
        .toList();
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: t.search,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(list[i].name),
                  subtitle: Text(
                      '${list[i].sku} · ${t.quantity}: ${list[i].quantity.toStringAsFixed(0)}'),
                  onTap: () => Navigator.pop(context, list[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineDialog extends StatefulWidget {
  final PurchaseLine line;
  const _LineDialog({required this.line});

  @override
  State<_LineDialog> createState() => _LineDialogState();
}

class _LineDialogState extends State<_LineDialog> {
  late final TextEditingController _qty;
  late final TextEditingController _cost;
  String? _error;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void initState() {
    super.initState();
    _qty = TextEditingController(text: _fmt(widget.line.quantity));
    _cost = TextEditingController(
        text: widget.line.unitCost == null ? '' : _fmt(widget.line.unitCost!));
  }

  @override
  void dispose() {
    _qty.dispose();
    _cost.dispose();
    super.dispose();
  }

  double? _num(String s) => double.tryParse(s.replaceAll(',', '.'));

  void _ok() {
    final t = AppLocalizations.of(context);
    final q = _num(_qty.text) ?? 0;
    if (q <= 0) {
      setState(() => _error = t.required);
      return;
    }
    final c = _cost.text.trim().isEmpty ? null : _num(_cost.text);
    Navigator.pop(
      context,
      PurchaseLine(
        productId: widget.line.productId,
        productName: widget.line.productName,
        quantity: q,
        unitCost: (c != null && c >= 0) ? c : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final formatters = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return AlertDialog(
      title: Text(widget.line.productName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _qty,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: formatters,
            decoration:
                InputDecoration(labelText: t.quantity, errorText: _error),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: formatters,
            decoration: InputDecoration(
                labelText: t.unitCost, helperText: t.unitCostHint),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(onPressed: _ok, child: Text(t.save)),
      ],
    );
  }
}
