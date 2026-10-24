import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/v5_strings.dart';
import '../../core/logic/pin_logic.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/expiry_service.dart';
import '../../core/services/pin_service.dart';
import '../../core/services/secure_screen.dart';
import '../../widgets/lock_gate.dart';

String _dt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _size(int bytes) => bytes > 1048576
    ? '${(bytes / 1048576).toStringAsFixed(1)} Mo'
    : '${(bytes / 1024).toStringAsFixed(0)} Ko';

// ============================================================ SAUVEGARDE

class BackupCard extends ConsumerStatefulWidget {
  const BackupCard({super.key});

  @override
  ConsumerState<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<BackupCard> {
  final _svc = BackupService();
  List<BackupInfo> _list = [];
  bool _auto = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _svc.list();
    final auto = await _svc.autoEnabled();
    if (mounted) {
      setState(() {
        _list = list;
        _auto = auto;
      });
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _backupNow() async {
    final t = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await _svc.createBackup();
      await _load();
      if (mounted) _snack(t.backupDoneMsg);
    } catch (_) {
      if (mounted) _snack(t.backupFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(BackupInfo b) async {
    await LockGuard.external(() => Share.shareXFiles(
        [XFile(b.file.path, mimeType: 'application/zip')],
        subject: 'StockTout backup'));
  }

  Future<void> _pickAndRestore() async {
    final res = await LockGuard.external(
        () => FilePicker.platform.pickFiles(type: FileType.any));
    final path = res?.files.single.path;
    if (path != null) await _restore(path);
  }

  Future<void> _restore(String path) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: Text(t.restoreConfirmTitle),
        content: Text(t.restoreConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.restoreBtn)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _svc.restoreFrom(path);
      if (!mounted) return;
      reloadAllData(ref);
      await _load();
      if (mounted) _snack(t.restoreDone);
    } on FormatException {
      if (mounted) _snack(t.restoreInvalid);
    } catch (_) {
      if (mounted) _snack(t.restoreFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.backup, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(_list.isEmpty
                ? t.noBackupYet
                : t.lastBackup(_dt(_list.first.date))),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.autoBackup),
              subtitle: Text(t.autoBackupHint),
              value: _auto,
              onChanged: (v) async {
                setState(() => _auto = v);
                await _svc.setAutoEnabled(v);
              },
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.save_alt),
                  label: Text(t.backupNow),
                  onPressed: _busy ? null : _backupNow,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.restore),
                  label: Text(t.restoreFromFile),
                  onPressed: _busy ? null : _pickAndRestore,
                ),
              ],
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            if (_list.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(t.savedBackups, style: text.titleSmall),
              for (final b in _list)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_zip_outlined),
                  title: Text(_dt(b.date)),
                  subtitle: Text(_size(b.size)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: t.shareBackup,
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () => _share(b),
                      ),
                      IconButton(
                        tooltip: t.restoreBtn,
                        icon: const Icon(Icons.restore),
                        onPressed: _busy ? null : () => _restore(b.file.path),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================ SÉCURITÉ

class SecurityCard extends ConsumerStatefulWidget {
  const SecurityCard({super.key});

  @override
  ConsumerState<SecurityCard> createState() => _SecurityCardState();
}

class _SecurityCardState extends ConsumerState<SecurityCard> {
  final _pin = PinService();
  bool _enabled = false;
  int _auto = 1;
  bool _bio = false;
  bool _secure = false;
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final en = await _pin.isEnabled();
    final auto = await _pin.autoLockMinutes();
    final bio = await _pin.biometricEnabled();
    final sec = await _pin.secureScreen();
    var avail = false;
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        avail = await LocalAuthentication().canCheckBiometrics;
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _enabled = en;
        _auto = auto;
        _bio = bio;
        _secure = sec;
        _bioAvailable = avail;
      });
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Demande le PIN actuel. Retourne true s'il est correct.
  Future<bool> _verifyCurrent() async {
    final t = AppLocalizations.of(context);
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => _PinInputDialog(title: t.pinEnterCurrent),
    );
    if (pin == null || !mounted) return false;
    final r = await _pin.verify(pin);
    if (r.ok) return true;
    if (mounted) {
      _snack(r.locked > Duration.zero
          ? t.pinLockedFor('${r.locked.inSeconds} s')
          : t.pinWrong(r.attemptsLeft));
    }
    return false;
  }

  Future<String?> _askNewPin() => showDialog<String>(
        context: context,
        builder: (_) => _PinInputDialog(
            title: AppLocalizations.of(context).pinChooseNew, confirm: true),
      );

  Future<void> _enable() async {
    final t = AppLocalizations.of(context);
    final pin = await _askNewPin();
    if (pin == null || !mounted) return;
    await _pin.setPin(pin);
    await ref.read(lockProvider.notifier).reload();
    await _load();
    if (mounted) _snack(t.pinEnabledMsg);
  }

  Future<void> _change() async {
    final t = AppLocalizations.of(context);
    if (!await _verifyCurrent()) return;
    final pin = await _askNewPin();
    if (pin == null || !mounted) return;
    await _pin.setPin(pin);
    if (mounted) _snack(t.pinChangedMsg);
  }

  Future<void> _disable() async {
    final t = AppLocalizations.of(context);
    if (!await _verifyCurrent()) return;
    await _pin.disable();
    await ref.read(lockProvider.notifier).reload();
    await _load();
    if (mounted) _snack(t.pinDisabledMsg);
  }

  Future<void> _toggleBio(bool v) async {
    final t = AppLocalizations.of(context);
    if (v) {
      try {
        final ok = await LockGuard.external(() => LocalAuthentication()
            .authenticate(
                localizedReason: t.pinUnlockReason,
                options: const AuthenticationOptions(
                    biometricOnly: true, stickyAuth: true)));
        if (!ok) return;
      } catch (_) {
        return;
      }
    }
    await _pin.setBiometric(v);
    if (mounted) setState(() => _bio = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.security, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(t.securityHint),
            const SizedBox(height: 8),
            if (!_enabled)
              FilledButton.tonalIcon(
                icon: const Icon(Icons.lock_outline),
                label: Text(t.enablePin),
                onPressed: _enable,
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.password),
                    label: Text(t.changePin),
                    onPressed: _change,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.lock_open),
                    label: Text(t.disablePin),
                    onPressed: _disable,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _auto,
                decoration: InputDecoration(labelText: t.autoLock),
                items: [
                  for (final m in kAutoLockMinutes)
                    DropdownMenuItem(
                        value: m,
                        child: Text(
                            m == 0 ? t.lockImmediately : t.afterMinutes(m))),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _auto = v);
                  await _pin.setAutoLockMinutes(v);
                },
              ),
              if (_bioAvailable)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.useFingerprint),
                  value: _bio,
                  onChanged: _toggleBio,
                ),
              if (Platform.isAndroid)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.hideInRecents),
                  subtitle: Text(t.hideInRecentsHint),
                  value: _secure,
                  onChanged: (v) async {
                    setState(() => _secure = v);
                    await _pin.setSecureScreen(v);
                    await SecureScreen.set(v);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Saisie d'un PIN (4 à 6 chiffres). Avec [confirm] : double saisie.
class _PinInputDialog extends StatefulWidget {
  final String title;
  final bool confirm;
  const _PinInputDialog({required this.title, this.confirm = false});

  @override
  State<_PinInputDialog> createState() => _PinInputDialogState();
}

class _PinInputDialogState extends State<_PinInputDialog> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _ok() {
    final t = AppLocalizations.of(context);
    if (!isValidPinFormat(_a.text)) {
      setState(() => _error = t.pinFormat);
      return;
    }
    if (widget.confirm && _a.text != _b.text) {
      setState(() => _error = t.pinMismatch);
      return;
    }
    Navigator.pop(context, _a.text);
  }

  InputDecoration _deco(String label, {String? error}) =>
      InputDecoration(labelText: label, errorText: error, counterText: '');

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _a,
            autofocus: true,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration:
                _deco(t.pinLabel, error: widget.confirm ? null : _error),
          ),
          if (widget.confirm)
            TextField(
              controller: _b,
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _deco(t.pinConfirm, error: _error),
              onSubmitted: (_) => _ok(),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(onPressed: _ok, child: Text(t.confirm)),
      ],
    );
  }
}

// ============================================================ PÉREMPTION

class ExpiryCard extends ConsumerWidget {
  const ExpiryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.expirySettings, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(t.expiryDelayHint),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in const [7, 15, 30, 60, 90])
                  ChoiceChip(
                    label: Text(t.daysShort(d)),
                    selected: settings.expiryDays == d,
                    onSelected: (_) async {
                      await ref
                          .read(settingsProvider.notifier)
                          .setExpiryDays(d);
                      if (settings.expiryNotify) {
                        await refreshExpiryNotification(ref);
                      }
                    },
                  ),
              ],
            ),
            if (ExpiryNotifier.supported)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.expiryNotifOption),
                subtitle: Text(t.expiryNotifHint),
                value: settings.expiryNotify,
                onChanged: (v) async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (v) {
                    final ok = await LockGuard.external(
                        ExpiryNotifier.requestPermission);
                    if (!ok) {
                      messenger
                          .showSnackBar(SnackBar(content: Text(t.notifDenied)));
                      return;
                    }
                  }
                  await ref.read(settingsProvider.notifier).setExpiryNotify(v);
                  if (v) {
                    await refreshExpiryNotification(ref);
                  } else {
                    await ExpiryNotifier.cancel();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
