import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../database/database.dart';
import '../logic/expiry.dart';
import '../models/automation.dart';
import '../models/product.dart';
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

/// Vérification quotidienne (au démarrage) : déclenche l'automatisation
/// `AutoTrigger.productExpiry` pour chaque produit concerné, une seule
/// fois par jour.
class ExpiryService {
  static const _kDay = 'expiry_check_day';

  static Future<void> dailyCheck(AutomationEngine engine,
      {required int soonDays}) async {
    final db = AppDatabase.instance;
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    if (await db.getSetting(_kDay) == today) return;
    await db.setSetting(_kDay, today);
    final report =
        buildExpiryReport(await db.allProducts(), now, soonDays: soonDays);
    for (final p in [...report.expired, ...report.soon].take(30)) {
      await engine.fire(AutoTrigger.productExpiry, product: p);
    }
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

  static Future<void> cancel() async {
    if (!supported) return;
    await _init();
    await _plugin.cancel(_id);
  }
}
