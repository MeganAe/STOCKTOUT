import 'package:flutter/material.dart';

/// Traductions embarquees (27 langues). Repli automatique sur l'anglais.
class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('es'),
    Locale('de'),
    Locale('it'),
    Locale('pt'),
    Locale('nl'),
    Locale('ru'),
    Locale('zh'),
    Locale('ja'),
    Locale('ko'),
    Locale('ar'),
    Locale('hi'),
    Locale('tr'),
    Locale('pl'),
    Locale('sv'),
    Locale('da'),
    Locale('no'),
    Locale('fi'),
    Locale('el'),
    Locale('cs'),
    Locale('ro'),
    Locale('hu'),
    Locale('id'),
    Locale('sw'),
    Locale('ln'),
    Locale('uk'),
  ];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
          const AppLocalizations(Locale('en'));

  static const _v = <String, Map<String, String>>{
    'dashboard': {$inner},
    'products': {$inner},
    'inventory': {$inner},
    'sales': {$inner},
    'purchases': {$inner},
    'partners': {$inner},
    'reports': {$inner},
    'automations': {$inner},
    'settings': {$inner},
    'about': {$inner},
    'search': {$inner},
    'add': {$inner},
    'edit': {$inner},
    'delete': {$inner},
    'save': {$inner},
    'cancel': {$inner},
    'sku': {$inner},
    'productName': {$inner},
    'category': {$inner},
    'quantity': {$inner},
    'buyPrice': {$inner},
    'sellPrice': {$inner},
    'minStock': {$inner},
    'total': {$inner},
    'stockValue': {$inner},
    'lowStock': {$inner},
    'outOfStock': {$inner},
    'newSale': {$inner},
    'newProduct': {$inner},
    'language': {$inner},
    'currency': {$inner},
    'theme': {$inner},
    'close': {$inner},
  };

  String _t(String key) =>
      _v[key]?[locale.languageCode] ?? _v[key]?['en'] ?? key;

  String get dashboard => _t('dashboard');
  String get products => _t('products');
  String get inventory => _t('inventory');
  String get sales => _t('sales');
  String get purchases => _t('purchases');
  String get partners => _t('partners');
  String get reports => _t('reports');
  String get automations => _t('automations');
  String get settings => _t('settings');
  String get about => _t('about');
  String get search => _t('search');
  String get add => _t('add');
  String get edit => _t('edit');
  String get delete => _t('delete');
  String get save => _t('save');
  String get cancel => _t('cancel');
  String get sku => _t('sku');
  String get productName => _t('productName');
  String get category => _t('category');
  String get quantity => _t('quantity');
  String get buyPrice => _t('buyPrice');
  String get sellPrice => _t('sellPrice');
  String get minStock => _t('minStock');
  String get total => _t('total');
  String get stockValue => _t('stockValue');
  String get lowStock => _t('lowStock');
  String get outOfStock => _t('outOfStock');
  String get newSale => _t('newSale');
  String get newProduct => _t('newProduct');
  String get language => _t('language');
  String get currency => _t('currency');
  String get theme => _t('theme');
  String get close => _t('close');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) =>
      ['en', 'fr', 'es', 'de', 'it', 'pt', 'nl', 'ru', 'zh', 'ja', 'ko', 'ar', 'hi', 'tr', 'pl', 'sv', 'da', 'no', 'fi', 'el', 'cs', 'ro', 'hu', 'id', 'sw', 'ln', 'uk'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
