import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Barre de titre integree facon apps modernes (VS Code, Discord...).
/// Remplace la barre native : deplacement par glisser, double-clic pour
/// agrandir, boutons reduire / agrandir / fermer sur Windows et Linux.
/// Sur macOS, les feux tricolores natifs restent (on leur laisse la place).
class TitleBar extends StatefulWidget {
  const TitleBar({super.key});

  @override
  State<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<TitleBar> with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isMaximized().then((v) {
      if (mounted) setState(() => _maximized = v);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMac = Platform.isMacOS;

    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: isMac ? null : _toggleMaximize,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Row(
          children: [
            SizedBox(width: isMac ? 76 : 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset(
                'assets/images/logo.png',
                width: 20,
                height: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text('StockTout',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            Expanded(child: Container()),
            if (!isMac) ...[
              _WinButton(
                icon: Icons.remove,
                tooltip: 'Reduire',
                onTap: windowManager.minimize,
              ),
              _WinButton(
                icon: _maximized ? Icons.filter_none : Icons.crop_square,
                tooltip: _maximized ? 'Restaurer' : 'Agrandir',
                onTap: _toggleMaximize,
              ),
              _WinButton(
                icon: Icons.close,
                tooltip: 'Fermer',
                hoverDanger: true,
                onTap: windowManager.close,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WinButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Future<void> Function() onTap;
  final bool hoverDanger;

  const _WinButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.hoverDanger = false,
  });

  @override
  State<_WinButton> createState() => _WinButtonState();
}

class _WinButtonState extends State<_WinButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip,
          child: Container(
            width: 46,
            height: 40,
            color: !_hover
                ? Colors.transparent
                : widget.hoverDanger
                    ? const Color(0xFFE81123)
                    : scheme.onSurface.withOpacity(0.08),
            child: Icon(
              widget.icon,
              size: 16,
              color: _hover && widget.hoverDanger
                  ? Colors.white
                  : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
