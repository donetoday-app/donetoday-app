import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // Architectural Background Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(
                painter: _ArchitecturalPainter(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),

          SafeArea(
            child: ResponsiveConstraints(
              maxWidth: 800,
              child: Padding(
                padding: AppSpacing.screenPadding.copyWith(
                  top: AppSpacing.huge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    // Brand Icon
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: AppRadius.radiusXl,
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'lib/assets/icon/logo.png',
                            width: 54,
                            height: 54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md - 2,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: AppRadius.radiusMd,
                      ),
                      child: Text(
                        'Start stronger today',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Heading
                    Text(
                      "Not Just Logs,\nDaily Clarity.",
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: 0,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      "Stay consistent with one meaningful action every day.",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        height: 1.7,
                        fontSize: 19,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    // Primary Action
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 64,
                          child: ElevatedButton(
                            onPressed: () => context.go('/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Let’s Get Started",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 1,
                              color: theme.colorScheme.primary.withOpacity(0.2),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Text(
                                "A BETTER SELF — A BETTER DAY",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.5,
                                  ),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ),
                            Container(
                              width: 12,
                              height: 1,
                              color: theme.colorScheme.primary.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ],
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

class _ArchitecturalPainter extends CustomPainter {
  final Color color;
  _ArchitecturalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Abstract shapes
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 200, paint);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.7, 300, 300),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
