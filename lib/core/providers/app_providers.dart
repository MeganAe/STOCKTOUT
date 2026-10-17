import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../models/automation.dart';
import '../models/currency.dart';
import '../models/product.dart';
import '../services/automation_engine.dart';
import '../services/currency_service.dart';

// ---------- Reglages ----------

class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;
  final String currency;

  const AppSettings({
    this.locale = const Locale('fr'),
    this.themeMode = ThemeMode.system,
    this.currency = 'USD',
  });

  AppSettings copyWith({Locale? locale, ThemeMode? themeMode, String? currency}) =>
      AppSettings(
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
        currency: currency ?? this.currency,
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
    state = AppSettings(
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
      m == ThemeMode.dark ? 'dark' : m == ThemeMode.light ? 'light' : 'system',
    );
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
  return AutomationEngine(AppDatabase.instance);
});

// ---------- Donnees ----------

final productsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final q = ref.watch(productSearchProvider);
  return AppDatabase.instance.allProducts(query: q);
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
