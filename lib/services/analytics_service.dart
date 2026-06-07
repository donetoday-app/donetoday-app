import 'package:done_today/storage/hive/hive_service.dart';
import 'package:done_today/storage/models/activity_analytics.dart';
import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/storage/models/daily_meta_log.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  /// Generates complete analytics. Use `range` for specific periods.
  static Future<ActivityAnalytics> generateAnalytics({
    DateTimeRange? range,
  }) async {
    // Load raw data
    final List<Map<String, dynamic>> rawLogs =
        await HiveService.getAllLogsAsync();
    final List<Map<String, dynamic>> rawChallenges =
        await HiveService.getAllChallenges();

    final List<Log> allLogs = rawLogs.map((m) => Log.fromJson(m)).toList();
    final List<DailyMetaLog> allMeta = _generateMetaFromLogs(allLogs);

    final List<Challenge> allChallenges = rawChallenges
        .map((m) => Challenge.fromJson(m))
        .toList();

    if (allLogs.isEmpty && allMeta.isEmpty && allChallenges.isEmpty) {
      return ActivityAnalytics.initial();
    }

    // Filter by date range
    final List<Log> filteredLogs = _filterLogsByRange(allLogs, range);
    final List<DailyMetaLog> filteredMeta = _filterMetaByRange(allMeta, range);

    final totalDaysInRange = range != null
        ? range.end.difference(range.start).inDays + 1
        : _calculateTotalDays(allMeta, allLogs);

    final totalLogs = filteredLogs.length;
    int uniqueDaysLogged = filteredMeta
        .where((m) => m.hasDailyLog || m.isCompleted)
        .length;

    // Fallback if meta is empty but logs exist
    if (uniqueDaysLogged == 0 && filteredLogs.isNotEmpty) {
      uniqueDaysLogged = filteredLogs.map((l) => l.date).toSet().length;
    }

    final consistencyRate = totalDaysInRange > 0
        ? (uniqueDaysLogged / totalDaysInRange) * 100
        : 0.0;

    final streaks = _calculateStreaks(filteredMeta);
    final challengeStats = _calculateChallengeStats(filteredMeta);

    // Advanced Challenge Analytics
    final totalActiveChallenges = allChallenges.length;
    double avgChallengeProgress = 0;
    if (allChallenges.isNotEmpty) {
      double totalProgressSum = 0;
      for (var c in allChallenges) {
        final cLogs = allLogs.where((l) => l.challengeId == c.id).toList();
        totalProgressSum += (cLogs.length / c.totalDays).clamp(0.0, 1.0);
      }
      avgChallengeProgress = totalProgressSum / allChallenges.length;
    }
    final challengeCategoryInsights = _analyzeChallengeCategories(
      allChallenges,
    );

    // Basic time patterns (Free)
    final logsByDayOfWeek = _calculateLogsByDayOfWeek(filteredLogs);
    final monthlyTrend = _calculateMonthlyTrend(filteredLogs);

    // Simple quality metrics
    final avgWordCount = _calculateAverageWordCount(filteredLogs);
    final avgReadTime = _calculateAverageReadTime(filteredLogs);

    final momentumScore = _calculateMomentumScore(filteredMeta);
    final weekdayPerformance = _calculateWeekdayPerformance(filteredMeta);
    final recoveryRate = _calculateRecoveryRate(filteredMeta);
    final lateEntryImpact = _calculateLateEntryImpact(filteredMeta);
    final bestTimeToLog = _findBestLoggingHour(filteredLogs);

    // Content depth
    final categoryInsights = _analyzeCategories(filteredLogs);
    final tagCloud = _analyzeTags(filteredLogs);
    final moodInsights = _analyzeMoodDistribution(filteredLogs);
    final advancedPatterns = _calculateAdvancedPatterns(
      filteredMeta,
      filteredLogs,
    );

    return ActivityAnalytics(
      // Free Fields
      totalLogs: totalLogs,
      totalDaysLogged: uniqueDaysLogged,
      loggingConsistency: consistencyRate,
      currentStreak: streaks.current,
      longestStreak: streaks.longest,
      monthlyTrend: monthlyTrend,
      logsByDayOfWeek: logsByDayOfWeek,
      avgWordCount: avgWordCount,
      avgReadTime: avgReadTime,

      challengeParticipationRate: challengeStats.participationRate,
      totalActiveChallenges: totalActiveChallenges,
      avgChallengeProgress: avgChallengeProgress,
      challengeCategoryInsights: challengeCategoryInsights,

      momentumScore: momentumScore,
      weekdayPerformance: weekdayPerformance,
      recoveryRate: recoveryRate,
      lateEntryRate: lateEntryImpact.lateRate,
      bestLoggingHour: bestTimeToLog,
      categoryInsights: categoryInsights,
      topTags: tagCloud,
      moodInsights: moodInsights,
      advancedPatterns: advancedPatterns,
      generatedAt: DateTime.now(),
    );
  }

  // ====================== HELPER METHODS ======================

  static List<Log> _filterLogsByRange(List<Log> logs, DateTimeRange? range) {
    if (range == null) return logs;
    return logs.where((log) {
      final dt = log.parsedDate;
      return !dt.isBefore(range.start) && !dt.isAfter(range.end);
    }).toList();
  }

  static List<DailyMetaLog> _generateMetaFromLogs(List<Log> logs) {
    final Map<String, List<Log>> logsByDate = {};
    for (var log in logs) {
      logsByDate.putIfAbsent(log.date, () => []).add(log);
    }

    return logsByDate.entries.map((entry) {
      final date = entry.key;
      final dayLogs = entry.value;

      final challengeLogs = dayLogs
          .where((l) => l.challengeId != null)
          .toList();
      final activeChallenges = challengeLogs.map((l) => l.challengeId!).toSet();

      return DailyMetaLog(
        id: date,
        date: date,
        challengeLogIds: challengeLogs.map((l) => l.id).toList(),
        isCompleted: dayLogs.isNotEmpty,
        totalLogsCount: dayLogs.length,
        activeChallengesCount: activeChallenges.length,
        hasDailyLog: dayLogs.any((l) => l.challengeId == null),
        dailyLogId: null,
        isMissed: false,
        isLateEntry: false,
        createdAt: DateTime.tryParse(date) ?? DateTime.now(),
        updatedAt: DateTime.tryParse(date) ?? DateTime.now(),
      );
    }).toList();
  }

  static List<DailyMetaLog> _filterMetaByRange(
    List<DailyMetaLog> meta,
    DateTimeRange? range,
  ) {
    if (range == null) return meta;
    return meta.where((m) {
      final dt = m.parsedDate;
      return !dt.isBefore(range.start) && !dt.isAfter(range.end);
    }).toList();
  }

  static int _calculateTotalDays(List<DailyMetaLog> meta, List<Log> logs) {
    if (meta.isEmpty && logs.isEmpty) return 1;

    final List<DateTime> dates = [];
    if (meta.isNotEmpty) {
      dates.addAll(meta.map((m) => m.parsedDate));
    }
    if (logs.isNotEmpty) {
      dates.addAll(logs.map((l) => l.parsedDate));
    }

    if (dates.isEmpty) return 1;
    dates.sort();
    return dates.last.difference(dates.first).inDays + 1;
  }

  // ------------------- Analytics Helpers -------------------
  static Map<String, int> _calculateLogsByDayOfWeek(List<Log> logs) {
    final map = <String, int>{
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };
    final formatter = DateFormat('EEE');
    for (var log in logs) {
      final day = formatter.format(log.parsedDate);
      if (map.containsKey(day)) {
        map[day] = map[day]! + 1;
      }
    }
    return map;
  }

  static Map<String, int> _calculateMonthlyTrend(List<Log> logs) {
    final map = <String, int>{};
    final formatter = DateFormat('yyyy-MM');
    for (var log in logs) {
      final key = formatter.format(log.parsedDate);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  static double _calculateAverageWordCount(List<Log> logs) => logs.isEmpty
      ? 0
      : logs.fold(0, (sum, l) => sum + (l.wordCount)) / logs.length;

  static double _calculateAverageReadTime(List<Log> logs) => logs.isEmpty
      ? 0
      : logs.fold(0.0, (sum, l) => sum + (l.readTime)) / logs.length;

  static ChallengeStats _calculateChallengeStats(List<DailyMetaLog> meta) {
    int totalLogs = 0;
    int completedDays = 0;

    for (var m in meta) {
      totalLogs += m.challengeLogIds.length;
      if (m.isCompleted) completedDays++;
    }

    return ChallengeStats(
      totalLogs: totalLogs,
      participationRate: meta.isEmpty ? 0.0 : completedDays / meta.length,
    );
  }

  static double _calculateMomentumScore(List<DailyMetaLog> meta) {
    if (meta.isEmpty) return 0.0;
    final sorted = List<DailyMetaLog>.from(meta)
      ..sort((a, b) => a.date.compareTo(b.date));
    double score = 0.0;
    double alpha = 0.2;
    for (var m in sorted) {
      final dayScore = m.isCompleted
          ? 100.0
          : m.isMissed
          ? 0.0
          : 40.0;
      score = (alpha * dayScore) + ((1 - alpha) * score);
    }
    return score;
  }

  static Map<String, double> _calculateWeekdayPerformance(
    List<DailyMetaLog> meta,
  ) {
    final map = <String, int>{
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };
    final countMap = Map<String, int>.from(map);
    final formatter = DateFormat('EEE');
    for (var m in meta) {
      final day = formatter.format(m.parsedDate);
      if (countMap.containsKey(day)) {
        countMap[day] = countMap[day]! + 1;
        if (m.isCompleted) map[day] = map[day]! + 1;
      }
    }
    return map.map(
      (key, completed) => MapEntry(
        key,
        countMap[key]! > 0 ? (completed / countMap[key]!) * 100 : 0.0,
      ),
    );
  }

  static double _calculateRecoveryRate(List<DailyMetaLog> meta) {
    if (meta.length < 2) return 0.0;
    final sorted = List<DailyMetaLog>.from(meta)
      ..sort((a, b) => a.date.compareTo(b.date));
    int missedDays = 0;
    int recovered = 0;
    for (int i = 0; i < sorted.length - 1; i++) {
      if (sorted[i].isMissed) {
        missedDays++;
        for (int j = i + 1; j < (i + 4).clamp(0, sorted.length); j++) {
          if (sorted[j].isCompleted) {
            recovered++;
            break;
          }
        }
      }
    }
    return missedDays == 0 ? 100.0 : (recovered / missedDays) * 100;
  }

  static LateEntryImpact _calculateLateEntryImpact(List<DailyMetaLog> meta) {
    int lateCount = 0;
    int completedCount = 0;
    for (var m in meta) {
      if (m.isCompleted) completedCount++;
      if (m.isLateEntry) lateCount++;
    }
    return LateEntryImpact(
      lateRate: completedCount > 0 ? (lateCount / completedCount) * 100 : 0.0,
      impactOnStreak: 0.0,
    );
  }

  static String _findBestLoggingHour(List<Log> logs) {
    if (logs.isEmpty) return "N/A";
    final hourCount = <int, int>{};
    for (var log in logs) {
      if (log.time.isNotEmpty) {
        final hour = int.tryParse(log.time.split(':').first) ?? 12;
        hourCount[hour] = (hourCount[hour] ?? 0) + 1;
      }
    }
    if (hourCount.isEmpty) return "N/A";
    final bestHour = hourCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    return "$bestHour:00";
  }

  static Map<String, double> _analyzeCategories(List<Log> logs) {
    final counts = <String, int>{};
    for (var log in logs) {
      if (log.category != null) {
        counts[log.category!] = (counts[log.category!] ?? 0) + 1;
      }
    }
    final total = counts.values.fold(0, (a, b) => a + b);
    return counts.map((k, v) => MapEntry(k, total > 0 ? v / total * 100 : 0));
  }

  static List<TagCount> _analyzeTags(List<Log> logs) {
    final counts = <String, int>{};
    for (var log in logs) {
      if (log.tags != null) {
        for (var tag in log.tags!) {
          counts[tag] = (counts[tag] ?? 0) + 1;
        }
      }
    }
    return counts.entries
        .map((e) => TagCount(tag: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  static Map<String, double> _analyzeMoodDistribution(List<Log> logs) {
    final counts = <String, int>{};
    for (var log in logs) {
      if (log.mood != null && log.mood!.isNotEmpty) {
        counts[log.mood!] = (counts[log.mood!] ?? 0) + 1;
      }
    }
    final total = counts.values.fold(0, (a, b) => a + b);
    return counts.map((k, v) => MapEntry(k, total > 0 ? v / total : 0));
  }

  static Map<String, dynamic> _calculateAdvancedPatterns(
    List<DailyMetaLog> meta,
    List<Log> logs,
  ) {
    return {
      'consistencyTrend': 'Stable',
      'favouriteWritingTime': 'Morning',
      'topMood': 'Inspired',
    };
  }

  static _StreakResult _calculateStreaks(List<DailyMetaLog> meta) {
    if (meta.isEmpty) return const _StreakResult(0, 0);
    final sorted = List<DailyMetaLog>.from(meta)
      ..sort((a, b) => a.date.compareTo(b.date));
    int longest = 0, temp = 0;
    for (var m in sorted) {
      if (m.isCompleted) {
        temp++;
        if (temp > longest) longest = temp;
      } else {
        temp = 0;
      }
    }
    int current = 0;
    if (sorted.isNotEmpty) {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final yesterdayStr = DateFormat(
        'yyyy-MM-dd',
      ).format(now.subtract(const Duration(days: 1)));

      // Find the latest completed day
      int latestIdx = -1;
      for (int i = sorted.length - 1; i >= 0; i--) {
        if (sorted[i].isCompleted) {
          if (sorted[i].date == todayStr || sorted[i].date == yesterdayStr) {
            latestIdx = i;
          }
          break;
        }
      }

      if (latestIdx != -1) {
        DateTime checkDate = sorted[latestIdx].parsedDate;
        for (int i = latestIdx; i >= 0; i--) {
          final m = sorted[i];
          final mDate = m.parsedDate;
          if (m.isCompleted && mDate.isAtSameMomentAs(checkDate)) {
            current++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else if (mDate.isBefore(checkDate)) {
            break;
          }
        }
      }
    }
    return _StreakResult(current, longest);
  }

  static Map<String, double> _analyzeChallengeCategories(
    List<Challenge> challenges,
  ) {
    if (challenges.isEmpty) return {};
    final counts = <String, int>{};
    for (var c in challenges) {
      counts[c.category] = (counts[c.category] ?? 0) + 1;
    }
    final total = challenges.length;
    return counts.map((k, v) => MapEntry(k, v / total * 100));
  }
}

class ChallengeStats {
  final int totalLogs;
  final double participationRate;
  const ChallengeStats({
    required this.totalLogs,
    required this.participationRate,
  });
}

class LateEntryImpact {
  final double lateRate;
  final double impactOnStreak;
  const LateEntryImpact({required this.lateRate, required this.impactOnStreak});
}

class _StreakResult {
  final int current;
  final int longest;
  const _StreakResult(this.current, this.longest);
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;
  const DateTimeRange({required this.start, required this.end});
}
