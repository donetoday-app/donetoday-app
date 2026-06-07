import 'package:done_today/storage/models/activity_analytics.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/analytics/analytics_charts.dart';
import 'package:done_today/ui/widgets/custom_card.dart';
import 'package:done_today/ui/widgets/dashboard/activity.dart';
import 'package:done_today/ui/widgets/stat_card.dart';
import 'package:flutter/material.dart';

class OverviewTab extends StatelessWidget {
  final ActivityAnalytics analytics;
  final List<Log> logs;

  const OverviewTab({
    super.key,
    required this.analytics,
    required this.logs,
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
          // 1. High-Level Core Stats
          _buildSubHeader(context, "CORE METRICS"),
          const SizedBox(height: AppSpacing.sm),
          _buildCoreStatsGrid(context, isDesktop),
          const SizedBox(height: AppSpacing.lg),

          // 2. Heatmap / Logging Calendar
          Activity(theme, logs),
          const SizedBox(height: AppSpacing.lg),

          // 3. Trends Charts (Monthly / Weekday)
          _buildSubHeader(context, "TREND DYNAMICS"),
          const SizedBox(height: AppSpacing.sm),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildChartContainer(
                        theme,
                        "LOGS OVER TIME",
                        AnalyticsCharts.monthlyTrendLine(analytics, theme),
                        height: 200,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildChartContainer(
                        theme,
                        "WEEKLY DISTRIBUTION",
                        AnalyticsCharts.logsByWeekday(analytics, theme),
                        height: 200,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildChartContainer(
                      theme,
                      "LOGS OVER TIME",
                      AnalyticsCharts.monthlyTrendLine(analytics, theme),
                      height: 180,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildChartContainer(
                      theme,
                      "WEEKLY DISTRIBUTION",
                      AnalyticsCharts.logsByWeekday(analytics, theme),
                      height: 180,
                    ),
                  ],
                ),
          const SizedBox(height: AppSpacing.lg),

          // 4. Streak Milestones & Momentum Panel
          const SizedBox(height: AppSpacing.sm),
         Column(
                children: [
                    _buildStreakMilestones(theme),
                    const SizedBox(height: AppSpacing.md),
                    _buildMomentumCard(theme),
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

  Widget _buildCoreStatsGrid(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final int crossAxisCount = isDesktop ? 4 : 2;
    final double childAspectRatio = isDesktop ? 1.8 : 2.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: childAspectRatio,
      children: [
        StatCard(
          title: "Consistency",
          value: "${analytics.loggingConsistency.toInt()}",
          unit: "%",
          icon: Icons.auto_graph_rounded,
          color: theme.colorScheme.primary,
        ),
        StatCard(
          title: "Days Logged",
          value: "${analytics.totalDaysLogged}",
          unit: "days",
          icon: Icons.calendar_today_rounded,
          color: theme.colorScheme.secondary,
        ),
        StatCard(
          title: "Current Streak",
          value: "${analytics.currentStreak}",
          unit: "days",
          icon: Icons.local_fire_department_rounded,
          color: Colors.orange,
        ),
        StatCard(
          title: "Longest Streak",
          value: "${analytics.longestStreak}",
          unit: "max",
          icon: Icons.military_tech_rounded,
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStreakMilestones(ThemeData theme) {
    final streak = analytics.currentStreak;

    // Milestones definition
    final milestones = [
      {'name': 'Bronze Star', 'days': 5, 'color': Colors.orange.shade700},
      {'name': 'Silver Shield', 'days': 15, 'color': Colors.grey.shade400},
      {'name': 'Golden Crown', 'days': 30, 'color': Colors.amber.shade600},
      {'name': 'Diamond Flame', 'days': 100, 'color': Colors.cyan.shade300},
    ];

    Map<String, dynamic> nextMilestone = milestones.last;
    Map<String, dynamic>? currentMilestone;

    for (var m in milestones) {
      if (streak >= (m['days'] as int)) {
        currentMilestone = m;
      } else {
        nextMilestone = m;
        break;
      }
    }

    final int targetDays = nextMilestone['days'] as int;
    final int baseDays = currentMilestone != null
        ? currentMilestone['days'] as int
        : 0;
    final double progress = ((streak - baseDays) / (targetDays - baseDays))
        .clamp(0.0, 1.0);
    final int remaining = targetDays - streak;

    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "STREAK LEVEL",
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
              if (currentMilestone != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (currentMilestone['color'] as Color).withOpacity(
                      0.12,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (currentMilestone['color'] as Color).withOpacity(
                        0.3,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    (currentMilestone['name'] as String).toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: currentMilestone['color'] as Color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 40,
                color: streak > 0
                    ? Colors.orange
                    : theme.colorScheme.onSurface.withOpacity(0.2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streak == 0
                          ? "Start your streak today!"
                          : "$streak Days Burning",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      streak >= 100
                          ? "Ultimate Diamond Legend achieved!"
                          : "$remaining days until next milestone: ${nextMilestone['name']}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (streak < 100) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMomentumCard(ThemeData theme) {
    final score = analytics.momentumScore;
    final hasHighMomentum = score >= 60;
    final color = hasHighMomentum ? theme.colorScheme.primary : Colors.orange;

    String rating = "Steady";
    if (score >= 80) {
      rating = "EXCELLENT";
    } else if (score >= 60) {
      rating = "HIGH";
    } else if (score >= 40) {
      rating = "STABLE";
    } else {
      rating = "NEEDS FOCUS";
    }

    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 7,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${score.toInt()}",
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    "SCORE",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "DAILY MOMENTUM",
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Calculated from your log completions, missed days, and streak velocity over time.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer(
    ThemeData theme,
    String title,
    Widget chart, {
    required double height,
  }) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(height: height, child: chart),
        ],
      ),
    );
  }
}
