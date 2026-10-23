import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as pth;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/sale.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/report_service.dart';
import '../../widgets/feature_tour.dart';
import '../sales/sale_detail.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  final kActions = GlobalKey();
  final kChart = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final productsAsync = ref.watch(productsProvider);
    final salesAsync = ref.watch(salesProvider);

    return GuidedTour(
      id: 'reports',
      steps: [
        TourStep(target: kActions, title: t.gsAction, body: t.gsActionB),
        TourStep(target: kChart, title: t.gsTotals, body: t.gsTotalsB),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(t.reports)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            KeyedSubtree(
              key: kActions,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.table_view),
                    label: Text(t.exportCsv),
                    onPressed: () => _exportCsv(context),
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(t.stockPdf),
                    onPressed: () => _exportPdf(context, printIt: false),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.print),
                    label: Text(t.print),
                    onPressed: () => _exportPdf(context, printIt: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            KeyedSubtree(
              key: kChart,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.valueByCategory,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      productsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('$e'),
                        data: (products) {
                          final map = <String, double>{};
                          for (final p in products) {
                            final k = (p.category?.isEmpty ?? true)
                                ? t.noCategory
                                : p.category!;
                            map[k] = (map[k] ?? 0) + p.stockValue;
                          }
                          if (map.isEmpty) return Text(t.noData);
                          final max = map.values
                              .fold<double>(0, (a, b) => a > b ? a : b);
                          return Column(
                            children: map.entries.map((e) {
                              final w = max == 0 ? 0.0 : e.value / max;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    SizedBox(width: 160, child: Text(e.key)),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                            value: w, minHeight: 8),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                        width: 110,
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
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.salesHistory,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    salesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('$e'),
                      data: (sales) {
                        if (sales.isEmpty) return Text(t.noSales);
                        return Column(
                          children: sales.take(20).map((s) {
                            final sale = Sale.fromRow(s);
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.receipt_long),
                              title: Text(sale.number),
                              subtitle: Text(
                                  sale.date.toIso8601String().split('T').first),
                              trailing: Text(
                                '${sale.total.toStringAsFixed(2)} ${sale.currency}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              onTap: () => showSaleDetail(context, ref, s),
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
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final svc = ReportService(AppDatabase.instance);
    // BOM UTF-8 : Excel affiche correctement les accents.
    final csv = '\uFEFF${await svc.productsCsv(t)}';
    final d = DateTime.now();
    final name =
        'stock_${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}.csv';
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile : ecrit dans le cache puis ouvre le partage
        // (Enregistrer dans Fichiers, WhatsApp, e-mail, Drive...).
        final dir = await getTemporaryDirectory();
        final file = File(pth.join(dir.path, name));
        await file.writeAsString(csv);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/csv', name: name)],
          subject: name,
        );
        return;
      }
      final path = await FilePicker.platform.saveFile(
        dialogTitle: t.saveCsvTitle,
        fileName: name,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (path != null) {
        await File(path).writeAsString(csv);
        messenger.showSnackBar(SnackBar(content: Text(t.csvSaved(path))));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('CSV : $e')));
    }
  }

  Future<void> _exportPdf(BuildContext context, {required bool printIt}) async {
    final t = AppLocalizations.of(context);
    final products = await AppDatabase.instance.allProducts();
    final svc = ReportService(AppDatabase.instance);
    final doc = await svc.stockPdf(products, t);
    if (printIt) {
      await Printing.layoutPdf(onLayout: (_) => doc.save());
    } else {
      await Printing.sharePdf(bytes: await doc.save(), filename: 'stock.pdf');
    }
  }
}
