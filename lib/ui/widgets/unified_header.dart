import 'package:done_today/theme/ui_constants.dart';
import 'package:flutter/material.dart';

class UnifiedHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const UnifiedHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
            width: 1.0,
          ),
        ),
      ),
      child: NavigationToolbar(
        leading: onBack != null
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: onBack,
              )
            : null,
        centerMiddle: false,
        middle: Padding(
          padding: EdgeInsets.only(
            left: onBack == null ? AppSpacing.screenHorizontal - AppSpacing.sm : 0,
          ),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        trailing: actions != null
            ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
            : const SizedBox(width: AppSpacing.xxl),
      ),
    );
  }
}
