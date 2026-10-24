import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/v5_strings.dart';
import '../../core/logic/expiry.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/expiry_service.dart';
import 'product_dialog.dart';

String _d(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Liste détaillée des produits qui expirent bientôt ([expired] = false)
/// ou déjà périmés ([expired] = true). Un tap ouvre la fiche du produit.
Future<void> showExpiryList(BuildContext context, {required bool expired}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ExpirySheet(expired: expired),
  );
}

class _ExpirySheet extends ConsumerWidget {
  final bool expired;
  const _ExpirySheet({required this.expired});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final days = ref.watch(settingsProvider).expiryDays;
    final products = ref.watch(allProductsProvider).valueOrNull ?? const [];
    final report = buildExpiryReport(products, DateTime.now(), soonDays: days);
    final list = expired ? report.expired : report.soon;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(expired ? Icons.error : Icons.schedule,
                    color: expired ? Colors.red : Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      expired
                          ? t.expiredProducts
                          : t.expiringSoonProducts(days),
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text(t.noData))
                : ListView.builder(
                    controller: scroll,
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      final left = daysUntil(p.expiryDate!, DateTime.now());
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text(
                            '${_d(p.expiryDate!)} · ${left < 0 ? t.expiredDaysAgo(-left) : t.inDays(left)}'),
                        trailing: Text('×${p.quantity.toStringAsFixed(0)}'),
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => ProductDialog(product: p),
                          );
                          if (ok == true) {
                            ref.invalidate(productsProvider);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
