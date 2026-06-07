import 'package:done_today/utils/date_utils.dart';

class ChallengeLog {
  final String id;
  final String challengeId;
  final String challengeName;
  // core writing fields (same as Log)
  final String title;
  final String description;
  final List<String> tags;
  final String? mood;
  final String category;
  final String date;
  final String time;
  final int wordCount;
  final int readTime;
  final bool isDraft;
  // challenge-specific fields
  final int dayNumber; // Day 1, Day 12
  final int totalDays; // Snapshot at time of logging
  final bool isMissed; // If user skips but still counts
  final bool isLateEntry; // Logged after the day ended
  final int streakAtThatDay; // Challenge streak snapshot
  final double progress; // 0.0 → 1.0
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  ChallengeLog({
    required this.id,
    required this.challengeId,
    required this.challengeName,
    required this.title,
    required this.description,
    this.tags = const [],
    this.mood,
    this.category = 'Challenge',
    required this.date,
    required this.time,
    required this.wordCount,
    required this.readTime,
    this.isDraft = false,
    required this.dayNumber,
    required this.totalDays,
    this.isMissed = false,
    this.isLateEntry = false,
    required this.streakAtThatDay,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  factory ChallengeLog.fromJson(Map<String, dynamic> json) {
    return ChallengeLog(
      id: json['id'],
      challengeId: json['challengeId'],
      challengeName: json['challengeName'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      mood: json['mood'],
      category: json['category'] ?? 'Challenge',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      wordCount: json['wordCount'] ?? 0,
      readTime: json['readTime'] ?? 0,
      isDraft: json['isDraft'] ?? false,
      dayNumber: json['dayNumber'] ?? 0,
      totalDays: json['totalDays'] ?? 0,
      isMissed: json['isMissed'] ?? false,
      isLateEntry: json['isLateEntry'] ?? false,
      streakAtThatDay: json['streakAtThatDay'] ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: Dateutils.parseDate(json['createdAt']),
      updatedAt: Dateutils.parseDate(json['updatedAt']),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'challengeId': challengeId,
        'challengeName': challengeName,
        'title': title,
        'description': description,
        'tags': tags,
        'mood': mood,
        'category': category,
        'date': date,
        'time': time,
        'wordCount': wordCount,
        'readTime': readTime,
        'isDraft': isDraft,
        'dayNumber': dayNumber,
        'totalDays': totalDays,
        'isMissed': isMissed,
        'isLateEntry': isLateEntry,
        'streakAtThatDay': streakAtThatDay,
        'progress': progress,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDeleted': isDeleted,
      };

  ChallengeLog copyWith({
    String? id,
    String? challengeId,
    String? challengeName,
    String? title,
    String? description,
    List<String>? tags,
    String? mood,
    String? category,
    String? date,
    String? time,
    int? wordCount,
    int? readTime,
    bool? isDraft,
    int? dayNumber,
    int? totalDays,
    bool? isMissed,
    bool? isLateEntry,
    int? streakAtThatDay,
    double? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return ChallengeLog(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      challengeName: challengeName ?? this.challengeName,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      mood: mood ?? this.mood,
      category: category ?? this.category,
      date: date ?? this.date,
      time: time ?? this.time,
      wordCount: wordCount ?? this.wordCount,
      readTime: readTime ?? this.readTime,
      isDraft: isDraft ?? this.isDraft,
      dayNumber: dayNumber ?? this.dayNumber,
      totalDays: totalDays ?? this.totalDays,
      isMissed: isMissed ?? this.isMissed,
      isLateEntry: isLateEntry ?? this.isLateEntry,
      streakAtThatDay: streakAtThatDay ?? this.streakAtThatDay,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
