import 'package:flutter/material.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// ---------------- STYLE ----------------

class _SnackBarStyle {
  final Color background;
  final Color foreground;
  final Color accent;

  _SnackBarStyle({
    required this.background,
    required this.foreground,
    required this.accent,
  });

  factory _SnackBarStyle.fromTheme(ThemeData theme, {bool isError = false}) {
    final scheme = theme.colorScheme;

    return _SnackBarStyle(
      background: isError
          ? scheme.errorContainer
          : scheme.surfaceContainerHighest,
      foreground: isError ? scheme.onErrorContainer : scheme.onSurface,
      accent: isError ? scheme.error : scheme.primary,
    );
  }
}

/// ---------------- API ----------------

void showGlobalSnackBar(
  String message, {
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
  bool isError = false,
  bool showTimer = false,
}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  final context = rootScaffoldMessengerKey.currentContext;

  if (messenger == null || context == null) return;

  final theme = Theme.of(context);
  final style = _SnackBarStyle.fromTheme(theme, isError: isError);

  messenger.clearSnackBars();

  final adjustedDuration = duration - const Duration(milliseconds: 300);

  messenger.showSnackBar(
    SnackBar(
      duration: adjustedDuration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: style.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      content: Row(
        children: [
          /// MESSAGE
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: style.foreground,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          /// TIMER
          if (showTimer)
            _CircularTimer(duration: adjustedDuration, style: style),

          /// BUTTON
          if (actionLabel != null && onAction != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: onAction,
                child: Container(
                  decoration: BoxDecoration(
                    color: style.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      color: style.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// ---------------- TIMER ----------------

class _CircularTimer extends StatefulWidget {
  final Duration duration;
  final _SnackBarStyle style;

  const _CircularTimer({required this.duration, required this.style});

  @override
  State<_CircularTimer> createState() => _CircularTimerState();
}

class _CircularTimerState extends State<_CircularTimer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fallController;
  int secondsRemaining = 0;

  @override
  void initState() {
    super.initState();

    secondsRemaining = widget.duration.inSeconds;

    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() {
        final newSeconds = (widget.duration.inSeconds * (1 - _controller.value))
            .ceil();

        if (newSeconds != secondsRemaining && mounted) {
          setState(() => secondsRemaining = newSeconds);
          // Restart fall animation for new number
          _fallController.forward(from: 0);
        }
      })
      ..forward();

    _fallController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _fallController.dispose();
    super.dispose();
  }

  int get safeSeconds => secondsRemaining < 0 ? 0 : secondsRemaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// BACK RING
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.style.foreground.withOpacity(0.2),
                width: 2,
              ),
            ),
          ),

          /// PROGRESS
          CustomPaint(
            size: const Size.square(28),
            painter: _CircleProgressPainter(
              progress: _controller.value,
              color: widget.style.accent,
            ),
          ),

          /// TEXT WITH FALLING ANIMATION
          AnimatedBuilder(
            animation: _fallController,
            builder: (context, child) {
              // Falling animation: moves down as progress increases
              final offset = Tween<double>(begin: -6, end: 0).evaluate(
                CurvedAnimation(parent: _fallController, curve: Curves.easeOut),
              );

              // Opacity animation: fades in as it falls
              final opacity = Tween<double>(begin: 0.5, end: 1.0).evaluate(
                CurvedAnimation(parent: _fallController, curve: Curves.easeOut),
              );

              return Transform.translate(
                offset: Offset(0, offset),
                child: Opacity(
                  opacity: opacity,
                  child: Text(
                    '$safeSeconds',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: widget.style.foreground,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ---------------- PAINTER ----------------

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircleProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.1415926535 / 2;
    final sweepAngle = 2 * 3.1415926535 * progress;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
