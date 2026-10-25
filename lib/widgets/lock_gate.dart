import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logic/pin_logic.dart';
import '../core/providers/app_providers.dart';
import '../core/services/backup_service.dart';
import '../core/services/expiry_service.dart';
import '../core/services/pin_service.dart';
import '../core/services/secure_screen.dart';
import 'lock_screen.dart';
import '../core/database/database.dart';
import '../core/l10n/app_localizations.dart';
import '../core/l10n/v5_strings.dart';

/// Permet d'ouvrir une activité externe (caméra, sélecteur de fichiers,
/// feuille de partage, empreinte) sans que le retour au premier plan
/// déclenche un verrouillage « immédiat ».
class LockGuard {
  static int _depth = 0;

  static Future<T> external<T>(Future<T> Function() action) async {
    _depth++;
    try {
      return await action();
    } finally {
      // Le retour de l'activité peut arriver après la fin du Future.
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (_depth > 0) _depth--;
      });
    }
  }

  static bool get suspended => _depth > 0;
}

/// Enveloppe de l'application : écran de verrouillage PIN, verrouillage
/// automatique après N minutes en arrière-plan, masquage du contenu dans
/// les applications récentes, et sauvegarde automatique au retour.
class LockGate extends ConsumerStatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applySecure();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startupTasks());
  }

  /// Au démarrage : sauvegarde quotidienne, vérification de péremption
  /// (une fois par jour) et mise à jour de la notification éventuelle.
  /// Aucune erreur ne doit bloquer l'application.
  Future<void> _startupTasks() async {
    try {
      unawaited(BackupService().autoBackupIfDue());
      final settings = ref.read(settingsProvider);
      final engine = ref.read(automationEngineProvider);
      await ExpiryService.dailyCheck(engine, soonDays: settings.expiryDays);
      await ExpiryService.dailyReport(engine);
      if (!mounted) return;
      if (settings.expiryNotify) await refreshExpiryNotification(ref);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _applySecure() async {
    try {
      await SecureScreen.set(await PinService().secureScreen());
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = ref.read(lockProvider);
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (lock.enabled && !LockGuard.suspended) {
          setState(() => _covered = true);
        }
      case AppLifecycleState.paused:
        if (lock.enabled && !LockGuard.suspended) {
          _backgroundedAt ??= DateTime.now();
        }
      case AppLifecycleState.resumed:
        _onResumed();
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _onResumed() async {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (ref.read(lockProvider).enabled && since != null) {
      final minutes = await PinService().autoLockMinutes();
      if (!mounted) return;
      if (shouldAutoLock(since, DateTime.now(), minutes)) {
        // Ferme les dialogues et pages ouverts : sinon ils resteraient
        // visibles AU-DESSUS de l'écran de verrouillage.
        Navigator.of(context).popUntil((r) => r.isFirst);
        ref.read(lockProvider.notifier).lock();
      }
    }
    if (mounted) setState(() => _covered = false);
    // Sauvegarde quotidienne au retour au premier plan (silencieuse).
    unawaited(BackupService().autoBackupIfDue());
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(lockProvider);
    // Écoute le réglage « masquer dans les récents » après changement.
    ref.listen(lockProvider, (_, __) => _applySecure());
    if (!lock.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Stack(
      children: [
        // Le contenu reste monté (état conservé) mais caché si verrouillé.
        Offstage(offstage: lock.locked, child: widget.child),
        if (lock.locked)
          LockScreen(
              onUnlocked: () => ref.read(lockProvider.notifier).unlock()),
        if (_covered && !lock.locked)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: const Center(child: Icon(Icons.lock_outline, size: 48)),
            ),
          ),
      ],
    );
  }
}

/// Recalcule le texte de la notification quotidienne de péremption
/// (ou l'annule s'il n'y a rien à signaler).
Future<void> refreshExpiryNotification(WidgetRef ref) async {
  final settings = ref.read(settingsProvider);
  final t = AppLocalizations(settings.locale);
  final report = buildExpiryReport(
      await AppDatabase.instance.allProducts(), DateTime.now(),
      soonDays: settings.expiryDays);
  if (report.isEmpty) {
    await ExpiryNotifier.cancel();
    return;
  }
  await ExpiryNotifier.schedule(t.expiryNotifTitle,
      t.expiryNotifBody(report.soon.length, report.expired.length));
}
