/// Schéma SQL de StockTout. Aucune dépendance : testable seul.
///
/// Version 1 = schéma d'origine. Version 2 ajoute (sans rien supprimer) :
/// - table `payments` (dettes clients), table `expenses` (dépenses),
/// - colonne `sales.paid` (montant payé à la vente),
/// - colonne `products.image_path` (photo du produit).
/// Les nouvelles installations exécutent [kSchemaV1] puis la migration v2,
/// donc obtiennent exactement le même schéma final que les mises à jour.
const int kDbVersion = 2;

const List<String> kSchemaV1 = [
  '''
CREATE TABLE products(
  id TEXT PRIMARY KEY, sku TEXT, name TEXT NOT NULL,
  barcode TEXT, category TEXT, unit TEXT,
  buy_price REAL DEFAULT 0, sell_price REAL DEFAULT 0,
  quantity REAL DEFAULT 0, min_stock REAL DEFAULT 0,
  supplier_id TEXT, location TEXT, expiry_date TEXT,
  notes TEXT, created_at TEXT, updated_at TEXT
)''',
  '''
CREATE TABLE movements(
  id TEXT PRIMARY KEY, product_id TEXT NOT NULL,
  type TEXT, quantity REAL, unit_price REAL,
  reason TEXT, reference TEXT, date TEXT
)''',
  '''
CREATE TABLE sales(
  id TEXT PRIMARY KEY, number TEXT, date TEXT,
  customer_id TEXT, customer_name TEXT,
  lines TEXT, discount REAL DEFAULT 0, tax REAL DEFAULT 0,
  currency TEXT, rate REAL DEFAULT 1,
  payment_method TEXT, notes TEXT
)''',
  '''
CREATE TABLE purchases(
  id TEXT PRIMARY KEY, number TEXT, date TEXT,
  supplier_id TEXT, supplier_name TEXT,
  lines TEXT, status TEXT DEFAULT 'draft',
  currency TEXT, rate REAL DEFAULT 1, notes TEXT
)''',
  '''
CREATE TABLE partners(
  id TEXT PRIMARY KEY, kind TEXT, name TEXT NOT NULL,
  phone TEXT, email TEXT, address TEXT, notes TEXT
)''',
  '''
CREATE TABLE currencies(
  code TEXT PRIMARY KEY, symbol TEXT, name TEXT,
  decimals INTEGER DEFAULT 2, rate REAL DEFAULT 1
)''',
  '''
CREATE TABLE automations(
  id TEXT PRIMARY KEY, name TEXT, description TEXT,
  trigger TEXT, actions TEXT, enabled INTEGER DEFAULT 1
)''',
  'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)',
];

/// Colonnes ajoutées en v2 : (table, colonne, définition).
const List<List<String>> kAddedColumnsV2 = [
  ['sales', 'paid', 'REAL'],
  ['products', 'image_path', 'TEXT'],
];

/// Tables et index ajoutés en v2 (idempotents).
const List<String> kMigrationV2 = [
  '''
CREATE TABLE IF NOT EXISTS payments(
  id TEXT PRIMARY KEY, sale_id TEXT, partner_id TEXT,
  customer_name TEXT, amount REAL DEFAULT 0, currency TEXT,
  date TEXT, method TEXT, note TEXT
)''',
  '''
CREATE TABLE IF NOT EXISTS expenses(
  id TEXT PRIMARY KEY, date TEXT, category TEXT,
  amount REAL DEFAULT 0, currency TEXT, note TEXT
)''',
  'CREATE INDEX IF NOT EXISTS idx_payments_sale ON payments(sale_id)',
  'CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(date)',
  'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date)',
];
