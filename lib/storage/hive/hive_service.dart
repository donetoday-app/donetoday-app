import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Main Hive storage service - handles all persistence operations
///
/// Features:
/// - Generic storage with type safety: get<T>(), put<T>(), delete()
/// - Auth operations: token management
/// - Settings operations: theme, colors, preferences
/// - Logs CRUD operations
///
/// Usage:
/// ```dart
/// // Initialize on app startup
/// await HiveService.init();
///
/// // Store token
/// await HiveService.setToken('jwt_token');
///
/// // Store logs
/// await HiveService.saveLog(logMap);
/// final logs = await HiveService.getAllLogsAsync();
/// ```
class HiveService {
  // Box names
  static const String _settingsBox = 'settings';
  static const String _logsBox = 'logs';
  static const String _challengesBox = 'challenges';
  

  // Auth keys
  static const String _tokenKey = '__dt_token';
  static const String _userDetailsKey = '__dt_user_details';

  // Settings keys
  static const String _themeModeKey = 'themeMode';
  static const String _seedColorKey = 'seedColor';
  static const String _activityViewKey = 'activityView';
  static const String _useBlackModeKey = 'useBlackMode';

  /// Initialize all Hive boxes on app startup
  /// Call this in main() before runApp()
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_logsBox);
    await Hive.openBox(_challengesBox);
    
  }

  // =====================
  // Generic Repository Pattern
  // =====================
  /// Standard get method for any key with type safety
  ///
  /// Example:
  /// ```dart
  /// final token = HiveService.get<String>('authBox', 'token');
  /// final count = HiveService.get<int>('settingsBox', 'itemCount');
  /// ```
  static T? get<T>(String boxName, String key) {
    try {
      return Hive.box(boxName).get(key);
    } catch (e) {
      return null;
    }
  }

  /// Standard put method for any key with type safety
  ///
  /// Example:
  /// ```dart
  /// await HiveService.put<String>('authBox', 'token', 'mytoken');
  /// await HiveService.put<int>('settingsBox', 'itemCount', 42);
  /// ```
  static Future<void> put<T>(String boxName, String key, T value) async {
    try {
      await Hive.box(boxName).put(key, value);
    } catch (e) {
      rethrow;
    }
  }

  /// Standard delete method for any key
  ///
  /// Example:
  /// ```dart
  /// await HiveService.delete('authBox', 'token');
  /// ```
  static Future<void> delete(String boxName, String key) async {
    try {
      await Hive.box(boxName).delete(key);
    } catch (e) {
      rethrow;
    }
  }

  // =====================
  // Auth Operations
  // =====================
  /// Get stored JWT token
  static String? getToken() {
    return get<String>(_settingsBox, _tokenKey);
  }

  /// Store JWT token
  static Future<void> setToken(String token) async {
    await put<String>(_settingsBox, _tokenKey, token);
  }

  /// Delete stored token (logout)
  static Future<void> deleteToken() async {
    await delete(_settingsBox, _tokenKey);
    await delete(_settingsBox, _userDetailsKey);
  }

  /// Clear ALL data from ALL boxes (Logs, Auth, Daily Meta, Challenges, Settings, etc.)
  /// Used during logout for maximum privacy.
  static Future<void> clearAllData() async {
    try {
      await Hive.box(_logsBox).clear();
      await Hive.box(_challengesBox).clear();
      
      // We also clear settings to ensure a complete fresh start
      await Hive.box(_settingsBox).clear();
    } catch (e) {
      rethrow;
    }
  }

  /// Get stored user details
  static Map<String, dynamic>? getUserDetails() {
    final data = get<dynamic>(_settingsBox, _userDetailsKey);
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  /// Store user details
  static Future<void> setUserDetails(Map<String, dynamic> details) async {
    await put<Map>(_settingsBox, _userDetailsKey, details);
  }

  /// Get or create a unique device ID for this installation
  static String getOrCreateDeviceId() {
    String? id = get<String>(_settingsBox, 'device_id');
    if (id == null) {
      id = const Uuid().v4();
      put<String>(_settingsBox, 'device_id', id);
    }
    return id;
  }

  // =====================
  // Theme Operations
  // =====================
  /// Get saved theme mode index (0=light, 1=dark, 2=system)
  static int? getThemeModeIndex() {
    return get<int>(_settingsBox, _themeModeKey);
  }

  /// Save theme mode index
  static Future<void> setThemeModeIndex(int index) async {
    await put<int>(_settingsBox, _themeModeKey, index);
  }

  /// Get saved seed color value
  static int? getSeedColor() {
    return get<int>(_settingsBox, _seedColorKey);
  }

  /// Save seed color value
  static Future<void> setSeedColor(int colorValue) async {
    await put<int>(_settingsBox, _seedColorKey, colorValue);
  }

  /// Get saved black mode preference
  static bool? getUseBlackMode() {
    return get<bool>(_settingsBox, _useBlackModeKey);
  }

  /// Save black mode preference
  static Future<void> setUseBlackMode(bool value) async {
    await put<bool>(_settingsBox, _useBlackModeKey, value);
  }

  // =====================
  // View Operations
  // =====================
  /// Get saved activity view index
  static int? getActivityViewIndex() {
    return get<int>(_settingsBox, _activityViewKey);
  }

  /// Save activity view index
  static Future<void> setActivityViewIndex(int index) async {
    await put<int>(_settingsBox, _activityViewKey, index);
  }

  // =====================
  // Logs Operations (Standard CRUD Pattern)
  // =====================
  /// Get all logs as list of JSON objects
  ///
  /// Returns: List<Map<String, dynamic>> where each map is a log
  /// Get all logs from storage (Sync version for UI warm boot)
  static List<Map<String, dynamic>> getAllLogs() {
    try {
      final box = Hive.box(_logsBox);
      return box.values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all logs from storage (Async version)
  static Future<List<Map<String, dynamic>>> getAllLogsAsync() async {
    try {
      final box = Hive.box(_logsBox);
      final allValues = box.values.toList();
      return List<Map<String, dynamic>>.from(
        allValues.map((v) => v is Map ? Map<String, dynamic>.from(v) : {}),
      );
    } catch (e) {
      rethrow;
    }
  }
  ///
  /// Returns: Map<String, dynamic> or null if not found
  static Map<String, dynamic>? getLog(String logId) {
    try {
      final value = Hive.box(_logsBox).get(logId);
      return value is Map ? Map<String, dynamic>.from(value) : null;
    } catch (e) {
      return null;
    }
  }

  /// Save a new log
  ///
  /// Example:
  /// ```dart
  /// await HiveService.saveLog({
  ///   'id': 'log_123',
  ///   'title': 'My log',
  ///   'description': 'Today was great',
  ///   'date': '2025-01-15',
  /// });
  /// ```
  static Future<void> saveLog(Map<String, dynamic> log) async {
    try {
      final logId = log['id'];
      if (logId == null) throw Exception('Log must have an id');
      await Hive.box(_logsBox).put(logId, log);
    } catch (e) {
      rethrow;
    }
  }

  /// Update existing log
  ///
  /// Example:
  /// ```dart
  /// await HiveService.updateLog('log_123', {
  ///   'title': 'Updated title',
  ///   'description': 'New description',
  /// });
  /// ```
  static Future<void> updateLog(
    String logId,
    Map<String, dynamic> logData,
  ) async {
    try {
      final existing = Hive.box(_logsBox).get(logId);
      if (existing == null) throw Exception('Log with id $logId not found');

      final updated = {...?existing, ...logData};
      await Hive.box(_logsBox).put(logId, updated);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete log by ID
  ///
  /// Example:
  /// ```dart
  /// await HiveService.deleteLog('log_123');
  /// ```
  static Future<void> deleteLog(String logId) async {
    try {
      await Hive.box(_logsBox).delete(logId);
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all logs
  ///
  /// WARNING: This deletes all logs!
  static Future<void> clearAllLogs() async {
    try {
      await Hive.box(_logsBox).clear();
    } catch (e) {
      rethrow;
    }
  }


  // =====================
  // Challenges Operations
  // =====================
  static Future<void> saveChallenge(Map<String, dynamic> challenge) async {
    final id = challenge['id'];
    if (id == null) throw Exception('Challenge must have an id');
    await Hive.box(_challengesBox).put(id, challenge);
  }

  static Map<String, dynamic>? getChallenge(String id) {
    final data = Hive.box(_challengesBox).get(id);
    return data != null ? Map<String, dynamic>.from(data as Map) : null;
  }

  static Future<List<Map<String, dynamic>>> getAllChallenges() async {
    final allValues = Hive.box(_challengesBox).values.toList();
    return List<Map<String, dynamic>>.from(
      allValues.map((v) => v is Map ? Map<String, dynamic>.from(v) : {}),
    );
  }

  static Future<void> deleteChallenge(String id) async {
    await Hive.box(_challengesBox).delete(id);
  }

  static Future<List<Map<String, dynamic>>> getLogsByDate(String date) async {
    final allLogs = Hive.box(_logsBox).values.toList();
    return List<Map<String, dynamic>>.from(
      allLogs
          .map((v) => v is Map ? Map<String, dynamic>.from(v) : {})
          .where((log) => log['date'] == date),
    );
  }

  static Future<List<Map<String, dynamic>>> getLogs(String challengeId) async {
    final allLogs = Hive.box(_logsBox).values.toList();
    return List<Map<String, dynamic>>.from(
      allLogs
          .map((v) => v is Map ? Map<String, dynamic>.from(v) : {})
          .where((log) => log['challengeId'] == challengeId),
    );
  }
}
