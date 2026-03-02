import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget de confeti personalizado sin dependencias externas.
/// Muestra partículas de colores festivas cayendo con formas variadas.
class ConfettiOverlay extends StatefulWidget {
  final bool play;
  final Duration duration;
  final VoidCallback? onComplete;

  const ConfettiOverlay({
    super.key,
    required this.play,
    this.duration = const Duration(seconds: 6),
    this.onComplete,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

enum _ParticleShape { rect, circle, strip }

class _Particle {
  final double startX; // 0..1 normalizado
  final double delay; // 0..1 porción del tiempo antes de que aparezca
  final double speed; // velocidad de caída normalizada
  final double wobbleAmp;
  final double wobbleFreq;
  final double wobblePhase;
  final double rotation;
  final double rotSpeed;
  final Color color;
  final double size;
  final _ParticleShape shape;
  final double drift;

  _Particle({
    required this.startX,
    required this.delay,
    required this.speed,
    required this.wobbleAmp,
    required this.wobbleFreq,
    required this.wobblePhase,
    required this.rotation,
    required this.rotSpeed,
    required this.color,
    required this.size,
    required this.shape,
    required this.drift,
  });
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();
  bool _initialized = false;

  static const List<Color> _colors = [
    Color(0xFFFF6B6B), // rojo
    Color(0xFFFFD93D), // amarillo
    Color(0xFF6BCB77), // verde
    Color(0xFF4D96FF), // azul
    Color(0xFFFF6FB7), // rosa
    Color(0xFFAB46D2), // púrpura
    Color(0xFFFF9A3C), // naranja
    Color(0xFF00D2FF), // cyan
    Color(0xFF2ED573), // verde lima
    Color(0xFFFFC312), // dorado
    Color(0xFFED4C67), // magenta
    Color(0xFFF368E0), // fucsia
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _startIfReady();
    }
  }

  void _startIfReady() {
    // Esperar al siguiente frame para tener tamaño del LayoutBuilder
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _initialized) {
        _controller.reset();
        _controller.forward();
      }
    });
  }

  void _generateParticles(Size size) {
    _particles.clear();
    final count = (size.width / 2).clamp(120, 300).toInt();
    final shapes = _ParticleShape.values;

    for (int i = 0; i < count; i++) {
      _particles.add(
        _Particle(
          startX: _rng.nextDouble(),
          delay:
              _rng.nextDouble() *
              0.4, // las partículas aparecen en los primeros 40%
          speed: _rng.nextDouble() * 0.6 + 0.4,
          wobbleAmp: _rng.nextDouble() * 50 + 10,
          wobbleFreq: _rng.nextDouble() * 4 + 2,
          wobblePhase: _rng.nextDouble() * math.pi * 2,
          rotation: _rng.nextDouble() * math.pi * 2,
          rotSpeed: (_rng.nextDouble() - 0.5) * 12,
          color: _colors[_rng.nextInt(_colors.length)],
          size: _rng.nextDouble() * 8 + 5,
          shape: shapes[_rng.nextInt(shapes.length)],
          drift: (_rng.nextDouble() - 0.5) * 80,
        ),
      );
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Generar partículas en el primer build con tamaño real
        if (!_initialized && size.width > 0 && size.height > 0) {
          _generateParticles(size);
          // Si play ya está activo, iniciar
          if (widget.play) {
            _startIfReady();
          }
        }

        // Siempre construir el AnimatedBuilder para que escuche las notificaciones
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = _controller.value;
              if (progress == 0 && !_controller.isAnimating) {
                return const SizedBox.expand();
              }
              return CustomPaint(
                size: size,
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: progress,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    for (final p in particles) {
      // La partícula no aparece hasta que pase su delay
      if (progress < p.delay) continue;

      // Tiempo local de esta partícula (0..1)
      final localT = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);

      // Posición
      final x =
          p.startX * w +
          p.wobbleAmp *
              math.sin(localT * p.wobbleFreq * math.pi * 2 + p.wobblePhase) +
          p.drift * localT;
      // Gravedad acelerada: empieza lento y acelera
      final gravity = localT * localT;
      final y = -20 + (p.speed * localT * 0.5 + gravity * 0.7) * h;

      if (y > h + 40 || x < -60 || x > w + 60) continue;

      final rotation = p.rotation + p.rotSpeed * localT;

      // Opacidad: aparece rápido, se mantiene, desaparece al final
      double opacity;
      if (localT < 0.08) {
        opacity = localT / 0.08;
      } else if (localT > 0.75) {
        opacity = 1.0 - ((localT - 0.75) / 0.25);
      } else {
        opacity = 1.0;
      }
      opacity = opacity.clamp(0.0, 1.0);

      final paint =
          Paint()
            ..color = p.color.withValues(alpha: opacity * 0.9)
            ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Dibujar según forma
      switch (p.shape) {
        case _ParticleShape.rect:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size,
                height: p.size * 1.6,
              ),
              const Radius.circular(1.5),
            ),
            paint,
          );
          break;
        case _ParticleShape.circle:
          canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
          break;
        case _ParticleShape.strip:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size * 0.35,
                height: p.size * 2.2,
              ),
              const Radius.circular(1),
            ),
            paint,
          );
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
