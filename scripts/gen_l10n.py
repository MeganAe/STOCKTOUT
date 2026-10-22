#!/usr/bin/env python3
"""Genere lib/core/l10n/app_localizations.dart + l10n/*.arb (27 langues).

Les chaines viennent de scripts/l10n_data.py (source de verite).
Une cle contenant {nom} devient une methode : saleSaved('V-12').
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l10n_data import LANGS, ROWS  # noqa: E402

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DART = os.path.join(BASE, 'lib/core/l10n/app_localizations.dart')
ARB_DIR = os.path.join(BASE, 'l10n')

# ---- verification -----------------------------------------------------
T = {}
for row in ROWS:
    key, vals = row[0], row[1:]
    if len(vals) != len(LANGS):
        raise SystemExit(f'{key}: {len(vals)} valeurs pour {len(LANGS)} langues')
    if key in T:
        raise SystemExit(f'cle dupliquee: {key}')
    if any(not str(v).strip() for v in vals):
        raise SystemExit(f'{key}: valeur vide')
    T[key] = dict(zip(LANGS, vals))

PLACEHOLDER = re.compile(r'\{(\w+)\}')


def placeholders(key):
    return PLACEHOLDER.findall(T[key]['en'])


def dq(s):
    s = s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
    return f"'{s}'"


# ---- fichiers .arb ----------------------------------------------------
os.makedirs(ARB_DIR, exist_ok=True)
for lang in LANGS:
    data = {'@@locale': lang}
    for key, vals in T.items():
        data[key] = vals[lang]
    with open(os.path.join(ARB_DIR, f'app_{lang}.arb'), 'w',
              encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# ---- fichier Dart -----------------------------------------------------
L = []
L.append("import 'package:flutter/material.dart';")
L.append('')
L.append('/// Traductions embarquees : 27 langues, aucune chaine en dur.')
L.append("/// Genere par scripts/gen_l10n.py - ne pas editer a la main.")
L.append('class AppLocalizations {')
L.append('  final Locale locale;')
L.append('  const AppLocalizations(this.locale);')
L.append('')
L.append('  static const supportedLocales = [')
for lang in LANGS:
    L.append(f"    Locale('{lang}'),")
L.append('  ];')
L.append('')
L.append('  static AppLocalizations of(BuildContext context) =>')
L.append('      Localizations.of<AppLocalizations>(context, AppLocalizations) ??')
L.append("      const AppLocalizations(Locale('en'));")
L.append('')
L.append('  static const _v = <String, Map<String, String>>{')
for key, vals in T.items():
    inner = ', '.join(f"'{l}': {dq(vals[l])}" for l in LANGS)
    L.append(f"    '{key}': {{{inner}}},")
L.append('  };')
L.append('')
L.append('  String _t(String key) =>')
L.append("      _v[key]?[locale.languageCode] ?? _v[key]?['en'] ?? key;")
L.append('')
for key in T:
    ph = placeholders(key)
    if not ph:
        L.append(f"  String get {key} => _t('{key}');")
    else:
        args = ', '.join(f'String {p}' for p in ph)
        body = f"_t('{key}')"
        for p in ph:
            body += f".replaceFirst('{{{p}}}', {p})"
        L.append(f'  String {key}({args}) => {body};')
L.append('}')
L.append('''
class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) =>
      [''')
for lang in LANGS:
    L.append(f"        '{lang}',")
L.append('''      ].contains(locale.languageCode.toLowerCase());
  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);
  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
''')

with open(OUT_DART, 'w', encoding='utf-8') as f:
    f.write('\n'.join(L))

print(f'OK: {len(T)} cles x {len(LANGS)} langues')
print(f'  {OUT_DART}')
print(f'  {ARB_DIR}/app_*.arb ({len(LANGS)} fichiers)')
