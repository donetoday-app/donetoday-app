import 'package:flutter/foundation.dart';

@immutable
class ActivityAnalytics {
  // --- FREE FIELDS ---
  final int totalLogs;
  final int totalDaysLogged;
  final double loggingConsistency;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> monthlyTrend;
  final Map<String, int> logsByDayOfWeek;
  final double avgWordCount;
  final double avgReadTime;
  final double challengeParticipationRate;
  final int totalActiveChallenges;
  final double avgChallengeProgress;
  final Map<String, double> challengeCategoryInsights;

  final double momentumScore;
  final Map<String, double> weekdayPerformance;
  final double recoveryRate;
  final double lateEntryRate;
  final String bestLoggingHour;
  final Map<String, double> categoryInsights;
  final List<TagCount> topTags;
  final Map<String, double> moodInsights;
  final Map<String, dynamic>? advancedPatterns;

  final DateTime generatedAt;

  const ActivityAnalytics({
    required this.totalLogs,
    required this.totalDaysLogged,
    required this.loggingConsistency,
    required this.currentStreak,
    required this.longestStreak,
    required this.monthlyTrend,
    required this.logsByDayOfWeek,
    required this.avgWordCount,
    required this.avgReadTime,
    required this.challengeParticipationRate,
    required this.totalActiveChallenges,
    required this.avgChallengeProgress,
    required this.challengeCategoryInsights,
    required this.momentumScore,
    required this.weekdayPerformance,
    required this.recoveryRate,
    required this.lateEntryRate,
    required this.bestLoggingHour,
    required this.categoryInsights,
    required this.topTags,
    required this.moodInsights,
    this.advancedPatterns,
    required this.generatedAt,
  });

  factory ActivityAnalytics.initial() {
    return ActivityAnalytics(
      totalLogs: 0,
      totalDaysLogged: 0,
      loggingConsistency: 0.0,
      currentStreak: 0,
      longestStreak: 0,
      monthlyTrend: {},
      logsByDayOfWeek: {},
      avgWordCount: 0.0,
      avgReadTime: 0.0,
      challengeParticipationRate: 0.0,
      totalActiveChallenges: 0,
      avgChallengeProgress: 0.0,
      challengeCategoryInsights: {},
      momentumScore: 0.0,
      weekdayPerformance: {},
      recoveryRate: 0.0,
      lateEntryRate: 0.0,
      bestLoggingHour: "N/A",
      categoryInsights: {},
      topTags: [],
      moodInsights: {},
      generatedAt: DateTime.now(),
    );
  }

  factory ActivityAnalytics.fromJson(Map<String, dynamic> json) {
    return ActivityAnalytics(
      totalLogs: json['totalLogs'] ?? 0,
      totalDaysLogged: json['totalDaysLogged'] ?? 0,
      loggingConsistency: (json['loggingConsistency'] ?? 0.0).toDouble(),
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      monthlyTrend: Map<String, int>.from(json['monthlyTrend'] ?? {}),
      logsByDayOfWeek: Map<String, int>.from(json['logsByDayOfWeek'] ?? {}),
      avgWordCount: (json['avgWordCount'] ?? 0.0).toDouble(),
      avgReadTime: (json['avgReadTime'] ?? 0.0).toDouble(),
      challengeParticipationRate: (json['challengeParticipationRate'] ?? 0.0).toDouble(),
      totalActiveChallenges: json['totalActiveChallenges'] ?? 0,
      avgChallengeProgress: (json['avgChallengeProgress'] ?? 0.0).toDouble(),
      challengeCategoryInsights: Map<String, double>.from(json['challengeCategoryInsights'] ?? {}),
      momentumScore: (json['momentumScore'] ?? 0.0).toDouble(),
      weekdayPerformance: Map<String, double>.from(json['weekdayPerformance'] ?? {}),
      recoveryRate: (json['recoveryRate'] ?? 0.0).toDouble(),
      lateEntryRate: (json['lateEntryRate'] ?? 0.0).toDouble(),
      bestLoggingHour: json['bestLoggingHour'] ?? "N/A",
      categoryInsights: Map<String, double>.from(json['categoryInsights'] ?? {}),
      topTags: (json['topTags'] as List? ?? [])
          .map((e) => TagCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      moodInsights: Map<String, double>.from(json['moodInsights'] ?? {}),
      advancedPatterns: json['advancedPatterns'],
      generatedAt: DateTime.parse(json['generatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalLogs': totalLogs,
    'totalDaysLogged': totalDaysLogged,
    'loggingConsistency': loggingConsistency,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'monthlyTrend': monthlyTrend,
    'logsByDayOfWeek': logsByDayOfWeek,
    'avgWordCount': avgWordCount,
    'avgReadTime': avgReadTime,
    'challengeParticipationRate': challengeParticipationRate,
    'totalActiveChallenges': totalActiveChallenges,
    'avgChallengeProgress': avgChallengeProgress,
    'challengeCategoryInsights': challengeCategoryInsights,
    'momentumScore': momentumScore,
    'weekdayPerformance': weekdayPerformance,
    'recoveryRate': recoveryRate,
    'lateEntryRate': lateEntryRate,
    'bestLoggingHour': bestLoggingHour,
    'categoryInsights': categoryInsights,
    'topTags': topTags.map((e) => e.toJson()).toList(),
    'moodInsights': moodInsights,
    'advancedPatterns': advancedPatterns,
    'generatedAt': generatedAt.toIso8601String(),
  };
}

class TagCount {
  final String tag;
  final int count;
  const TagCount({required this.tag, required this.count});

  factory TagCount.fromJson(Map<String, dynamic> json) => TagCount(
    tag: json['tag'] ?? '',
    count: json['count'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'count': count,
  };
}
