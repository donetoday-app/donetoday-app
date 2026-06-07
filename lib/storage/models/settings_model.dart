/// Settings data model
///
/// Represents user preferences and application settings
class SettingsModel {
  final int themeModeIndex;
  final int seedColor;
  final int activityViewIndex;

  SettingsModel({
    required this.themeModeIndex,
    required this.seedColor,
    required this.activityViewIndex,
  });

  /// Create default settings
  factory SettingsModel.defaults() => SettingsModel(
    themeModeIndex: 0, // ThemeMode.system
    seedColor: 0xFF2196F3, // Material blue
    activityViewIndex: 0, // Default view
  );

  /// Convert to Map for Hive storage
  Map<String, dynamic> toMap() => {
    'themeModeIndex': themeModeIndex,
    'seedColor': seedColor,
    'activityViewIndex': activityViewIndex,
  };

  /// Create from Map (from Hive)
  factory SettingsModel.fromMap(Map<String, dynamic> map) => SettingsModel(
    themeModeIndex: map['themeModeIndex'] ?? 0,
    seedColor: map['seedColor'] ?? 0xFF2196F3,
    activityViewIndex: map['activityViewIndex'] ?? 0,
  );

  /// Create a copy with some fields optionally changed
  SettingsModel copyWith({
    int? themeModeIndex,
    int? seedColor,
    int? activityViewIndex,
  }) => SettingsModel(
    themeModeIndex: themeModeIndex ?? this.themeModeIndex,
    seedColor: seedColor ?? this.seedColor,
    activityViewIndex: activityViewIndex ?? this.activityViewIndex,
  );

  @override
  String toString() =>
      'SettingsModel(themeMode: $themeModeIndex, color: $seedColor, view: $activityViewIndex)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModel &&
          runtimeType == other.runtimeType &&
          themeModeIndex == other.themeModeIndex &&
          seedColor == other.seedColor &&
          activityViewIndex == other.activityViewIndex;

  @override
  int get hashCode =>
      themeModeIndex.hashCode ^ seedColor.hashCode ^ activityViewIndex.hashCode;
}
