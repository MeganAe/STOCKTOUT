import 'dart:convert';

import 'package:uuid/uuid.dart';

/// Statuts d'un achat (code stable en base).
class PurchaseStatus {
  static const draft = 'draft';
  static const received = 'received';
  static const cancelled = 'cancelled';
}

/// Ligne d'achat : produit, quantité commandée, coût unitaire.
class PurchaseLine {
  final String productId;
  final String productName;
  final double quantity;

  /// Coût d'achat unitaire dans la devise de l'achat (null = inconnu :
  /// anciens achats ou brouillons automatiques ; le prix d'achat du produit
  /// n'est alors pas modifié à la réception).
  final double? unitCost;

  const PurchaseLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unitCost,
  });

  double get total => quantity * (unitCost ?? 0);

  PurchaseLine copyWith({double? quantity, double? unitCost}) => PurchaseLine(
        productId: productId,
        productName: productName,
        quantity: quantity ?? this.quantity,
        unitCost: unitCost ?? this.unitCost,
      );

  Map<String, Object?> toMap() => {
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        if (unitCost != null) 'unit_cost': unitCost,
      };

  /// Relit une ligne. Accepte l'ancien format `{"product_id","qty"}`.
  factory PurchaseLine.fromMap(Map<String, Object?> m) => PurchaseLine(
        productId: '${m['product_id'] ?? ''}',
        productName: '${m['product_name'] ?? ''}',
        quantity: ((m['quantity'] ?? m['qty']) as num?)?.toDouble() ?? 0,
        unitCost: (m['unit_cost'] as num?)?.toDouble(),
      );
}

/// Lit le JSON des lignes ; une valeur illisible donne une liste vide
/// (jamais d'exception : l'écran des achats ne doit pas planter).
List<PurchaseLine> parsePurchaseLines(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final data = jsonDecode(raw);
    if (data is! List) return const [];
    return [
      for (final e in data)
        if (e is Map) PurchaseLine.fromMap(Map<String, Object?>.from(e)),
    ];
  } catch (_) {
    return const [];
  }
}

String encodePurchaseLines(List<PurchaseLine> lines) =>
    jsonEncode(lines.map((l) => l.toMap()).toList());

class Purchase {
  final String id;
  final String number;
  final DateTime date;
  final String? supplierId;
  final String supplierName;
  final List<PurchaseLine> lines;
  final String status;
  final String currency;
  final String? notes;

  Purchase({
    String? id,
    required this.number,
    DateTime? date,
    this.supplierId,
    this.supplierName = '',
    required this.lines,
    this.status = PurchaseStatus.draft,
    required this.currency,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  double get total => lines.fold<double>(0, (s, l) => s + l.total);

  Map<String, Object?> toRow() => {
        'id': id,
        'number': number,
        'date': date.toIso8601String(),
        'supplier_id': supplierId,
        'supplier_name': supplierName,
        'lines': encodePurchaseLines(lines),
        'status': status,
        'currency': currency,
        'rate': 1,
        'notes': notes ?? '',
      };

  factory Purchase.fromRow(Map<String, Object?> r) => Purchase(
        id: r['id'] as String?,
        number: '${r['number'] ?? ''}',
        date: DateTime.tryParse('${r['date']}'),
        supplierId: r['supplier_id'] as String?,
        supplierName: '${r['supplier_name'] ?? ''}',
        lines: parsePurchaseLines(r['lines'] as String?),
        status: '${r['status'] ?? PurchaseStatus.draft}',
        currency: '${r['currency'] ?? 'USD'}',
        notes: r['notes'] as String?,
      );
}
