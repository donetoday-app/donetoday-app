import 'package:done_today/utils/date_utils.dart';

class Challenge {
  final String id;
  final String title;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Challenge({
    required this.id,
    required this.title,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      category: json['category'] ?? 'Challenge',
      startDate: Dateutils.parseDate(json['startDate']),
      endDate: Dateutils.parseDate(json['endDate']),
      totalDays: json['totalDays'],
      createdAt: Dateutils.parseDate(json['createdAt']),
      updatedAt: Dateutils.parseDate(json['updatedAt']),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'totalDays': totalDays,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isDeleted': isDeleted,
  };
}

extension ChallengeCopy on Challenge {
  Challenge copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDays,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDays: totalDays ?? this.totalDays,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
