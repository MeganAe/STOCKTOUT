import 'dart:io';

import 'package:app_settings/app_settings.dart' as sys;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/v5_strings.dart';
import '../../core/logic/product_lookup.dart';
import '../../core/models/product.dart';

/// Scanner de codes-barres (caméra).
///
/// Deux usages :
/// - [onCode] : renvoie le code brut et se ferme (formulaire produit) ;
/// - [products] + [onProduct] : recherche exacte par code-barres/référence,
///   mode continu (rafale) pour la caisse : la caméra reste ouverte.
class ScannerPage extends StatefulWidget {
  final bool continuous;
  final List<Product> products;
  final Future<bool> Function(Product product)? onProduct;
  final void Function(String code)? onCode;

  /// Code inconnu : propose de créer le produit.
  final Future<void> Function(String code)? onUnknown;

  const ScannerPage({
    super.key,
    this.continuous = false,
    this.products = const [],
    this.onProduct,
    this.onCode,
    this.onUnknown,
  });

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late final MobileScannerController _controller;
  String? _lastCode;
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _busy = false;
  bool _torch = false;
  int _count = 0;
  String? _message;
  bool _messageOk = true;
  String? _unknownCode;

  bool get _supported =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.qrCode,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _feedback() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    String? code;
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.trim().isNotEmpty) {
        code = v.trim();
        break;
      }
    }
    if (code == null) return;
    // Anti-rebond : même code ignoré pendant 2 s.
    final now = DateTime.now();
    if (code == _lastCode && now.difference(_lastAt).inMilliseconds < 2000) {
      return;
    }
    _lastCode = code;
    _lastAt = now;
    _busy = true;
    try {
      final t = AppLocalizations.of(context);
      if (widget.onCode != null) {
        _feedback();
        widget.onCode!(code);
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final p = findProductByCode(widget.products, code);
      if (p == null) {
        HapticFeedback.heavyImpact();
        if (mounted) {
          setState(() {
            _message = t.unknownCode(code!);
            _messageOk = false;
            _unknownCode = code;
          });
        }
        return;
      }
      _feedback();
      final handled = await widget.onProduct?.call(p) ?? true;
      if (!mounted) return;
      if (handled) _count++;
      setState(() {
        _message = '${p.name}  ✓';
        _messageOk = true;
        _unknownCode = null;
      });
      if (!widget.continuous) Navigator.of(context).pop();
    } finally {
      _busy = false;
    }
  }

  Widget _errorView(BuildContext context, MobileScannerException error) {
    final t = AppLocalizations.of(context);
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(denied ? Icons.no_photography : Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(denied ? t.cameraDenied : t.cameraError,
                textAlign: TextAlign.center),
            if (denied) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.settings),
                label: Text(t.openSettings),
                onPressed: () => sys.AppSettings.openAppSettings(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.scanBarcode),
        actions: [
          if (_supported)
            IconButton(
              tooltip: t.torch,
              icon: Icon(_torch ? Icons.flash_on : Icons.flash_off),
              onPressed: () async {
                await _controller.toggleTorch();
                if (mounted) setState(() => _torch = !_torch);
              },
            ),
          if (_supported)
            IconButton(
              tooltip: t.switchCamera,
              icon: const Icon(Icons.cameraswitch_outlined),
              onPressed: () => _controller.switchCamera(),
            ),
          if (widget.continuous)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.scanDone(_count)),
            ),
        ],
      ),
      body: !_supported
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(t.scanUnsupported, textAlign: TextAlign.center),
              ),
            )
          : Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error, child) =>
                      _errorView(context, error),
                ),
                // Cadre de visée.
                Center(
                  child: Container(
                    width: 260,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                if (_message != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: Material(
                      color: _messageOk ? Colors.green : Colors.red.shade700,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(_message!,
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            if (!_messageOk &&
                                _unknownCode != null &&
                                widget.onUnknown != null)
                              TextButton(
                                onPressed: () async {
                                  final c = _unknownCode!;
                                  await widget.onUnknown!(c);
                                },
                                child: Text(t.createProduct,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
