import 'dart:async';

import 'package:done_today/providers/auth/auth_notifier.dart';
import 'package:done_today/state/auth/auth_state.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/storage/models/log_stats_model.dart';
import 'package:done_today/state/logs/logs_state.dart';
import 'package:done_today/storage/hive/hive_service.dart';
import 'package:done_today/utils/snackbar.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final logsNotifierProvider = NotifierProvider<LogsNotifier, LogsState>(() {
  return LogsNotifier();
});

class LogsNotifier extends Notifier<LogsState> {
  Map<String, dynamic>? _deletedLog;

  @override
  LogsState build() {
    // Listen to auth state changes to clear data on logout
    ref.listen(authNotifierProvider, (previous, next) {
      if (next is AuthLoggedOut) {
        state = LogsInitial();
      } else if (next is AuthLoggedIn && previous is! AuthLoggedIn) {
        // Re-fetch data when a new user logs in
        fetchInitialData();
      }
    });

    // Load logs on initialization
    Future.microtask(() {
      fetchInitialData();
    });

    // Try to load existing logs synchronously to avoid flicker
    try {
      final cached = HiveService.getAllLogs();
      if (cached.isNotEmpty) {
        final logs = cached.map((j) => Log.fromJson(j)).where((log) {
          final cid = log.challengeId;
          final hasChallengeId =
              cid != null && cid.trim().isNotEmpty && cid.trim() != 'null';
          return !hasChallengeId;
        }).toList();
        return LogsLoaded(logs, stats: _computeStats(logs));
      }
    } catch (_) {}

    return LogsInitial();
  }

  /// Load all logs from storage.
  Future<void> fetchInitialData() async {
    // Only show full loading state on first load
    if (state is! LogsLoaded) {
      state = LogsLoading();
    }

    try {
      final rawLogs = await HiveService.getAllLogsAsync();
      final logs = rawLogs.map((json) => Log.fromJson(json)).where((log) {
        final cid = log.challengeId;
        final hasChallengeId =
            cid != null && cid.trim().isNotEmpty && cid.trim() != 'null';
        return !hasChallengeId; // Only keep daily journals
      }).toList();
      final stats = _computeStats(logs);

      state = LogsLoaded(logs, stats: stats);
    } catch (e) {
      if (state is! LogsLoaded) {
        state = LogsError(e.toString());
      }
    }
  }

  /// Create a new log and persist to Drift.
  Future<void> createLog(Map<String, dynamic> logData) async {
    final currentState = state;
    if (currentState is! LogsLoaded) {
      state = LogsLoading();
    }

    try {
      final date = logData['date'] as String;

      // Check if a log for this date already exists to enforce "one per day"
      Log? existingLog;
      if (currentState is LogsLoaded) {
        existingLog = currentState.logs
            .where((l) => l.date == date)
            .firstOrNull;
      }

      if (existingLog != null) {
        // If it exists, we update instead of create to be strict
        await editLog(existingLog.id, logData);
        return;
      }

      logData['createdAt'] ??= DateTime.now().toUtc().toIso8601String();
      logData['updatedAt'] = DateTime.now().toUtc().toIso8601String();

      final newLog = Log.fromJson(logData);

      // Optimistic update
      if (currentState is LogsLoaded) {
        final updatedLogs = [newLog, ...currentState.logs]
          ..sort((a, b) => b.date.compareTo(a.date));
        state = LogsLoaded(updatedLogs, stats: _computeStats(updatedLogs));
      }

      await HiveService.saveLog(logData);

      // Silent refresh
      _updateLocalState();

      showGlobalSnackBar("Log created successfully!");
    } catch (e) {
      if (state is! LogsLoaded) {
        state = LogsError(e.toString());
      }
    }
  }

  /// Edit an existing log by id and persist to Drift.
  Future<void> editLog(
    String? logId,
    Map<String, dynamic> logData, {
    bool silent = false,
  }) async {
    final currentState = state;

    try {
      final id = logId ?? logData['id'] as String?;
      if (id == null) {
        throw Exception('Log ID not found for editing');
      }

      // Update timestamp
      logData['updatedAt'] = DateTime.now().toUtc().toIso8601String();

      // Optimistic update
      if (currentState is LogsLoaded) {
        final updatedLogs = currentState.logs.map((l) {
          if (l.id == id) {
            return Log.fromJson({...l.toJson(), ...logData});
          }
          return l;
        }).toList()..sort((a, b) => b.date.compareTo(a.date));

        state = LogsLoaded(updatedLogs, stats: _computeStats(updatedLogs));
      }

      await HiveService.updateLog(id, logData);

      // Silent refresh
      _updateLocalState();

      if (!silent) showGlobalSnackBar("Log edited successfully!");
    } catch (e) {
      if (state is! LogsLoaded) {
        state = LogsError(e.toString());
      }
    }
  }

  Future<void> _updateLocalState() async {
    try {
      final rawLogs = await HiveService.getAllLogsAsync();
      final logs = rawLogs.map((json) => Log.fromJson(json)).where((log) {
        final cid = log.challengeId;
        final hasChallengeId =
            cid != null && cid.trim().isNotEmpty && cid.trim() != 'null';
        return !hasChallengeId; // Only keep daily journals
      }).toList();
      final stats = _computeStats(logs);
      state = LogsLoaded(logs, stats: stats);
    } catch (_) {}
  }

  /// Delete a log by id from Drift with undo support.
  Future<void> deleteLog(String logId) async {
    final currentState = state;
    if (currentState is! LogsLoaded) return;

    final previousLogs = List<Log>.from(currentState.logs);
    final previousStats = currentState.stats;

    // Immediate UI feedback
    final updatedLogs = previousLogs.where((log) => log.id != logId).toList();
    final updatedStats = _computeStats(updatedLogs);
    state = LogsLoaded(updatedLogs, stats: updatedStats);

    // Process persistence silently
    unawaited(() async {
      try {
        // Find for undo support
        final logToDelete = previousLogs
            .where((log) => log.id == logId)
            .firstOrNull;
        if (logToDelete != null) {
          _deletedLog = logToDelete.toJson();
        }

        // Persistent delete
        await HiveService.deleteLog(logId);

        // Show Snackbar with Undo option
        const duration = Duration(seconds: 4);
        showGlobalSnackBar(
          "Log deleted",
          duration: duration,
          actionLabel: 'UNDO',
          onAction: () => _restoreLog(previousLogs, previousStats),
          showTimer: true,
        );
      } catch (e) {
        debugPrint("LogsNotifier: Delete failed in background: $e");
        // We don't necessarily want to revert the UI if Hive fails,
        // as the user already expects it to be gone.
        // But we could show an error snackbar here if needed.
      }
    }());
  }

  /// Restore the previously deleted log.
  Future<void> _restoreLog(
    List<Log> previousLogs,
    LogStats? previousStats,
  ) async {
    if (_deletedLog == null) return;

    try {
      // Restore to storage
      await HiveService.saveLog(_deletedLog!);

      // Restore UI state immediately
      state = LogsLoaded(previousLogs, stats: previousStats);
      _deletedLog = null;

      showGlobalSnackBar("Log restored!");
    } catch (e) {
      showGlobalSnackBar("Failed to restore log", isError: true);
    }
  }

  // -------------------
  // Stats Computation
  // -------------------

  /// Compute LogStats from the local log list.
  LogStats _computeStats(List<Log> logs) {
    if (logs.isEmpty) return LogStats.empty();

    final today = TimeUtil.todayIso();

    // Total logs
    final totalLogs = logs.length;

    // Total words (avoid fold overhead)
    int totalWords = 0;
    for (final l in logs) {
      totalWords += l.wordCount;
    }

    // Logs this month
    final monthPrefix = TimeUtil.currentMonthPrefix();
    int logsThisMonth = 0;
    for (final l in logs) {
      if (l.date.startsWith(monthPrefix)) {
        logsThisMonth++;
      }
    }

    // Today logged
    bool todayLogged = false;
    for (final l in logs) {
      if (l.date == today) {
        todayLogged = true;
        break;
      }
    }

    // Last log date
    final lastLogDate = logs.isNotEmpty ? logs.first.date : '';

    // Extract unique dates sorted ascending using pre-parsed UTC DateTimes
    final uniqueDates = logs.map((l) => l.parsedDate).toSet().toList()..sort();
    if (uniqueDates.isEmpty) {
      return LogStats(
        streak: 0,
        totalLogs: totalLogs,
        totalWords: totalWords,
        logsThisMonth: logsThisMonth,
        lastLogDate: lastLogDate,
        longestStreak: 0,
        todayLogged: todayLogged,
      );
    }

    int streak = 0;
    int longestStreak = 0;

    // 1. Current streak: check if latest date is today or yesterday
    final todayDate =
        DateTime.tryParse('${today}T00:00:00Z') ?? DateTime.now().toUtc();
    final latestLogDate = uniqueDates.last;
    final difference = todayDate.difference(latestLogDate).inDays;

    if (difference >= 0 && difference <= 1) {
      int currentStreak = 0;
      DateTime checkDate = latestLogDate;
      for (int i = uniqueDates.length - 1; i >= 0; i--) {
        final logDate = uniqueDates[i];
        if (logDate.isAtSameMomentAs(checkDate)) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      streak = currentStreak;
    }

    // 2. Longest streak from unique dates (ascending)
    int tempStreak = 1;
    longestStreak = 1;
    for (int i = 1; i < uniqueDates.length; i++) {
      final prev = uniqueDates[i - 1];
      final curr = uniqueDates[i];
      if (curr.difference(prev).inDays == 1) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else if (curr.difference(prev).inDays > 1) {
        tempStreak = 1;
      }
    }

    return LogStats(
      streak: streak,
      totalLogs: totalLogs,
      totalWords: totalWords,
      logsThisMonth: logsThisMonth,
      lastLogDate: lastLogDate,
      longestStreak: longestStreak,
      todayLogged: todayLogged,
    );
  }
}
