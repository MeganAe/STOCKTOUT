import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/report_service.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final productsAsync = ref.watch(productsProvider);
    final salesAsync = ref.watch(salesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.reports)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.table_view),
                label: const Text('Export stock CSV'),
                onPressed: () => _exportCsv(context),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Etat stock PDF'),
                onPressed: () => _exportPdf(context, ref),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Imprimer'),
                onPressed: () => _exportPdf(context, ref, printIt: true),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Valeur par categorie',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  productsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                    data: (products) {
                      final map = <String, double>{};
                      for (final p in products) {
                        final k = (p.category?.isEmpty ?? true)
                            ? 'Sans categorie'
                            : p.category!;
                        map[k] = (map[k] ?? 0) + p.stockValue;
                      }
                      if (map.isEmpty) return const Text('Aucune donnee.');
                      final max =
                          map.values.fold<double>(0, (a, b) => a > b ? a : b);
                      return Column(
                        children: map.entries.map((e) {
                          final w = max == 0 ? 0.0 : e.value / max;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                SizedBox(width: 180, child: Text(e.key)),
                                Expanded(
                                  child: LinearProgressIndicator(value: w),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                    width: 120,
                                    child: Text(e.value.toStringAsFixed(2),
                                        textAlign: TextAlign.right)),
                              ],
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
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historique des ventes',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  salesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                    data: (sales) {
                      if (sales.isEmpty) {
                        return const Text('Aucune vente.');
                      }
                      return Column(
                        children: sales.take(20).map((s) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.receipt_long),
                            title: Text('${s['number']}'),
                            subtitle: Text(
                                '${s['date']} · ${s['payment_method'] ?? ''}'),
                            trailing: Text('${s['currency'] ?? ''}'),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final svc = ReportService(AppDatabase.instance);
    final csv = await svc.productsCsv();
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Enregistrer le CSV',
      fileName: 'stock.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (path != null) {
      await File(path).writeAsString(csv);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('CSV enregistre : $path')));
      }
    }
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref,
      {bool printIt = false}) async {
    final products = await AppDatabase.instance.allProducts();
    final svc = ReportService(AppDatabase.instance);
    final doc = await svc.stockPdf(products);
    if (printIt) {
      await Printing.layoutPdf(onLayout: (_) => doc.save());
    } else {
      await Printing.sharePdf(bytes: await doc.save(), filename: 'stock.pdf');
    }
  }
}
