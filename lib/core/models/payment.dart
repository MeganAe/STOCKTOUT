import 'package:uuid/uuid.dart';

/// Paiement reçu d'un client pour solder (en partie) une dette.
class Payment {
  final String id;
  final String? saleId;
  final String? partnerId;
  final String customerName;
  final double amount;
  final String currency;
  final DateTime date;
  final String? method;
  final String? note;

  Payment({
    String? id,
    this.saleId,
    this.partnerId,
    required this.customerName,
    required this.amount,
    required this.currency,
    DateTime? date,
    this.method,
    this.note,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, Object?> toMap() => {
        'id': id,
        'sale_id': saleId,
        'partner_id': partnerId,
        'customer_name': customerName,
        'amount': amount,
        'currency': currency,
        'date': date.toIso8601String(),
        'method': method,
        'note': note,
      };

  factory Payment.fromMap(Map<String, Object?> m) => Payment(
        id: m['id'] as String?,
        saleId: m['sale_id'] as String?,
        partnerId: m['partner_id'] as String?,
        customerName: m['customer_name'] as String? ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        currency: m['currency'] as String? ?? 'USD',
        date: DateTime.tryParse('${m['date']}'),
        method: m['method'] as String?,
        note: m['note'] as String?,
      );
}
