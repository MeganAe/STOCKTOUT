import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/extra_strings.dart';
import '../../core/l10n/v5_strings.dart';
import '../../core/logic/debts.dart';
import '../../core/logic/money_format.dart';
import '../../core/services/expiry_service.dart';
import '../debts/debts_page.dart';
import '../products/expiry_list.dart';
import '../../core/models/currency.dart';
import '../../core/models/sale.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/feature_tour.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final kStats = GlobalKey();
  final kSales = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final productsAsync = ref.watch(productsProvider);
    final salesAsync = ref.watch(salesProvider);
    final settings = ref.watch(settingsProvider);

    return GuidedTour(
      id: 'dashboard',
      steps: [
        TourStep(target: kStats, title: t.gsTotals, body: t.gsTotalsB),
        TourStep(target: kSales, title: t.sales, body: t.gsListB),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(t.dashboard)),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productsProvider);
            ref.invalidate(salesProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              KeyedSubtree(
                key: kStats,
                child: productsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e'),
                  data: (products) {
                    final low = products
                        .where((e) => e.isLowStock)
                        .toList(growable: false);
                    final out = products
                        .where((e) => e.isOutOfStock)
                        .toList(growable: false);
                    final value =
                        products.fold<double>(0, (s, e) => s + e.stockValue);
                    final now = DateTime.now();
                    final rates = ref.watch(currenciesProvider).value ??
                        const <AppCurrency>[];
                    double rateOf(String code) {
                      for (final c in rates) {
                        if (c.code == code && c.rateToBase != 0) {
                          return c.rateToBase;
                        }
                      }
                      return 1;
                    }

                    final todayTotal = (salesAsync.value ?? const [])
                        .map(Sale.fromRow)
                        .where((e) =>
                            e.date.year == now.year &&
                            e.date.month == now.month &&
                            e.date.day == now.day)
                        .fold<double>(
                            0,
                            (s, e) =>
                                s +
                                e.total *
                                    rateOf(settings.currency) /
                                    rateOf(e.currency));
                    final fmt = MoneyFmt(rates);
                    final debts =
                        ref.watch(debtsProvider).valueOrNull ?? const [];
                    final report = buildExpiryReport(
                        ref.watch(allProductsProvider).valueOrNull ?? products,
                        now,
                        soonDays: settings.expiryDays);
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const DebtsPage())),
                          child: _StatCard(
                              title: t.debts,
                              value: fmt(totalDebt(debts), settings.currency),
                              subtitle: t.debtors(debts.length),
                              icon: Icons.account_balance_wallet_outlined,
                              color: Colors.deepOrange),
                        ),
                        GestureDetector(
                          onTap: () => showExpiryList(context, expired: false),
                          child: _StatCard(
                              title: t.expiringSoon,
                              value: '${report.soon.length}',
                              subtitle: t.withinDays(settings.expiryDays),
                              icon: Icons.schedule,
                              color: Colors.orange),
                        ),
                        GestureDetector(
                          onTap: () => showExpiryList(context, expired: true),
                          child: _StatCard(
                              title: t.expired,
                              value: '${report.expired.length}',
                              icon: Icons.error_outline,
                              color: Colors.red),
                        ),
                        _StatCard(
                            title: t.todaySales,
                            value: todayTotal.toStringAsFixed(2),
                            subtitle: settings.currency,
                            icon: Icons.payments,
                            color: Colors.green),
                        _StatCard(
                            title: t.products,
                            value: '${products.length}',
                            icon: Icons.inventory_2),
                        _StatCard(
                            title: t.stockValue,
                            value: value.toStringAsFixed(2),
                            subtitle: settings.currency,
                            icon: Icons.account_balance_wallet),
                        _StatCard(
                            title: t.lowStock,
                            value: '${low.length}',
                            icon: Icons.warning_amber,
                            color: Colors.orange),
                        _StatCard(
                            title: t.outOfStock,
                            value: '${out.length}',
                            icon: Icons.remove_shopping_cart,
                            color: Colors.red),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (ctx, c) {
                  final wide = c.maxWidth >= 720;
                  final salesCard = KeyedSubtree(
                    key: kSales,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.sales,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            salesAsync.when(
                              loading: () => const Padding(
                                padding: EdgeInsets.all(16),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                              error: (e, _) => Text('$e'),
                              data: (sales) {
                                if (sales.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(t.noSales),
                                  );
                                }
                                return Column(
                                  children: sales.take(8).map((s) {
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.receipt_long),
                                      title: Text('${s['number']}'),
                                      subtitle:
                                          Text('${s['date']}'.split('T').first),
                                      trailing: Text(
                                        Sale.fromRow(s)
                                            .total
                                            .toStringAsFixed(2),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  final lowCard = Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.lowStock,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          productsAsync.when(
                            loading: () => const SizedBox(),
                            error: (e, _) => Text('$e'),
                            data: (products) {
                              final low = products
                                  .where((e) => e.isLowStock)
                                  .take(10)
                                  .toList();
                              if (low.isEmpty) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(t.nothingToReport),
                                );
                              }
                              return Column(
                                children: low
                                    .map((e) => ListTile(
                                          dense: true,
                                          title: Text(e.name),
                                          subtitle: Text(e.sku),
                                          trailing: Chip(
                                            label: Text('${e.quantity}'),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ))
                                    .toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                  if (!wide) {
                    return Column(
                      children: [
                        salesCard,
                        const SizedBox(height: 12),
                        lowCard,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: salesCard),
                      const SizedBox(width: 12),
                      Expanded(child: lowCard),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: (color ?? scheme.primary).withOpacity(0.12),
                child: Icon(icon, color: color ?? scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall),
                    Text(value,
                        style: text.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (subtitle != null)
                      Text(subtitle!, style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
