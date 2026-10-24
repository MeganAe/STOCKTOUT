import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/v5_strings.dart';
import '../../core/logic/money_format.dart';
import '../../core/logic/stats.dart';
import '../../core/models/expense.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/feature_tour.dart';

/// Catégories prédéfinies (code stable en base ; le libellé est traduit).
const kExpenseCategories = [
  'transport',
  'rent',
  'electricity',
  'salary',
  'supplies',
  'other',
];

String expenseCategoryLabel(AppLocalizations t, String code) =>
    kExpenseCategories.contains(code) ? t.expenseCategory(code) : code;

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final kTotal = GlobalKey();
  final kAdd = GlobalKey();

  void _shift(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  Future<void> _edit([Expense? e]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ExpenseDialog(expense: e),
    );
    if (saved == true) ref.invalidate(expensesProvider);
  }

  Future<void> _delete(Expense e) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.delete),
        content: Text(t.deleteExpenseAsk),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(t.no)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(t.yes)),
        ],
      ),
    );
    if (ok != true) return;
    await AppDatabase.instance.deleteExpense(e.id);
    ref.invalidate(expensesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final base = ref.watch(settingsProvider).currency;
    final fmt = MoneyFmt(ref.watch(currenciesProvider).valueOrNull ?? const []);
    final rates =
        ref.watch(ratesProvider).valueOrNull ?? const <String, double>{};
    final async = ref.watch(expensesProvider);

    return GuidedTour(
      id: 'expenses',
      steps: [
        TourStep(
            target: kTotal,
            title: t.expensesTourTotal,
            body: t.expensesTourTotalB),
        TourStep(target: kAdd, title: t.addExpense, body: t.expensesTourAddB),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(t.expenses)),
        floatingActionButton: KeyedSubtree(
          key: kAdd,
          child: FloatingActionButton.extended(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: Text(t.addExpense),
          ),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (all) {
            final list = all
                .where((e) =>
                    e.date.year == _month.year && e.date.month == _month.month)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            final total = expensesTotalForMonth(
                all, rates, base, _month.year, _month.month);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                KeyedSubtree(
                  key: kTotal,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => _shift(-1),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                    '${_month.month.toString().padLeft(2, '0')}/${_month.year}'),
                                Text(
                                  fmt(total, base),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(t.monthExpenses),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _shift(1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(t.noExpenses)),
                  ),
                for (final e in list)
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.receipt_long_outlined)),
                      title: Text(expenseCategoryLabel(t, e.category)),
                      subtitle: Text(
                          '${_date(e.date)}${(e.note ?? '').isEmpty ? '' : ' · ${e.note}'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(fmt(e.amount, e.currency),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(e),
                          ),
                        ],
                      ),
                      onTap: () => _edit(e),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExpenseDialog extends ConsumerStatefulWidget {
  final Expense? expense;
  const _ExpenseDialog({this.expense});

  @override
  ConsumerState<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends ConsumerState<_ExpenseDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _custom = TextEditingController();
  String _category = 'transport';
  late String _currency;
  late DateTime _date;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _currency = e?.currency ?? ref.read(settingsProvider).currency;
    _date = e?.date ?? DateTime.now();
    if (e != null) {
      _amount.text = e.amount == e.amount.roundToDouble()
          ? e.amount.toInt().toString()
          : e.amount.toString();
      _note.text = e.note ?? '';
      if (kExpenseCategories.contains(e.category)) {
        _category = e.category;
      } else {
        _category = 'other';
        _custom.text = e.category;
      }
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _custom.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final v = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
    if (v <= 0) {
      setState(() => _error = t.required);
      return;
    }
    final category = (_category == 'other' && _custom.text.trim().isNotEmpty)
        ? _custom.text.trim()
        : _category;
    final old = widget.expense;
    await AppDatabase.instance.upsertExpense(Expense(
      id: old?.id,
      // Garde l'heure pour l'ordre d'affichage ; seule la date compte.
      date: DateTime(
          _date.year,
          _date.month,
          _date.day,
          old?.date.hour ?? DateTime.now().hour,
          old?.date.minute ?? DateTime.now().minute),
      category: category,
      amount: v,
      currency: _currency,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final currencies = ref.watch(currenciesProvider).valueOrNull ?? const [];
    return AlertDialog(
      title: Text(widget.expense == null ? t.addExpense : t.edit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    autofocus: widget.expense == null,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration:
                        InputDecoration(labelText: t.amount, errorText: _error),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 96,
                  child: DropdownButtonFormField<String>(
                    value: currencies.any((c) => c.code == _currency)
                        ? _currency
                        : null,
                    isExpanded: true,
                    items: [
                      for (final c in currencies)
                        DropdownMenuItem(value: c.code, child: Text(c.code)),
                    ],
                    onChanged: (v) =>
                        setState(() => _currency = v ?? _currency),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c in kExpenseCategories)
                  ChoiceChip(
                    label: Text(t.expenseCategory(c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            if (_category == 'other') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _custom,
                decoration: InputDecoration(labelText: t.customCategory),
              ),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: t.dateLabel,
                  prefixIcon: const Icon(Icons.event),
                ),
                child: Text(_dateText(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: InputDecoration(labelText: t.noteOptional),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel)),
        FilledButton(onPressed: _save, child: Text(t.save)),
      ],
    );
  }

  String _dateText(DateTime d) => _date2(d);
}

String _date2(DateTime d) => _date(d);
