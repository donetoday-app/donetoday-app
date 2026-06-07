import 'package:flutter/foundation.dart';

@immutable
class LogStats {
  final int streak;
  final int totalLogs;
  final int totalWords;
  final int logsThisMonth;
  final String lastLogDate;
  final int longestStreak;
  final bool todayLogged;

  const LogStats({
    required this.streak,
    required this.totalLogs,
    required this.totalWords,
    required this.logsThisMonth,
    required this.lastLogDate,
    required this.longestStreak,
    required this.todayLogged,
  });

  factory LogStats.fromJson(Map<String, dynamic> json) {
    return LogStats(
      streak: json['streak'] as int? ?? 0,
      totalLogs: json['totalLogs'] as int? ?? 0,
      totalWords: json['totalWords'] as int? ?? 0,
      logsThisMonth: json['logsThisMonth'] as int? ?? 0,
      lastLogDate: json['lastLogDate'] as String? ?? '',
      longestStreak: json['longestStreak'] as int? ?? 0,
      todayLogged: json['todayLogged'] as bool? ?? false,
    );
  }

  factory LogStats.empty() {
    return const LogStats(
      streak: 0,
      totalLogs: 0,
      totalWords: 0,
      logsThisMonth: 0,
      lastLogDate: '',
      longestStreak: 0,
      todayLogged: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'streak': streak,
    'totalLogs': totalLogs,
    'totalWords': totalWords,
    'logsThisMonth': logsThisMonth,
    'lastLogDate': lastLogDate,
    'longestStreak': longestStreak,
    'todayLogged': todayLogged,
  };

  Map<String, dynamic> toMap() => toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogStats &&
          runtimeType == other.runtimeType &&
          streak == other.streak &&
          totalLogs == other.totalLogs &&
          totalWords == other.totalWords &&
          logsThisMonth == other.logsThisMonth &&
          lastLogDate == other.lastLogDate &&
          longestStreak == other.longestStreak &&
          todayLogged == other.todayLogged;

  @override
  int get hashCode =>
      streak.hashCode ^
      totalLogs.hashCode ^
      totalWords.hashCode ^
      logsThisMonth.hashCode ^
      lastLogDate.hashCode ^
      longestStreak.hashCode ^
      todayLogged.hashCode;
}
