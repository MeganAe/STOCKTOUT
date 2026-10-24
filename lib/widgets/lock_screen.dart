import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../core/database/database.dart';
import '../core/l10n/app_localizations.dart';
import '../core/l10n/v5_strings.dart';
import '../core/providers/app_providers.dart';
import '../core/services/pin_service.dart';
import 'lock_gate.dart';

/// Écran de verrouillage : pavé numérique large (usage au pouce),
/// points de saisie, retour haptique, blocage progressif.
class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pin = PinService();
  String _entry = '';
  int _length = 4;
  String? _error;
  Duration _locked = Duration.zero;
  bool _bio = false;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final len = await _pin.length();
    final bio =
        await _pin.biometricEnabled() && (Platform.isAndroid || Platform.isIOS);
    final remaining = await _pin.lockRemaining();
    if (!mounted) return;
    setState(() {
      _length = len;
      _bio = bio;
    });
    _startCountdown(remaining);
    if (bio && remaining == Duration.zero) _tryBiometric();
  }

  void _startCountdown(Duration d) {
    _timer?.cancel();
    setState(() => _locked = d);
    if (d <= Duration.zero) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = _locked - const Duration(seconds: 1);
      if (left <= Duration.zero) {
        t.cancel();
        if (mounted) setState(() => _locked = Duration.zero);
      } else if (mounted) {
        setState(() => _locked = left);
      }
    });
  }

  Future<void> _tryBiometric() async {
    final t = AppLocalizations.of(context);
    try {
      final auth = LocalAuthentication();
      if (!await auth.canCheckBiometrics) return;
      final ok = await LockGuard.external(() => auth.authenticate(
            localizedReason: t.pinUnlockReason,
            options: const AuthenticationOptions(
                biometricOnly: true, stickyAuth: true),
          ));
      if (ok && mounted) widget.onUnlocked();
    } catch (_) {
      // Indisponible ou annulé : le PIN reste la référence.
    }
  }

  Future<void> _press(String d) async {
    if (_busy || _locked > Duration.zero || _entry.length >= _length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entry += d;
      _error = null;
    });
    if (_entry.length == _length) await _submit();
  }

  void _back() {
    if (_entry.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    _busy = true;
    final res = await _pin.verify(_entry);
    _busy = false;
    if (!mounted) return;
    if (res.ok) {
      HapticFeedback.lightImpact();
      widget.onUnlocked();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _entry = '';
      _error = res.locked > Duration.zero ? null : t.pinWrong(res.attemptsLeft);
    });
    if (res.locked > Duration.zero) _startCountdown(res.locked);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return m > 0 ? '$m min ${s.toString().padLeft(2, '0')} s' : '$s s';
  }

  Future<void> _forgot() async {
    final t = AppLocalizations.of(context);
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: Text(t.pinForgotTitle),
        content: Text(t.pinForgotBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.pinResetContinue)),
        ],
      ),
    );
    if (first != true || !mounted) return;
    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever, color: Colors.red),
        title: Text(t.pinResetFinalTitle),
        content: Text(t.pinResetFinalBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.pinResetDo),
          ),
        ],
      ),
    );
    if (second != true) return;
    await AppDatabase.instance.resetAll();
    if (!mounted) return;
    reloadAllData(ref);
    widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final blocked = _locked > Duration.zero;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 40, color: scheme.primary),
                    const SizedBox(height: 12),
                    Text(t.pinEnter,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _length; i++)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < _entry.length
                                  ? scheme.primary
                                  : Colors.transparent,
                              border:
                                  Border.all(color: scheme.primary, width: 2),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(
                      height: 44,
                      child: Center(
                        child: blocked
                            ? Text(t.pinLockedFor(_fmt(_locked)),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: scheme.error))
                            : Text(_error ?? '',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: scheme.error)),
                      ),
                    ),
                    for (final row in const [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                    ])
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [for (final d in row) _key(d)],
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _bio
                            ? _iconKey(Icons.fingerprint, _tryBiometric)
                            : const SizedBox(width: 76, height: 76),
                        _key('0'),
                        _iconKey(Icons.backspace_outlined, _back),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _forgot,
                      child: Text(t.pinForgot),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _key(String d) => Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          width: 64,
          height: 64,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            onPressed: () => _press(d),
            child: Text(d, style: const TextStyle(fontSize: 26)),
          ),
        ),
      );

  Widget _iconKey(IconData icon, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          width: 64,
          height: 64,
          child: IconButton(
            iconSize: 28,
            onPressed: onTap,
            icon: Icon(icon),
          ),
        ),
      );
}
