import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7200),
  )..repeat();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.12, 0.78, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.82, end: 1)
      .animate(
        CurvedAnimation(
          parent: _intro,
          curve: const Interval(0.08, 0.9, curve: Curves.elasticOut),
        ),
      );
  late final Animation<double> _lift = Tween<double>(begin: 12, end: 0).animate(
    CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.08, 0.84, curve: Curves.easeOutCubic),
    ),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2750), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final size = MediaQuery.sizeOf(context);
    final logoSize = math.min(size.width * 0.82, 390.0);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5E9),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _CreamBackdrop(),
          if (!reduceMotion)
            AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) => CustomPaint(
                painter: _NaturePainter(progress: _ambient.value),
              ),
            ),
          Center(
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, child) => Opacity(
                opacity: reduceMotion ? 1 : _fade.value,
                child: Transform.translate(
                  offset: Offset(0, reduceMotion ? 0 : _lift.value),
                  child: Transform.scale(
                    scale: reduceMotion ? 1 : _scale.value,
                    child: child,
                  ),
                ),
              ),
              child: Image.asset(
                'assets/logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                semanticLabel: 'Rabbit Hub',
              ),
            ),
          ),
          if (!reduceMotion)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _intro,
                  builder: (context, child) => Opacity(
                    opacity: (1 - _intro.value).clamp(0, 1),
                    child: child,
                  ),
                  child: CustomPaint(
                    painter: _FallingLeavesPainter(progress: _ambient.value),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CreamBackdrop extends StatelessWidget {
  const _CreamBackdrop();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(0, -0.12),
        radius: 1.12,
        colors: [Color(0xFFFFFDF4), Color(0xFFF3F0DE)],
      ),
    ),
  );
}

class _NaturePainter extends CustomPainter {
  const _NaturePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final sparklePaint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(17);
    for (var index = 0; index < 24; index++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final phase = (progress * 2 * math.pi + index * 0.71);
      final radius = 0.8 + ((math.sin(phase) + 1) * 0.8);
      final alpha = (0.12 + ((math.sin(phase) + 1) * 0.09))
          .clamp(0.0, 0.3)
          .toDouble();
      sparklePaint.color = const Color(0xFF719568).withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, sparklePaint);
    }

    final leafPaint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 5; index++) {
      final phase = progress * 2 * math.pi + index * 1.4;
      final x = size.width * (0.12 + index * 0.19) + math.sin(phase) * 12;
      final y = size.height * (0.27 + (index % 3) * 0.2) + math.cos(phase) * 7;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(math.sin(phase) * 0.14);
      leafPaint.color = const Color(0xFF62865C).withValues(alpha: 0.13);
      _drawLeaf(canvas, leafPaint, 8 + (index % 3) * 2);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _NaturePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FallingLeavesPainter extends CustomPainter {
  const _FallingLeavesPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 8; index++) {
      final seed = index * 0.137;
      final local = (progress + seed) % 1.0;
      final fall = (local * 1.35) % 1.0;
      final xBase = size.width * ((index * 0.173 + 0.07) % 0.9 + 0.05);
      final x = xBase + math.sin(local * math.pi * 2 + index) * 22;
      final y = fall * size.height * 1.1 - size.height * 0.1;
      final rotation = math.sin(local * math.pi * 3 + index) * 1.3;
      final leafSize = 8.0 + (index % 4) * 2.4;
      final alpha = (0.22 + (index % 3) * 0.07).clamp(0.0, 0.44).toDouble();
      paint.color = index.isEven
          ? const Color(0xFF477B4A).withValues(alpha: alpha)
          : const Color(0xFF789A5C).withValues(alpha: alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      _drawLeaf(canvas, paint, leafSize);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FallingLeavesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

void _drawLeaf(Canvas canvas, Paint paint, double size) {
  final path = Path()
    ..moveTo(0, -size)
    ..quadraticBezierTo(size * 1.05, -size * 0.34, 0, size)
    ..quadraticBezierTo(-size * 1.05, -size * 0.34, 0, -size)
    ..close();
  canvas.drawPath(path, paint);
  final veinPaint = Paint()
    ..color = Colors.white.withValues(alpha: paint.color.a * 0.45)
    ..strokeWidth = 0.8
    ..style = PaintingStyle.stroke;
  canvas.drawLine(Offset(0, -size * 0.78), Offset(0, size * 0.78), veinPaint);
}
