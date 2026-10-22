import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/product.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/feature_tour.dart';

/// Inventaire : liste + historique des mouvements.
/// Ecran large : cote a cote. Mobile : detail sur une page dediee.
class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});
  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  String? _selectedId;
  final kList = GlobalKey();
  final kDetail = GlobalKey();

  String _movementLabel(AppLocalizations t, String raw) {
    switch (raw) {
      case 'in_':
        return t.movementIn;
      case 'out':
        return t.movementOut;
      case 'adjustment':
        return t.adjustment;
      case 'loss':
        return t.loss;
      case 'return_':
        return t.movementIn;
      default:
        return t.movement;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final productsAsync = ref.watch(productsProvider);

    return GuidedTour(
      id: 'inventory',
      steps: [
        TourStep(target: kList, title: t.gsList, body: t.gsListB),
        TourStep(target: kDetail, title: t.gsDetail, body: t.gsDetailB),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(t.inventory)),
        body: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (products) {
            if (products.isEmpty) {
              return Center(child: Text(t.noProducts));
            }
            _selectedId ??= products.first.id;
            return LayoutBuilder(
              builder: (ctx, c) {
                if (c.maxWidth >= 700) {
                  final selected =
                      products.where((e) => e.id == _selectedId).toList();
                  return Row(
                    children: [
                      SizedBox(
                        width: 320,
                        child: KeyedSubtree(
                          key: kList,
                          child: _productList(products, (id) {
                            setState(() => _selectedId = id);
                          }),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: KeyedSubtree(
                          key: kDetail,
                          child: selected.isEmpty
                              ? Center(child: Text(t.chooseProduct))
                              : _movementsDetail(selected.first),
                        ),
                      ),
                    ],
                  );
                }
                return KeyedSubtree(
                  key: kList,
                  child: _productList(products, (id) {
                    final p = products.firstWhere((e) => e.id == id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: Text(p.name)),
                          body: _movementsDetail(p),
                        ),
                      ),
                    );
                  }),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _productList(List<Product> products, ValueChanged<String> onTap) {
    final t = AppLocalizations.of(context);
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (ctx, i) {
        final p = products[i];
        return ListTile(
          selected: p.id == _selectedId,
          title: Text(p.name),
          subtitle: Text('${p.sku} · ${t.quantity}: '
              '${p.quantity.toStringAsFixed(0)}'),
          trailing: p.isLowStock
              ? const Icon(Icons.warning_amber, color: Colors.orange, size: 18)
              : null,
          onTap: () => onTap(p.id),
        );
      },
    );
  }

  Widget _movementsDetail(Product product) {
    final t = AppLocalizations.of(context);
    return FutureBuilder(
      future: AppDatabase.instance.movementsFor(product.id),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final moves = snap.data!;
        if (moves.isEmpty) {
          return Center(child: Text(t.noMovements));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: moves.length,
          itemBuilder: (ctx, i) {
            final m = moves[i];
            final isIn = m.type.name.contains('in') || m.type.name == 'return_';
            final date = m.date.toLocal();
            final stamp = '${date.day.toString().padLeft(2, '0')}/'
                '${date.month.toString().padLeft(2, '0')}/${date.year} '
                '${date.hour.toString().padLeft(2, '0')}:'
                '${date.minute.toString().padLeft(2, '0')}';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  isIn ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIn ? Colors.green : Colors.red,
                ),
                title:
                    Text('${_movementLabel(t, m.type.name)} — ${m.quantity}'),
                subtitle:
                    Text('$stamp${m.reason != null ? ' · ${m.reason}' : ''}'),
                trailing: Text(m.reference ?? ''),
              ),
            );
          },
        );
      },
    );
  }
}
