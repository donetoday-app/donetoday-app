import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/ui/widgets/section_header.dart';
import 'package:done_today/ui/widgets/dashboard/challenge_stats.dart';
import 'package:done_today/providers/challenges/challenges_notifier.dart';
import 'package:done_today/state/challenges/challenges_state.dart';
import 'package:done_today/ui/widgets/dashboard/active_challenges_slider.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/providers/auth/auth_notifier.dart';
import 'package:done_today/providers/logs/logs_notifier.dart';
import 'package:done_today/state/logs/logs_state.dart';
import 'package:done_today/storage/models/log_stats_model.dart';
import 'package:done_today/ui/widgets/dashboard/greeting.dart';
import 'package:done_today/ui/widgets/dashboard/recent_logs.dart';
import 'package:done_today/ui/widgets/dashboard/stats.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:go_router/go_router.dart';
import 'package:done_today/providers/settings/theme_notifier.dart';
import 'package:done_today/storage/hive/hive_service.dart';
import 'package:done_today/services/update_service.dart';
import 'package:done_today/ui/widgets/update_dialogs.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<String> _widgetOrder = [
    'daily_logs',
    'challenges_stats',
    'active_challenges',
  ];

  @override
  void initState() {
    super.initState();
    _loadWidgetOrder();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await UpdateService.checkForUpdates();
    if (updateInfo != null && mounted) {
      if (updateInfo.type == UpdateType.major) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => MajorUpdateDialog(updateInfo: updateInfo),
        );
      } else if (updateInfo.type == UpdateType.minor) {
        showDialog(
          context: context,
          builder: (context) => MinorUpdateDialog(updateInfo: updateInfo),
        );
      }
    }
  }

  void _loadWidgetOrder() {
    final savedOrder = HiveService.get<List<dynamic>>(
      'settings',
      'dashboard_widget_order_v2',
    );
    if (savedOrder != null) {
      setState(() {
        _widgetOrder = savedOrder.map((e) => e.toString()).toList();
      });
    }
  }

  Future<void> _saveWidgetOrder() async {
    await HiveService.put<List<String>>(
      'settings',
      'dashboard_widget_order_v2',
      _widgetOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logState = ref.watch(logsNotifierProvider);
    final challengeState = ref.watch(challengesNotifierProvider);
    final logsProvider = ref.read(logsNotifierProvider.notifier);
    final use24Hour = ref.watch(themeNotifierProvider).use24HourFormat;

    List<Log> logs = [];
    LogStats? stats;
    String? errorMessage;

    if (logState is LogsLoaded) {
      logs = logState.logs;
      stats = logState.stats;
    } else if (logState is LogsError) {
      errorMessage = logState.message;
    }

    final List<Challenge> activeChallenges = challengeState is ChallengesLoaded
        ? challengeState.challenges
        : [];
    final Map<String, List<Log>> challengeLogs =
        challengeState is ChallengesLoaded ? challengeState.challengeLogs : {};

    if (logs.isEmpty &&
        (logState is LogsInitial ||
            (logState is LogsLoading && stats == null))) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null && logs.isEmpty) {
      return Scaffold(body: Center(child: Text(errorMessage)));
    }

    final today = TimeUtil.todayIso();
    final todayLogs = logs.where((l) => l.date == today).toList();
    final hasToday = todayLogs.isNotEmpty;
    final user = ref.watch(authNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await logsProvider.fetchInitialData();
            await ref
                .read(challengesNotifierProvider.notifier)
                .fetchInitialData();
          },
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.screenPadding,
                  child: ResponsiveConstraints(
                    maxWidth: ResponsiveHelper.maxFullWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        greeting(context, theme, user, hasToday),
                        // Divider line below greeting
                        Container(
                          height: 1.0,
                          width: double.infinity,
                          color: theme.colorScheme.onSurface.withOpacity(0.08),
                        ),

                        // Reorderable Dashboard Items list
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          onReorder: (int oldIndex, int newIndex) {
                            setState(() {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final String item = _widgetOrder.removeAt(
                                oldIndex,
                              );
                              _widgetOrder.insert(newIndex, item);
                              _saveWidgetOrder();
                            });
                          },
                          children: _widgetOrder.map((key) {
                            return _buildDashboardWidget(
                              key,
                              theme,
                              stats,
                              activeChallenges,
                              challengeLogs,
                              logs,
                              use24Hour,
                            );
                          }).toList(),
                        ),
                        RecentAchievements(theme, use24Hour: use24Hour),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardWidget(
    String key,
    ThemeData theme,
    LogStats? stats,
    List<Challenge> activeChallenges,
    Map<String, List<Log>> challengeLogs,
    List<Log> logs,
    bool use24Hour,
  ) {
    switch (key) {
      case 'daily_logs':
        return Container(
          key: const ValueKey('daily_logs'),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: SectionHeader(title: "Daily Logs Stats"),
                  ),
                  ReorderableDragStartListener(
                    index: _widgetOrder.indexOf('daily_logs'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.35),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Stats(theme, stats),
            ],
          ),
        );
      case 'challenges_stats':
        return Container(
          key: const ValueKey('challenges_stats'),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: SectionHeader(title: "Challenge Logs Stats"),
                  ),
                  ReorderableDragStartListener(
                    index: _widgetOrder.indexOf('challenges_stats'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.35),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ChallengeStats(theme, activeChallenges, challengeLogs),
            ],
          ),
        );
      case 'active_challenges':
        return Container(
          key: const ValueKey('active_challenges'),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: SectionHeader(title: "Active Challenges"),
                  ),
                  ReorderableDragStartListener(
                    index: _widgetOrder.indexOf('active_challenges'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.35),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ActiveChallengesSlider(
                challenges: activeChallenges,
                challengeLogs: challengeLogs,
                onChallengeTap: (c) => context.push('/challenges/${c.id}'),
                onLog: (c) =>
                    context.push('/challenges/${c.id}/logs/new', extra: c),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink(key: ValueKey('empty'));
    }
  }
}
