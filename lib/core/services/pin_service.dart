import '../database/database.dart';
import '../logic/pin_logic.dart';

/// Résultat d'une vérification de PIN.
class PinResult {
  final bool ok;

  /// Essais restants avant blocage (si faux et pas bloqué).
  final int attemptsLeft;

  /// Durée de blocage restante (non nulle = bloqué).
  final Duration locked;
  const PinResult(
      {this.ok = false, this.attemptsLeft = 0, this.locked = Duration.zero});
}

/// Code PIN : hash SHA-256 salé dans la table `settings`.
class PinService {
  PinService([AppDatabase? db]) : db = db ?? AppDatabase.instance;
  final AppDatabase db;

  static const _kHash = 'pin_hash';
  static const _kSalt = 'pin_salt';
  static const _kFails = 'pin_fails';
  static const _kUntil = 'pin_locked_until';
  static const _kAuto = 'pin_auto_lock';
  static const _kBio = 'pin_biometric';
  static const _kSecure = 'secure_screen';
  static const _kLen = 'pin_len';

  Future<bool> isEnabled() async => (await db.getSetting(_kHash)) != null;

  /// Active ou change le PIN (nouveau sel à chaque fois).
  Future<void> setPin(String pin) async {
    final salt = generateSalt();
    await db.setSetting(_kSalt, salt);
    await db.setSetting(_kHash, hashPin(pin, salt));
    // Longueur (4 à 6) : sert à valider automatiquement à la dernière touche.
    await db.setSetting(_kLen, '${pin.length}');
    await _resetFails();
  }

  /// Désactive le PIN (le code actuel doit avoir été vérifié avant).
  Future<void> disable() async {
    for (final k in [_kHash, _kSalt, _kLen, _kFails, _kUntil, _kBio]) {
      await db.db.delete('settings', where: 'key = ?', whereArgs: [k]);
    }
  }

  Future<int> length() async {
    final v = int.tryParse(await db.getSetting(_kLen) ?? '');
    return (v != null && v >= 4 && v <= 6) ? v : 4;
  }

  Future<Duration> lockRemaining() async {
    final raw = await db.getSetting(_kUntil);
    return pinLockRemaining(
        raw == null ? null : DateTime.tryParse(raw), DateTime.now());
  }

  /// Vérifie un PIN. Après 5 erreurs : blocage croissant.
  Future<PinResult> verify(String pin) async {
    final remaining = await lockRemaining();
    if (remaining > Duration.zero) return PinResult(locked: remaining);

    final hash = await db.getSetting(_kHash);
    final salt = await db.getSetting(_kSalt);
    if (hash == null || salt == null) return const PinResult(ok: true);

    if (verifyPin(pin, salt, hash)) {
      await _resetFails();
      return const PinResult(ok: true);
    }
    final fails = (int.tryParse(await db.getSetting(_kFails) ?? '') ?? 0) + 1;
    await db.setSetting(_kFails, '$fails');
    final lock = pinLockDuration(fails);
    if (lock > Duration.zero) {
      await db.setSetting(_kUntil, DateTime.now().add(lock).toIso8601String());
      return PinResult(locked: lock);
    }
    return PinResult(attemptsLeft: kPinFreeAttempts - fails);
  }

  Future<void> _resetFails() async {
    await db.setSetting(_kFails, '0');
    await db.db.delete('settings', where: 'key = ?', whereArgs: [_kUntil]);
  }

  // ---- Réglages liés ----
  Future<int> autoLockMinutes() async {
    final v = int.tryParse(await db.getSetting(_kAuto) ?? '');
    return (v != null && kAutoLockMinutes.contains(v)) ? v : 1;
  }

  Future<void> setAutoLockMinutes(int m) => db.setSetting(_kAuto, '$m');

  Future<bool> biometricEnabled() async => (await db.getSetting(_kBio)) == '1';
  Future<void> setBiometric(bool v) => db.setSetting(_kBio, v ? '1' : '0');

  Future<bool> secureScreen() async => (await db.getSetting(_kSecure)) == '1';
  Future<void> setSecureScreen(bool v) =>
      db.setSetting(_kSecure, v ? '1' : '0');
}
