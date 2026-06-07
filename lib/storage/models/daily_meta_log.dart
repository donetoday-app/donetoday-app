class DailyMetaLog {
  final String id; // virtual meta id
  final String date; // yyyy-MM-dd

  /// Daily log (Done Today core)
  final bool hasDailyLog;
  final String? dailyLogId;

  /// Challenge logs for this day
  final List<String> challengeLogIds;

  /// Completion state
  final bool isCompleted; // true if daily OR challenge log exists
  final bool isMissed; // user skipped the day intentionally
  final bool isLateEntry; // logs added after day ended

  /// Snapshots (important for analytics)
  final int totalLogsCount; // daily + challenge logs
  final int activeChallengesCount;

  /// Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  late final DateTime parsedDate = DateTime.tryParse('${date}T00:00:00Z') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  DailyMetaLog({
    required this.id,
    required this.date,

    this.hasDailyLog = false,
    this.dailyLogId,
    this.challengeLogIds = const [],

    this.isCompleted = false,
    this.isMissed = false,
    this.isLateEntry = false,

    this.totalLogsCount = 0,
    this.activeChallengesCount = 0,

    required this.createdAt,
    required this.updatedAt,
  });

  DailyMetaLog copyWith({
    String? id,
    bool? hasDailyLog,
    String? dailyLogId,
    List<String>? challengeLogIds,
    bool? isCompleted,
    bool? isMissed,
    bool? isLateEntry,
    int? totalLogsCount,
    int? activeChallengesCount,
    DateTime? updatedAt,
  }) {
    return DailyMetaLog(
      id: id ?? this.id,
      date: date,

      hasDailyLog: hasDailyLog ?? this.hasDailyLog,
      dailyLogId: dailyLogId ?? this.dailyLogId,
      challengeLogIds: challengeLogIds ?? this.challengeLogIds,

      isCompleted: isCompleted ?? this.isCompleted,
      isMissed: isMissed ?? this.isMissed,
      isLateEntry: isLateEntry ?? this.isLateEntry,

      totalLogsCount: totalLogsCount ?? this.totalLogsCount,
      activeChallengesCount:
          activeChallengesCount ?? this.activeChallengesCount,

      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
