import 'package:done_today/storage/models/activity_analytics.dart';
import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/analytics/analytics_charts.dart';
import 'package:done_today/ui/widgets/custom_card.dart';
import 'package:done_today/ui/widgets/stat_card.dart';
import 'package:flutter/material.dart';

class ChallengesTab extends StatelessWidget {
  final ActivityAnalytics analytics;
  final List<Challenge> challenges;
  final Map<String, List<Log>> challengeLogs;

  const ChallengesTab({
    super.key,
    required this.analytics,
    required this.challenges,
    required this.challengeLogs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isDesktop = screenWidth >= 950;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Challenges Stats Grid
          _buildSubHeader(context, "CHALLENGE PERFORMANCE"),
          const SizedBox(height: AppSpacing.sm),
          _buildChallengeStatsGrid(theme, isDesktop),
          const SizedBox(height: AppSpacing.lg),

          // 2. Active Challenges List & Category Distribution
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubHeader(
                            context,
                            "ACTIVE CHALLENGES & STREAKS",
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildActiveChallengesList(context),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubHeader(context, "CHALLENGE CATEGORIES"),
                          const SizedBox(height: AppSpacing.sm),
                          CustomCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: AnalyticsCharts.challengeCategoryBreakdown(
                              analytics,
                              theme,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSubHeader(context, "ACTIVE CHALLENGES & STREAKS"),
                    const SizedBox(height: AppSpacing.sm),
                    _buildActiveChallengesList(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSubHeader(context, "CHALLENGE CATEGORIES"),
                    const SizedBox(height: AppSpacing.sm),
                    CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: AnalyticsCharts.challengeCategoryBreakdown(
                        analytics,
                        theme,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSubHeader(
    BuildContext context,
    String title) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        )
      ],
    );
  }

  Widget _buildChallengeStatsGrid(ThemeData theme, bool isDesktop) {
    final int crossAxisCount = isDesktop ? 4 : 2;
    final double childAspectRatio = isDesktop ? 1.8 : 2.2;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: childAspectRatio,
      children: [
        StatCard(
          title: "Active Challenges",
          value: "${analytics.totalActiveChallenges}",
          unit: "challenges",
          icon: Icons.emoji_events_rounded,
          color: theme.colorScheme.primary,
        ),
        StatCard(
          title: "Check-ins Done",
          value: "${analytics.totalLogs}",
          unit: "logs",
          icon: Icons.assignment_turned_in_rounded,
          color: theme.colorScheme.secondary,
        ),
        StatCard(
          title: "Avg Progress",
          value: "${(analytics.avgChallengeProgress * 100).toInt()}",
          unit: "%",
          icon: Icons.trending_up_rounded,
          color: theme.colorScheme.tertiary,
        ),
        StatCard(
          title: "Check-in Rate",
          value: "${(analytics.challengeParticipationRate * 100).toInt()}",
          unit: "%",
          icon: Icons.verified_rounded,
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildActiveChallengesList(BuildContext context) {
    final theme = Theme.of(context);
    final activeChallenges = challenges.where((c) => !c.isDeleted).toList();

    if (activeChallenges.isEmpty) {
      return const CustomCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "No active challenges right now.\nGo start a new challenge and define your journey!",
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5),
            ),
          ),
        ),
      );
    }

    return Column(
      children: activeChallenges.map((challenge) {
        final logs = challengeLogs[challenge.id] ?? [];
        final completed = logs.length;
        final total = challenge.totalDays;
        final progress = (completed / total).clamp(0.0, 1.0);
        final progressPercent = (progress * 100).toInt();

        // Calculate days remaining
        final today = DateTime.now();
        final remainingDays = challenge.endDate.difference(today).inDays;
        final cleanRemaining = remainingDays < 0 ? 0 : remainingDays;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: CustomCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'Outfit',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        challenge.category.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "$completed / $total check-ins done",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      "$progressPercent%",
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Ends in $cleanRemaining days",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    if (progress >= 1.0)
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "COMPLETED",
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
