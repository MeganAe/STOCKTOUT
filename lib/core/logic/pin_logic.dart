import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// 4 à 6 chiffres exactement.
bool isValidPinFormat(String pin) => RegExp(r'^\d{4,6}$').hasMatch(pin);

/// Sel aléatoire (16 octets, hexadécimal).
String generateSalt([Random? random]) {
  final r = random ?? Random.secure();
  return List.generate(
      16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

/// Hash SHA-256 du PIN salé. Le PIN n'est jamais stocké en clair.
String hashPin(String pin, String salt) =>
    sha256.convert(utf8.encode('$salt:$pin')).toString();

/// Vérifie un PIN (comparaison à temps constant).
bool verifyPin(String pin, String salt, String expectedHash) {
  final h = hashPin(pin, salt);
  if (h.length != expectedHash.length) return false;
  var diff = 0;
  for (var i = 0; i < h.length; i++) {
    diff |= h.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
  }
  return diff == 0;
}

/// Nombre d'erreurs avant le premier blocage.
const int kPinFreeAttempts = 5;

/// Durée de blocage après [failures] erreurs consécutives :
/// < 5 : aucun ; 5 : 30 s ; 6 : 1 min ; 7 : 5 min ; 8 : 15 min ; 9+ : 1 h.
Duration pinLockDuration(int failures) {
  if (failures < kPinFreeAttempts) return Duration.zero;
  const steps = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
  ];
  final i = failures - kPinFreeAttempts;
  return steps[i >= steps.length ? steps.length - 1 : i];
}

/// Temps de blocage restant (zéro si débloqué).
Duration pinLockRemaining(DateTime? lockedUntil, DateTime now) {
  if (lockedUntil == null) return Duration.zero;
  final d = lockedUntil.difference(now);
  return d.isNegative ? Duration.zero : d;
}

/// Délais de verrouillage automatique proposés (minutes ; 0 = immédiat).
const List<int> kAutoLockMinutes = [0, 1, 5, 15];

/// Faut-il verrouiller au retour au premier plan ?
bool shouldAutoLock(
    DateTime? backgroundedAt, DateTime now, int timeoutMinutes) {
  if (backgroundedAt == null) return false;
  return now.difference(backgroundedAt) >= Duration(minutes: timeoutMinutes);
}
