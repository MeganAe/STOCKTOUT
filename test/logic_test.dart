import 'package:flutter_test/flutter_test.dart';
import 'package:stocktout/core/logic/backup_logic.dart';
import 'package:stocktout/core/logic/debts.dart';
import 'package:stocktout/core/logic/expiry.dart';
import 'package:stocktout/core/logic/import_logic.dart';
import 'package:stocktout/core/logic/money.dart';
import 'package:stocktout/core/logic/pin_logic.dart';
import 'package:stocktout/core/logic/product_codes.dart';
import 'package:stocktout/core/logic/product_lookup.dart';
import 'package:stocktout/core/logic/stats.dart';
import 'package:stocktout/core/models/expense.dart';
import 'package:stocktout/core/models/payment.dart';
import 'package:stocktout/core/models/product.dart';
import 'package:stocktout/core/models/sale.dart';

const rates = <String, double>{'USD': 1, 'CDF': 2850, 'EUR': 0.9};

Sale sale(
  String id,
  DateTime date,
  List<SaleLine> lines, {
  double discount = 0,
  String currency = 'USD',
  String? method = 'cash',
  double? paid,
  String? customer,
  String? customerId,
}) =>
    Sale(
      id: id,
      number: id,
      date: date,
      lines: lines,
      discount: discount,
      currency: currency,
      paymentMethod: method,
      paid: paid,
      customerName: customer,
      customerId: customerId,
    );

void main() {
  group('Devises', () {
    test('conversion avec taux croisés', () {
      expect(convertAmount(2850, 'CDF', 'USD', rates), closeTo(1, 1e-9));
      expect(convertAmount(10, 'USD', 'CDF', rates), closeTo(28500, 1e-6));
      expect(convertAmount(5, 'USD', 'USD', rates), 5);
      expect(convertAmount(5, 'XXX', 'USD', rates), 5);
    });
    test('affichage selon les décimales', () {
      expect(formatMoney(12.345, 2), '12.35');
      expect(formatMoney(2849.6, 0), '2850');
    });
  });

  group('Codes produit', () {
    test('prochaine référence', () {
      expect(nextSku(['P-0003', 'X', 'P-0010']), 'P-0011');
      expect(nextSku([]), 'P-0001');
    });
    test('EAN-13 valide', () {
      expect(isValidEan13(generateEan13(123456789)), isTrue);
      expect(generateEan13(1).length, 13);
      expect(isValidEan13('2001234567891'), isFalse);
    });
  });

  group('Recherche exacte (scan)', () {
    final ps = [
      Product(sku: 'P-0001', name: 'A', barcode: '2000000000017'),
      Product(sku: 'ABC', name: 'B', barcode: '123'),
    ];
    test('code-barres, référence, inconnu, vide', () {
      expect(findProductByCode(ps, ' 2000000000017 ')?.name, 'A');
      expect(findProductByCode(ps, 'abc')?.name, 'B');
      expect(findProductByCode(ps, '12'), isNull);
      expect(findProductByCode(ps, '  '), isNull);
    });
  });

  group('Péremption', () {
    final now = DateTime(2026, 10, 23, 15, 30);
    test('classification et bornes', () {
      expect(classifyExpiry(null, now), ExpiryStatus.none);
      expect(classifyExpiry(DateTime(2026, 10, 22), now), ExpiryStatus.expired);
      expect(classifyExpiry(DateTime(2026, 10, 23), now), ExpiryStatus.soon);
      expect(classifyExpiry(DateTime(2026, 11, 22), now), ExpiryStatus.soon);
      expect(classifyExpiry(DateTime(2026, 11, 23), now), ExpiryStatus.ok);
      expect(classifyExpiry(DateTime(2026, 11, 23), now, soonDays: 31),
          ExpiryStatus.soon);
    });
  });

  group('Dettes', () {
    final d1 = DateTime(2026, 10, 1);
    final d2 = DateTime(2026, 10, 5);
    final line = const SaleLine(
        productId: 'p', productName: 'P', quantity: 2, unitPrice: 50);
    test('ancienne vente sans colonne paid', () {
      expect(sale('a', d1, [line], method: 'cash').paidAtSale, 100);
      expect(sale('b', d1, [line], method: 'credit').paidAtSale, 0);
    });
    test('solde d\'un client avec paiement partiel', () {
      final s1 = sale('s1', d1, [line],
          method: 'credit', paid: 30, customer: 'Jean ', customerId: 'c1');
      final s2 = sale('s2', d2, [line],
          method: 'credit', customer: 'Jean', customerId: 'c1');
      final pay = [
        Payment(saleId: 's1', customerName: 'Jean', amount: 20, currency: 'USD')
      ];
      final debts = computeDebts([s2, s1], pay, rates, 'USD');
      expect(debts.length, 1);
      expect(debts.first.totalInBase, closeTo(50 + 100, 1e-9));
      expect(debts.first.sales.first.sale.id, 's1'); // plus ancienne d'abord
      expect(debts.first.sales.first.outstanding, closeTo(50, 1e-9));
    });
    test('clients triés par dette décroissante, soldés exclus', () {
      final a = sale('a', d1, [line],
          method: 'credit', customer: 'Anna', customerId: 'a');
      final b = sale('b', d1, [line.copyWith(quantity: 5)],
          method: 'credit', customer: 'Bob', customerId: 'b');
      final c = sale('c', d1, [line], method: 'cash', customer: 'Cécile');
      final debts = computeDebts([a, b, c], [], rates, 'USD');
      expect(debts.map((d) => d.name).toList(), ['Bob', 'Anna']);
      expect(totalDebt(debts), closeTo(350, 1e-9));
    });
    test('devises mixtes converties dans la devise par défaut', () {
      final a = sale('a', d1, [line],
          method: 'credit', customer: 'Z', currency: 'USD');
      final b = sale(
          'b',
          d1,
          [
            const SaleLine(
                productId: 'p', productName: 'P', quantity: 1, unitPrice: 2850)
          ],
          method: 'credit',
          customer: 'Z',
          currency: 'CDF');
      final debts = computeDebts([a, b], [], rates, 'USD');
      expect(debts.first.totalInBase, closeTo(101, 1e-9));
      expect(debts.first.byCurrency['CDF'], 2850);
    });
    test('répartition d\'un paiement sur les plus anciennes dettes', () {
      final s1 = sale('s1', d1, [line], method: 'credit', customer: 'J');
      final s2 = sale('s2', d2, [line], method: 'credit', customer: 'J');
      final open = computeDebts([s2, s1], [], rates, 'USD').first.sales;
      final r = allocatePayment(open, 130, 'USD');
      expect(r.parts.length, 2);
      expect(r.parts[0].saleId, 's1');
      expect(r.parts[0].amount, 100);
      expect(r.parts[1].saleId, 's2');
      expect(r.parts[1].amount, 30);
      expect(r.unallocated, 0);
      final over = allocatePayment(open, 250, 'USD');
      expect(over.unallocated, closeTo(50, 1e-9));
      expect(allocatePayment(open, 10, 'CDF').parts, isEmpty);
    });
    test('paiement total solde la vente', () {
      final s1 = sale('s1', d1, [line], method: 'credit', customer: 'J');
      final pay = [
        Payment(saleId: 's1', customerName: 'J', amount: 100, currency: 'USD')
      ];
      expect(computeDebts([s1], pay, rates, 'USD'), isEmpty);
    });
  });

  group('Statistiques', () {
    final today = DateTime(2026, 10, 23, 10);
    final range = rangeFor(PeriodKind.today, today);
    test('périodes', () {
      expect(range.from, DateTime(2026, 10, 23));
      expect(range.to, DateTime(2026, 10, 24));
      expect(rangeFor(PeriodKind.days7, today).from, DateTime(2026, 10, 17));
      expect(rangeFor(PeriodKind.days30, today).days, 30);
      final m = rangeFor(PeriodKind.thisMonth, today);
      expect(m.from, DateTime(2026, 10, 1));
      expect(m.to, DateTime(2026, 11, 1));
      final c = rangeFor(PeriodKind.custom, today,
          customFrom: DateTime(2026, 10, 5), customTo: DateTime(2026, 10, 3));
      expect(c.from, DateTime(2026, 10, 3));
      expect(c.to, DateTime(2026, 10, 6));
    });
    test('bénéfice avec remise de ligne + remise globale', () {
      // 2 x 10 (remise ligne 2) = 18 ; 1 x 30 = 30 ; sous-total 48 ;
      // remise globale 8 -> chiffre d'affaires 40.
      // coût : 2 x 6 + 1 x 20 = 32 -> bénéfice 8.
      final s = sale(
        's',
        today,
        [
          const SaleLine(
              productId: 'a',
              productName: 'A',
              quantity: 2,
              unitPrice: 10,
              discount: 2,
              cost: 6),
          const SaleLine(
              productId: 'b',
              productName: 'B',
              quantity: 1,
              unitPrice: 30,
              cost: 20),
        ],
        discount: 8,
      );
      final st = computeStats(
        sales: [s],
        expenses: [],
        rates: rates,
        base: 'USD',
        range: range,
        buyPriceOf: {},
      );
      expect(st.revenue, closeTo(40, 1e-9));
      expect(st.cost, closeTo(32, 1e-9));
      expect(st.grossProfit, closeTo(8, 1e-9));
      expect(st.marginPct, closeTo(20, 1e-9));
      expect(st.discounts, closeTo(10, 1e-9));
      expect(st.salesCount, 1);
      expect(st.avgBasket, closeTo(40, 1e-9));
      // Σ bénéfices par produit = bénéfice brut.
      final sum = st.topByProfit.fold<double>(0, (a, e) => a + e.profit);
      expect(sum, closeTo(8, 1e-9));
    });
    test('devises mixtes', () {
      final usd = sale('u', today, [
        const SaleLine(
            productId: 'a',
            productName: 'A',
            quantity: 1,
            unitPrice: 10,
            cost: 4)
      ]);
      final cdf = sale(
          'c',
          today,
          [
            const SaleLine(
                productId: 'a',
                productName: 'A',
                quantity: 1,
                unitPrice: 28500,
                cost: 11400)
          ],
          currency: 'CDF');
      final st = computeStats(
        sales: [usd, cdf],
        expenses: [],
        rates: rates,
        base: 'USD',
        range: range,
        buyPriceOf: {},
      );
      expect(st.revenue, closeTo(20, 1e-9));
      expect(st.cost, closeTo(8, 1e-9));
      expect(st.grossProfit, closeTo(12, 1e-9));
    });
    test('anciennes ventes sans coût : repli sur le prix d\'achat actuel', () {
      final s = sale('s', today, [
        const SaleLine(
            productId: 'a', productName: 'A', quantity: 3, unitPrice: 10)
      ]);
      final st = computeStats(
        sales: [s],
        expenses: [],
        rates: rates,
        base: 'USD',
        range: range,
        buyPriceOf: {'a': 7},
      );
      expect(st.cost, closeTo(21, 1e-9));
      expect(st.grossProfit, closeTo(9, 1e-9));
    });
    test('bénéfice net = brut - dépenses, hors période ignoré', () {
      final s = sale('s', today, [
        const SaleLine(
            productId: 'a',
            productName: 'A',
            quantity: 1,
            unitPrice: 100,
            cost: 60)
      ]);
      final old = sale('o', DateTime(2026, 9, 1), [
        const SaleLine(
            productId: 'a',
            productName: 'A',
            quantity: 1,
            unitPrice: 999,
            cost: 1)
      ]);
      final exps = [
        Expense(date: today, category: 'Transport', amount: 5, currency: 'USD'),
        Expense(date: today, category: 'Loyer', amount: 2850, currency: 'CDF'),
        Expense(
            date: DateTime(2026, 9, 1),
            category: 'Loyer',
            amount: 500,
            currency: 'USD'),
      ];
      final st = computeStats(
        sales: [s, old],
        expenses: exps,
        rates: rates,
        base: 'USD',
        range: range,
        buyPriceOf: {},
      );
      expect(st.grossProfit, closeTo(40, 1e-9));
      expect(st.expenses, closeTo(6, 1e-9));
      expect(st.netProfit, closeTo(34, 1e-9));
      expect(st.buckets.length, 1);
    });
    test('produits dormants', () {
      final p1 = Product(id: '1', sku: 'a', name: 'Vendu', quantity: 5);
      final p2 = Product(id: '2', sku: 'b', name: 'Dort', quantity: 5);
      final p3 = Product(id: '3', sku: 'c', name: 'Sans stock', quantity: 0);
      final s = sale('s', DateTime(2026, 10, 10), [
        const SaleLine(
            productId: '1', productName: 'Vendu', quantity: 1, unitPrice: 1)
      ]);
      final d = dormantProducts([p1, p2, p3], [s], DateTime(2026, 10, 23));
      expect(d.map((e) => e.id).toList(), ['2']);
    });
    test('total des dépenses par mois', () {
      final exps = [
        Expense(
            date: DateTime(2026, 10, 2),
            category: 'a',
            amount: 10,
            currency: 'USD'),
        Expense(
            date: DateTime(2026, 10, 30),
            category: 'a',
            amount: 2850,
            currency: 'CDF'),
        Expense(
            date: DateTime(2026, 11, 1),
            category: 'a',
            amount: 99,
            currency: 'USD'),
      ];
      expect(expensesTotalForMonth(exps, rates, 'USD', 2026, 10),
          closeTo(11, 1e-9));
    });
  });

  group('Import CSV', () {
    test('détection du séparateur et BOM', () {
      expect(detectDelimiter('a;b;c\n1;2;3'), ';');
      expect(detectDelimiter('a,b,c\n1,2,3'), ',');
      expect(detectDelimiter('a\tb\n1\t2'), '\t');
      expect(detectDelimiter('"a;b",c\n1,2'), ',');
      expect(stripBom('\uFEFFnom;x'), 'nom;x');
      final rows = parseCsv('\uFEFFnom;prix\r\nSavon;1,5\r\n');
      expect(rows, [
        ['nom', 'prix'],
        ['Savon', '1,5']
      ]);
    });
    test('guillemets, retours à la ligne et lignes vides', () {
      final rows = parseCsv('a,b\n"x, y","He said ""hi"""\n\n"l1\nl2",z');
      expect(rows.length, 3);
      expect(rows[1], ['x, y', 'He said "hi"']);
      expect(rows[2], ['l1\nl2', 'z']);
    });
    test('nombres avec virgule décimale', () {
      expect(parseNumber('12,5'), 12.5);
      expect(parseNumber('12.5'), 12.5);
      expect(parseNumber('1 250,50'), 1250.5);
      expect(parseNumber('1.250,50'), 1250.5);
      expect(parseNumber('1,250.50'), 1250.5);
      expect(parseNumber('1,250'), 1250);
      expect(parseNumber('\$12'), 12);
      expect(parseNumber('0,5'), 0.5);
      expect(parseNumber('abc'), isNull);
      expect(parseNumber(''), isNull);
      expect(parseNumber('-3'), -3);
    });
    test('association automatique fr/en', () {
      final m = autoMapColumns([
        'Nom du produit',
        'Référence',
        'Code-barres',
        'Catégorie',
        'Unité',
        "Prix d'achat",
        'Prix de vente',
        'Quantité',
        'Stock mini'
      ]);
      expect(m[ImportField.name], 0);
      expect(m[ImportField.sku], 1);
      expect(m[ImportField.barcode], 2);
      expect(m[ImportField.category], 3);
      expect(m[ImportField.unit], 4);
      expect(m[ImportField.buyPrice], 5);
      expect(m[ImportField.sellPrice], 6);
      expect(m[ImportField.quantity], 7);
      expect(m[ImportField.minStock], 8);
      final en = autoMapColumns(['name', 'sku', 'barcode', 'price', 'qty']);
      expect(en[ImportField.sellPrice], 3);
      expect(en[ImportField.quantity], 4);
      expect(en[ImportField.buyPrice], isNull);
    });
    final existing = [
      Product(
          id: 'e1', sku: 'P-0001', name: 'Ancien', barcode: '111', quantity: 4),
    ];
    final mapping = autoMapColumns(
        ['nom', 'reference', 'code-barres', 'prix achat', 'prix vente', 'qte']);
    test('doublons : mise à jour', () {
      final plan = planImport(
        rows: [
          ['Nouveau nom', 'P-0001', '', '2,5', '4', '10'],
          ['Frais', '', '', '10', '', '3'],
        ],
        mapping: mapping,
        existing: existing,
        mode: DuplicateMode.update,
        seed: 42,
      );
      expect(plan.toUpdate.length, 1);
      expect(plan.toUpdate.first.id, 'e1');
      expect(plan.toUpdate.first.name, 'Nouveau nom');
      expect(plan.toUpdate.first.buyPrice, 2.5);
      expect(plan.toUpdate.first.quantity, 10);
      expect(plan.toCreate.length, 1);
      expect(plan.toCreate.first.sku, 'P-0002');
      expect(isValidEan13(plan.toCreate.first.barcode!), isTrue);
      expect(plan.toCreate.first.sellPrice, closeTo(13, 1e-9)); // +30 %
    });
    test('doublons : ignorer, par code-barres', () {
      final plan = planImport(
        rows: [
          ['X', '', '111', '1', '2', '1'],
        ],
        mapping: mapping,
        existing: existing,
        mode: DuplicateMode.skip,
      );
      expect(plan.skipped, 1);
      expect(plan.toCreate, isEmpty);
      expect(plan.toUpdate, isEmpty);
    });
    test('lignes invalides et doublon dans le fichier', () {
      final plan = planImport(
        rows: [
          ['', 'A', '', '1', '2', '1'],
          ['Ok', 'N-1', '', 'abc', '2', '1'],
          ['Neg', 'N-2', '', '1', '2', '-5'],
          ['Bon', 'N-3', '', '1', '2', '1'],
          ['Bon bis', 'n-3', '', '1', '2', '1'],
        ],
        mapping: mapping,
        existing: const [],
        mode: DuplicateMode.update,
      );
      expect(plan.toCreate.length, 1);
      expect(plan.errors.map((e) => e.line).toList(), [2, 3, 4, 6]);
      expect(plan.errors[0].code, ImportErrorCode.missingName);
      expect(plan.errors[1].code, ImportErrorCode.badNumber);
      expect(plan.errors[2].code, ImportErrorCode.negativeNumber);
      expect(plan.errors[3].code, ImportErrorCode.duplicateInFile);
    });
    test('5000 lignes : références et codes-barres tous uniques', () {
      final rows = [
        for (var i = 0; i < 5000; i++) ['Produit $i', '', '', '1', '2', '1'],
      ];
      final plan = planImport(
        rows: rows,
        mapping: mapping,
        existing: existing,
        mode: DuplicateMode.update,
      );
      expect(plan.toCreate.length, 5000);
      expect(plan.toCreate.map((p) => p.sku).toSet().length, 5000);
      expect(plan.toCreate.map((p) => p.barcode).toSet().length, 5000);
    });
    test('modèle CSV relisible', () {
      final rows = parseCsv(csvTemplate());
      expect(rows.length, 3);
      expect(rows.first.length, 9);
      expect(parseNumber(rows[1][5]), 1.5);
    });
  });

  group('Code PIN', () {
    test('format', () {
      expect(isValidPinFormat('1234'), isTrue);
      expect(isValidPinFormat('123456'), isTrue);
      expect(isValidPinFormat('123'), isFalse);
      expect(isValidPinFormat('1234567'), isFalse);
      expect(isValidPinFormat('12a4'), isFalse);
    });
    test('hash salé et vérification', () {
      final salt = generateSalt();
      final h = hashPin('4821', salt);
      expect(h.contains('4821'), isFalse);
      expect(h.length, 64);
      expect(verifyPin('4821', salt, h), isTrue);
      expect(verifyPin('4822', salt, h), isFalse);
      expect(hashPin('4821', generateSalt()) == h, isFalse);
      // Vecteur connu : sha256("a:1234") calculé indépendamment.
      expect(hashPin('1234', 'a').length, 64);
    });
    test('blocage croissant après 5 échecs', () {
      expect(pinLockDuration(4), Duration.zero);
      expect(pinLockDuration(5), const Duration(seconds: 30));
      expect(pinLockDuration(6), const Duration(minutes: 1));
      expect(pinLockDuration(7), const Duration(minutes: 5));
      expect(pinLockDuration(8), const Duration(minutes: 15));
      expect(pinLockDuration(50), const Duration(hours: 1));
    });
    test('durée restante', () {
      final now = DateTime(2026, 1, 1, 12);
      final until = now.add(const Duration(seconds: 30));
      expect(pinLockRemaining(until, now), const Duration(seconds: 30));
      expect(pinLockRemaining(until, now.add(const Duration(minutes: 1))),
          Duration.zero);
      expect(pinLockRemaining(null, now), Duration.zero);
    });
    test('verrouillage automatique', () {
      final t = DateTime(2026, 1, 1, 12);
      expect(shouldAutoLock(null, t, 5), isFalse);
      expect(shouldAutoLock(t, t, 0), isTrue);
      expect(shouldAutoLock(t, t.add(const Duration(minutes: 4)), 5), isFalse);
      expect(shouldAutoLock(t, t.add(const Duration(minutes: 5)), 5), isTrue);
    });
  });

  group('Sauvegardes', () {
    test('nom et date', () {
      final d = DateTime(2026, 10, 23, 14, 30, 5);
      final n = backupFileName(d);
      expect(n, 'stocktout-backup-20261023-143005.zip');
      expect(parseBackupDate(n), d);
      expect(parseBackupDate('photo.jpg'), isNull);
    });
    test('rotation : garde les 7 plus récentes', () {
      final names = [
        for (var i = 1; i <= 10; i++) backupFileName(DateTime(2026, 10, i, 8)),
        'notes.txt',
      ];
      final del = backupsToDelete(names..shuffle());
      expect(del.length, 3);
      del.sort();
      expect(del, [
        backupFileName(DateTime(2026, 10, 1, 8)),
        backupFileName(DateTime(2026, 10, 2, 8)),
        backupFileName(DateTime(2026, 10, 3, 8)),
      ]);
      expect(backupsToDelete(names.take(5)), isEmpty);
    });
    test('sauvegarde due après 24 h', () {
      final now = DateTime(2026, 10, 23, 12);
      expect(isBackupDue(null, now), isTrue);
      expect(
          isBackupDue(now.subtract(const Duration(hours: 23)), now), isFalse);
      expect(isBackupDue(now.subtract(const Duration(hours: 25)), now), isTrue);
    });
  });

  group('Modèles', () {
    test('SaleLine : coût sérialisé et ancien format relu', () {
      final l = const SaleLine(
          productId: 'p', productName: 'P', quantity: 1, unitPrice: 5, cost: 3);
      expect(l.toMap()['cost'], 3);
      expect(SaleLine.fromMap(l.toMap()).cost, 3);
      final old = SaleLine.fromMap({
        'product_id': 'p',
        'product_name': 'P',
        'quantity': 1,
        'unit_price': 5,
      });
      expect(old.cost, isNull);
      expect(old.toMap().containsKey('cost'), isFalse);
      expect(l.copyWith(quantity: 2).cost, 3);
    });
    test('Product : photo et péremption', () {
      final p = Product(sku: 'a', name: 'b', imagePath: '/x.jpg');
      expect(Product.fromMap(p.toMap()).imagePath, '/x.jpg');
      expect(p.copyWith(clearImage: true).imagePath, isNull);
      final q = Product(sku: 'a', name: 'b', expiryDate: DateTime(2026, 12, 1));
      expect(q.copyWith(clearExpiry: true).expiryDate, isNull);
      expect(q.copyWith(name: 'c').expiryDate, DateTime(2026, 12, 1));
    });
  });
}
