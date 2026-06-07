import 'package:done_today/storage/models/activity_analytics.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/analytics/analytics_charts.dart';
import 'package:done_today/ui/widgets/analytics/tag_cloud.dart';
import 'package:done_today/ui/widgets/custom_card.dart';
import 'package:done_today/ui/widgets/stat_card.dart';
import 'package:flutter/material.dart';

class LogAnalysisTab extends StatelessWidget {
  final ActivityAnalytics analytics;
  final List<Log> logs;
  final bool use24Hour;

  const LogAnalysisTab({
    super.key,
    required this.analytics,
    required this.logs,
    required this.use24Hour,
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
          // 1. Text Metrics Summary Grid
          _buildSubHeader(context, "TEXT METRICS"),
          const SizedBox(height: AppSpacing.sm),
          _buildTextMetricsGrid(theme, isDesktop),
          const SizedBox(height: AppSpacing.lg),

          // 2. Best Logging Hour & Category Breakdown (Dynamic Desktop Split)
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubHeader(context, "PEAK LOGGING TIME"),
                          const SizedBox(height: AppSpacing.sm),
                          _buildTimeCard(
                            theme,
                            _formatBestTime(
                              analytics.bestLoggingHour,
                              use24Hour,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildSubHeader(context, "POPULAR TOPICS (TAGS)"),
                          const SizedBox(height: AppSpacing.sm),
                          CustomCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: TagCloudWidget(tags: analytics.topTags),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubHeader(context, "CATEGORY BREAKDOWN"),
                          const SizedBox(height: AppSpacing.sm),
                          CustomCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: AnalyticsCharts.categoryBreakdown(
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
                    _buildSubHeader(context, "PEAK LOGGING TIME"),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTimeCard(
                      theme,
                      _formatBestTime(analytics.bestLoggingHour, use24Hour),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSubHeader(context, "CATEGORY BREAKDOWN"),
                    const SizedBox(height: AppSpacing.sm),
                    CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: AnalyticsCharts.categoryBreakdown(
                        analytics,
                        theme,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSubHeader(context, "POPULAR TOPICS (TAGS)"),
                    const SizedBox(height: AppSpacing.sm),
                    CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: TagCloudWidget(tags: analytics.topTags),
                    ),
                  ],
                ),
          const SizedBox(height: AppSpacing.lg),

          // 3. Mood Correlation
          _buildSubHeader(context, "MOOD CORRELATION"),
          const SizedBox(height: AppSpacing.sm),
        _buildMoodCorrelation(theme),
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
        ),
      ],
    );
  }

  Widget _buildTextMetricsGrid(ThemeData theme, bool isDesktop) {
    final int crossAxisCount = isDesktop ? 3 : 3;
    final double childAspectRatio = isDesktop ? 1.9 : 1.35;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: AppSpacing.xs,
      crossAxisSpacing: AppSpacing.xs,
      childAspectRatio: childAspectRatio,
      children: [
        StatCard(
          title: "Avg Words",
          value: "${analytics.avgWordCount.toInt()}",
          unit: "wds",
          icon: Icons.text_fields_rounded,
          color: theme.colorScheme.primary,
        ),
        StatCard(
          title: "Avg Read Time",
          value: "${analytics.avgReadTime.toStringAsFixed(1)}",
          unit: "min",
          icon: Icons.chrome_reader_mode_rounded,
          color: theme.colorScheme.secondary,
        ),
        StatCard(
          title: "Late Logs",
          value: "${analytics.lateEntryRate.toInt()}",
          unit: "%",
          icon: Icons.lock_clock_rounded,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildTimeCard(ThemeData theme, String time) {
    int hour = 12;
    try {
      final cleanTime = time.replaceAll(RegExp(r'[^0-9:]'), '');
      if (cleanTime.contains(':')) {
        hour = int.parse(cleanTime.split(':').first);
        if (time.toLowerCase().contains('pm') && hour < 12) {
          hour += 12;
        } else if (time.toLowerCase().contains('am') && hour == 12) {
          hour = 0;
        }
      }
    } catch (_) {}

    IconData periodIcon = Icons.wb_sunny_rounded;
    Color periodColor = Colors.amber;
    String label = "MID-DAY";
    String description = "A productive time of day to record updates.";

    if (hour >= 5 && hour < 12) {
      periodIcon = Icons.wb_twilight_rounded;
      periodColor = Colors.orange;
      label = "EARLY BIRD";
      description = "Your thoughts are captured fresh in the morning.";
    } else if (hour >= 12 && hour < 17) {
      periodIcon = Icons.wb_sunny_rounded;
      periodColor = Colors.blue;
      label = "PRODUCTIVE PM";
      description = "Reflecting and keeping track of mid-day tasks.";
    } else if (hour >= 17 && hour < 21) {
      periodIcon = Icons.wb_twilight_rounded;
      periodColor = Colors.deepOrange;
      label = "SUNSET VIBES";
      description = "Winding down and logging your daily accomplishments.";
    } else {
      periodIcon = Icons.nights_stay_rounded;
      periodColor = Colors.purpleAccent;
      label = "NIGHT OWL";
      description = "Deep thoughts captured under the quiet night sky.";
    }

    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: periodColor.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: periodColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Icon(periodIcon, size: 30, color: periodColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: periodColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: periodColor.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: periodColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBestTime(String bestTime, bool use24Hour) {
    if (bestTime == "N/A" || bestTime.isEmpty) return bestTime;
    if (use24Hour) return bestTime;
    try {
      final parts = bestTime.split(':');
      final hour24 = int.parse(parts[0]);
      final minute = parts.length > 1 ? parts[1] : "00";
      final period = hour24 >= 12 ? "PM" : "AM";
      var hour12 = hour24 % 12;
      if (hour12 == 0) hour12 = 12;
      return "$hour12:$minute $period";
    } catch (_) {
      return bestTime;
    }
  }

  Widget _buildMoodCorrelation(ThemeData theme) {
    if (logs.isEmpty) {
      return const CustomCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text("Not enough data to calculate correlations yet."),
          ),
        ),
      );
    }

    final Map<String, List<double>> catScores = {};
    for (var log in logs) {
      final cat = log.category ?? 'Uncategorized';
      final score = _getMoodScore(log.mood);
      catScores.putIfAbsent(cat, () => []).add(score);
    }

    final List<MapEntry<String, double>> averages = catScores.entries.map((e) {
      return MapEntry(e.key, e.value.reduce((a, b) => a + b) / e.value.length);
    }).toList();

    averages.sort((a, b) => b.value.compareTo(a.value));

    final booster = averages.first;
    final drainer = averages.length > 1 ? averages.last : null;

    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _correlationItem(
            theme,
            "Mood Booster",
            booster.key,
            booster.value,
            theme.colorScheme.primary,
            Icons.trending_up_rounded,
          ),
          if (drainer != null) ...[
            const SizedBox(height: AppSpacing.md),
            _correlationItem(
              theme,
              "Mood Drainer",
              drainer.key,
              drainer.value,
              theme.colorScheme.error,
              Icons.trending_down_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _correlationItem(
    ThemeData theme,
    String label,
    String category,
    double score,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  category,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${(score * 100).toInt()}%",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text("Positive", style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  double _getMoodScore(String? mood) {
    if (mood == null) return 0.5;
    final m = mood.toLowerCase();
    if (m.contains('happy') ||
        m.contains('excited') ||
        m.contains('energized') ||
        m.contains('creative'))
      return 0.9;
    if (m.contains('normal') || m.contains('peaceful') || m.contains('focused'))
      return 0.6;
    if (m.contains('sad') || m.contains('tired')) return 0.2;
    if (m.contains('angry')) return 0.1;
    return 0.5;
  }
}
