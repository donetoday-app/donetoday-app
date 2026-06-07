import 'dart:ui';
import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/providers/logs/logs_notifier.dart';
import 'package:done_today/providers/challenges/challenges_notifier.dart';
import 'package:done_today/state/logs/logs_state.dart';
import 'package:done_today/state/challenges/challenges_state.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/ui/widgets/logs/log_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GlobalSearchPopup extends ConsumerStatefulWidget {
  const GlobalSearchPopup({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const GlobalSearchPopup();
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
  ConsumerState<GlobalSearchPopup> createState() => _GlobalSearchPopupState();
}

class _GlobalSearchPopupState extends ConsumerState<GlobalSearchPopup> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logState = ref.watch(logsNotifierProvider);
    final challengeState = ref.watch(challengesNotifierProvider);

    final results = _performSearch(logState, challengeState);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Container(
              width: 700,
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.04,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              onChanged: (val) => setState(() => _query = val),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: "Search logs, challenges...",
                                hintStyle: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.3),
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                                suffixIcon: _query.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _query = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.onSurface
                                .withOpacity(0.04),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Results Area
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    child: _query.isEmpty
                        ? _buildInitialState(theme)
                        : _buildResultsList(theme, results),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<dynamic> _performSearch(
    LogsState logState,
    ChallengesState challengeState,
  ) {
    if (_query.isEmpty) return [];

    final q = _query.toLowerCase();
    final List<dynamic> results = [];

    if (logState is LogsLoaded) {
      final filteredLogs = logState.logs.where((log) {
        return log.title.toLowerCase().contains(q) ||
            log.description.toLowerCase().contains(q);
      }).toList();
      results.addAll(filteredLogs);
    }

    if (challengeState is ChallengesLoaded) {
      for (final logs in challengeState.challengeLogs.values) {
        final filteredLogs = logs.where((log) {
          return log.title.toLowerCase().contains(q) ||
              log.description.toLowerCase().contains(q);
        }).toList();
        results.addAll(filteredLogs);
      }
    }

    results.sort((a, b) {
      final dateA = a is Log ? a.date : (a as Log).date;
      final dateB = b is Log ? b.date : (b as Log).date;
      return dateB.compareTo(dateA);
    });

    return results;
  }

  Widget _buildInitialState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.explore_rounded,
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "QUICK SEARCH",
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              letterSpacing: 4.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(ThemeData theme, List<dynamic> results) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          "NO MATCHES FOUND",
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            letterSpacing: 2.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];

        if (item is Log) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LogCard(
              title: item.title,
              date: item.date,
              time: item.time,
              description: item.description,
              mood: item.mood,
              tags: item.tags,
              onTap: () {
                context.pop(); // Close popup
                context.push('/logs/${item.id}', extra: item);
              },
              wordCount: item.wordCount,
            ),
          );
        } else if (item is Log) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LogCard(
              title: item.title,
              date: item.date,
              time: item.time,
              description: item.description,
              mood: item.mood,
              tags: item.tags,
              onTap: () {
                context.pop(); // Close popup
                Challenge? challenge;
                final challengeState = ref.read(challengesNotifierProvider);
                if (challengeState is ChallengesLoaded) {
                  try {
                    challenge = challengeState.challenges.firstWhere(
                      (c) => c.id == item.challengeId,
                    );
                  } catch (_) {}
                }

                if (challenge != null) {
                  context.push(
                    '/challenges/${item.challengeId}/logs/${item.id}',
                    extra: {'log': item, 'challenge': challenge},
                  );
                } else {
                  context.push(
                    '/challenges/${item.challengeId}/logs/${item.id}',
                  );
                }
              },
              wordCount: item.wordCount,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
