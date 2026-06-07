import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedParticles extends StatefulWidget {
  final Duration duration;
  final int particleCount;
  final double maxSize;
  final List<Color> colors;

  const AnimatedParticles({
    super.key,
    required this.duration,
    this.particleCount = 10,
    this.maxSize = 6,
    required this.colors,
  });

  @override
  State<AnimatedParticles> createState() => _AnimatedParticlesState();
}

class _AnimatedParticlesState extends State<AnimatedParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();

    _initializeParticles();
  }

  void _initializeParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        position: Offset(
          Random().nextDouble() * 100,
          Random().nextDouble() * 100,
        ),
        size: Random().nextDouble() * widget.maxSize,
        color: widget.colors[Random().nextInt(widget.colors.length)],
        speed: 0.5 + Random().nextDouble() * 1.5,
        angle: Random().nextDouble() * 2 * pi,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class Particle {
  Offset position;
  double size;
  Color color;
  double speed;
  double angle;

  Particle({
    required this.position,
    required this.size,
    required this.color,
    required this.speed,
    required this.angle,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      // Calculate new position based on progress
      final distance = particle.speed * 30 * progress;
      final newPosition = Offset(
        particle.position.dx + distance * cos(particle.angle),
        particle.position.dy + distance * sin(particle.angle),
      );

      // Draw particle
      paint.color = particle.color.withOpacity(1.0 - progress);
      canvas.drawCircle(newPosition, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
