import 'dart:math' as math;

/// Taux de change : code de devise -> nombre d'unités de cette devise pour
/// 1 unité de la devise de référence (ex. USD=1, CDF=2850).
typedef Rates = Map<String, double>;

/// Convertit [amount] de la devise [from] vers la devise [to].
/// Une devise inconnue ou de taux nul est traitée avec un taux de 1
/// (même comportement que le tableau de bord existant).
double convertAmount(double amount, String from, String to, Rates rates) {
  if (from == to) return amount;
  double r(String c) {
    final v = rates[c];
    return (v == null || v == 0) ? 1 : v;
  }

  return amount * r(to) / r(from);
}

/// Affiche [v] avec exactement [decimals] décimales (sans arrondi anticipé
/// sur les totaux : on n'arrondit qu'à l'affichage).
String formatMoney(double v, int decimals) {
  if (decimals <= 0) return v.round().toString();
  return v.toStringAsFixed(decimals);
}

/// Arrondit à [decimals] décimales (utilisé pour comparer des soldes).
double roundTo(double v, int decimals) {
  final m = math.pow(10, decimals).toDouble();
  return (v * m).round() / m;
}

/// Nombre de décimales d'une devise, 2 par défaut.
int decimalsOf(String code, Map<String, int> decimals) => decimals[code] ?? 2;
