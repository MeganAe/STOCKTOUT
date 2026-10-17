import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../database/database.dart';
import '../models/product.dart';

/// Exports CSV / PDF. Utilise par les rapports et les automatisations.
class ReportService {
  final AppDatabase db;
  ReportService(this.db);

  Future<String> productsCsv() async {
    final products = await db.allProducts();
    final rows = <List<Object?>>[
      ['SKU', 'Nom', 'Categorie', 'Quantite', 'Prix achat', 'Prix vente', 'Valeur'],
      ...products.map((e) => [
            e.sku,
            e.name,
            e.category ?? '',
            e.quantity,
            e.buyPrice,
            e.sellPrice,
            e.stockValue,
          ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  Future<pw.Document> stockPdf(List<Product> products) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Etat du stock')),
          pw.TableHelper.fromTextArray(
            headers: ['SKU', 'Produit', 'Qte', 'P. vente', 'Valeur'],
            data: products
                .map((e) => [
                      e.sku,
                      e.name,
                      e.quantity.toString(),
                      e.sellPrice.toString(),
                      e.stockValue.toStringAsFixed(2),
                    ])
                .toList(),
          ),
        ],
      ),
    );
    return doc;
  }
}
