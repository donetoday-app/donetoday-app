import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:done_today/storage/models/activity_analytics.dart';
import 'package:done_today/theme/ui_constants.dart';

class AnalyticsCharts {
  // 1. Monthly Trend Line Chart (FREE)
  static Widget monthlyTrendLine(ActivityAnalytics analytics, ThemeData theme) {
    if (analytics.monthlyTrend.isEmpty)
      return const Center(child: Text("No monthly data available"));

    final sortedEntries = analytics.monthlyTrend.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final List<MapEntry<String, int>> monthlyData = sortedEntries;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: 5,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outlineVariant.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      monthlyData[value.toInt()].key.substring(5), // e.g., "05"
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(monthlyData.length, (i) {
              return FlSpot(i.toDouble(), monthlyData[i].value.toDouble());
            }),
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Logs by Day of Week (FREE)
  static Widget logsByWeekday(ActivityAnalytics analytics, ThemeData theme) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = days
        .map((day) => analytics.logsByDayOfWeek[day] ?? 0)
        .toList();
    final maxVal = values.isEmpty
        ? 10.0
        : values.reduce((a, b) => a > b ? a : b).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxVal * 1.2).ceilToDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                space: 8,
                child: Text(
                  days[value.toInt()],
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ),
            ),
          ),
        ),
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i].toDouble(),
                color: theme.colorScheme.secondary,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // 3. Mood Distribution (PREMIUM)
  static Widget moodDistributionPie(
    ActivityAnalytics analytics,
    ThemeData theme,
  ) {
    return _InteractiveMoodTrends(analytics: analytics, theme: theme);
  }

  // 4. Category Breakdown (PREMIUM)
  static Widget categoryBreakdown(
    ActivityAnalytics analytics,
    ThemeData theme,
  ) {
    final sortedCategories = analytics.categoryInsights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty)
      return const Center(child: Text("No category data"));

    return Column(
      children: sortedCategories.take(5).map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${entry.value.toInt()}%',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: entry.value / 100,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: theme.colorScheme.primary,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 5. Challenge Category Breakdown (FREE)
  static Widget challengeCategoryBreakdown(
    ActivityAnalytics analytics,
    ThemeData theme,
  ) {
    final sortedCategories =
        analytics.challengeCategoryInsights.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty)
      return const Center(child: Text("No challenge categories"));

    return Column(
      children: sortedCategories.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${entry.value.toInt()}%',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: entry.value / 100,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: theme.colorScheme.secondary,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InteractiveMoodTrends extends StatefulWidget {
  final ActivityAnalytics analytics;
  final ThemeData theme;

  const _InteractiveMoodTrends({required this.analytics, required this.theme});

  @override
  State<_InteractiveMoodTrends> createState() => _InteractiveMoodTrendsState();
}

class _InteractiveMoodTrendsState extends State<_InteractiveMoodTrends> {
  bool _showLegend = false;
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final colors = [
      widget.theme.colorScheme.primary,
      widget.theme.colorScheme.secondary,
      widget.theme.colorScheme.tertiary,
      widget.theme.colorScheme.error,
      widget.theme.colorScheme.primaryContainer,
    ];

    final entries = widget.analytics.moodInsights.entries.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The Pie Chart Wrapper
        GestureDetector(
          onTap: () {
            setState(() {
              _showLegend = !_showLegend;
            });
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: SizedBox(
                width: 150,
                height: 150,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                    sections: entries.map((entry) {
                      final index = entries.indexOf(entry);
                      final isTouched = index == _touchedIndex;
                      final percentage = entry.value * 100;
                      final radius = isTouched ? 48.0 : 38.0;

                      return PieChartSectionData(
                        value: percentage,
                        title: isTouched
                            ? '${percentage.toStringAsFixed(0)}%'
                            : '',
                        color: colors[index % colors.length],
                        radius: radius,
                        titleStyle: widget.theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                        badgeWidget: _Badge(
                          entry.key,
                          size: isTouched ? 34 : 26,
                        ),
                        badgePositionPercentageOffset: 1.35,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Dynamic Quick Instruction Text (Subtle hint)
        Text(
          _showLegend
              ? "TAP CHART TO HIDE BREAKDOWN"
              : "TAP CHART TO SHOW BREAKDOWN LEGEND",
          style: widget.theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            letterSpacing: 0.8,
            color: widget.theme.colorScheme.onSurface.withOpacity(0.4),
            fontWeight: FontWeight.bold,
          ),
        ),

        // Highlighted Tap Info Card
        if (_touchedIndex != -1 && _touchedIndex < entries.length) ...[
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final entry = entries[_touchedIndex];
              final color = colors[_touchedIndex % colors.length];
              final percentage = entry.value * 100;

              String labelName = entry.key;
              String emoji = "";
              if (entry.key.contains(' ')) {
                final parts = entry.key.split(' ');
                emoji = parts.last;
                labelName = parts.first;
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      child: Text(emoji, style: const TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${labelName[0].toUpperCase()}${labelName.substring(1)}",
                            style: widget.theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${percentage.toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],

        // Expandable Full Legend Panel
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 14, left: 4, right: 4),
            child: Column(
              children: entries.map((entry) {
                final index = entries.indexOf(entry);
                final percentage = entry.value * 100;
                final color = colors[index % colors.length];

                String labelName = entry.key;
                String emoji = "";
                if (entry.key.contains(' ')) {
                  final parts = entry.key.split(' ');
                  emoji = parts.last;
                  labelName = parts.first;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.theme.colorScheme.outlineVariant
                            .withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${labelName[0].toUpperCase()}${labelName.substring(1)}",
                            style: widget.theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: widget.theme.colorScheme.onSurface
                                  .withOpacity(0.8),
                            ),
                          ),
                        ),
                        Text(
                          "${percentage.toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          crossFadeState: _showLegend
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String emoji;
  final double size;

  const _Badge(this.emoji, {required this.size});

  @override
  Widget build(BuildContext context) {
    // Extract emoji from mood string like "happy 😊"
    String actualEmoji = emoji;
    if (emoji.contains(' ')) {
      actualEmoji = emoji.split(' ').last;
    }
    return Text(actualEmoji, style: TextStyle(fontSize: size));
  }
}
