import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n/app_localizations.dart';

/// Etat de la visite, sauvegarde sur l'appareil :
/// chaque ecran ne montre ses astuces qu'une seule fois (premier usage).
class TourSession {
  TourSession._();

  static const _key = 'tour_shown';
  static final Set<String> _shown = {};
  static bool enabled = true;

  /// A appeler au demarrage (avant runApp).
  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    enabled = p.getBool('tips_enabled') ?? true;
    _shown
      ..clear()
      ..addAll(p.getStringList(_key) ?? const <String>[]);
  }

  static bool shouldShow(String id) => enabled && !_shown.contains(id);

  static void markShown(String id) {
    _shown.add(id);
    _save();
  }

  /// Utilise par Parametres pour rejouer la visite.
  static void resetAll() {
    _shown.clear();
    _save();
  }

  static Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, _shown.toList());
  }
}

/// Une etape : une cible a l'ecran + un texte.
class TourStep {
  final GlobalKey target;
  final String title;
  final String body;

  const TourStep({
    required this.target,
    required this.title,
    required this.body,
  });
}

/// Enveloppe un ecran et affiche ses astuces a la premiere ouverture.
/// Les etapes dont la cible n'est pas visible sont ignorees.
class GuidedTour extends StatefulWidget {
  final String id;
  final List<TourStep> steps;
  final Widget child;

  const GuidedTour({
    super.key,
    required this.id,
    required this.steps,
    required this.child,
  });

  @override
  State<GuidedTour> createState() => _GuidedTourState();
}

class _GuidedTourState extends State<GuidedTour> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  Future<void> _maybeStart() async {
    if (!mounted || !TourSession.shouldShow(widget.id)) return;
    // Laisse le premier rendu se stabiliser (animations, chargement).
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final visible = widget.steps.where((s) {
      final ctx = s.target.currentContext;
      if (ctx == null) return false;
      final box = ctx.findRenderObject();
      return box is RenderBox && box.hasSize && box.size.shortestSide > 8;
    }).toList();
    if (visible.isEmpty) return;

    TourSession.markShown(widget.id);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, __) => TourOverlay(steps: visible),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Calque sombre, halo sur la cible, fleche et carte de texte.
class TourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  const TourOverlay({super.key, required this.steps});

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay>
    with SingleTickerProviderStateMixin {
  int _i = 0;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _next() {
    if (_i < widget.steps.length - 1) {
      setState(() => _i++);
    } else {
      Navigator.of(context).pop();
    }
  }

  Rect? _rectOf(TourStep step) {
    final ctx = step.target.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final origin =
        box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
    return origin & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final step = widget.steps[_i];
    final rect = _rectOf(step);
    final size = MediaQuery.of(context).size;

    // Carte placee sous la cible si la place le permet, sinon au-dessus.
    const cardW = 340.0;
    const gap = 34.0;
    double cardTop;
    double cardLeft;
    if (rect != null) {
      final below = rect.bottom + gap + 150 < size.height;
      cardTop = below ? rect.bottom + gap : rect.top - gap - 170;
      cardTop = cardTop.clamp(16.0, size.height - 190);
      cardLeft =
          (rect.center.dx - cardW / 2).clamp(16.0, size.width - cardW - 16);
    } else {
      cardTop = size.height / 2 - 90;
      cardLeft = (size.width - cardW) / 2;
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Voile + halo perce sur la cible.
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(
                hole: rect?.inflate(8),
                pulse: _pulse,
                color: scheme.primary,
              ),
            ),
          ),
          if (rect != null)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final dy = 6 * (0.5 - _pulse.value).abs() * 2;
                return Positioned(
                  left: rect.center.dx - 12,
                  top: rect.bottom + 6 + dy,
                  child: Icon(Icons.arrow_drop_down,
                      size: 30, color: scheme.primary),
                );
              },
            ),
          Positioned(
            left: cardLeft,
            top: cardTop,
            width: cardW,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_i),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (_, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - v)),
                  child: child,
                ),
              ),
              child: _TourCard(
                index: _i,
                total: widget.steps.length,
                title: step.title,
                body: step.body,
                onNext: _next,
                onSkip: () => Navigator.of(context).pop(),
                labels: (t.guideSkip, t.guideDone, t.obNext),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final int index;
  final int total;
  final String title;
  final String body;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final (String, String, String) labels;

  const _TourCard({
    required this.index,
    required this.total,
    required this.title,
    required this.body,
    required this.onNext,
    required this.onSkip,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final last = index >= total - 1;

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      color: scheme.surface,
      shadowColor: Colors.black38,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text('${index + 1}/$total',
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(body, style: text.bodyMedium),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: onSkip, child: Text(labels.$1)),
                FilledButton(
                  onPressed: onNext,
                  child: Text(last ? labels.$2 : labels.$3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final Animation<double> pulse;
  final Color color;

  _SpotlightPainter({
    required this.hole,
    required this.pulse,
    required this.color,
  }) : super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final scrim = Paint()..color = Colors.black.withOpacity(0.62);

    if (hole == null) {
      canvas.drawPath(full, scrim);
      return;
    }
    final r = hole!.inflate(8);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
    final cut = Path()..addRRect(rr);
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, cut),
      scrim,
    );
    // Liseré qui respire autour de la cible.
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withOpacity(0.45 + 0.35 * pulse.value);
    canvas.drawRRect(rr, glow);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.color != color;
}
