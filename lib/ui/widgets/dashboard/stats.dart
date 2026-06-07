import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/storage/models/log_stats_model.dart';
import 'package:done_today/ui/widgets/custom_card.dart';
import 'package:done_today/ui/widgets/stat_card.dart';
import 'package:flutter/material.dart';

Widget Stats(ThemeData theme, LogStats? s) {
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: StatCard(
              title: "STREAK",
              value: "${s?.streak ?? 0}",
              unit: "days",
              color: theme.colorScheme.primary,
              icon: Icons.local_fire_department_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: StatCard(
              title: "TOTAL",
              value: "${s?.totalLogs ?? 0}",
              unit: "logs",
              color: theme.colorScheme.secondary,
              icon: Icons.auto_graph_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: StatCard(
              title: "BEST",
              value: "${s?.longestStreak ?? 0}",
              unit: "days",
              color: theme.colorScheme.tertiary,
              icon: Icons.emoji_events_rounded,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      _buildMasterInsight(theme, s),
    ],
  );
}

Widget _buildMasterInsight(ThemeData theme, LogStats? s) {
  final totalWords = s?.totalWords ?? 0;

  return CustomCard(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: 14,
    ),
    borderRadius: AppRadius.lg,
    child: Row(
      children: [
        Icon(
          Icons.auto_awesome_rounded,
          size: 20,
          color: theme.colorScheme.primary.withOpacity(0.8),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            "YOU HAVE DEFINED YOUR WORLD WITH ",
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ),
        Text(
          "$totalWords WORDS",
          style: TextStyle(fontFamily: 'JetBrainsMono', 
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}
