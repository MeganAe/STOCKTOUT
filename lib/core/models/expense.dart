import 'package:uuid/uuid.dart';

/// Dépense de la boutique (transport, loyer, électricité...).
class Expense {
  final String id;
  final DateTime date;
  final String category;
  final double amount;
  final String currency;
  final String? note;

  Expense({
    String? id,
    DateTime? date,
    required this.category,
    required this.amount,
    required this.currency,
    this.note,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'category': category,
        'amount': amount,
        'currency': currency,
        'note': note,
      };

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as String?,
        date: DateTime.tryParse('${m['date']}'),
        category: m['category'] as String? ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        currency: m['currency'] as String? ?? 'USD',
        note: m['note'] as String?,
      );
}
