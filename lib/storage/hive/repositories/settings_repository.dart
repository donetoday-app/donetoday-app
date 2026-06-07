import 'package:done_today/storage/hive/base/hive_repository.dart';
import 'package:done_today/storage/models/settings_model.dart';

/// Type-safe repository for settings management
///
/// Example:
/// ```dart
/// final repo = SettingsRepository();
/// await repo.init();
///
/// // Get current settings
/// final settings = await repo.getCurrentSettings();
///
/// // Update settings
/// final updated = settings.copyWith(seedColor: 0xFF4CAF50);
/// await repo.updateSettings(updated);
///
/// // Reset to defaults
/// await repo.resetToDefaults();
/// ```
class SettingsRepository extends HiveRepository<SettingsModel> {
  static const String _currentSettingsKey = 'current_settings';

  SettingsRepository() : super('settingsBox');

  @override
  Map<String, dynamic> toMap(SettingsModel settings) => settings.toMap();

  @override
  SettingsModel fromMap(Map<String, dynamic> map) => SettingsModel.fromMap(map);

  /// Get current settings or create defaults if not found
  Future<SettingsModel> getCurrentSettings() async {
    final existing = await getByKey(_currentSettingsKey);
    if (existing != null) return existing;

    final defaults = SettingsModel.defaults();
    await save(_currentSettingsKey, defaults);
    return defaults;
  }

  /// Update settings
  Future<void> updateSettings(SettingsModel settings) async {
    await save(_currentSettingsKey, settings);
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    await save(_currentSettingsKey, SettingsModel.defaults());
  }
}
