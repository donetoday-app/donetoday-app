/// Hive storage model for logs.
///
/// This model is stored as a Map<String, dynamic> in Hive and used throughout
/// the app for log persistence and display.
class Log {
  final String id;
  final String slug;
  final String title;
  final String description;
  final List<String>? tags;
  final String? mood;
  final String? category;
  final String date;
  final String time;
  final int wordCount;
  final int readTime;
  final String? createdAt;
  final String? updatedAt;
  final String? userId;
  
  // Challenge fields
  final String? challengeId;
  final int? dayNumber;

  late final DateTime parsedDate = DateTime.tryParse('${date}T00:00:00Z') ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  Log({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    this.tags,
    this.mood,
    this.category,
    required this.date,
    required this.time,
    required this.wordCount,
    required this.readTime,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.challengeId,
    this.dayNumber,
  });

  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      id: json['id']?.toString() ?? '',
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List<dynamic>)
          : null,
      mood: json['mood'] as String?,
      category: json['category'] as String?,
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      wordCount: json['wordCount'] is int
          ? json['wordCount'] as int
          : (json['wordCount'] as num?)?.toInt() ?? 0,
      readTime: json['readTime'] is int
          ? json['readTime'] as int
          : (json['readTime'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      userId: json['userId'] as String?,
      challengeId: json['challengeId'] as String?,
      dayNumber: json['dayNumber'] as int?,
    );
  }

  factory Log.fromMap(Map<String, dynamic> map) => Log.fromJson(map);

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'title': title,
    'description': description,
    'tags': tags,
    'mood': mood,
    'category': category,
    'date': date,
    'time': time,
    'wordCount': wordCount,
    'readTime': readTime,
    'createdAt': createdAt ?? date,
    'updatedAt': updatedAt ?? DateTime.now().toUtc().toIso8601String(),
    'userId': userId,
    'challengeId': challengeId,
    'dayNumber': dayNumber,
  };

  Map<String, dynamic> toMap() => toJson();

  Log copyWith({
    String? id,
    String? slug,
    String? title,
    String? description,
    List<String>? tags,
    String? mood,
    String? category,
    String? date,
    String? time,
    int? wordCount,
    int? readTime,
    String? createdAt,
    String? updatedAt,
    String? userId,
    String? challengeId,
    int? dayNumber,
  }) {
    return Log(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      mood: mood ?? this.mood,
      category: category ?? this.category,
      date: date ?? this.date,
      time: time ?? this.time,
      wordCount: wordCount ?? this.wordCount,
      readTime: readTime ?? this.readTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      dayNumber: dayNumber ?? this.dayNumber,
    );
  }
}
