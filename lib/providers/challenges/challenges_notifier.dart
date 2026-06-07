import 'package:done_today/providers/auth/auth_notifier.dart';
import 'package:done_today/state/auth/auth_state.dart';
import 'package:done_today/state/challenges/challenges_state.dart';
import 'package:done_today/storage/hive/hive_service.dart';
import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/utils/snackbar.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:done_today/providers/settings/theme_notifier.dart';
import 'package:uuid/uuid.dart';

final challengesNotifierProvider =
    NotifierProvider<ChallengesNotifier, ChallengesState>(() {
      return ChallengesNotifier();
    });

class ChallengesNotifier extends Notifier<ChallengesState> {
  final _uuid = const Uuid();

  @override
  ChallengesState build() {
    ref.listen(authNotifierProvider, (previous, next) {
      if (next is AuthLoggedOut) {
        state = ChallengesInitial();
      } else if (next is AuthLoggedIn && previous is! AuthLoggedIn) {
        fetchInitialData();
      }
    });

    Future.microtask(() => fetchInitialData());

    return ChallengesInitial();
  }

  Future<void> fetchInitialData() async {
    state = ChallengesLoading();
    try {
      final rawChallenges = await HiveService.getAllChallenges();
      final challenges = rawChallenges
          .map((json) => Challenge.fromJson(json))
          .where((c) => !c.isDeleted)
          .toList();

      final Map<String, List<Log>> challengeLogsMap = {};
      for (final challenge in challenges) {
        challengeLogsMap[challenge.id] = [];
      }

      final rawLogs = await HiveService.getAllLogs();
      final allLogs = rawLogs.map((json) => Log.fromJson(json));

      for (final log in allLogs) {
        if (challengeLogsMap.containsKey(log.challengeId)) {
          challengeLogsMap[log.challengeId]!.add(log);
        }
      }

      for (final challengeId in challengeLogsMap.keys) {
        challengeLogsMap[challengeId]!.sort((a, b) => a.date.compareTo(b.date));
      }

      state = ChallengesLoaded(
        challenges: challenges,
        challengeLogs: challengeLogsMap,
      );
    } catch (e) {
      state = ChallengesError(e.toString());
    }
  }

  Future<void> createChallenge({
    required String title,
    required String category,
    required DateTime startDate,
    required int durationDays,
  }) async {
    final currentState = state;
    if (currentState is! ChallengesLoaded) return;

    // 0. Duplicate Check
    final isDuplicate = currentState.challenges.any(
      (c) => c.title.trim().toUpperCase() == title.trim().toUpperCase(),
    );

    if (isDuplicate) {
      showGlobalSnackBar(
        "A challenge with this title already exists!",
        isError: true,
      );
      return;
    }

    try {
      final id = _uuid.v4();
      final endDate = startDate.add(Duration(days: durationDays));
      final now = DateTime.now().toUtc();

      final challenge = Challenge(
        id: id,
        title: title.toUpperCase(),
        category: category,
        startDate: startDate,
        endDate: endDate,
        totalDays: durationDays,
        createdAt: now,
        updatedAt: now,
      );

      await HiveService.saveChallenge(challenge.toJson());

      // Update local state
      state = ChallengesLoaded(
        challenges: [...currentState.challenges, challenge],
        challengeLogs: currentState.challengeLogs,
      );

      showGlobalSnackBar("Challenge started! 🚀");
    } catch (e) {
      showGlobalSnackBar("Failed to create challenge", isError: true);
    }
  }

  Future<void> logChallengeDay({
    required Challenge challenge,
    required DateTime date,
    required String title,
    String? description,
    String? mood,
    List<String>? tags,
  }) async {
    final dateStr = TimeUtil.formatIsoDate(date);
    final now = DateTime.now().toUtc();

    try {
      final currentState = state;
      Log? existingLog;
      if (currentState is ChallengesLoaded) {
        existingLog = currentState.challengeLogs[challenge.id]
            ?.where((l) => l.date == dateStr)
            .firstOrNull;
      }

      if (existingLog != null) {
        // If it exists, we update instead of create to be strict
        await updateLog(
          logId: existingLog.id,
          title: title,
          description: description ?? '',
          mood: mood,
          tags: tags,
        );
        return;
      }

      final logId = _uuid.v4();
      final dayNumber = date.difference(challenge.startDate).inDays + 1;
      final use24Hour = ref.read(themeNotifierProvider).use24HourFormat;

      final challengeLog = Log(
        id: logId,
        slug: logId,
        challengeId: challenge.id,
        title: title,
        description: description ?? '',
        tags: tags ?? [],
        mood: mood,
        category: challenge.category,
        date: dateStr,
        time: TimeUtil.getCurrentTimeFormatted(use24Hour: use24Hour),
        wordCount:
            title.split(' ').length + (description?.split(' ').length ?? 0),
        readTime: 1,
        dayNumber: dayNumber,
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      );

      await HiveService.saveLog(challengeLog.toJson());

      // Optimistic update
      if (currentState is ChallengesLoaded) {
        final updatedLogs = <Log>[
          challengeLog,
          ...(currentState.challengeLogs[challenge.id] ?? []),
        ]..sort((a, b) => a.date.compareTo(b.date));

        final newLogsMap = Map<String, List<Log>>.from(
          currentState.challengeLogs,
        );
        newLogsMap[challenge.id] = updatedLogs;

        state = ChallengesLoaded(
          challenges: currentState.challenges,
          challengeLogs: newLogsMap,
        );
      }

      // Silent refresh
      _refreshLocalData();

      showGlobalSnackBar("Check-in successful! ✨");
    } catch (e) {
      showGlobalSnackBar("Failed to log progress", isError: true);
    }
  }

  Future<void> _refreshLocalData() async {
    try {
      final rawChallenges = await HiveService.getAllChallenges();
      final challenges = rawChallenges
          .map((json) => Challenge.fromJson(json))
          .where((c) => !c.isDeleted)
          .toList();

      final Map<String, List<Log>> challengeLogsMap = {};
      for (final challenge in challenges) {
        challengeLogsMap[challenge.id] = [];
      }

      final rawLogs = await HiveService.getAllLogs();
      final allLogs = rawLogs.map((json) => Log.fromJson(json));

      for (final log in allLogs) {
        if (challengeLogsMap.containsKey(log.challengeId)) {
          challengeLogsMap[log.challengeId]!.add(log);
        }
      }

      for (final challengeId in challengeLogsMap.keys) {
        challengeLogsMap[challengeId]!.sort((a, b) => a.date.compareTo(b.date));
      }

      state = ChallengesLoaded(
        challenges: challenges,
        challengeLogs: challengeLogsMap,
      );
    } catch (_) {}
  }

  Future<void> updateLog({
    required String logId,
    required String title,
    required String description,
    String? mood,
    List<String>? tags,
    bool silent = false,
  }) async {
    try {
      final rawLog = HiveService.getLog(logId);
      if (rawLog == null) return;

      final log = Log.fromJson(rawLog);
      final updated = log.copyWith(
        title: title,
        description: description,
        mood: mood,
        tags: tags,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
        wordCount: title.split(' ').length + (description.split(' ').length),
      );

      await HiveService.saveLog(updated.toJson());

      // Optimistic update
      final currentState = state;
      if (currentState is ChallengesLoaded) {
        final challengeId = updated.challengeId;
        final updatedLogs =
            currentState.challengeLogs[challengeId]?.map<Log>((l) {
              return l.id == logId ? updated : l;
            }).toList() ??
            <Log>[];

        final newLogsMap = Map<String, List<Log>>.from(
          currentState.challengeLogs,
        );
        if (challengeId != null) {
          newLogsMap[challengeId] = updatedLogs;
        }

        state = ChallengesLoaded(
          challenges: currentState.challenges,
          challengeLogs: newLogsMap,
        );
      }

      _refreshLocalData();
      if (!silent) showGlobalSnackBar("Log updated! ✨");
    } catch (e) {
      showGlobalSnackBar("Failed to update log", isError: true);
    }
  }

  Future<void> updateChallenge({
    required String challengeId,
    required String title,
    required String category,
    required DateTime startDate,
    required int durationDays,
  }) async {
    final currentState = state;
    if (currentState is ChallengesLoaded) {
      final isDuplicate = currentState.challenges.any(
        (c) =>
            c.id != challengeId &&
            c.title.trim().toUpperCase() == title.trim().toUpperCase(),
      );

      if (isDuplicate) {
        showGlobalSnackBar(
          "Another challenge with this title already exists!",
          isError: true,
        );
        return;
      }
    }

    try {
      final challengeData = HiveService.getChallenge(challengeId);
      if (challengeData == null) return;

      final challenge = Challenge.fromJson(challengeData);
      final endDate = startDate.add(Duration(days: durationDays));

      final updated = challenge.copyWith(
        title: title.toUpperCase(),
        category: category,
        startDate: startDate,
        endDate: endDate,
        totalDays: durationDays,
        updatedAt: DateTime.now().toUtc(),
      );

      await HiveService.saveChallenge(updated.toJson());

      // Cascading Update: Update challengeName in all logs for this challenge
      final rawLogs = await HiveService.getLogs(challengeId);
      for (final logJson in rawLogs) {
        final log = Log.fromJson(logJson);
        final updatedLog = log.copyWith(
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
        await HiveService.saveLog(updatedLog.toJson());
      }

      // Optimistic update
      final currentState = state;
      if (currentState is ChallengesLoaded) {
        final updatedChallenges = currentState.challenges.map((c) {
          return c.id == challengeId ? updated : c;
        }).toList();

        // Update logs in local state too
        final newLogsMap = Map<String, List<Log>>.from(
          currentState.challengeLogs,
        );
        if (newLogsMap.containsKey(challengeId)) {
          newLogsMap[challengeId] = newLogsMap[challengeId]!.toList();
        }

        state = ChallengesLoaded(
          challenges: updatedChallenges,
          challengeLogs: newLogsMap,
        );
      }

      _refreshLocalData();
      showGlobalSnackBar("Challenge updated!");
    } catch (e) {
      showGlobalSnackBar("Failed to update", isError: true);
    }
  }

  Future<void> deleteChallenge(String challengeId) async {
    try {
      final challengeData = HiveService.getChallenge(challengeId);
      if (challengeData == null) return;

      final challenge = Challenge.fromJson(challengeData);
      await HiveService.saveChallenge(
        challenge
            .copyWith(isDeleted: true, updatedAt: DateTime.now().toUtc())
            .toJson(),
      );

      // Optimistic update
      final currentState = state;
      if (currentState is ChallengesLoaded) {
        final updatedChallenges = currentState.challenges
            .where((c) => c.id != challengeId)
            .toList();
        final newLogsMap = Map<String, List<Log>>.from(
          currentState.challengeLogs,
        );
        newLogsMap.remove(challengeId);

        state = ChallengesLoaded(
          challenges: updatedChallenges,
          challengeLogs: newLogsMap,
        );
      }

      _refreshLocalData();
      showGlobalSnackBar("Challenge deleted");
    } catch (e) {
      showGlobalSnackBar("Failed to delete", isError: true);
    }
  }
}
