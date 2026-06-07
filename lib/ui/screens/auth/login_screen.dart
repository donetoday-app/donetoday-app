import 'package:done_today/theme/app_theme.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:done_today/providers/auth/auth_notifier.dart';
import 'package:done_today/state/auth/auth_state.dart';
import 'package:done_today/utils/responsive_helper.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customColors = AppTheme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // Architectural Background Pattern (Full Screen Canvas)
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: AppSpacing.screenPadding.copyWith(
                  top: AppSpacing.huge,
                  bottom: AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.huge),
                    // Brand Icon (Hero)
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
                            width: 44,
                            height: 44,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Modern Branding & Vibe
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
                        'Welcome Back!',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      "Secure Access,\nDaily Intent.",
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: 0,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      "Set up your local account and keep track of your daily habits. Your sanctuary is waiting.",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        height: 1.7,
                        fontSize: 19,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.huge),

                    // Auth Error Message
                    if (authState is AuthError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: customColors.error.withOpacity(0.08),
                            borderRadius: AppRadius.radiusMd,
                            border: Border.all(
                              color: customColors.error.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            authState.message,
                            style: TextStyle(
                              color: customColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                    // Actions (Full Width / Spanning)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AuthButton(
                          onPressed: authState is AuthLoading
                              ? null
                              : () => authNotifier.initializeAccount(),
                          icon: Icons.person_add_outlined,
                          label: "Set Up Local Account",
                          backgroundColor: theme.colorScheme.surface,
                          textColor: theme.colorScheme.onSurface,
                          isLocal: true,
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

class _AuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool isLocal;

  const _AuthButton({
    required this.onPressed,
    this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isLocal
                ? BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                  )
                : BorderSide.none,
          ),
        ),
        child:  Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
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

    // Abstract shapes to match GetStarted vibe
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 150, paint);
    canvas.drawRect(Rect.fromLTWH(-50, size.height * 0.8, 200, 200), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
