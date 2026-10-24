import '../models/currency.dart';
import 'money.dart';

/// Formate un montant avec le symbole et les décimales de sa devise.
class MoneyFmt {
  final Map<String, AppCurrency> _byCode;
  MoneyFmt(Iterable<AppCurrency> currencies)
      : _byCode = {for (final c in currencies) c.code: c};

  String call(double v, String code) {
    final c = _byCode[code];
    final dec = c?.decimals ?? 2;
    final sym = (c?.symbol.isNotEmpty ?? false) ? c!.symbol : code;
    return '${formatMoney(v, dec)} $sym';
  }

  int decimals(String code) => _byCode[code]?.decimals ?? 2;
}
