import '../models/payment.dart';
import '../models/sale.dart';
import 'money.dart';

/// Tolérance pour les comparaisons de montants (double).
const double kMoneyEps = 1e-6;

/// Normalise un nom de client pour regrouper « Jean », « jean  ».
String normalizeName(String? n) =>
    (n ?? '').trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// Clé de regroupement d'un client : identifiant du partenaire s'il existe,
/// sinon le nom normalisé. Chaîne vide = vente sans client.
String customerKeyOf(String? customerId, String? customerName) {
  if (customerId != null && customerId.isNotEmpty) return 'id:$customerId';
  final n = normalizeName(customerName);
  return n.isEmpty ? '' : 'name:$n';
}

/// Une vente avec un reste à payer, dans sa propre devise.
class OpenSale {
  final Sale sale;
  final double outstanding;
  const OpenSale(this.sale, this.outstanding);
}

/// Reste à payer d'une vente : total − payé à la vente − paiements reçus.
double outstandingOf(Sale s, Iterable<Payment> paymentsOfSale) {
  final paid = paymentsOfSale.fold<double>(0, (a, p) => a + p.amount);
  final v = s.total - s.paidAtSale - paid;
  return v < kMoneyEps ? 0 : v;
}

class CustomerDebt {
  final String key;
  final String name;
  final String? partnerId;

  /// Ventes impayées, de la plus ancienne à la plus récente.
  final List<OpenSale> sales;

  /// Dette par devise (devise de chaque vente).
  final Map<String, double> byCurrency;

  /// Dette totale convertie dans la devise par défaut.
  final double totalInBase;

  const CustomerDebt({
    required this.key,
    required this.name,
    required this.partnerId,
    required this.sales,
    required this.byCurrency,
    required this.totalInBase,
  });
}

/// Calcule la dette de chaque client (triée par montant décroissant).
/// Seuls les clients ayant un reste à payer sont retournés.
List<CustomerDebt> computeDebts(
  List<Sale> sales,
  List<Payment> payments,
  Rates rates,
  String base,
) {
  final bySale = <String, List<Payment>>{};
  for (final p in payments) {
    final id = p.saleId;
    if (id != null) (bySale[id] ??= []).add(p);
  }
  final groups = <String, List<OpenSale>>{};
  final names = <String, String>{};
  final partners = <String, String?>{};
  for (final s in sales) {
    final key = customerKeyOf(s.customerId, s.customerName);
    if (key.isEmpty) continue;
    final out = outstandingOf(s, bySale[s.id] ?? const []);
    if (out <= 0) continue;
    (groups[key] ??= []).add(OpenSale(s, out));
    names.putIfAbsent(key, () => (s.customerName ?? '').trim());
    partners.putIfAbsent(key, () => s.customerId);
  }
  final result = <CustomerDebt>[];
  groups.forEach((key, list) {
    list.sort((a, b) => a.sale.date.compareTo(b.sale.date));
    final byCur = <String, double>{};
    var total = 0.0;
    for (final o in list) {
      byCur[o.sale.currency] = (byCur[o.sale.currency] ?? 0) + o.outstanding;
      total += convertAmount(o.outstanding, o.sale.currency, base, rates);
    }
    result.add(CustomerDebt(
      key: key,
      name: names[key] ?? '',
      partnerId: partners[key],
      sales: list,
      byCurrency: byCur,
      totalInBase: total,
    ));
  });
  result.sort((a, b) => b.totalInBase.compareTo(a.totalInBase));
  return result;
}

/// Total général des dettes, en devise par défaut.
double totalDebt(List<CustomerDebt> debts) =>
    debts.fold<double>(0, (a, d) => a + d.totalInBase);

/// Part d'un paiement affectée à une vente.
class Allocation {
  final String saleId;
  final double amount;
  const Allocation(this.saleId, this.amount);
}

class AllocationResult {
  final List<Allocation> parts;

  /// Montant qui n'a pu être affecté (supérieur à la dette dans cette devise).
  final double unallocated;
  const AllocationResult(this.parts, this.unallocated);
}

/// Répartit [amount] (dans [currency]) sur les plus anciennes dettes
/// d'abord. [open] doit être trié du plus ancien au plus récent ; seules les
/// ventes dans la même devise sont concernées.
AllocationResult allocatePayment(
  List<OpenSale> open,
  double amount,
  String currency,
) {
  var left = amount;
  final parts = <Allocation>[];
  for (final o in open) {
    if (left <= kMoneyEps) break;
    if (o.sale.currency != currency) continue;
    final take = left < o.outstanding ? left : o.outstanding;
    if (take > kMoneyEps) {
      parts.add(Allocation(o.sale.id, take));
      left -= take;
    }
  }
  return AllocationResult(parts, left < kMoneyEps ? 0 : left);
}
