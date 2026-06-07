import 'dart:ui';
import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/section_header.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:done_today/providers/logs/logs_notifier.dart';
import 'package:done_today/providers/challenges/challenges_notifier.dart';
import 'package:done_today/state/logs/logs_state.dart';
import 'package:done_today/state/challenges/challenges_state.dart';

class AchievementEntry {
  final String id;
  final String title;
  final String description;
  final String time;
  final String date;
  final String? mood;
  final String type; // 'DAILY' or 'CHALLENGE'
  final DateTime sortDate;
  final dynamic original;

  AchievementEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.date,
    this.mood,
    required this.type,
    required this.sortDate,
    required this.original,
  });
}

final achievementEntriesProvider = Provider<List<AchievementEntry>>((ref) {
  final logState = ref.watch(logsNotifierProvider);
  final challengeState = ref.watch(challengesNotifierProvider);

  if (logState is! LogsLoaded || challengeState is! ChallengesLoaded) {
    return [];
  }

  final List<AchievementEntry> entries = [];

  // Filter out deleted daily logs
  final activeDailyLogs = logState.logs
      .where((l) => !(l.toMap()['isDeleted'] ?? false))
      .toList();

  for (var log in activeDailyLogs) {
    entries.add(
      AchievementEntry(
        id: log.id,
        title: log.title,
        description: log.description,
        time: log.time,
        date: log.date,
        mood: log.mood,
        type: 'DAILY',
        sortDate:
            DateTime.tryParse(log.updatedAt ?? log.createdAt ?? log.date) ??
            DateTime.now(),
        original: log,
      ),
    );
  }

  // Filter out deleted challenges and their logs
  final activeChallenges = challengeState.challenges
      .where((c) => !c.isDeleted)
      .toList();
  final activeChallengeIds = activeChallenges.map((c) => c.id).toSet();

  challengeState.challengeLogs.forEach((challengeId, logsList) {
    if (!activeChallengeIds.contains(challengeId)) return;

    // Find the challenge object
    final challenge = activeChallenges.firstWhere((c) => c.id == challengeId);

    // Filter out deleted logs within the challenge
    final activeLogs = logsList.toList();

    for (var log in activeLogs) {
      entries.add(
        AchievementEntry(
          id: log.id,
          title: log.challengeId != null
              ? "[Challenge] ${log.title}"
              : log.title,
          description: log.description,
          time: log.time,
          date: log.date,
          mood: log.mood,
          type: 'CHALLENGE',
          sortDate:
              DateTime.tryParse(log.updatedAt ?? log.createdAt ?? log.date) ??
              DateTime.now(),
          original: {'log': log, 'challenge': challenge},
        ),
      );
    }
  });

  // Sort by date (most recent first)
  entries.sort((a, b) => b.sortDate.compareTo(a.sortDate));

  return entries;
});

class RecentAchievements extends ConsumerWidget {
  final ThemeData theme;
  final bool use24Hour;

  const RecentAchievements(this.theme, {super.key, required this.use24Hour});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(achievementEntriesProvider);
    final recent = entries.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "RECENT ACHIEVEMENTS",
          trailing: TextButton(
            onPressed: () {
              AllAchievementsPopup.show(context, entries, use24Hour);
            },
            child: const Text("VIEW ALL"),
          ),
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                "No achievements yet. Start your story.",
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          ..._buildGroupedTimeline(theme, recent, context, use24Hour),
      ],
    );
  }
}

List<Widget> _buildGroupedTimeline(
  ThemeData theme,
  List<AchievementEntry> entriesList,
  BuildContext ctx,
  bool use24Hour, {
  bool isPopup = false,
}) {
  if (entriesList.isEmpty) return [];

  // Group by date
  final Map<String, List<AchievementEntry>> grouped = {};
  for (var e in entriesList) {
    grouped.putIfAbsent(e.date, () => []).add(e);
  }

  final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

  return sortedDates.map((dateStr) {
    final dayEntries = grouped[dateStr]!;
    final parsedDate = DateTime.tryParse(dateStr);

    String headerText = dateStr;
    if (parsedDate != null) {
      if (TimeUtil.isToday(dateStr)) {
        headerText = "Today";
      } else {
        headerText = TimeUtil.formatReadableDate(parsedDate);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  headerText.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Divider(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...dayEntries.map(
            (e) => _buildAchievementCard(
              theme,
              e,
              ctx,
              use24Hour,
              isPopup: isPopup,
            ),
          ),
        ],
      ),
    );
  }).toList();
}

Widget _buildAchievementCard(
  ThemeData theme,
  AchievementEntry entry,
  BuildContext ctx,
  bool use24Hour, {
  bool isPopup = false,
}) {
  final isChallenge = entry.type == 'CHALLENGE';

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GestureDetector(
      onTap: () {
        if (isPopup) ctx.pop();
        if (isChallenge) {
          final data = entry.original as Map<String, dynamic>;
          final log = data['log'] as Log;
          final challenge = data['challenge'] as Challenge;
          ctx.push(
            '/challenges/${challenge.id}/logs/${log.id}',
            extra: {'log': log, 'challenge': challenge},
          );
        } else {
          final log = entry.original as Log;
          ctx.push('/logs/${log.id}', extra: log);
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Left Accent Border
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(
                color: isChallenge
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isChallenge
                                      ? theme.colorScheme.secondary
                                      : theme.colorScheme.primary)
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isChallenge
                                  ? Icons.emoji_events_rounded
                                  : Icons.article_rounded,
                              size: 14,
                              color: isChallenge
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isChallenge ? "CHALLENGE" : "DAILY",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isChallenge
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        TimeUtil.formatTimeString(
                          entry.time,
                          use24Hour: use24Hour,
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (entry.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                entry.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (entry.mood != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          entry.mood!.split(' ').last,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

List<dynamic> _getFlattenedTimeline(List<AchievementEntry> entriesList) {
  if (entriesList.isEmpty) return [];

  final Map<String, List<AchievementEntry>> grouped = {};
  for (var e in entriesList) {
    grouped.putIfAbsent(e.date, () => []).add(e);
  }

  final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  final List<dynamic> flattened = [];

  for (var dateStr in sortedDates) {
    flattened.add(dateStr); // Header
    flattened.addAll(grouped[dateStr]!); // Entries
  }

  return flattened;
}

Widget _buildTimelineHeader(ThemeData theme, String dateStr) {
  final parsedDate = DateTime.tryParse(dateStr);
  String headerText = dateStr;
  if (parsedDate != null) {
    if (TimeUtil.isToday(dateStr)) {
      headerText = "Today";
    } else {
      headerText = TimeUtil.formatReadableDate(parsedDate);
    }
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.sm),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            headerText.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
      ],
    ),
  );
}

class AllAchievementsPopup extends StatefulWidget {
  final List<AchievementEntry> entries;
  final bool use24Hour;

  const AllAchievementsPopup({
    super.key,
    required this.entries,
    required this.use24Hour,
  });

  static Future<void> show(
    BuildContext context,
    List<AchievementEntry> entries,
    bool use24Hour,
  ) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'All Achievements',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return AllAchievementsPopup(entries: entries, use24Hour: use24Hour);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(anim1),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AllAchievementsPopup> createState() => _AllAchievementsPopupState();
}

class _AllAchievementsPopupState extends State<AllAchievementsPopup> {
  String _filter = 'ALL';

  Widget _buildFilterChip(ThemeData theme, String value, String label) {
    final isSelected = _filter == value;
    return ActionChip(
      label: Text(label),
      onPressed: () => setState(() => _filter = value),
      backgroundColor: isSelected
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    final filtered = widget.entries.where((e) {
      if (_filter == 'DAILY') return e.type == 'DAILY';
      if (_filter == 'CHALLENGE') return e.type == 'CHALLENGE';
      return true;
    }).toList();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Container(
              width: isMobile ? double.infinity : 750,
              height: isMobile
                  ? double.infinity
                  : MediaQuery.of(context).size.height * 0.8,
              margin: EdgeInsets.all(isMobile ? 0 : AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(isMobile ? 0 : 24),
                border: isMobile
                    ? null
                    : Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        width: 1,
                      ),
                boxShadow: isMobile
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "ALL ACHIEVEMENTS",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                    ).copyWith(bottom: 2),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(theme, 'ALL', 'All'),
                          const SizedBox(width: 8),
                          _buildFilterChip(theme, 'DAILY', 'Daily Logs'),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            theme,
                            'CHALLENGE',
                            'Challenge Logs',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              "No achievements match this filter.",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              final flattened = _getFlattenedTimeline(filtered);
                              return ListView.builder(
                                padding: const EdgeInsets.all(24),
                                itemCount: flattened.length,
                                itemBuilder: (context, index) {
                                  final item = flattened[index];
                                  if (item is String) {
                                    return _buildTimelineHeader(theme, item);
                                  } else if (item is AchievementEntry) {
                                    return _buildAchievementCard(
                                      theme,
                                      item,
                                      context,
                                      widget.use24Hour,
                                      isPopup: true,
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
