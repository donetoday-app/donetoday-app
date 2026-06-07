import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final List<Color>? gradient;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 12,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            color ??
            (theme.brightness == Brightness.dark
                ? Color.alphaBlend(
                    theme.colorScheme.primary.withOpacity(0.015),
                    theme.colorScheme.surfaceContainer,
                  )
                : theme.colorScheme.surfaceContainer), // 100% pure white in light mode for maximum brightness
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
          width: 1.0,
        ),
        boxShadow: theme.brightness == Brightness.dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                  spreadRadius: -1,
                ),
              ],
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: child,
    );
  }
}
