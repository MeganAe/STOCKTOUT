import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../database/database.dart';
import '../logic/expiry.dart';
import '../models/automation.dart';
import '../models/product.dart';
import '../l10n/v5_strings.dart';
import 'automation_engine.dart';

/// Produits classés selon leur péremption.
class ExpiryReport {
  final List<Product> soon;
  final List<Product> expired;
  const ExpiryReport(this.soon, this.expired);
  bool get isEmpty => soon.isEmpty && expired.isEmpty;
}

ExpiryReport buildExpiryReport(List<Product> products, DateTime now,
    {int soonDays = 30}) {
  final soon = <Product>[];
  final expired = <Product>[];
  for (final p in products) {
    switch (classifyExpiry(p.expiryDate, now, soonDays: soonDays)) {
      case ExpiryStatus.soon:
        soon.add(p);
      case ExpiryStatus.expired:
        expired.add(p);
      case ExpiryStatus.none:
      case ExpiryStatus.ok:
        break;
    }
  }
  soon.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
  expired.sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
  return ExpiryReport(soon, expired);
}

/// Déclenchements quotidiens (une fois par jour, au démarrage) :
/// - `productExpiry` pour les produits périmés ou qui expirent bientôt ;
/// - `dailyReport` (rapport du jour).
class ExpiryService {
  static const _kDay = 'expiry_check_day';
  static const _kReportDay = 'daily_report_day';

  static String _today(DateTime now) => '${now.year}-${now.month}-${now.day}';

  static Future<void> dailyCheck(AutomationEngine engine,
      {required int soonDays}) async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    if (await db.getSetting(_kDay) == _today(now)) return;
    await db.setSetting(_kDay, _today(now));
    final report =
        buildExpiryReport(await db.allProducts(), now, soonDays: soonDays);
    if (report.isEmpty) return;
    final rules = (await db.allAutomations())
        .where((r) => r.enabled && r.trigger == AutoTrigger.productExpiry)
        .toList();
    if (rules.isEmpty) return;
    // Les autres actions tournent produit par produit ; la notification est
    // regroupée en UN seul message (pas 30 alertes d'affilée).
    for (final p in [...report.expired, ...report.soon].take(30)) {
      await engine.fire(AutoTrigger.productExpiry, product: p, notify: false);
    }
    if (rules.any((r) => r.actions.contains(AutoAction.notify))) {
      engine.emit(engine.t.expiryNotifTitle,
          engine.t.expiryNotifBody(report.soon.length, report.expired.length));
    }
  }

  /// Rapport quotidien : déclenche les règles `dailyReport` une fois par jour.
  static Future<void> dailyReport(AutomationEngine engine) async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    if (await db.getSetting(_kReportDay) == _today(now)) return;
    await db.setSetting(_kReportDay, _today(now));
    await engine.fire(AutoTrigger.dailyReport);
  }
}

/// Notification locale quotidienne (Android uniquement, optionnelle).
/// Le texte est calculé au lancement de l'application : il reflète l'état
/// du dernier démarrage (limite connue).
class ExpiryNotifier {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const _id = 4201;

  static bool get supported => Platform.isAndroid;

  static Future<void> _init() async {
    if (_ready || !supported) return;
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    _ready = true;
  }

  /// Demande la permission (Android 13+). À appeler seulement quand
  /// l'utilisateur ACTIVE l'option. Retourne false si refusée.
  static Future<bool> requestPermission() async {
    if (!supported) return false;
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// (Re)programme la notification quotidienne avec [title]/[body].
  static Future<void> schedule(String title, String body) async {
    if (!supported) return;
    await _init();
    await _plugin.periodicallyShow(
      _id,
      title,
      body,
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'stocktout_expiry',
          'Péremption',
          channelDescription: 'Produits qui expirent bientôt',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static bool _asked = false;

  /// Notification immédiate (règles d'automatisation). Demande la
  /// permission une seule fois par session si elle manque. Sans effet hors Android.
  static Future<void> showNow(String title, String body) async {
    if (!supported) return;
    try {
      await _init();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      var allowed = await android?.areNotificationsEnabled() ?? false;
      if (!allowed && !_asked) {
        _asked = true;
        allowed = await android?.requestNotificationsPermission() ?? false;
      }
      if (!allowed) return;
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch % 100000000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'stocktout_rules',
            'Automatisations',
            channelDescription: 'Notifications des règles automatiques',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
      );
    } catch (_) {
      // Une notification manquée ne doit jamais bloquer l'application.
    }
  }

  static Future<void> cancel() async {
    if (!supported) return;
    await _init();
    await _plugin.cancel(_id);
  }
}
