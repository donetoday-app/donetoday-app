import 'package:done_today/theme/ui_constants.dart';
import 'package:flutter/material.dart';

class AnalyticsHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const AnalyticsHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title and count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: theme.colorScheme.onSurface,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Premium Segmented Time Filter
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHigh.withOpacity(0.5)
                      : theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSegmentButton(context, "7D", "7 Days"),
                    _buildSegmentButton(context, "30D", "30 Days"),
                    _buildSegmentButton(context, "ALL", "All Time"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(
    BuildContext context,
    String value,
    String tooltip,
  ) {
    final theme = Theme.of(context);
    final isSelected = selectedFilter == value;
    final activeColor = theme.colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => onFilterChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(
                    isThemeDark(theme) ? 0.15 : 0.1,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? activeColor.withOpacity(0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  bool isThemeDark(ThemeData theme) => theme.brightness == Brightness.dark;
}
