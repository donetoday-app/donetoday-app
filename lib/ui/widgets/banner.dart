import 'package:flutter/material.dart';

class BannerMessage extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;

  const BannerMessage({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border:
            border ??
            Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: child,
    );
  }
}
