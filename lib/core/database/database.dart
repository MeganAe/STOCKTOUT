import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../logic/import_logic.dart';
import '../models/automation.dart';
import '../models/currency.dart';
import '../models/expense.dart';
import '../models/payment.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/stock_movement.dart';
import 'schema.dart';

/// Base SQLite locale. Aucun serveur requis.
/// Fichier : <documents>/stocktout/stocktout.db
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  Database get db => _db!;

  /// Dossier de données : <documents>/stocktout
  Future<Directory> dataDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'stocktout'));
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  Future<String> dbFilePath() async =>
      p.join((await dataDir()).path, 'stocktout.db');

  /// Dossier des photos produits : <documents>/stocktout/product_images
  Future<Directory> imagesDir() async {
    final d = Directory(p.join((await dataDir()).path, 'product_images'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<void> init() async {
    final path = await dbFilePath();
    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: kDbVersion,
        onCreate: _create,
        onUpgrade: _upgrade,
      ),
    );
    await _seed();
  }

  /// Ferme la base (avant restauration / réinitialisation).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Nouvelle installation : schéma d'origine puis migration v2, pour
  /// obtenir exactement le même schéma final qu'une mise à jour.
  Future<void> _create(Database db, int version) async {
    for (final sql in kSchemaV1) {
      await db.execute(sql);
    }
    await migrateToV2(db);
  }

  /// Mise à jour : AUCUNE suppression, uniquement des ajouts.
  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await migrateToV2(db);
  }

  /// Migration v1 -> v2 (idempotente, ne supprime rien).
  Future<void> migrateToV2(DatabaseExecutor db) async {
    for (final c in kAddedColumnsV2) {
      final info = await db.rawQuery('PRAGMA table_info(${c[0]})');
      final has = info.any((r) => r['name'] == c[1]);
      if (!has)
        await db.execute('ALTER TABLE ${c[0]} ADD COLUMN ${c[1]} ${c[2]}');
    }
    for (final sql in kMigrationV2) {
      await db.execute(sql);
    }
    // Ventes existantes : non « credit » => payées en totalité,
    // « credit » => 0 payé (le total vient des lignes JSON).
    final rows = await db.query('sales');
    for (final r in rows) {
      if (r['paid'] != null) continue;
      final sale = Sale.fromRow(r);
      final paid = sale.paymentMethod == 'credit' ? 0.0 : sale.total;
      await db.update('sales', {'paid': paid},
          where: 'id = ?', whereArgs: [r['id']]);
    }
  }

  /// Copie COHÉRENTE de la base vers [destPath] (VACUUM INTO) : jamais une
  /// copie brute d'un fichier en cours d'écriture. [destPath] ne doit pas
  /// exister.
  Future<void> snapshotTo(String destPath) async {
    final f = File(destPath);
    if (await f.exists()) await f.delete();
    final lit = destPath.replaceAll("'", "''");
    await _db!.execute("VACUUM INTO '$lit'");
  }

  /// Efface TOUTES les données (base + photos) et repart d'une base neuve.
  Future<void> resetAll() async {
    await close();
    final path = await dbFilePath();
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final f = File('$path$suffix');
      if (await f.exists()) await f.delete();
    }
    final imgs = Directory(p.join((await dataDir()).path, 'product_images'));
    if (await imgs.exists()) await imgs.delete(recursive: true);
    await init();
  }

  Future<void> _seed() async {
    final cur = await _db!.query('currencies');
    if (cur.isEmpty) {
      for (final c in AppCurrency.defaults()) {
        await _db!.insert('currencies', c.toMap());
      }
    }
    final auto = await _db!.query('automations');
    if (auto.isEmpty) {
      for (final r in AutomationRule.presets()) {
        await _db!.insert('automations', r.toMap());
      }
    }
  }

  // ---------- Produits ----------
  Future<List<Product>> allProducts({String query = ''}) async {
    final rows = await _db!.query('products', orderBy: 'name ASC');
    var list = rows.map(Product.fromMap).toList();
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.sku.toLowerCase().contains(q) ||
              (e.barcode ?? '').contains(q))
          .toList();
    }
    return list;
  }

  Future<void> upsertProduct(Product p) async {
    await _db!.insert(
      'products',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Multiplie tous les prix (achat et vente) par [factor], arrondis
  /// selon les decimales de la nouvelle devise. Sert au changement de devise.
  Future<void> convertProductPrices(double factor, int decimals) async {
    final m = math.pow(10, decimals).toDouble();
    double r(num v) => (v.toDouble() * factor * m).round() / m;
    final rows = await _db!
        .query('products', columns: ['id', 'buy_price', 'sell_price']);
    final batch = _db!.batch();
    for (final row in rows) {
      batch.update(
        'products',
        {
          'buy_price': r((row['buy_price'] as num?) ?? 0),
          'sell_price': r((row['sell_price'] as num?) ?? 0),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteProduct(String id) async {
    final rows = await _db!.query('products',
        columns: ['image_path'], where: 'id = ?', whereArgs: [id]);
    await _db!.delete('products', where: 'id = ?', whereArgs: [id]);
    // Supprime aussi la photo du produit.
    final img = rows.isEmpty ? null : rows.first['image_path'] as String?;
    if (img != null && img.isNotEmpty) {
      try {
        final f = File(img);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  /// Import par lots dans UNE transaction. [onProgress] reçoit (fait, total).
  Future<void> applyImport(
    ImportPlan plan, {
    void Function(int done, int total)? onProgress,
  }) async {
    final total = plan.toCreate.length + plan.toUpdate.length;
    var done = 0;
    const chunk = 400;
    await _db!.transaction((txn) async {
      Future<void> run(List<Product> list, bool create) async {
        for (var i = 0; i < list.length; i += chunk) {
          final batch = txn.batch();
          for (final pr in list.skip(i).take(chunk)) {
            if (create) {
              batch.insert('products', pr.toMap());
            } else {
              batch.update('products', pr.toMap(),
                  where: 'id = ?', whereArgs: [pr.id]);
            }
          }
          await batch.commit(noResult: true);
          done += list.skip(i).take(chunk).length;
          onProgress?.call(done, total);
          // Laisse respirer l'interface entre deux lots.
          await Future<void>.delayed(Duration.zero);
        }
      }

      await run(plan.toCreate, true);
      await run(plan.toUpdate, false);
    });
  }

  Future<void> addMovement(StockMovement m) async {
    await _db!.insert('movements', m.toMap());
    // Met a jour la quantite produit.
    final rows =
        await _db!.query('products', where: 'id = ?', whereArgs: [m.productId]);
    if (rows.isEmpty) return;
    final prod = Product.fromMap(rows.first);
    double qty = prod.quantity;
    switch (m.type) {
      case MovementType.in_:
      case MovementType.return_:
        qty += m.quantity;
        break;
      case MovementType.out:
      case MovementType.loss:
        qty -= m.quantity;
        break;
      case MovementType.adjustment:
        qty = m.quantity;
        break;
      case MovementType.transfer:
        break;
    }
    await _db!.update(
      'products',
      {'quantity': qty, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [m.productId],
    );
  }

  Future<List<StockMovement>> movementsFor(String productId) async {
    final rows = await _db!.query(
      'movements',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'date DESC',
    );
    return rows.map(StockMovement.fromMap).toList();
  }

  // ---------- Ventes ----------
  Future<void> insertSale(Map<String, Object?> row) async {
    await _db!.insert('sales', row);
  }

  Future<List<Map<String, Object?>>> allSales() async {
    return _db!.query('sales', orderBy: 'date DESC');
  }

  /// Supprime la vente ET ses paiements liés.
  Future<void> deleteSale(String id) async {
    await _db!.transaction((txn) async {
      await txn.delete('payments', where: 'sale_id = ?', whereArgs: [id]);
      await txn.delete('sales', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> paymentCountForSale(String saleId) async {
    final r = await _db!.rawQuery(
        'SELECT COUNT(*) AS n FROM payments WHERE sale_id = ?', [saleId]);
    return (r.first['n'] as num?)?.toInt() ?? 0;
  }

  // ---------- Paiements (dettes clients) ----------
  Future<List<Payment>> allPayments() async {
    final rows = await _db!.query('payments', orderBy: 'date DESC');
    return rows.map(Payment.fromMap).toList();
  }

  Future<void> insertPayments(List<Payment> list) async {
    await _db!.transaction((txn) async {
      for (final pay in list) {
        await txn.insert('payments', pay.toMap());
      }
    });
  }

  // ---------- Dépenses ----------
  Future<List<Expense>> allExpenses() async {
    final rows = await _db!.query('expenses', orderBy: 'date DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<void> upsertExpense(Expense e) async {
    await _db!.insert('expenses', e.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteExpense(String id) async {
    await _db!.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Clients ----------
  /// Clients (kind = 'customer'), filtrés par nom ou téléphone.
  Future<List<Map<String, Object?>>> customers({String query = ''}) async {
    final rows = await _db!.query('partners',
        where: 'kind = ?', whereArgs: ['customer'], orderBy: 'name ASC');
    if (query.trim().isEmpty) return rows;
    final q = query.trim().toLowerCase();
    return rows
        .where((r) =>
            '${r['name']}'.toLowerCase().contains(q) ||
            '${r['phone'] ?? ''}'.toLowerCase().contains(q))
        .toList();
  }

  /// Crée un client à la volée et retourne sa ligne.
  Future<Map<String, Object?>> createCustomer(String name,
      {String? phone}) async {
    final row = <String, Object?>{
      'id': const Uuid().v4(),
      'kind': 'customer',
      'name': name.trim(),
      'phone': phone?.trim(),
      'email': null,
      'address': null,
      'notes': null,
    };
    await _db!.insert('partners', row);
    return row;
  }

  // ---------- Devises ----------
  Future<List<AppCurrency>> allCurrencies() async {
    final rows = await _db!.query('currencies', orderBy: 'code ASC');
    return rows.map(AppCurrency.fromMap).toList();
  }

  Future<void> upsertCurrency(AppCurrency c) async {
    await _db!.insert(
      'currencies',
      c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------- Automatisations ----------
  Future<List<AutomationRule>> allAutomations() async {
    final rows = await _db!.query('automations');
    return rows.map(AutomationRule.fromMap).toList();
  }

  Future<void> upsertAutomation(AutomationRule r) async {
    await _db!.insert(
      'automations',
      r.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAutomation(String id) async {
    await _db!.delete('automations', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Reglages ----------
  Future<void> setSetting(String key, String value) async {
    await _db!.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final rows =
        await _db!.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Map<String, Object?> encodeLines(List<Map<String, Object?>> lines) =>
      {'lines': jsonEncode(lines)};
}
