import 'dart:async';
import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/storage/hive/hive_service.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/custom_card.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityCalendar extends ConsumerStatefulWidget {
  final List<Log> logs;

  const ActivityCalendar({super.key, required this.logs});

  @override
  ConsumerState<ActivityCalendar> createState() => _ActivityCalendarState();
}

class _ActivityCalendarState extends ConsumerState<ActivityCalendar> {
  String selectedMode =
      "GRID"; // "GRID" (Default Modern Calendar) or "MATRIX" (GitHub Style)
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = TimeUtil.now();
    // Retrieve stored calendar mode preference, defaulting to "GRID"
    selectedMode =
        HiveService.get<String>('settings', 'calendarViewMode') ?? 'GRID';
  }

  void _updateMode(String newMode) async {
    setState(() {
      selectedMode = newMode;
    });
    // Persist user preference locally
    await HiveService.put<String>('settings', 'calendarViewMode', newMode);
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeMode = selectedMode;

    // Map logs to calendar days
    final events = <DateTime, List<Log>>{};
    DateTime? minDate;
    DateTime? maxDate;

    for (final log in widget.logs) {
      final date = TimeUtil.parseIsoDate(log.date);
      final day = DateTime(date.year, date.month, date.day);
      events[day] = [...events[day] ?? [], log];

      // Track min/max dates
      minDate = minDate == null || date.isBefore(minDate) ? date : minDate;
      maxDate = maxDate == null || date.isAfter(maxDate) ? date : maxDate;
    }

    // Always include current month
    final now = TimeUtil.now();
    final currentMonthFirst = TimeUtil.firstOfCurrentMonth();
    final currentMonthLast = TimeUtil.lastOfCurrentMonth();

    // Calculate calendar bounds
    DateTime firstLogDay = minDate != null
        ? DateTime(minDate.year, minDate.month, 1)
        : currentMonthFirst;
    DateTime lastLogDay = maxDate != null
        ? DateTime(maxDate.year, maxDate.month + 1, 0)
        : currentMonthLast;

    // Ensure current month is always included
    if (currentMonthFirst.isBefore(firstLogDay)) {
      firstLogDay = currentMonthFirst;
    }
    if (currentMonthLast.isAfter(lastLogDay)) {
      lastLogDay = currentMonthLast;
    }

    // Safely clamp focusedDay to valid range
    DateTime focusedDay = now.isBefore(firstLogDay)
        ? firstLogDay
        : now.isAfter(lastLogDay)
        ? lastLogDay
        : now;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Logging",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            // Segmented Selector matching WordActivity exactly
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: ["Grid", "Matrix"].map((mode) {
                  final modeUpper = mode.toUpperCase();
                  final isSelected = activeMode == modeUpper;
                  return GestureDetector(
                    onTap: () => _updateMode(modeUpper),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mode,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.4,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Render content based on selected mode
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: activeMode == "MATRIX"
              ? _buildContributionMatrix(context, theme, events)
              : _buildCalendarView(
                  context,
                  theme,
                  firstLogDay,
                  lastLogDay,
                  focusedDay,
                  events,
                ),
        ),

        // 🚀 Selected Day's Momentum details panel (Daily logs and active challenges status)
        _buildSelectedDayDetailsSection(context, theme, widget.logs),
      ],
    );
  }

  Widget _buildSelectedDayDetailsSection(
    BuildContext context,
    ThemeData theme,
    List<Log> logs,
  ) {
    final now = TimeUtil.now();
    final resolvedDate = selectedDate ?? now;
    final todayKey = DateTime(
      resolvedDate.year,
      resolvedDate.month,
      resolvedDate.day,
    );

    // Find today's daily log
    Log? todayLog;
    for (final log in logs) {
      final date = TimeUtil.parseIsoDate(log.date);
      if (date.year == todayKey.year &&
          date.month == todayKey.month &&
          date.day == todayKey.day) {
        todayLog = log;
        break;
      }
    }

    // Get today's active challenges and their logs from Hive
    List<Map<String, dynamic>> activeChallenges = [];
    List<Map<String, dynamic>> todayLogs = [];

    try {
      final challengesBox = Hive.box('challenges');
      final allChallenges = challengesBox.values
          .map(
            (v) =>
                v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{},
          )
          .where((c) => c.isNotEmpty && c['isDeleted'] != true)
          .toList();

      activeChallenges = allChallenges.where((c) {
        try {
          final start = DateTime.parse(c['startDate']);
          final end = DateTime.parse(c['endDate']);
          final todayZero = DateTime(
            resolvedDate.year,
            resolvedDate.month,
            resolvedDate.day,
          );
          final startZero = DateTime(start.year, start.month, start.day);
          final endZero = DateTime(end.year, end.month, end.day);
          return !todayZero.isBefore(startZero) && !todayZero.isAfter(endZero);
        } catch (_) {
          return false;
        }
      }).toList();

      final logsBox = Hive.box('logs');
      todayLogs = logsBox.values
          .map(
            (v) =>
                v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{},
          )
          .where(
            (l) =>
                l.isNotEmpty &&
                l['isDeleted'] != true &&
                l['challengeId'] != null,
          )
          .where((l) {
            try {
              final logDate = DateTime.parse(l['date']);
              return logDate.year == todayKey.year &&
                  logDate.month == todayKey.month &&
                  logDate.day == todayKey.day;
            } catch (_) {
              return false;
            }
          })
          .toList();
    } catch (_) {
      // Safely fall back if Hive is not initialized or box is not opened yet
    }

    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? Colors.white
        : theme.colorScheme.onSurface;

    final isToday =
        resolvedDate.year == now.year &&
        resolvedDate.month == now.month &&
        resolvedDate.day == now.day;

    final isFuture = todayKey.isAfter(DateTime(now.year, now.month, now.day));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        // Section Subheader
        Text(
          isToday
              ? "TODAY'S MOMENTUM"
              : "${TimeUtil.formatShortMonthDay(resolvedDate).toUpperCase()}'S MOMENTUM",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: primaryTextColor.withOpacity(0.55),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),

        // 1. Daily Log Status Card
        CustomCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderRadius: AppRadius.lg,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: todayLog != null
                      ? theme.colorScheme.primary.withOpacity(0.08)
                      : theme.colorScheme.onSurface.withOpacity(0.03),
                ),
                child: Icon(
                  todayLog != null
                      ? Icons.done_all_rounded
                      : Icons.history_edu_rounded,
                  color: todayLog != null
                      ? theme.colorScheme.primary
                      : primaryTextColor.withOpacity(0.35),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Log",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      todayLog != null
                          ? "Logged • ${todayLog.wordCount} words • ${todayLog.readTime} min read"
                          : (isFuture
                                ? "Locked • Cannot log future dates"
                                : (isToday
                                      ? "Your thoughts are waiting to be written."
                                      : "Missed • No entry recorded for this day.")),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: primaryTextColor.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (todayLog == null && isToday)
                TextButton(
                  onPressed: () => context.push('/logs/new'),
                  style: TextButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.08,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "WRITE",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1,
                    ),
                  ),
                )
              else if (todayLog != null && todayLog.mood != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    todayLog.mood!.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 2. Active Challenges Status list
        if (activeChallenges.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            "ACTIVE CHALLENGES",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: primaryTextColor.withOpacity(0.4),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _SelectedDayChallengesSlider(
            activeChallenges: activeChallenges,
            todayLogs: todayLogs,
            isToday: isToday,
            isFuture: isFuture,
            theme: theme,
            primaryTextColor: primaryTextColor,
          ),
        ],
      ],
    );
  }

  /// Render GitHub Contribution Matrix View (Scrollable horizontally with Month markers)
  Widget _buildContributionMatrix(
    BuildContext context,
    ThemeData theme,
    Map<DateTime, List<Log>> events,
  ) {
    final now = TimeUtil.now();
    final dayLabels = ["M", "T", "W", "T", "F", "S", "S"];

    // Generate last 4 months (chronological order)
    final List<DateTime> monthsToDisplay = [];
    for (int i = 3; i >= 0; i--) {
      int targetMonth = now.month - i;
      int targetYear = now.year;
      if (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }
      monthsToDisplay.add(DateTime(targetYear, targetMonth, 1));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.015),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pinned Day Labels Column (ALL letters visible, Sunday in RED!)
              Padding(
                padding: const EdgeInsets.only(
                  top: 24.0,
                ), // Indent to align below month headers
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(7, (index) {
                    final isSunday = index == 6; // Sunday is index 6
                    return Container(
                      height: 18,
                      width: 20,
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Text(
                        dayLabels[index],
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isSunday
                              ? const Color(0xFFEF4444) // Pure red
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),

              // Scrollable Months Matrix
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true, // Auto-scroll to show recent months first
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: monthsToDisplay.map((monthStart) {
                      return _buildSingleMonthMatrix(
                        context,
                        theme,
                        monthStart,
                        events,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Legend and subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Monthly Activity Tracker",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              Row(
                children: [
                  Text(
                    "Less",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildLegendBlock(
                    theme.colorScheme.onSurface.withOpacity(0.04),
                  ),
                  const SizedBox(width: 3),
                  _buildLegendBlock(
                    theme.colorScheme.primary.withOpacity(0.25),
                  ),
                  const SizedBox(width: 3),
                  _buildLegendBlock(theme.colorScheme.primary.withOpacity(0.5)),
                  const SizedBox(width: 3),
                  _buildLegendBlock(
                    theme.colorScheme.primary.withOpacity(0.75),
                  ),
                  const SizedBox(width: 3),
                  _buildLegendBlock(theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    "More",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleMonthMatrix(
    BuildContext context,
    ThemeData theme,
    DateTime monthStart,
    Map<DateTime, List<Log>> events,
  ) {
    final now = TimeUtil.now();
    final todayKey = DateTime(now.year, now.month, now.day);

    // Calculate weeks boundaries for this month
    final startMonday = monthStart.subtract(
      Duration(days: monthStart.weekday - 1),
    );

    final nextMonth = DateTime(monthStart.year, monthStart.month + 1, 1);
    final monthEnd = nextMonth.subtract(const Duration(days: 1));
    final endSunday = monthEnd.add(Duration(days: 7 - monthEnd.weekday));

    final numWeeks = (endSunday.difference(startMonday).inDays + 1) ~/ 7;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Label (e.g. "MAY")
          Padding(
            padding: const EdgeInsets.only(left: 2.0),
            child: Text(
              _getMonthName(monthStart.month).toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Month Contribution Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(numWeeks, (weekIndex) {
              final weekStart = startMonday.add(Duration(days: weekIndex * 7));
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Column(
                  children: List.generate(7, (dayIndex) {
                    final cellDate = weekStart.add(Duration(days: dayIndex));
                    final cellKey = DateTime(
                      cellDate.year,
                      cellDate.month,
                      cellDate.day,
                    );

                    final isCurrentMonth = cellKey.month == monthStart.month;
                    final isFuture = cellKey.isAfter(todayKey);
                    final isToday = cellKey == todayKey;

                    int totalWords = 0;
                    final hasLog = events.containsKey(cellKey);
                    if (hasLog) {
                      final dayLogs = events[cellKey]!;
                      totalWords = dayLogs.fold<int>(
                        0,
                        (sum, log) => sum + log.wordCount,
                      );
                    }

                    // Color based on activity volume
                    Color cellColor = theme.colorScheme.onSurface.withOpacity(
                      0.04,
                    );

                    if (!isCurrentMonth) {
                      cellColor = Colors.transparent;
                    } else if (isFuture) {
                      cellColor = theme.colorScheme.onSurface.withOpacity(0.04);
                    } else if (hasLog) {
                      if (totalWords <= 50) {
                        cellColor = theme.colorScheme.primary.withOpacity(0.25);
                      } else if (totalWords <= 150) {
                        cellColor = theme.colorScheme.primary.withOpacity(0.5);
                      } else if (totalWords <= 300) {
                        cellColor = theme.colorScheme.primary.withOpacity(0.75);
                      } else {
                        cellColor = theme.colorScheme.primary;
                      }
                    }

                    final isSelected =
                        selectedDate != null &&
                        selectedDate!.year == cellKey.year &&
                        selectedDate!.month == cellKey.month &&
                        selectedDate!.day == cellKey.day;

                    Border? cellBorder;
                    if (isCurrentMonth) {
                      if (isSelected) {
                        cellBorder = Border.all(
                          color: theme.colorScheme.primary,
                          width: 2.0,
                        );
                      } else if (isToday) {
                        cellBorder = Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          width: 1.5,
                        );
                      } else {
                        cellBorder = Border.all(
                          color: theme.colorScheme.onSurface.withOpacity(0.08),
                          width: 0.8,
                        );
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        if (isCurrentMonth) {
                          setState(() {
                            selectedDate = cellKey;
                          });
                        }
                      },
                      child: Tooltip(
                        message: !isCurrentMonth
                            ? ""
                            : (isFuture
                                  ? "${TimeUtil.formatShortMonthDay(cellDate)}: Future"
                                  : "${TimeUtil.formatShortMonthDay(cellDate)}: ${hasLog ? '$totalWords words' : 'No logs'}"),
                        child: Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.symmetric(vertical: 2.5),
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(12),
                            border: cellBorder,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBlock(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  /// 📅 Render TableCalendar Grid View (Modern Grid Mode)
  Widget _buildCalendarView(
    BuildContext context,
    ThemeData theme,
    DateTime firstLogDay,
    DateTime lastLogDay,
    DateTime focusedDay,
    Map<DateTime, List<Log>> events,
  ) {
    return TableCalendar(
      firstDay: firstLogDay,
      lastDay: lastLogDay,
      focusedDay: focusedDay,
      selectedDayPredicate: (day) {
        return selectedDate != null &&
            selectedDate!.year == day.year &&
            selectedDate!.month == day.month &&
            selectedDate!.day == day.day;
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          selectedDate = selectedDay;
        });
      },
      calendarFormat: CalendarFormat.month,
      rowHeight: 52,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
        leftChevronIcon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.05),
            ),
          ),
          child: Icon(
            Icons.chevron_left_rounded,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
        ),
        rightChevronIcon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.05),
            ),
          ),
          child: Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
        ),
        headerPadding: const EdgeInsets.only(top: 8, bottom: 0),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
        weekendStyle: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha(76),
          borderRadius: BorderRadius.circular(12),
        ),
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        outsideDaysVisible: true,
        outsideTextStyle: TextStyle(
          fontFamily: 'JetBrainsMono',
          color: theme.colorScheme.onSurface.withAlpha(76),
          fontSize: 13,
        ),
        weekendTextStyle: TextStyle(
          fontFamily: 'JetBrainsMono',
          color: theme.colorScheme.onSurface,
          fontSize: 13,
        ),
        defaultTextStyle: TextStyle(
          fontFamily: 'JetBrainsMono',
          color: theme.colorScheme.onSurface,
          fontSize: 13,
        ),
        holidayTextStyle: TextStyle(
          fontFamily: 'JetBrainsMono',
          color: theme.colorScheme.onSurface,
          fontSize: 13,
        ),
        selectedTextStyle: TextStyle(
          fontFamily: 'JetBrainsMono',
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        todayTextStyle: TextStyle(
          fontFamily: 'JetBrainsMono',
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        cellMargin: const EdgeInsets.all(4),
      ),
      eventLoader: (day) => events[day] ?? [],
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          final dayKey = DateTime(day.year, day.month, day.day);
          final hasLog = events.containsKey(dayKey);

          if (hasLog) {
            final dayLogs = events[dayKey]!;
            final totalWords = dayLogs.fold<int>(
              0,
              (sum, log) => sum + log.wordCount,
            );

            return Container(
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: totalWords > 200 ? 5 : 3.5,
                    height: totalWords > 200 ? 5 : 3.5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: totalWords > 200
                          ? [
                              const BoxShadow(
                                color: Colors.white,
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.04),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          );
        },
        outsideBuilder: (context, day, focusedDay) {
          return Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                color: theme.colorScheme.onSurface.withOpacity(0.15),
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
            ),
          );
        },
        todayBuilder: (context, day, focusedDay) {
          final dayKey = DateTime(day.year, day.month, day.day);
          final hasLog = events.containsKey(dayKey);

          if (!hasLog) {
            return Container(
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            );
          }
          return null;
        },
        selectedBuilder: (context, day, focusedDay) {
          final dayKey = DateTime(day.year, day.month, day.day);
          final hasLog = events.containsKey(dayKey);

          if (hasLog) {
            final dayLogs = events[dayKey]!;
            final totalWords = dayLogs.fold<int>(
              0,
              (sum, log) => sum + log.wordCount,
            );

            return Container(
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.onPrimary,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: totalWords > 200 ? 5 : 3.5,
                    height: totalWords > 200 ? 5 : 3.5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SelectedDayChallengesSlider extends StatefulWidget {
  final List<Map<String, dynamic>> activeChallenges;
  final List<Map<String, dynamic>> todayLogs;
  final bool isToday;
  final bool isFuture;
  final ThemeData theme;
  final Color primaryTextColor;

  const _SelectedDayChallengesSlider({
    required this.activeChallenges,
    required this.todayLogs,
    required this.isToday,
    required this.isFuture,
    required this.theme,
    required this.primaryTextColor,
  });

  @override
  State<_SelectedDayChallengesSlider> createState() =>
      __SelectedDayChallengesSliderState();
}

class __SelectedDayChallengesSliderState
    extends State<_SelectedDayChallengesSlider> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(_SelectedDayChallengesSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeChallenges.length != oldWidget.activeChallenges.length) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (widget.activeChallenges.length < 2) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= widget.activeChallenges.length) {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeChallenges.length == 1) {
      final challenge = widget.activeChallenges[0];
      return _buildChallengeCard(challenge, isSingle: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 76,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.activeChallenges.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final challenge = widget.activeChallenges[index];
              return _buildChallengeCard(challenge, isSingle: false);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.activeChallenges.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 5,
              width: _currentPage == index ? 15 : 5,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? widget.theme.colorScheme.secondary
                    : widget.theme.colorScheme.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(
    Map<String, dynamic> challenge, {
    required bool isSingle,
  }) {
    final challengeId = challenge['id'];
    final isCheckedIn = widget.todayLogs.any(
      (l) => l['challengeId'] == challengeId,
    );

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(right: isSingle ? 0 : 8, left: isSingle ? 0 : 8),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        borderRadius: AppRadius.md,
        child: Row(
          children: [
            Icon(
              Icons.stars_rounded,
              color: isCheckedIn
                  ? widget.theme.colorScheme.secondary
                  : widget.primaryTextColor.withOpacity(0.2),
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    challenge['title']?.toString().toUpperCase() ?? 'CHALLENGE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: widget.theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: widget.primaryTextColor.withOpacity(
                        isCheckedIn ? 0.8 : 0.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCheckedIn
                        ? "Checked in!"
                        : (widget.isFuture
                              ? "Not open yet"
                              : (widget.isToday
                                    ? "Pending check-in"
                                    : "Missed check-in")),
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: isCheckedIn
                          ? widget.theme.colorScheme.secondary
                          : widget.primaryTextColor.withOpacity(0.4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCheckedIn && widget.isToday)
              TextButton(
                onPressed: () => context.push(
                  '/challenges/$challengeId/logs/new',
                  extra: Challenge.fromJson(challenge),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: widget.theme.colorScheme.secondary
                      .withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "CHECK IN",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: widget.theme.colorScheme.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            else if (isCheckedIn)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.theme.colorScheme.secondary.withOpacity(0.12),
                ),
                child: Icon(
                  Icons.done_rounded,
                  color: widget.theme.colorScheme.secondary,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
