import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/automation.dart';
import '../models/currency.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';

/// Base SQLite locale. Aucun serveur requis.
/// Fichier : <documents>/stocktout/stocktout.db
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  Database get db => _db!;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'stocktout'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final path = p.join(folder.path, 'stocktout.db');
    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _create,
      ),
    );
    await _seed();
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY, sku TEXT, name TEXT NOT NULL,
        barcode TEXT, category TEXT, unit TEXT,
        buy_price REAL DEFAULT 0, sell_price REAL DEFAULT 0,
        quantity REAL DEFAULT 0, min_stock REAL DEFAULT 0,
        supplier_id TEXT, location TEXT, expiry_date TEXT,
        notes TEXT, created_at TEXT, updated_at TEXT
      )''');
    await db.execute('''
      CREATE TABLE movements(
        id TEXT PRIMARY KEY, product_id TEXT NOT NULL,
        type TEXT, quantity REAL, unit_price REAL,
        reason TEXT, reference TEXT, date TEXT
      )''');
    await db.execute('''
      CREATE TABLE sales(
        id TEXT PRIMARY KEY, number TEXT, date TEXT,
        customer_id TEXT, customer_name TEXT,
        lines TEXT, discount REAL DEFAULT 0, tax REAL DEFAULT 0,
        currency TEXT, rate REAL DEFAULT 1,
        payment_method TEXT, notes TEXT
      )''');
    await db.execute('''
      CREATE TABLE purchases(
        id TEXT PRIMARY KEY, number TEXT, date TEXT,
        supplier_id TEXT, supplier_name TEXT,
        lines TEXT, status TEXT DEFAULT 'draft',
        currency TEXT, rate REAL DEFAULT 1, notes TEXT
      )''');
    await db.execute('''
      CREATE TABLE partners(
        id TEXT PRIMARY KEY, kind TEXT, name TEXT NOT NULL,
        phone TEXT, email TEXT, address TEXT, notes TEXT
      )''');
    await db.execute('''
      CREATE TABLE currencies(
        code TEXT PRIMARY KEY, symbol TEXT, name TEXT,
        decimals INTEGER DEFAULT 2, rate REAL DEFAULT 1
      )''');
    await db.execute('''
      CREATE TABLE automations(
        id TEXT PRIMARY KEY, name TEXT, description TEXT,
        trigger TEXT, actions TEXT, enabled INTEGER DEFAULT 1
      )''');
    await db.execute('''
      CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)
    ''');
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

  Future<void> deleteProduct(String id) async {
    await _db!.delete('products', where: 'id = ?', whereArgs: [id]);
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
