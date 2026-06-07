import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.96, end: 1.02),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 0.96),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF4F5F7),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Breathing App Icon with Premium Glow
            AnimatedBuilder(
              animation: _scale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'lib/assets/icon/logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Premium Spaced Typography matching web splash using local fonts
            Text(
              'DONE TODAY',
              style: TextStyle(
                fontFamily: 'Outfit',
                color: theme.colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'LOADING LOGS...',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                color: primaryColor.withOpacity(0.7),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 28),

            // Pulsing thin brand linear progress indicator
            SizedBox(
              width: 220,
              height: 3.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1.5),
                child: LinearProgressIndicator(
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.04),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
