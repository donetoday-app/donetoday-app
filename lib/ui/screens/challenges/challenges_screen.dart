import 'package:done_today/providers/challenges/challenges_notifier.dart';
import 'package:done_today/state/challenges/challenges_state.dart';
import 'package:done_today/theme/app_theme.dart';
import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/ui/widgets/app_dialog.dart';
import 'package:done_today/ui/widgets/custom_card.dart';
import 'package:done_today/ui/widgets/custom_popup.dart';
import 'package:done_today/ui/widgets/logs/category_picker.dart';
import 'package:done_today/ui/widgets/section_header.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:done_today/providers/settings/theme_notifier.dart';
import 'package:flutter/gestures.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  String _selectedFilter = 'All';
  late final ScrollController _scrollController;
  late final ScrollController _filterScrollController;
  bool _isFabVisible = true;
  bool _isHeaderVisible = true;

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

  Widget _buildFilterBar(ThemeData theme) {
    final filters = ['All', 'Active', 'Upcoming', 'Completed'];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
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
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = _selectedFilter == filter;

              final String emoji;
              switch (filter) {
                case 'All':
                  emoji = '🏆';
                  break;
                case 'Active':
                  emoji = '⚡';
                  break;
                case 'Upcoming':
                  emoji = '📅';
                  break;
                case 'Completed':
                  emoji = '✅';
                  break;
                default:
                  emoji = '🎯';
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
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
                            filter.toUpperCase(),
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

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(challengesNotifierProvider);
    final themeState = ref.watch(themeNotifierProvider);

    int displayCount = 0;
    if (state is ChallengesLoaded) {
      final nonDeleted = state.challenges.where((c) => !c.isDeleted).toList();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      displayCount = nonDeleted.where((challenge) {
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

        if (_selectedFilter == 'Active') return isActive;
        if (_selectedFilter == 'Upcoming') return isUpcoming;
        if (_selectedFilter == 'Completed') return isCompleted;
        return true;
      }).length;
    }

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
                height: _isHeaderVisible ? 68.0 : 0.0,
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
                        AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CHALLENGES",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state is ChallengesLoaded
                                ? "$displayCount ${_selectedFilter.toLowerCase()} challenges"
                                : "Loading your challenges...",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.65,
                              ),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Premium, clean full-width bottom border line
              Container(
                height: 1.0,
                width: double.infinity,
                color: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
              _buildFilterBar(theme),
              Expanded(child: _buildBody(theme, state)),
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
          child: FloatingActionButton.extended(
            onPressed: () => _showCreateChallengePopup(context),
            label: const Text("NEW CHALLENGE"),
            icon: const Icon(Icons.add_rounded),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ChallengesState state) {
    if (state is ChallengesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ChallengesError) {
      return Center(child: Text(state.message));
    }

    if (state is ChallengesLoaded) {
      final nonDeletedChallenges = state.challenges
          .where((c) => !c.isDeleted)
          .toList();

      if (nonDeletedChallenges.isEmpty) {
        return _buildEmptyState(theme, filter: 'All');
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final filteredChallenges = nonDeletedChallenges.where((challenge) {
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

        if (_selectedFilter == 'Active') {
          return isActive;
        } else if (_selectedFilter == 'Upcoming') {
          return isUpcoming;
        } else if (_selectedFilter == 'Completed') {
          return isCompleted;
        }
        return true; // 'All'
      }).toList();

      if (filteredChallenges.isEmpty) {
        return _buildEmptyState(theme, filter: _selectedFilter);
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.xs,
          AppSpacing.screenHorizontal,
          AppSpacing.xl,
        ),
        itemCount: filteredChallenges.length,
        itemBuilder: (context, index) {
          final challenge = filteredChallenges[index];
          return _ChallengeCard(challenge: challenge);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(ThemeData theme, {String filter = 'All'}) {
    String title = "NO CHALLENGES";
    String description =
        "Push your limits. Start a 7-day, 30-day, or custom challenge today.";

    if (filter == 'Active') {
      title = "NO ACTIVE CHALLENGES";
      description =
          "No challenges currently in progress. Start one now or check upcoming/completed.";
    } else if (filter == 'Upcoming') {
      title = "NO UPCOMING CHALLENGES";
      description =
          "All planned challenges have started. Plan a new future challenge today!";
    } else if (filter == 'Completed') {
      title = "NO COMPLETED CHALLENGES";
      description =
          "Finish an active challenge to see it marked as completed here!";
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.1),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: title, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateChallengePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateChallengePopup(),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  final Challenge challenge;
  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customColors = AppTheme.of(context);
    final state = ref.watch(challengesNotifierProvider);

    // Get logs for this specific challenge to calculate actual progress
    int logsCount = 0;
    if (state is ChallengesLoaded) {
      logsCount = state.challengeLogs[challenge.id]?.length ?? 0;
    }

    final total = challenge.totalDays;
    final progress = (logsCount / total).clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: CustomCard(
        padding: EdgeInsets.zero,
        borderRadius: 20,
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(color: theme.colorScheme.secondary),
              ),
              InkWell(
                onTap: () => context.push('/challenges/${challenge.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(
                                0.06,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              challenge.category.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          (() {
                            final now = DateTime.now();
                            final today = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
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

                            String label = 'ACTIVE';
                            Color bg = theme.colorScheme.primary.withOpacity(
                              0.12,
                            );
                            Color text = theme.colorScheme.primary;

                            if (isUpcoming) {
                              label = 'UPCOMING';
                              bg = customColors.info.withOpacity(0.12);
                              text = customColors.info;
                            } else if (isCompleted) {
                              label = 'COMPLETED';
                              bg = theme.colorScheme.onSurface.withOpacity(
                                0.08,
                              );
                              text = theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              );
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: text,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          })(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  challenge.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${TimeUtil.formatReadableDate(challenge.startDate)} — ${TimeUtil.formatReadableDate(challenge.endDate)}",
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showEditPopup(context),
                                icon: Icon(
                                  Icons.edit_rounded,
                                  size: 22,
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.8,
                                  ),
                                ),
                                style: IconButton.styleFrom(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                ),
                                tooltip: 'Edit Challenge',
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              IconButton(
                                onPressed: () => _confirmDelete(context, ref),
                                icon: Icon(
                                  Icons.delete_rounded,
                                  size: 22,
                                  color: customColors.error.withOpacity(0.8),
                                ),
                                style: IconButton.styleFrom(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                ),
                                tooltip: 'Delete Challenge',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: theme.colorScheme.onSurface
                                    .withOpacity(0.05),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "${(progress * 100).toInt()}%",
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateChallengePopup(challenge: challenge),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    await AppDialog.show(
      context: context,
      title: "Delete Challenge",
      isDestructive: true,
      confirmLabel: "Delete",
      content: const Text(
        "Deleting this challenge will also remove all associated daily logs. This cannot be undone.",
      ),
      onConfirm: () {
        context.pop();
        ref
            .read(challengesNotifierProvider.notifier)
            .deleteChallenge(challenge.id);
      },
    );
  }
}

class _CreateChallengePopup extends ConsumerStatefulWidget {
  final Challenge? challenge;
  const _CreateChallengePopup({this.challenge});

  @override
  ConsumerState<_CreateChallengePopup> createState() =>
      _CreateChallengePopupState();
}

class _CreateChallengePopupState extends ConsumerState<_CreateChallengePopup> {
  final _titleController = TextEditingController();
  String _category = 'Growth 🌱';
  DateTime _startDate = DateTime.now();
  int _duration = 7;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.challenge != null) {
      _titleController.text = widget.challenge!.title;
      _category = widget.challenge!.category;
      _startDate = widget.challenge!.startDate;
      _duration = widget.challenge!.totalDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.challenge != null;

    final challengesState = ref.watch(challengesNotifierProvider);

    int lifetimeCreatedCount = 0;
    int activeChallengesCount = 0;

    if (challengesState is ChallengesLoaded) {
      final nonDeleted = challengesState.challenges
          .where((c) => !c.isDeleted)
          .toList();
      lifetimeCreatedCount = nonDeleted.length;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      activeChallengesCount = nonDeleted.where((challenge) {
        if (isEditing && challenge.id == widget.challenge!.id) return false;

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
        return !isUpcoming && !isCompleted;
      }).length;
    }

    // Calculate end date based on start date and duration
    final calculatedEndDate = _startDate.add(Duration(days: _duration - 1));

    return CustomPopup(
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("CANCEL"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () {
                if (_titleController.text.trim().isEmpty) {
                  setState(() {
                    _errorMessage = "Please enter a challenge title.";
                  });
                  return;
                }

                // 1. Duplicate check locally in popup
                if (challengesState is ChallengesLoaded) {
                  final isDuplicate = challengesState.challenges.any(
                    (c) =>
                        (!isEditing || c.id != widget.challenge!.id) &&
                        c.title.trim().toUpperCase() ==
                            _titleController.text.trim().toUpperCase(),
                  );
                  if (isDuplicate) {
                    setState(() {
                      _errorMessage =
                          "A challenge with this title already exists!";
                    });
                    return;
                  }
                }

                // Apply limits for creation (lifetime limit for free users)
                if (!isEditing && lifetimeCreatedCount >= 3) {
                  setState(() {
                    _errorMessage =
                        "Free tier is limited to 3 lifetime challenges. Please upgrade to PRO for unlimited!";
                  });
                  return;
                }

                // Check each day in the selected challenge's duration for parallel conflicts
                if (challengesState is ChallengesLoaded) {
                  final nonDeleted = challengesState.challenges
                      .where((c) => !c.isDeleted)
                      .toList();

                  for (int i = 0; i < _duration; i++) {
                    final day = _startDate.add(Duration(days: i));
                    final dayNormalized = DateTime(
                      day.year,
                      day.month,
                      day.day,
                    );

                    int activeOnDay = 0;
                    for (final challenge in nonDeleted) {
                      if (isEditing && challenge.id == widget.challenge!.id)
                        continue;

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

                      final isActiveOnDay =
                          !dayNormalized.isBefore(start) &&
                          !dayNormalized.isAfter(end);
                      if (isActiveOnDay) {
                        activeOnDay++;
                      }
                    }

                    if (activeOnDay >= 1) {
                      setState(() {
                        _errorMessage = isEditing
                            ? "Free tier is limited to 1 active challenge at a time. Upgrade to PRO to schedule overlapping challenges!"
                            : "Free tier is limited to 1 active challenge at a time. Upgrade to PRO to schedule overlapping challenges!";
                      });
                      return;
                    }

                    if (activeOnDay >= 3) {
                      setState(() {
                        _errorMessage =
                            "You cannot have more than 3 active challenges running at the same time on ${TimeUtil.formatReadableDate(dayNormalized)}.";
                      });
                      return;
                    }
                  }
                }

                if (isEditing) {
                  ref
                      .read(challengesNotifierProvider.notifier)
                      .updateChallenge(
                        challengeId: widget.challenge!.id,
                        title: _titleController.text.trim(),
                        category: _category,
                        startDate: _startDate,
                        durationDays: _duration,
                      );
                } else {
                  ref
                      .read(challengesNotifierProvider.notifier)
                      .createChallenge(
                        title: _titleController.text.trim(),
                        category: _category,
                        startDate: _startDate,
                        durationDays: _duration,
                      );
                }
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isEditing ? "UPDATE" : "START"),
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? "EDIT CHALLENGE" : "NEW CHALLENGE",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEditing
                ? "Extend or shorten your challenge."
                : "Set a challenge and stick to it.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: theme.colorScheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: "CHALLENGE TITLE",
              hintText: "e.g. 30 DAYS OF YOGA",
            ),
            textCapitalization: TextCapitalization.characters,
            onChanged: (val) {
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
          ),
          const SizedBox(height: 20),
          _buildCategoryPicker(theme),
          const SizedBox(height: 20),
          Opacity(
            opacity: isEditing ? 0.6 : 1.0,
            child: AbsorbPointer(
              absorbing: isEditing,
              child: _buildStartDatePicker(theme),
            ),
          ),
          const SizedBox(height: 20),
          _buildEndDatePicker(theme, calculatedEndDate),
          const SizedBox(height: 20),
          _buildDurationInfo(theme),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CATEGORY",
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 8),
        CategoryPicker(
          selectedCategory: _category,
          onChanged: (v) => setState(() => _category = v!),
        ),
      ],
    );
  }

  Widget _buildStartDatePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "START DATE",
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) setState(() => _startDate = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18),
                const SizedBox(width: 12),
                Text(TimeUtil.formatReadableDate(_startDate)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndDatePicker(ThemeData theme, DateTime currentEndDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "END DATE",
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: currentEndDate,
              firstDate: _startDate.add(const Duration(days: 1)),
              lastDate: _startDate.add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _duration = date.difference(_startDate).inDays + 1;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  TimeUtil.formatReadableDate(currentEndDate),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationInfo(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "TOTAL DURATION",
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$_duration DAYS",
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
