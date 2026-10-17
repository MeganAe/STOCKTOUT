import 'package:intl/intl.dart';

import '../database/database.dart';
import '../models/currency.dart';

/// Conversion et formatage multi-devises.
/// La devise de base est celle de la boutique (USD par defaut).
class CurrencyService {
  final AppDatabase db;
  String baseCode;

  CurrencyService(this.db, {this.baseCode = 'USD'});

  Future<List<AppCurrency>> list() => db.allCurrencies();

  Future<void> save(AppCurrency c) => db.upsertCurrency(c);

  /// Convertit un montant de [from] vers [to].
  Future<double> convert(double amount, String from, String to) async {
    if (from == to) return amount;
    final all = await db.allCurrencies();
    final f = all.firstWhere((e) => e.code == from,
        orElse: () => const AppCurrency(code: 'USD', symbol: r'$', name: ''));
    final t = all.firstWhere((e) => e.code == to,
        orElse: () => const AppCurrency(code: 'USD', symbol: r'$', name: ''));
    if (f.rateToBase == 0 || t.rateToBase == 0) return amount;
    final inBase = amount / f.rateToBase;
    return inBase * t.rateToBase;
  }

  /// Formate selon la devise : symbole + decimales.
  Future<String> format(double amount, String code, {String? locale}) async {
    final all = await db.allCurrencies();
    final cur = all.firstWhere((e) => e.code == code,
        orElse: () => AppCurrency(code: code, symbol: code, name: code));
    final fmt = NumberFormat.currency(
      locale: locale,
      symbol: '${cur.symbol} ',
      decimalDigits: cur.decimals,
    );
    return fmt.format(amount);
  }
}
