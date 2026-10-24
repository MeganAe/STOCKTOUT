import 'dart:convert';

import 'package:uuid/uuid.dart';

class SaleLine {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discount;

  /// Coût d'achat UNITAIRE au moment de la vente (null pour les anciennes
  /// ventes : on se rabat alors sur le prix d'achat actuel du produit).
  final double? cost;

  const SaleLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    this.cost,
  });

  double get total => quantity * unitPrice - discount;

  SaleLine copyWith({
    double? quantity,
    double? unitPrice,
    double? discount,
    double? cost,
  }) =>
      SaleLine(
        productId: productId,
        productName: productName,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        discount: discount ?? this.discount,
        cost: cost ?? this.cost,
      );

  Map<String, Object?> toMap() => {
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'discount': discount,
        if (cost != null) 'cost': cost,
      };

  factory SaleLine.fromMap(Map<String, Object?> m) => SaleLine(
        productId: m['product_id'] as String,
        productName: m['product_name'] as String? ?? '',
        quantity: (m['quantity'] as num).toDouble(),
        unitPrice: (m['unit_price'] as num).toDouble(),
        discount: (m['discount'] as num?)?.toDouble() ?? 0,
        cost: (m['cost'] as num?)?.toDouble(),
      );
}

class Sale {
  final String id;
  final String number;
  final DateTime date;
  final String? customerId;
  final String? customerName;
  final List<SaleLine> lines;
  final double discount;
  final double tax;
  final String currency;
  final double rate;
  final String? paymentMethod;
  final String? notes;

  /// Montant payé au moment de la vente (null = colonne absente/ancienne
  /// donnée : voir [paidAtSale]).
  final double? paid;

  Sale({
    String? id,
    required this.number,
    DateTime? date,
    this.customerId,
    this.customerName,
    this.lines = const [],
    this.discount = 0,
    this.tax = 0,
    this.currency = 'USD',
    this.rate = 1,
    this.paymentMethod,
    this.notes,
    this.paid,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  /// Reconstruit une vente depuis une ligne de la table `sales`.
  factory Sale.fromRow(Map<String, Object?> r) {
    var lines = <SaleLine>[];
    try {
      final raw = r['lines'] as String?;
      if (raw != null && raw.isNotEmpty) {
        lines = (jsonDecode(raw) as List)
            .map((e) => SaleLine.fromMap(Map<String, Object?>.from(e as Map)))
            .toList();
      }
    } catch (_) {}
    return Sale(
      id: r['id'] as String?,
      number: '${r['number'] ?? ''}',
      date: DateTime.tryParse('${r['date']}'),
      customerId: r['customer_id'] as String?,
      customerName: r['customer_name'] as String?,
      lines: lines,
      discount: (r['discount'] as num?)?.toDouble() ?? 0,
      tax: (r['tax'] as num?)?.toDouble() ?? 0,
      currency: r['currency'] as String? ?? 'USD',
      rate: (r['rate'] as num?)?.toDouble() ?? 1,
      paymentMethod: r['payment_method'] as String?,
      notes: r['notes'] as String?,
      paid: (r['paid'] as num?)?.toDouble(),
    );
  }

  double get subTotal => lines.fold(0, (s, l) => s + l.total);
  double get total => subTotal - discount + tax;

  /// Remises accordées : remises de ligne + remise globale.
  double get totalDiscounts =>
      lines.fold<double>(0, (s, l) => s + l.discount) + discount;

  /// Montant réellement payé à la vente. Règle de migration conservée :
  /// ancienne vente non « credit » => payée en totalité ; « credit » => 0.
  double get paidAtSale {
    final v = paid;
    if (v != null) return v;
    return paymentMethod == 'credit' ? 0 : total;
  }
}
