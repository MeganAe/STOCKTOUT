class AppCurrency {
  final String code;
  final String symbol;
  final String name;
  final int decimals;
  final double rateToBase;

  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.name,
    this.decimals = 2,
    this.rateToBase = 1,
  });

  AppCurrency copyWith({double? rateToBase, String? symbol, String? name}) =>
      AppCurrency(
        code: code,
        symbol: symbol ?? this.symbol,
        name: name ?? this.name,
        decimals: decimals,
        rateToBase: rateToBase ?? this.rateToBase,
      );

  Map<String, Object?> toMap() => {
        'code': code,
        'symbol': symbol,
        'name': name,
        'decimals': decimals,
        'rate': rateToBase,
      };

  factory AppCurrency.fromMap(Map<String, Object?> m) => AppCurrency(
        code: m['code'] as String,
        symbol: m['symbol'] as String? ?? '',
        name: m['name'] as String? ?? '',
        decimals: (m['decimals'] as num?)?.toInt() ?? 2,
        rateToBase: (m['rate'] as num?)?.toDouble() ?? 1,
      );

  /// Devises installees par defaut.
  static List<AppCurrency> defaults() => const [
        AppCurrency(code: 'USD', symbol: r'$', name: 'Dollar americain'),
        AppCurrency(code: 'EUR', symbol: '€', name: 'Euro'),
        AppCurrency(
            code: 'CDF', symbol: 'FC', name: 'Franc congolais', decimals: 0),
        AppCurrency(
            code: 'XAF',
            symbol: 'FCFA',
            name: 'Franc CFA (CEMAC)',
            decimals: 0),
        AppCurrency(
            code: 'XOF',
            symbol: 'FCFA',
            name: 'Franc CFA (UEMOA)',
            decimals: 0),
      ];
}
