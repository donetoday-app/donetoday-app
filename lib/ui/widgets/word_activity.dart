import 'package:done_today/storage/models/log_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:done_today/utils/time_util.dart';

/// Helper: aggregate word counts per day (midnight → count)
Map<DateTime, int> _aggregateWordsPerDay(List<Log> logs) {
  final Map<DateTime, int> result = {};

  for (final log in logs) {
    final date = TimeUtil.parseIsoDate(log.date);
    final day = DateTime(date.year, date.month, date.day);
    result[day] = (result[day] ?? 0) + log.wordCount;
  }
  return result;
}

class _WordsOverTimeChart extends StatelessWidget {
  final Map<DateTime, int> wordsPerDay;
  final DateTime firstDay;
  final DateTime lastDay;

  const _WordsOverTimeChart({
    required this.wordsPerDay,
    required this.firstDay,
    required this.lastDay,
  });

  List<FlSpot> _buildSpots() {
    final List<FlSpot> spots = [];
    for (int i = 0; i <= lastDay.difference(firstDay).inDays; i++) {
      final day = DateTime(firstDay.year, firstDay.month, firstDay.day + i);
      final count = wordsPerDay[day] ?? 0;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = _buildSpots();

    if (spots.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Text(
          'No activity recorded for this range',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final maxY =
        (spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b) * 1.15)
            .ceilToDouble();

    final chartData = LineChartData(
      minX: 0,
      maxX: spots.last.x,
      minY: 0,
      maxY: maxY < 10 ? 10 : maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY / 4).clamp(1, double.infinity),
        getDrawingHorizontalLine: (value) => FlLine(
          color: theme.colorScheme.onSurface.withOpacity(0.04),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (spots.length / 4).ceilToDouble(),
            getTitlesWidget: (value, meta) {
              final day = firstDay.add(Duration(days: value.toInt()));
              return SideTitleWidget(
                meta: meta,
                space: 8,
                child: Text(
                  TimeUtil.formatShortMonthDay(day),
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    color: theme.colorScheme.onSurface.withOpacity(0.35),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (maxY / 4).clamp(1, double.infinity),
            reservedSize: 36,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              space: 4,
              child: Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  color: theme.colorScheme.onSurface.withOpacity(0.35),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) =>
              theme.colorScheme.surfaceContainerHighest,
          tooltipBorder: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
            width: 1,
          ),
          tooltipBorderRadius: BorderRadius.circular(12),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = firstDay.add(Duration(days: spot.x.toInt()));
              final isNoActivity = spot.y == 0;

              return LineTooltipItem(
                isNoActivity
                    ? "${TimeUtil.formatShortMonthDay(date)}\nNo logs"
                    : "${TimeUtil.formatShortMonthDay(date)}\n${spot.y.toInt()} words",
                TextStyle(
                  fontFamily: 'Outfit',
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          preventCurveOverShooting: true,
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
          barWidth: 4,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.15),
                theme.colorScheme.primary.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final isLastSpot = spot == spots.last;
              final hasWords = spot.y > 0;

              if (spots.length < 30 || isLastSpot) {
                return FlDotCirclePainter(
                  radius: isLastSpot ? 5 : 3,
                  color: hasWords
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  strokeWidth: isLastSpot ? 3 : 2,
                  strokeColor: theme.colorScheme.surface,
                );
              }

              return FlDotCirclePainter(radius: 0, color: Colors.transparent);
            },
          ),
        ),
      ],
      borderData: FlBorderData(show: false),
    );

    return SizedBox(
      width: double.infinity,
      height: 220,
      child: LineChart(chartData),
    );
  }
}

/// WordActivity – modern chart with range selector
class WordActivity extends StatefulWidget {
  final List<Log> logs;

  const WordActivity({super.key, required this.logs});

  @override
  State<WordActivity> createState() => _WordActivityState();
}

class _WordActivityState extends State<WordActivity> {
  String selectedRange = "1W";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.logs.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine overall date range
    DateTime? minDate;
    DateTime? maxDate;
    for (final l in widget.logs) {
      final d = TimeUtil.parseIsoDate(l.date);
      minDate = minDate == null || d.isBefore(minDate) ? d : minDate;
      maxDate = maxDate == null || d.isAfter(maxDate) ? d : maxDate;
    }

    final now = TimeUtil.now();
    final currentMonthFirst = TimeUtil.firstOfCurrentMonth();
    final currentMonthLast = TimeUtil.lastOfCurrentMonth();

    DateTime firstDay;
    DateTime lastDay;

    switch (selectedRange) {
      case "1W":
        firstDay = now.subtract(const Duration(days: 6));
        lastDay = now;
        break;
      case "1M":
        firstDay = currentMonthFirst;
        lastDay = currentMonthLast;
        break;
      default: // "ALL"
        firstDay = minDate ?? currentMonthFirst;
        lastDay = maxDate ?? currentMonthLast;
    }

    final wordsPerDay = _aggregateWordsPerDay(widget.logs);

    // Calculate stats for the selected period
    int periodTotalWords = 0;
    int activeDays = 0;

    for (int i = 0; i <= lastDay.difference(firstDay).inDays; i++) {
      final day = DateTime(firstDay.year, firstDay.month, firstDay.day + i);
      final count = wordsPerDay[day] ?? 0;
      if (count > 0) {
        periodTotalWords += count;
        activeDays++;
      }
    }

    final dailyAvg = activeDays > 0
        ? (periodTotalWords / activeDays).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Word Count",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            // Segmented Selector
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: ["1W", "1M", "ALL"].map((range) {
                  final isSelected = selectedRange == range;
                  return GestureDetector(
                    onTap: () => setState(() => selectedRange = range),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        range,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Stat cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TOTAL WORDS",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$periodTotalWords",
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DAILY AVERAGE",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$dailyAvg",
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _WordsOverTimeChart(
          wordsPerDay: wordsPerDay,
          firstDay: firstDay,
          lastDay: lastDay,
        ),
      ],
    );
  }
}
