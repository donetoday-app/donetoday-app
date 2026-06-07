import 'package:flutter/material.dart';

class DoneTodayIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const DoneTodayIcon({super.key, this.size = 30, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = color ?? colorScheme.onSurface;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      child: CustomPaint(
        painter: _DoneTodayIconPainter(
          color: iconColor,
          surfaceColor: colorScheme.surface,
        ),
      ),
    );
  }
}

class _DoneTodayIconPainter extends CustomPainter {
  final Color color;
  final Color surfaceColor;

  _DoneTodayIconPainter({required this.color, required this.surfaceColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint baseCircle = Paint()
      ..color = color.withAlpha(25)
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint shadow = Paint()
      ..color = color.withAlpha(102)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);

    final Paint highlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [surfaceColor.withAlpha(153), surfaceColor.withAlpha(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint checkmark = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw shadow
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width * 0.375;

    canvas.drawCircle(center, radius, shadow);

    // Draw base circle
    canvas.drawCircle(center, radius, baseCircle);

    // Draw highlight
    canvas.drawCircle(center, radius, highlight);

    // Draw checkmark
    final Path checkPath = Path()
      ..moveTo(size.width * 0.333, size.height * 0.5)
      ..lineTo(size.width * 0.458, size.height * 0.625)
      ..lineTo(size.width * 0.75, size.height * 0.375);

    canvas.drawPath(checkPath, checkmark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
