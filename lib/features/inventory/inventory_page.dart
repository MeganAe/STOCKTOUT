import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/app_providers.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});
  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.inventory)),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (products) {
          _selectedId ??= products.isNotEmpty ? products.first.id : null;
          final selected = products.where((e) => e.id == _selectedId).toList();
          return Row(
            children: [
              SizedBox(
                width: 320,
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (ctx, i) {
                    final p = products[i];
                    return ListTile(
                      selected: p.id == _selectedId,
                      title: Text(p.name),
                      subtitle: Text('${p.sku} — ${p.quantity}'),
                      trailing: p.isLowStock
                          ? const Icon(Icons.warning_amber,
                              color: Colors.orange, size: 18)
                          : null,
                      onTap: () => setState(() => _selectedId = p.id),
                    );
                  },
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: selected.isEmpty
                    ? const Center(child: Text('Choisissez un produit.'))
                    : FutureBuilder(
                        future: AppDatabase.instance
                            .movementsFor(selected.first.id),
                        builder: (ctx, snap) {
                          if (!snap.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final moves = snap.data!;
                          if (moves.isEmpty) {
                            return const Center(
                                child: Text('Aucun mouvement.'));
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: moves.length,
                            itemBuilder: (ctx, i) {
                              final m = moves[i];
                              return Card(
                                child: ListTile(
                                  leading: Icon(
                                    m.type.name.contains('in') ||
                                            m.type.name == 'return_'
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: m.type.name.contains('in') ||
                                            m.type.name == 'return_'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  title: Text(
                                      '${m.type.name} — ${m.quantity}'),
                                  subtitle: Text(
                                      '${m.date.toLocal()}${m.reason != null ? ' · ${m.reason}' : ''}'),
                                  trailing: Text(m.reference ?? ''),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
