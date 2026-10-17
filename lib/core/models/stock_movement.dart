import 'package:uuid/uuid.dart';

enum MovementType { in_, out, adjustment, transfer, loss, return_ }

class StockMovement {
  final String id;
  final String productId;
  final MovementType type;
  final double quantity;
  final double? unitPrice;
  final String? reason;
  final String? reference;
  final DateTime date;

  StockMovement({
    String? id,
    required this.productId,
    required this.type,
    required this.quantity,
    this.unitPrice,
    this.reason,
    this.reference,
    DateTime? date,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, Object?> toMap() => {
        'id': id,
        'product_id': productId,
        'type': type.name,
        'quantity': quantity,
        'unit_price': unitPrice,
        'reason': reason,
        'reference': reference,
        'date': date.toIso8601String(),
      };

  factory StockMovement.fromMap(Map<String, Object?> m) => StockMovement(
        id: m['id'] as String,
        productId: m['product_id'] as String,
        type: MovementType.values.firstWhere(
          (e) => e.name == (m['type'] as String),
          orElse: () => MovementType.adjustment,
        ),
        quantity: (m['quantity'] as num).toDouble(),
        unitPrice: (m['unit_price'] as num?)?.toDouble(),
        reason: m['reason'] as String?,
        reference: m['reference'] as String?,
        date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
      );
}
