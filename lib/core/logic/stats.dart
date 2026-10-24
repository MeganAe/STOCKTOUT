import '../models/expense.dart';
import '../models/product.dart';
import '../models/sale.dart';
import 'money.dart';

enum PeriodKind { today, days7, days30, thisMonth, custom }

/// Intervalle [from, to[ : [from] inclus, [to] exclu (minuit).
class DateRange {
  final DateTime from;
  final DateTime to;
  const DateRange(this.from, this.to);

  bool contains(DateTime d) => !d.isBefore(from) && d.isBefore(to);
  int get days => to.difference(from).inDays;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Intervalle d'une période prédéfinie (ou personnalisée : les deux dates
/// sont incluses). Les « N jours » comptent aujourd'hui.
DateRange rangeFor(PeriodKind k, DateTime now,
    {DateTime? customFrom, DateTime? customTo}) {
  final today = _day(now);
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  switch (k) {
    case PeriodKind.today:
      return DateRange(today, tomorrow);
    case PeriodKind.days7:
      return DateRange(
          DateTime(today.year, today.month, today.day - 6), tomorrow);
    case PeriodKind.days30:
      return DateRange(
          DateTime(today.year, today.month, today.day - 29), tomorrow);
    case PeriodKind.thisMonth:
      return DateRange(DateTime(today.year, today.month, 1),
          DateTime(today.year, today.month + 1, 1));
    case PeriodKind.custom:
      var a = _day(customFrom ?? today);
      var b = _day(customTo ?? today);
      if (b.isBefore(a)) {
        final t = a;
        a = b;
        b = t;
      }
      return DateRange(a, DateTime(b.year, b.month, b.day + 1));
  }
}

class ProductStat {
  final String productId;
  final String name;
  final double quantity;
  final double profit;
  const ProductStat(this.productId, this.name, this.quantity, this.profit);
}

class Bucket {
  final DateTime start;
  final double revenue;
  const Bucket(this.start, this.revenue);
}

class Stats {
  final double revenue;
  final double cost;
  final double grossProfit;
  final double marginPct;
  final int salesCount;
  final double avgBasket;
  final double discounts;
  final double expenses;
  final double netProfit;
  final List<Bucket> buckets;
  final bool monthly;
  final List<ProductStat> topByQty;
  final List<ProductStat> topByProfit;

  const Stats({
    required this.revenue,
    required this.cost,
    required this.grossProfit,
    required this.marginPct,
    required this.salesCount,
    required this.avgBasket,
    required this.discounts,
    required this.expenses,
    required this.netProfit,
    required this.buckets,
    required this.monthly,
    required this.topByQty,
    required this.topByProfit,
  });
}

/// Statistiques d'une période, tout en devise [base].
///
/// - chiffre d'affaires = sous-total − remise globale (hors taxe) ;
/// - coût d'une ligne = quantité × coût unitaire enregistré à la vente
///   (devise de la vente, convertie) ; pour une ancienne vente sans coût,
///   repli sur le prix d'achat ACTUEL du produit ([buyPriceOf], déjà dans la
///   devise par défaut puisque les prix produits sont convertis quand la
///   devise change) ;
/// - la remise globale est répartie sur les lignes au prorata pour les
///   classements par produit ;
/// - bénéfice net = bénéfice brut − dépenses de la période.
Stats computeStats({
  required List<Sale> sales,
  required List<Expense> expenses,
  required Rates rates,
  required String base,
  required DateRange range,
  required Map<String, double> buyPriceOf,
  int topN = 10,
}) {
  double conv(double v, String cur) => convertAmount(v, cur, base, rates);

  var revenue = 0.0, cost = 0.0, discounts = 0.0;
  var count = 0;
  final qty = <String, double>{};
  final profit = <String, double>{};
  final names = <String, String>{};
  final monthly = range.days > 62;
  final revBy = <DateTime, double>{};

  for (final s in sales) {
    if (!range.contains(s.date)) continue;
    count++;
    final sub = s.subTotal;
    final saleRevenue = sub - s.discount;
    revenue += conv(saleRevenue, s.currency);
    discounts += conv(s.totalDiscounts, s.currency);
    final key = monthly ? DateTime(s.date.year, s.date.month, 1) : _day(s.date);
    revBy[key] = (revBy[key] ?? 0) + conv(saleRevenue, s.currency);

    for (final l in s.lines) {
      final lineCost = l.cost != null
          ? conv(l.quantity * l.cost!, s.currency)
          : l.quantity * (buyPriceOf[l.productId] ?? 0);
      cost += lineCost;
      final share = sub == 0 ? 0.0 : l.total / sub;
      final lineRevenue = conv(l.total - s.discount * share, s.currency);
      qty[l.productId] = (qty[l.productId] ?? 0) + l.quantity;
      profit[l.productId] =
          (profit[l.productId] ?? 0) + (lineRevenue - lineCost);
      names[l.productId] = l.productName;
    }
  }

  var exp = 0.0;
  for (final e in expenses) {
    if (range.contains(e.date)) exp += conv(e.amount, e.currency);
  }

  // Seaux zéro-remplis pour un graphique continu.
  final buckets = <Bucket>[];
  if (monthly) {
    var m = DateTime(range.from.year, range.from.month, 1);
    while (m.isBefore(range.to)) {
      buckets.add(Bucket(m, revBy[m] ?? 0));
      m = DateTime(m.year, m.month + 1, 1);
    }
  } else {
    var d = range.from;
    while (d.isBefore(range.to)) {
      buckets.add(Bucket(d, revBy[d] ?? 0));
      d = DateTime(d.year, d.month, d.day + 1);
    }
  }

  final all = [
    for (final id in qty.keys)
      ProductStat(id, names[id] ?? '', qty[id]!, profit[id] ?? 0),
  ];
  final byQty = List<ProductStat>.of(all)
    ..sort((a, b) => b.quantity.compareTo(a.quantity));
  final byProfit = List<ProductStat>.of(all)
    ..sort((a, b) => b.profit.compareTo(a.profit));

  final gross = revenue - cost;
  return Stats(
    revenue: revenue,
    cost: cost,
    grossProfit: gross,
    marginPct: revenue == 0 ? 0 : gross / revenue * 100,
    salesCount: count,
    avgBasket: count == 0 ? 0 : revenue / count,
    discounts: discounts,
    expenses: exp,
    netProfit: gross - exp,
    buckets: buckets,
    monthly: monthly,
    topByQty: byQty.take(topN).toList(),
    topByProfit: byProfit.take(topN).toList(),
  );
}

/// Produits en stock sans aucune vente depuis [days] jours.
List<Product> dormantProducts(
  List<Product> products,
  List<Sale> sales,
  DateTime now, {
  int days = 30,
}) {
  final since = DateTime(now.year, now.month, now.day - days);
  final sold = <String>{};
  for (final s in sales) {
    if (s.date.isBefore(since)) continue;
    for (final l in s.lines) {
      sold.add(l.productId);
    }
  }
  return products.where((p) => p.quantity > 0 && !sold.contains(p.id)).toList();
}

/// Total des dépenses d'un mois (année, mois), en devise [base].
double expensesTotalForMonth(
  List<Expense> expenses,
  Rates rates,
  String base,
  int year,
  int month,
) {
  var t = 0.0;
  for (final e in expenses) {
    if (e.date.year == year && e.date.month == month) {
      t += convertAmount(e.amount, e.currency, base, rates);
    }
  }
  return t;
}
