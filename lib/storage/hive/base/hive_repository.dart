import 'package:hive_flutter/hive_flutter.dart';

/// Generic repository pattern for Hive storage
///
/// Use this abstract class for type-safe storage of complex objects.
/// Extend it for specific data types.
///
/// Example:
/// ```dart
/// class UserRepository extends HiveRepository<User> {
///   UserRepository() : super('users');
///
///   @override
///   Map<String, dynamic> toMap(User user) => user.toJson();
///
///   @override
///   User fromMap(Map<String, dynamic> map) => User.fromJson(map);
/// }
/// ```
abstract class HiveRepository<T> {
  final String boxName;
  late Box<dynamic> _box;

  HiveRepository(this.boxName);

  /// Initialize the repository - must call before using
  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox(boxName);
    } else {
      _box = Hive.box(boxName);
    }
  }

  /// Get all items as list
  ///
  /// Returns: List<T> of all stored items
  Future<List<T>> getAll() async {
    return _box.values
        .map((value) => fromMap(value as Map<String, dynamic>))
        .toList();
  }

  /// Get single item by key
  ///
  /// Returns: T or null if not found
  Future<T?> getByKey(String key) async {
    final value = _box.get(key);
    return value != null ? fromMap(value as Map<String, dynamic>) : null;
  }

  /// Save/update item
  ///
  /// Example:
  /// ```dart
  /// final repo = UserRepository();
  /// await repo.save('user_1', myUser);
  /// ```
  Future<void> save(String key, T item) async {
    await _box.put(key, toMap(item));
  }

  /// Save multiple items at once
  ///
  /// Example:
  /// ```dart
  /// await repo.saveMultiple({
  ///   'user_1': user1,
  ///   'user_2': user2,
  /// });
  /// ```
  Future<void> saveMultiple(Map<String, T> items) async {
    final map = items.map((k, v) => MapEntry(k, toMap(v)));
    await _box.putAll(map);
  }

  /// Delete item by key
  ///
  /// Example:
  /// ```dart
  /// await repo.delete('user_1');
  /// ```
  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  /// Delete multiple items
  ///
  /// Example:
  /// ```dart
  /// await repo.deleteMultiple(['user_1', 'user_2']);
  /// ```
  Future<void> deleteMultiple(List<String> keys) async {
    await _box.deleteAll(keys);
  }

  /// Clear all items
  ///
  /// WARNING: This deletes all data in the box!
  Future<void> clear() async {
    await _box.clear();
  }

  /// Check if key exists
  ///
  /// Example:
  /// ```dart
  /// if (repo.exists('user_1')) {
  ///   // Item exists
  /// }
  /// ```
  bool exists(String key) => _box.containsKey(key);

  /// Convert object to map for storage
  /// Subclasses must implement this
  Map<String, dynamic> toMap(T item);

  /// Convert map to object
  /// Subclasses must implement this
  T fromMap(Map<String, dynamic> map);
}
