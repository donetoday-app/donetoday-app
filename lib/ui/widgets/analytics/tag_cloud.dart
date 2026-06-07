import 'package:done_today/storage/models/activity_analytics.dart';
import 'package:flutter/material.dart';

class TagCloudWidget extends StatelessWidget {
  final List<TagCount> tags;

  const TagCloudWidget({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (tags.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            "No tags found. Start tagging your logs!",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // Find min and max count to scale the tags organically
    int maxCount = 1;
    int minCount = 1;
    if (tags.isNotEmpty) {
      maxCount = tags.map((t) => t.count).reduce((a, b) => a > b ? a : b);
      minCount = tags.map((t) => t.count).reduce((a, b) => a < b ? a : b);
    }
    final range = (maxCount - minCount).clamp(1, 999999);

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: tags.map((tagCount) {
        // Calculate a weight between 0.0 and 1.0
        final weight = (tagCount.count - minCount) / range;

        // Scale font sizes from 11 to 16 based on usage weight
        final double fontSize = 11.0 + (weight * 5.0);

        // Scale opacity of color
        final double bgOpacity = 0.05 + (weight * 0.15);
        final double borderOpacity = 0.1 + (weight * 0.3);

        // Pick colors from a rotating palette
        final Color baseColor = _getTagColor(tagCount.tag, theme);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: baseColor.withOpacity(bgOpacity),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: baseColor.withOpacity(borderOpacity),
              width: 1,
            ),
            boxShadow: [
              if (weight > 0.8)
                BoxShadow(
                  color: baseColor.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "#${tagCount.tag}",
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: fontSize,
                  fontWeight: weight > 0.6 ? FontWeight.w800 : FontWeight.w600,
                  color: baseColor.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "${tagCount.count}",
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: fontSize - 2,
                    fontWeight: FontWeight.w900,
                    color: baseColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getTagColor(String tag, ThemeData theme) {
    final hashCode = tag.hashCode.abs();
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.blue,
      Colors.indigo,
    ];
    return colors[hashCode % colors.length];
  }
}
