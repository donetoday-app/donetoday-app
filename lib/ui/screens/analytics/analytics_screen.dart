import 'package:done_today/providers/logs/logs_notifier.dart';
import 'package:done_today/state/logs/logs_state.dart';
import 'package:done_today/providers/challenges/challenges_notifier.dart';
import 'package:done_today/state/challenges/challenges_state.dart';
import 'package:done_today/providers/settings/theme_notifier.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/services/analytics_service.dart';
import 'package:done_today/storage/models/activity_analytics.dart';
import 'package:done_today/theme/ui_constants.dart';
import 'package:done_today/utils/responsive_helper.dart';
import 'package:done_today/ui/widgets/analytics/analytics_header.dart';
import 'package:done_today/ui/widgets/analytics/overview_tab.dart';
import 'package:done_today/ui/widgets/analytics/log_analysis_tab.dart';
import 'package:done_today/ui/widgets/analytics/challenges_tab.dart';
import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  ActivityAnalytics? _analytics;
  bool _isLoading = true;
  String _selectedFilter = 'ALL';
  int _activeTabIndex = 0;
  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  DateTimeRange? _getDateTimeRangeForFilter(String filter) {
    final now = DateTime.now();
    if (filter == '7D') {
      return DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      );
    } else if (filter == '30D') {
      return DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      );
    }
    return null; // All Time
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final range = _getDateTimeRangeForFilter(_selectedFilter);
    final data = await AnalyticsService.generateAnalytics(range: range);

    if (!mounted) return;
    setState(() {
      _analytics = data;
      _isLoading = false;
    });
  }

  List<Log> _filterLogsForRange(List<Log> allLogs, String filter) {
    if (filter == 'ALL') return allLogs;
    final range = _getDateTimeRangeForFilter(filter);
    if (range == null) return allLogs;
    return allLogs.where((log) {
      try {
        final dt = DateTime.parse(log.date);
        return !dt.isBefore(range.start) && !dt.isAfter(range.end);
      } catch (_) {
        return true;
      }
    }).toList();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.pixels <= 0) {
      if (!_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = true;
        });
      }
      return false;
    }

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        if (_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = false;
          });
        }
      } else if (notification.direction == ScrollDirection.forward) {
        if (!_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = true;
          });
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logsState = ref.watch(logsNotifierProvider);
    final challengesState = ref.watch(challengesNotifierProvider);

    final List<Log> logs = logsState is LogsLoaded ? logsState.logs : [];
    final List<Log> filteredLogs = _filterLogsForRange(logs, _selectedFilter);

    final List<Challenge> challenges = challengesState is ChallengesLoaded
        ? challengesState.challenges
        : [];
    final Map<String, List<Log>> challengeLogs =
        challengesState is ChallengesLoaded
        ? challengesState.challengeLogs
        : {};

    final use24Hour = ref.watch(themeNotifierProvider).use24HourFormat;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _analytics == null || _analytics!.totalLogs == 0
            ? _buildEmptyState(theme)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collapsible / Fixed Premium Editorial Header
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    height: _isHeaderVisible ? 85.0 : 0.0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isHeaderVisible ? 1.0 : 0.0,
                      curve: Curves.easeInOut,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnalyticsHeader(
                              title: "MY ACTIVITY",
                              subtitle: logsState is LogsLoaded
                                  ? "${filteredLogs.length} moments mapped"
                                  : "Loading activity map...",
                              selectedFilter: _selectedFilter,
                              onFilterChanged: (filter) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                                _loadAnalytics();
                              },
                            ),
                            Container(
                              height: 1.0,
                              width: double.infinity,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.08,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Collapsible Segmented Tabs selector
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    height: _isHeaderVisible ? 57.0 : 0.0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isHeaderVisible ? 1.0 : 0.0,
                      curve: Curves.easeInOut,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTabBar(theme),
                            Container(
                              height: 1.0,
                              width: double.infinity,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.08,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Dynamic Tab Views
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _onScrollNotification,
                      child: RefreshIndicator(
                        onRefresh: _loadAnalytics,
                        child: ResponsiveConstraints(
                          maxWidth: ResponsiveHelper.maxFullWidth,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _buildSelectedTabContent(
                              filteredLogs: filteredLogs,
                              challenges: challenges,
                              challengeLogs: challengeLogs,
                              use24Hour: use24Hour,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    final tabs = [
      {'label': 'Overview', 'icon': Icons.dashboard_rounded},
      {'label': 'Log Insights', 'icon': Icons.article_rounded},
      {'label': 'Challenges', 'icon': Icons.emoji_events_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _activeTabIndex == index;
          final tab = tabs[index];
          return GestureDetector(
            onTap: () => setState(() => _activeTabIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(
                        theme.brightness == Brightness.dark ? 0.15 : 0.1,
                      )
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary.withOpacity(0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tab['icon'] as IconData,
                    size: 16,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedTabContent({
    required List<Log> filteredLogs,
    required List<Challenge> challenges,
    required Map<String, List<Log>> challengeLogs,
    required bool use24Hour,
  }) {
    switch (_activeTabIndex) {
      case 0:
        return OverviewTab(
          key: const ValueKey('overview_tab'),
          analytics: _analytics!,
          logs: filteredLogs,
        );
      case 1:
        return LogAnalysisTab(
          key: const ValueKey('log_analysis_tab'),
          analytics: _analytics!,
          logs: filteredLogs,
          use24Hour: use24Hour,
        );
      case 2:
        return ChallengesTab(
          key: const ValueKey('challenges_tab'),
          analytics: _analytics!,
          challenges: challenges,
          challengeLogs: challengeLogs,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "NO DATA YET",
            style: theme.textTheme.titleMedium?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Start logging your wins to see insights.",
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
