import 'package:flutter_test/flutter_test.dart';
import 'package:stockpro/core/models/currency.dart';
import 'package:stockpro/core/models/product.dart';

void main() {
  test('stock bas detecte', () {
    final p = Product(sku: 'A1', name: 'Savon', quantity: 3, minStock: 5);
    expect(p.isLowStock, isTrue);
    expect(p.isOutOfStock, isFalse);
  });

  test('rupture detectee', () {
    final p = Product(sku: 'A2', name: 'Sel', quantity: 0, minStock: 5);
    expect(p.isOutOfStock, isTrue);
  });

  test('valorisation stock', () {
    final p = Product(sku: 'A3', name: 'Riz', quantity: 10, buyPrice: 2.5);
    expect(p.stockValue, 25.0);
  });

  test('marge', () {
    final p = Product(sku: 'A4', name: 'Huile', buyPrice: 8, sellPrice: 10);
    expect(p.margin, 2.0);
  });

  test('devises par defaut', () {
    final codes = AppCurrency.defaults().map((e) => e.code).toSet();
    expect(codes, containsAll({'USD', 'EUR', 'CDF', 'XAF', 'XOF'}));
  });
}
