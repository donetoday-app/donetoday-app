import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/providers/logs/logs_notifier.dart';
import 'package:done_today/state/logs/logs_state.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/ui/widgets/app_dialog.dart';
import 'package:done_today/ui/widgets/logs/log_card.dart';
import 'package:done_today/ui/widgets/action_button.dart';
import 'package:done_today/ui/widgets/section_header.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:done_today/providers/settings/theme_notifier.dart';
import 'package:flutter/gestures.dart';

enum LogSortOrder { recent, oldest, modified }

class MyLogScreen extends ConsumerStatefulWidget {
  const MyLogScreen({super.key});

  @override
  ConsumerState<MyLogScreen> createState() => _MyLogScreenState();
}

class _MyLogScreenState extends ConsumerState<MyLogScreen> {
  String _moodFilter = 'All';
  LogSortOrder _sortOrder = LogSortOrder.recent;
  late final ScrollController _scrollController;
  late final ScrollController _filterScrollController;
  bool _isFabVisible = true;
  bool _isHeaderVisible = true;

  LogsState? _lastState;
  String? _lastMoodFilter;
  LogSortOrder? _lastSortOrder;
  List<Log> _cachedFilteredLogs = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _filterScrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final double offset = _scrollController.offset;
    if (offset <= 0) {
      if (!_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = true;
        });
      }
      if (!_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
      }
      return;
    }

    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = false;
        });
      }
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = true;
        });
      }
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
    final state = ref.watch(logsNotifierProvider);
    final themeState = ref.watch(themeNotifierProvider);

    final filteredLogs = _filterAndSortLogs(state);
    final hasToday =
        state is LogsLoaded &&
        state.logs.any((l) => l.date == TimeUtil.todayIso());

    return Scaffold(
      body: SafeArea(
        child: ResponsiveConstraints(
          maxWidth: ResponsiveHelper.isDesktop(context)
              ? ResponsiveHelper.maxFullWidth
              : ResponsiveHelper.maxContentWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                height: _isHeaderVisible ? 62.0 : 0.0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isHeaderVisible ? 1.0 : 0.0,
                  curve: Curves.easeInOut,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        AppSpacing.xs,
                        AppSpacing.screenHorizontal,
                        AppSpacing.xs,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "MY JOURNEY",
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.8,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state is LogsLoaded
                                      ? "${state.logs.length} moments recorded"
                                      : "Syncing your story...",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.65),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/logs/book'),
                            child: Container(
                              height: 46,
                              width: 46,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.06,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.15,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.auto_stories_rounded,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                            ),
                          ),
                          _buildSortButton(theme),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Full-width bottom border line
              Container(
                height: 1.0,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                color: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
              _buildMoodFilters(theme),
              Expanded(child: _buildBody(theme, state, filteredLogs)),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: themeState.useFloatingNavBar ? 85 : 0),
        child: AnimatedScale(
          scale: _isFabVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: CustomFloatingActionButton(isLogged: hasToday),
        ),
      ),
    );
  }

  List<Log> _filterAndSortLogs(LogsState state) {
    if (state is! LogsLoaded) return [];

    if (_lastState == state &&
        _lastMoodFilter == _moodFilter &&
        _lastSortOrder == _sortOrder) {
      return _cachedFilteredLogs;
    }

    _lastState = state;
    _lastMoodFilter = _moodFilter;
    _lastSortOrder = _sortOrder;

    final filtered = state.logs.where((log) {
      // Handle mood matching (logs might store "happy", filter is "happy 😊")
      final moodMatch =
          _moodFilter == 'All' ||
          (log.mood != null &&
              _moodFilter.toLowerCase().contains(log.mood!.toLowerCase()));

      return moodMatch;
    }).toList();

    switch (_sortOrder) {
      case LogSortOrder.recent:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case LogSortOrder.oldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case LogSortOrder.modified:
        filtered.sort(
          (a, b) => (b.updatedAt ?? b.date).compareTo(a.updatedAt ?? a.date),
        );
        break;
    }

    _cachedFilteredLogs = filtered;
    return filtered;
  }

  Widget _buildSortButton(ThemeData theme) {
    return PopupMenuButton<LogSortOrder>(
      initialValue: _sortOrder,
      onSelected: (order) => setState(() => _sortOrder = order),
      offset: const Offset(0, 52),
      icon: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.tune_rounded, // Changed to more modern 'tune' icon
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          size: 18,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: LogSortOrder.recent,
          child: Text("Most Recent"),
        ),
        const PopupMenuItem(
          value: LogSortOrder.oldest,
          child: Text("Oldest First"),
        ),
      ],
    );
  }

  Widget _buildMoodFilters(ThemeData theme) {
    final moods = [
      'All',
      "happy 😊",
      "sad 😞",
      "excited 😆",
      "angry 😡",
      "normal 🙂",
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            final double delta = pointerSignal.scrollDelta.dy;
            if (delta != 0) {
              final double newOffset = (_filterScrollController.offset + delta)
                  .clamp(0.0, _filterScrollController.position.maxScrollExtent);
              _filterScrollController.animateTo(
                newOffset,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
              );
            }
          }
        },
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: ListView.builder(
            controller: _filterScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            itemCount: moods.length,
            itemBuilder: (context, index) {
              final mood = moods[index];
              final isSelected = _moodFilter == mood;

              final String label;
              final String emoji;
              if (mood == 'All') {
                label = 'ALL';
                emoji = '✨';
              } else {
                final parts = mood.split(' ');
                label = parts[0].toUpperCase();
                emoji = parts.length > 1 ? parts[1] : '•';
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _moodFilter = mood),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.08),
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.25,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.8,
                                    ),
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              letterSpacing: 0.8,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, LogsState state, List<Log> filteredLogs) {
    bool isLoading = false;
    String? errorMessage;

    if (state is LogsLoading || state is LogsInitial) {
      isLoading = true;
    } else if (state is LogsError) {
      errorMessage = state.message;
    }

    if (filteredLogs.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && filteredLogs.isEmpty) {
      return Center(child: Text(errorMessage));
    }

    if (filteredLogs.isEmpty && !isLoading) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.xs, // Reduced to xs
        AppSpacing.screenHorizontal,
        AppSpacing.xl,
      ),
      itemCount: filteredLogs.length,
      itemBuilder: (context, i) {
        final log = filteredLogs[i];
        return LogCard(
          title: log.title,
          date: log.date,
          time: log.time,
          description: log.description,
          mood: log.mood,
          tags: log.tags,
          wordCount: log.wordCount,
          onTap: () => context.push('/logs/${log.id}'),
          onEdit: () => context.push('/logs/edit/${log.id}'),
          onDelete: () => _confirmDelete(log.id, ref, log),
        );
      },
    );
  }

  Future<void> _confirmDelete(String logId, WidgetRef ref, Log log) async {
    await AppDialog.show(
      context: context,
      title: "Delete Log",
      isDestructive: true,
      confirmLabel: "Delete",
      content: Text(
        "Are you sure you want to delete this memory? This action cannot be undone.",
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
      ),
      onConfirm: () {
        context.pop();
        ref.read(logsNotifierProvider.notifier).deleteLog(logId);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 32),
            const SectionHeader(
              title: "NO RECORDS FOUND",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Your journey is waiting to be written. Try a different filter or search.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
