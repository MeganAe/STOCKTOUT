import 'package:uuid/uuid.dart';

class Product {
  final String id;
  final String sku;
  final String name;
  final String? barcode;
  final String? category;
  final String? unit;
  final double buyPrice;
  final double sellPrice;
  final double quantity;
  final double minStock;
  final String? supplierId;
  final String? location;
  final DateTime? expiryDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    String? id,
    required this.sku,
    required this.name,
    this.barcode,
    this.category,
    this.unit,
    this.buyPrice = 0,
    this.sellPrice = 0,
    this.quantity = 0,
    this.minStock = 0,
    this.supplierId,
    this.location,
    this.expiryDate,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isLowStock => quantity <= minStock;
  bool get isOutOfStock => quantity <= 0;
  double get stockValue => quantity * buyPrice;
  double get margin => sellPrice - buyPrice;

  Product copyWith({
    String? sku,
    String? name,
    String? barcode,
    String? category,
    String? unit,
    double? buyPrice,
    double? sellPrice,
    double? quantity,
    double? minStock,
    String? supplierId,
    String? location,
    DateTime? expiryDate,
    String? notes,
  }) {
    return Product(
      id: id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      quantity: quantity ?? this.quantity,
      minStock: minStock ?? this.minStock,
      supplierId: supplierId ?? this.supplierId,
      location: location ?? this.location,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'sku': sku,
        'name': name,
        'barcode': barcode,
        'category': category,
        'unit': unit,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'quantity': quantity,
        'min_stock': minStock,
        'supplier_id': supplierId,
        'location': location,
        'expiry_date': expiryDate?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Product.fromMap(Map<String, Object?> m) => Product(
        id: m['id'] as String,
        sku: m['sku'] as String? ?? '',
        name: m['name'] as String? ?? '',
        barcode: m['barcode'] as String?,
        category: m['category'] as String?,
        unit: m['unit'] as String?,
        buyPrice: (m['buy_price'] as num?)?.toDouble() ?? 0,
        sellPrice: (m['sell_price'] as num?)?.toDouble() ?? 0,
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        minStock: (m['min_stock'] as num?)?.toDouble() ?? 0,
        supplierId: m['supplier_id'] as String?,
        location: m['location'] as String?,
        expiryDate: m['expiry_date'] != null
            ? DateTime.tryParse(m['expiry_date'] as String)
            : null,
        notes: m['notes'] as String?,
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(m['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
