import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/v5_strings.dart';
import '../../core/logic/debts.dart';
import '../../core/logic/money_format.dart';
import '../../core/models/payment.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/feature_tour.dart';
import '../../widgets/lock_gate.dart';
import '../sales/sale_detail.dart';

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Liste des clients qui doivent de l'argent, du plus gros débiteur au plus
/// petit. Le total est affiché dans la devise par défaut.
class DebtsPage extends ConsumerStatefulWidget {
  const DebtsPage({super.key});

  @override
  ConsumerState<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends ConsumerState<DebtsPage> {
  final kList = GlobalKey();
  final kTotal = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final debtsAsync = ref.watch(debtsProvider);
    final base = ref.watch(settingsProvider).currency;
    final fmt = MoneyFmt(ref.watch(currenciesProvider).valueOrNull ?? const []);

    return GuidedTour(
      id: 'debts',
      steps: [
        TourStep(
            target: kTotal, title: t.debtsTourTotal, body: t.debtsTourTotalB),
        TourStep(target: kList, title: t.debtsTourList, body: t.debtsTourListB),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(t.debts)),
        body: debtsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (debts) {
            if (debts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_outlined, size: 56),
                      const SizedBox(height: 12),
                      Text(t.noDebts, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                KeyedSubtree(
                  key: kTotal,
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.totalOwed),
                                Text(
                                  fmt(totalDebt(debts), base),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Text(t.debtors(debts.length)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                KeyedSubtree(
                  key: kList,
                  child: Column(
                    children: [
                      for (final d in debts)
                        Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(d.name.isEmpty
                                  ? '?'
                                  : d.name[0].toUpperCase()),
                            ),
                            title: Text(d.name,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                                '${t.openSales(d.sales.length)} · ${t.since(_date(d.sales.first.sale.date))}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (final e in d.byCurrency.entries)
                                  Text(fmt(e.value, e.key),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error)),
                              ],
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    CustomerDebtPage(customerKey: d.key),
                              ),
                            ),
                          ),
                        ),
                    ],
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

/// Détail d'un client : ventes impayées, historique des paiements,
/// encaissement et rappel à partager.
class CustomerDebtPage extends ConsumerWidget {
  final String customerKey;
  const CustomerDebtPage({super.key, required this.customerKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final debts = ref.watch(debtsProvider).valueOrNull ?? const [];
    final payments = ref.watch(paymentsProvider).valueOrNull ?? const [];
    final fmt = MoneyFmt(ref.watch(currenciesProvider).valueOrNull ?? const []);
    final matches = debts.where((d) => d.key == customerKey);
    final debt = matches.isEmpty ? null : matches.first;
    final history = payments
        .where((p) => customerKeyOf(p.partnerId, p.customerName) == customerKey)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: Text(debt?.name ?? t.debts)),
      body: debt == null && history.isEmpty
          ? Center(child: Text(t.noDebts))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (debt != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.totalOwed),
                          for (final e in debt.byCurrency.entries)
                            Text(fmt(e.value, e.key),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                icon: const Icon(Icons.payments_outlined),
                                label: Text(t.recordPayment),
                                onPressed: () =>
                                    _recordPayment(context, ref, debt),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.share_outlined),
                                label: Text(t.sendReminder),
                                onPressed: () => LockGuard.external(
                                  () =>
                                      Share.share(_reminderText(t, debt, fmt)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(t.unpaidSales,
                      style: Theme.of(context).textTheme.titleMedium),
                  for (final o in debt.sales)
                    Card(
                      child: ListTile(
                        title: Text(o.sale.number),
                        subtitle: Text(
                            '${_date(o.sale.date)} · ${t.saleTotalPaid(fmt(o.sale.total, o.sale.currency), fmt(o.sale.total - o.outstanding, o.sale.currency))}'),
                        trailing: Text(fmt(o.outstanding, o.sale.currency),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.error)),
                        onTap: () async {
                          final rows = await AppDatabase.instance.allSales();
                          final row =
                              rows.where((r) => r['id'] == o.sale.id).toList();
                          if (row.isNotEmpty && context.mounted) {
                            showSaleDetail(context, ref, row.first);
                          }
                        },
                      ),
                    ),
                ],
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(t.paymentHistory,
                      style: Theme.of(context).textTheme.titleMedium),
                  for (final p in history)
                    ListTile(
                      leading: const Icon(Icons.check_circle_outline,
                          color: Colors.green),
                      title: Text(fmt(p.amount, p.currency)),
                      subtitle: Text(
                          '${_date(p.date)} · ${paymentLabel(t, p.method)}'),
                    ),
                ],
              ],
            ),
    );
  }

  String _reminderText(AppLocalizations t, CustomerDebt d, MoneyFmt fmt) {
    final amounts =
        d.byCurrency.entries.map((e) => fmt(e.value, e.key)).join(' + ');
    return t.reminderMessage(d.name, amounts);
  }

  Future<void> _recordPayment(
      BuildContext context, WidgetRef ref, CustomerDebt debt) async {
    final t = AppLocalizations.of(context);
    final fmt = MoneyFmt(ref.read(currenciesProvider).valueOrNull ?? const []);
    final result = await showDialog<_PaymentInput>(
      context: context,
      builder: (_) => _PaymentDialog(debt: debt, fmt: fmt),
    );
    if (result == null) return;
    final alloc = allocatePayment(debt.sales, result.amount, result.currency);
    final list = [
      for (final a in alloc.parts)
        Payment(
          saleId: a.saleId,
          partnerId: debt.partnerId,
          customerName: debt.name,
          amount: a.amount,
          currency: result.currency,
          method: result.method,
          note: result.note.isEmpty ? null : result.note,
        ),
    ];
    if (list.isEmpty) return;
    await AppDatabase.instance.insertPayments(list);
    ref.invalidate(paymentsProvider);
    ref.invalidate(debtsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(t.paymentSaved(
            fmt(result.amount - alloc.unallocated, result.currency))),
      ));
  }
}

class _PaymentInput {
  final double amount;
  final String currency;
  final String method;
  final String note;
  const _PaymentInput(this.amount, this.currency, this.method, this.note);
}

class _PaymentDialog extends StatefulWidget {
  final CustomerDebt debt;
  final MoneyFmt fmt;
  const _PaymentDialog({required this.debt, required this.fmt});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late String _currency;
  String _method = 'cash';
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _error;

  double get _owed => widget.debt.byCurrency[_currency] ?? 0;

  @override
  void initState() {
    super.initState();
    // Devise la plus dette en premier.
    final entries = widget.debt.byCurrency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _currency = entries.first.key;
    _amount.text = _initial(_owed);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  String _initial(double v) =>
      v.toStringAsFixed(widget.fmt.decimals(_currency));

  void _submit() {
    final t = AppLocalizations.of(context);
    final v = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
    if (v <= 0) {
      setState(() => _error = t.required);
      return;
    }
    if (v > _owed + kMoneyEps) {
      setState(() => _error = t.paymentTooHigh(widget.fmt(_owed, _currency)));
      return;
    }
    Navigator.pop(
        context, _PaymentInput(v, _currency, _method, _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final currencies = widget.debt.byCurrency.keys.toList();
    return AlertDialog(
      title: Text(t.recordPayment),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(t.remainingDue(widget.fmt(_owed, _currency))),
            ),
            const SizedBox(height: 12),
            if (currencies.length > 1) ...[
              DropdownButtonFormField<String>(
                value: _currency,
                items: [
                  for (final c in currencies)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() {
                  _currency = v ?? _currency;
                  _amount.text = _initial(_owed);
                  _error = null;
                }),
                decoration: InputDecoration(labelText: t.currency),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: t.amountPaid,
                errorText: _error,
              ),
              onTap: () => _amount.selection = TextSelection(
                  baseOffset: 0, extentOffset: _amount.text.length),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _method,
              items: [
                for (final m in const ['cash', 'mobile', 'card', 'transfer'])
                  DropdownMenuItem(value: m, child: Text(paymentLabel(t, m))),
              ],
              onChanged: (v) => setState(() => _method = v ?? 'cash'),
              decoration: InputDecoration(labelText: t.payment),
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
            onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(onPressed: _submit, child: Text(t.save)),
      ],
    );
  }
}
