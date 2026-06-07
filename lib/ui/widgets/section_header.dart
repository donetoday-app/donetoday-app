import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final TextAlign? textAlign;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            textAlign: textAlign,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textAlign == TextAlign.center
                  ? theme.colorScheme.onSurfaceVariant.withOpacity(0.5)
                  : theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
