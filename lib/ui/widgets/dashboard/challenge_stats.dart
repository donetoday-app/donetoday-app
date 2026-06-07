import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/ui/widgets/stat_card.dart';
import 'package:flutter/material.dart';

Widget ChallengeStats(
  ThemeData theme,
  List<Challenge> challenges,
  Map<String, List<Log>> challengeLogs,
) {
  int activeCount = challenges.length;
  int totalLogs = 0;
  for (var logs in challengeLogs.values) {
    totalLogs += logs.length;
  }

  // Calculate average progress across active challenges
  double avgProgress = 0;
  if (challenges.isNotEmpty) {
    double totalProgressSum = 0;
    for (var c in challenges) {
      final logs = challengeLogs[c.id] ?? [];
      final currentProgress = logs.length / c.totalDays;
      totalProgressSum += currentProgress;
    }
    avgProgress = totalProgressSum / challenges.length;
  }

  return Row(
    children: [
      Expanded(
        child: StatCard(
          title: "ACTIVE",
          value: "$activeCount",
          unit: "goals",
          color: theme.colorScheme.primary,
          icon: Icons.rocket_launch_rounded,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: StatCard(
          title: "LOGS",
          value: "$totalLogs",
          unit: "logs",
          color: theme.colorScheme.secondary,
          icon: Icons.task_alt_rounded,
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: StatCard(
          title: "PROGRESS",
          value: "${(avgProgress * 100).toInt()}",
          unit: "%",
          color: theme.colorScheme.tertiary,
          icon: Icons.pie_chart_rounded,
        ),
      ),
    ],
  );
}
