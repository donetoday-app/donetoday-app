import 'package:done_today/providers/challenges/challenges_notifier.dart';
import 'package:done_today/state/challenges/challenges_state.dart';
import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/logs/log_card.dart';
import 'package:done_today/ui/widgets/section_header.dart';
import 'package:done_today/ui/widgets/unified_header.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChallengeDetailsScreen extends ConsumerStatefulWidget {
  final String challengeId;

  const ChallengeDetailsScreen({super.key, required this.challengeId});

  @override
  ConsumerState<ChallengeDetailsScreen> createState() =>
      _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState
    extends ConsumerState<ChallengeDetailsScreen> {
  DateTime _selectedDate = DateTime.now();
  late final ScrollController _scrollController;
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    // Ensure selected date is within bounds or today
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(challengesNotifierProvider);

    if (state is! ChallengesLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final challenge = state.challenges.firstWhere(
      (c) => c.id == widget.challengeId,
      orElse: () => throw Exception("Challenge not found"),
    );

    // Get all logs for this challenge
    // We'll need to update the notifier to fetch these, but for now we'll simulate.
    final logs = _getLogsForChallenge(widget.challengeId);

    final hasTodayLog = logs.any((l) => l.date == TimeUtil.todayIso());

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      challenge.startDate.year,
      challenge.startDate.month,
      challenge.startDate.day,
    );
    final end = DateTime(
      challenge.endDate.year,
      challenge.endDate.month,
      challenge.endDate.day,
    );

    final isUpcoming = today.isBefore(start);
    final isCompleted = today.isAfter(end);
    final isActive = !isUpcoming && !isCompleted;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveConstraints(
          maxWidth: ResponsiveHelper.isDesktop(context)
              ? ResponsiveHelper.maxFullWidth
              : ResponsiveHelper.maxContentWidth,
          child: Column(
            children: [
              UnifiedHeader(
                title: challenge.title,
                onBack: () => context.pop(),
              ),
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      sliver: SliverToBoxAdapter(
                        child: _buildDateRangeInfo(theme, challenge),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: _buildHorizontalCalendar(theme, challenge, logs),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        height: 1.0,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        color: theme.colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                        ),
                        child: SectionHeader(title: "CHALLENGE JOURNEY"),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 6)),
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      sliver: _buildLogsList(theme, logs, challenge),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isActive
          ? AnimatedScale(
              scale: _isFabVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: FloatingActionButton.extended(
                heroTag: 'challenge-details-fab',
                onPressed: hasTodayLog
                    ? () {}
                    : () => context.push(
                        '/challenges/${challenge.id}/logs/new',
                        extra: challenge,
                      ),
                label: Text(
                  hasTodayLog ? "ALREADY LOGGED" : "LOG PROGRESS",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                icon: Icon(
                  hasTodayLog ? Icons.check_circle_rounded : Icons.add_rounded,
                ),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: hasTodayLog ? 0 : 4,
              ),
            )
          : null,
    );
  }

  Widget _buildDateRangeInfo(ThemeData theme, Challenge challenge) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CHALLENGE TIMELINE",
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.hintColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${TimeUtil.formatReadableDate(challenge.startDate)} — ${TimeUtil.formatReadableDate(challenge.endDate)}",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar(
    ThemeData theme,
    Challenge challenge,
    List<Log> logs,
  ) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        itemCount: challenge.totalDays,
        itemBuilder: (context, index) {
          final dayDate = challenge.startDate.add(Duration(days: index));
          final dateStr = TimeUtil.formatIsoDate(dayDate);
          final hasLog = logs.any((l) => l.date == dateStr);
          final isSelected = TimeUtil.formatIsoDate(_selectedDate) == dateStr;
          final isToday = TimeUtil.formatIsoDate(DateTime.now()) == dateStr;
          final isFuture = dayDate.isAfter(DateTime.now());

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = dayDate),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 65,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest.withOpacity(
                        0.3,
                      ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isToday
                            ? theme.colorScheme.primary.withOpacity(0.3)
                            : Colors.transparent),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "DAY",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.hintColor,
                    ),
                  ),
                  Text(
                    "${index + 1}",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasLog
                          ? (isSelected ? Colors.white : Colors.greenAccent)
                          : (isFuture
                                ? Colors.transparent
                                : (isSelected
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.redAccent.withOpacity(0.5))),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogsList(ThemeData theme, List<Log> logs, Challenge challenge) {
    if (logs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Text(
              "Your journey starts here.",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      sliver: SliverList.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[logs.length - 1 - index]; // Newest first
          return LogCard(
            title: "Day ${log.dayNumber}: ${log.title}",
            date: log.date,
            time: log.time,
            description: log.description,
            mood: log.mood,
            tags: log.tags,
            wordCount: log.wordCount,
            onTap: () => context.push(
              '/challenges/${challenge.id}/logs/${log.id}',
              extra: {'challenge': challenge, 'log': log},
            ),
            onEdit: () => context.push(
              '/challenges/${challenge.id}/logs/edit/${log.id}',
              extra: {'challenge': challenge, 'log': log},
            ),
          );
        },
      ),
    );
  }

  // Helper to fetch logs from the state
  List<Log> _getLogsForChallenge(String challengeId) {
    final state = ref.watch(challengesNotifierProvider);
    if (state is ChallengesLoaded) {
      return state.challengeLogs[challengeId] ?? [];
    }
    return [];
  }
}
