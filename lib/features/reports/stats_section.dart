import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/v5_strings.dart';
import '../../core/logic/money_format.dart';
import '../../core/logic/stats.dart';
import '../../core/models/sale.dart';
import '../../core/providers/app_providers.dart';

/// Bénéfice et statistiques d'une période (devise par défaut).
class StatsSection extends ConsumerStatefulWidget {
  const StatsSection({super.key});

  @override
  ConsumerState<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends ConsumerState<StatsSection> {
  PeriodKind _kind = PeriodKind.days30;
  DateTime? _from;
  DateTime? _to;
  bool _byProfit = false;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: _from ?? now.subtract(const Duration(days: 7)),
        end: _to ?? now,
      ),
    );
    if (r != null) {
      setState(() {
        _kind = PeriodKind.custom;
        _from = r.start;
        _to = r.end;
      });
    }
  }

  String _label(AppLocalizations t, PeriodKind k) => switch (k) {
        PeriodKind.today => t.periodToday,
        PeriodKind.days7 => t.period7,
        PeriodKind.days30 => t.period30,
        PeriodKind.thisMonth => t.periodMonth,
        PeriodKind.custom => t.periodCustom,
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final base = ref.watch(settingsProvider).currency;
    final fmt = MoneyFmt(ref.watch(currenciesProvider).valueOrNull ?? const []);
    final salesRows = ref.watch(salesProvider).valueOrNull;
    final products = ref.watch(allProductsProvider).valueOrNull;
    final expenses = ref.watch(expensesProvider).valueOrNull;
    final rates = ref.watch(ratesProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;

    Widget body;
    if (salesRows == null ||
        products == null ||
        expenses == null ||
        rates == null) {
      body = const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    } else {
      final sales = salesRows.map(Sale.fromRow).toList();
      final now = DateTime.now();
      final range = rangeFor(_kind, now, customFrom: _from, customTo: _to);
      final st = computeStats(
        sales: sales,
        expenses: expenses,
        rates: rates,
        base: base,
        range: range,
        buyPriceOf: {for (final p in products) p.id: p.buyPrice},
      );
      final dormant = dormantProducts(products, sales, now);
      final maxRev =
          st.buckets.fold<double>(0, (a, b) => b.revenue > a ? b.revenue : a);
      final top = _byProfit ? st.topByProfit : st.topByQty;

      Widget kpi(String label, String value, {Color? color, String? sub}) =>
          SizedBox(
            width: 160,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w700, color: color)),
                    if (sub != null)
                      Text(sub, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          );

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final k in PeriodKind.values)
                ChoiceChip(
                  label: Text(_label(t, k)),
                  selected: _kind == k,
                  onSelected: (_) => k == PeriodKind.custom
                      ? _pickRange()
                      : setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              kpi(t.revenue, fmt(st.revenue, base)),
              kpi(t.costOfGoods, fmt(st.cost, base)),
              kpi(t.grossProfit, fmt(st.grossProfit, base),
                  color: st.grossProfit >= 0 ? Colors.green : scheme.error,
                  sub: '${t.margin} ${st.marginPct.toStringAsFixed(1)} %'),
              kpi(t.expenses, fmt(st.expenses, base)),
              kpi(t.netProfit, fmt(st.netProfit, base),
                  color: st.netProfit >= 0 ? Colors.green : scheme.error),
              kpi(t.salesCount, '${st.salesCount}'),
              kpi(t.avgBasket, fmt(st.avgBasket, base)),
              kpi(t.discountsGiven, fmt(st.discounts, base)),
            ],
          ),
          const SizedBox(height: 16),
          Text(t.revenueEvolution,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: maxRev <= 0
                ? Center(child: Text(t.noData))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final b in st.buckets)
                        Expanded(
                          child: Tooltip(
                            message:
                                '${b.start.day.toString().padLeft(2, '0')}/${b.start.month.toString().padLeft(2, '0')} · ${fmt(b.revenue, base)}',
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor:
                                    (b.revenue / maxRev).clamp(0.02, 1.0),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(3)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(t.topProducts,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(t.byQuantity)),
                  ButtonSegment(value: true, label: Text(t.byProfit)),
                ],
                selected: {_byProfit},
                onSelectionChanged: (s) => setState(() => _byProfit = s.first),
              ),
            ],
          ),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(t.noData),
            ),
          for (var i = 0; i < top.length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
              title: Text(top[i].name, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${t.sold}: ${top[i].quantity.toStringAsFixed(top[i].quantity == top[i].quantity.roundToDouble() ? 0 : 2)}'),
              trailing: Text(fmt(top[i].profit, base),
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: top[i].profit >= 0 ? Colors.green : scheme.error)),
            ),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(t.dormantProducts(dormant.length)),
            subtitle: Text(t.dormantHint),
            children: [
              for (final p in dormant.take(50))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name),
                  trailing: Text('×${p.quantity.toStringAsFixed(0)}'),
                ),
            ],
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.profitStats, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }
}
