import 'package:uuid/uuid.dart';

class SaleLine {
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double discount;

  const SaleLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
  });

  double get total => quantity * unitPrice - discount;

  Map<String, Object?> toMap() => {
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'discount': discount,
      };

  factory SaleLine.fromMap(Map<String, Object?> m) => SaleLine(
        productId: m['product_id'] as String,
        productName: m['product_name'] as String? ?? '',
        quantity: (m['quantity'] as num).toDouble(),
        unitPrice: (m['unit_price'] as num).toDouble(),
        discount: (m['discount'] as num?)?.toDouble() ?? 0,
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
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  double get subTotal => lines.fold(0, (s, l) => s + l.total);
  double get total => subTotal - discount + tax;
}
