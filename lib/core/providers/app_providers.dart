import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../l10n/app_localizations.dart';
import '../logic/debts.dart';
import '../models/automation.dart';
import '../models/currency.dart';
import '../models/expense.dart';
import '../models/payment.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/automation_engine.dart';
import '../services/currency_service.dart';
import '../services/notifier.dart';
import '../services/pin_service.dart';

// ---------- Reglages ----------

class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;
  final String currency;

  /// Délai « expire bientôt » en jours (réglable, 30 par défaut).
  final int expiryDays;

  /// Notification quotidienne de péremption (désactivée par défaut).
  final bool expiryNotify;

  const AppSettings({
    this.locale = const Locale('fr'),
    this.themeMode = ThemeMode.system,
    this.currency = 'USD',
    this.expiryDays = 30,
    this.expiryNotify = false,
  });

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    String? currency,
    int? expiryDays,
    bool? expiryNotify,
  }) =>
      AppSettings(
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
        currency: currency ?? this.currency,
        expiryDays: expiryDays ?? this.expiryDays,
        expiryNotify: expiryNotify ?? this.expiryNotify,
      );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final lang = await db.getSetting('lang');
    final theme = await db.getSetting('theme');
    final cur = await db.getSetting('currency');
    final days = int.tryParse(await db.getSetting('expiry_days') ?? '');
    final notify = await db.getSetting('expiry_notify');
    state = AppSettings(
      expiryDays: (days != null && days > 0) ? days : 30,
      expiryNotify: notify == '1',
      locale: Locale(lang ?? 'fr'),
      themeMode: theme == 'dark'
          ? ThemeMode.dark
          : theme == 'light'
              ? ThemeMode.light
              : ThemeMode.system,
      currency: cur ?? 'USD',
    );
  }

  Future<void> setLocale(Locale l) async {
    state = state.copyWith(locale: l);
    await AppDatabase.instance.setSetting('lang', l.languageCode);
  }

  Future<void> setTheme(ThemeMode m) async {
    state = state.copyWith(themeMode: m);
    await AppDatabase.instance.setSetting(
      'theme',
      m == ThemeMode.dark
          ? 'dark'
          : m == ThemeMode.light
              ? 'light'
              : 'system',
    );
  }

  Future<void> setExpiryDays(int d) async {
    state = state.copyWith(expiryDays: d);
    await AppDatabase.instance.setSetting('expiry_days', '$d');
  }

  Future<void> setExpiryNotify(bool v) async {
    state = state.copyWith(expiryNotify: v);
    await AppDatabase.instance.setSetting('expiry_notify', v ? '1' : '0');
  }

  Future<void> setCurrency(String c) async {
    state = state.copyWith(currency: c);
    await AppDatabase.instance.setSetting('currency', c);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

// ---------- Services ----------

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final settings = ref.watch(settingsProvider);
  return CurrencyService(AppDatabase.instance, baseCode: settings.currency);
});

final automationEngineProvider = Provider<AutomationEngine>((ref) {
  final settings = ref.watch(settingsProvider);
  return AutomationEngine(
    AppDatabase.instance,
    AppLocalizations(settings.locale),
    onNotify: AppNotifier.show,
  );
});

// ---------- Donnees ----------

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final q = ref.watch(productSearchProvider);
  return AppDatabase.instance.allProducts(query: q);
});

/// Tous les produits, sans le filtre de recherche de l'écran Produits
/// (statistiques, tableau de bord). Se recharge quand les produits changent.
final allProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  ref.watch(productsProvider);
  return AppDatabase.instance.allProducts();
});

final productSearchProvider = StateProvider<String>((ref) => '');

final currenciesProvider =
    FutureProvider.autoDispose<List<AppCurrency>>((ref) async {
  return AppDatabase.instance.allCurrencies();
});

final automationsProvider =
    FutureProvider.autoDispose<List<AutomationRule>>((ref) async {
  return AppDatabase.instance.allAutomations();
});

final salesProvider =
    FutureProvider.autoDispose<List<Map<String, Object?>>>((ref) async {
  return AppDatabase.instance.allSales();
});

final paymentsProvider = FutureProvider.autoDispose<List<Payment>>((ref) async {
  return AppDatabase.instance.allPayments();
});

final expensesProvider = FutureProvider.autoDispose<List<Expense>>((ref) async {
  return AppDatabase.instance.allExpenses();
});

/// Taux de change (code -> taux) et décimales de chaque devise.
final ratesProvider =
    FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final list = await ref.watch(currenciesProvider.future);
  return {
    for (final c in list) c.code: c.rateToBase == 0 ? 1.0 : c.rateToBase,
  };
});

final decimalsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final list = await ref.watch(currenciesProvider.future);
  return {for (final c in list) c.code: c.decimals};
});

/// Dettes clients, triées par montant décroissant.
final debtsProvider =
    FutureProvider.autoDispose<List<CustomerDebt>>((ref) async {
  final rows = await ref.watch(salesProvider.future);
  final payments = await ref.watch(paymentsProvider.future);
  final rates = await ref.watch(ratesProvider.future);
  final base = ref.watch(settingsProvider).currency;
  return computeDebts(rows.map(Sale.fromRow).toList(), payments, rates, base);
});

// ---------- Verrouillage par code PIN ----------

class LockState {
  final bool loaded;
  final bool enabled;
  final bool locked;
  const LockState(
      {this.loaded = false, this.enabled = false, this.locked = false});

  LockState copyWith({bool? loaded, bool? enabled, bool? locked}) => LockState(
        loaded: loaded ?? this.loaded,
        enabled: enabled ?? this.enabled,
        locked: locked ?? this.locked,
      );
}

class LockNotifier extends StateNotifier<LockState> {
  LockNotifier() : super(const LockState()) {
    reload(lockNow: true);
  }

  /// Relit l'état du PIN. [lockNow] : verrouille aussitôt si un PIN existe
  /// (démarrage de l'application).
  Future<void> reload({bool lockNow = false}) async {
    final enabled = await PinService().isEnabled();
    state = LockState(
      loaded: true,
      enabled: enabled,
      locked: enabled && (lockNow || state.locked),
    );
  }

  void lock() {
    if (state.enabled) state = state.copyWith(locked: true);
  }

  void unlock() => state = state.copyWith(locked: false);
}

final lockProvider =
    StateNotifierProvider<LockNotifier, LockState>((ref) => LockNotifier());

/// Recharge tous les providers de données (après restauration d'une
/// sauvegarde ou réinitialisation).
void reloadAllData(WidgetRef ref) {
  ref.invalidate(settingsProvider);
  ref.invalidate(productsProvider);
  ref.invalidate(currenciesProvider);
  ref.invalidate(automationsProvider);
  ref.invalidate(salesProvider);
  ref.invalidate(paymentsProvider);
  ref.invalidate(expensesProvider);
  ref.invalidate(ratesProvider);
  ref.invalidate(decimalsProvider);
  ref.invalidate(debtsProvider);
  ref.invalidate(lockProvider);
}
