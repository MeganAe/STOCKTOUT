import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/app_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final productsAsync = ref.watch(productsProvider);
    final salesAsync = ref.watch(salesProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.dashboard)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productsProvider);
          ref.invalidate(salesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            productsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (products) {
                final low =
                    products.where((e) => e.isLowStock).toList(growable: false);
                final out = products
                    .where((e) => e.isOutOfStock)
                    .toList(growable: false);
                final value =
                    products.fold<double>(0, (s, e) => s + e.stockValue);
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
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
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
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
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (e, _) => Text('$e'),
                            data: (sales) {
                              if (sales.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Aucune vente pour le moment.'),
                                );
                              }
                              return Column(
                                children: sales.take(8).map((s) {
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.receipt_long),
                                    title: Text('${s['number']}'),
                                    subtitle: Text('${s['date']}'),
                                    trailing:
                                        Text('${s['customer_name'] ?? ''}'),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
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
                                return const Text('Rien à signaler.');
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
                  ),
                ),
              ],
            ),
          ],
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
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    (color ?? Theme.of(context).colorScheme.primary)
                        .withOpacity(0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodySmall),
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: Theme.of(context).textTheme.bodySmall),
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
