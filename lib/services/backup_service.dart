import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:done_today/storage/hive/hive_service.dart';
import 'package:done_today/utils/snackbar.dart';
import 'package:done_today/utils/file_helper.dart';
import 'package:done_today/utils/encryption_helper.dart';
import 'package:done_today/utils/time_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BackupService {
  /// Get the available date range based on existing logs
  static Future<DateTimeRange> getAvailableDateRange() async {
    final rawLogs = await HiveService.getAllLogsAsync();
    if (rawLogs.isEmpty) {
      final now = DateTime.now();
      return DateTimeRange(start: now, end: now);
    }

    final dates =
        rawLogs
            .map((json) => DateTime.tryParse(json['date'] ?? ''))
            .whereType<DateTime>()
            .toList()
          ..sort();

    if (dates.isEmpty) {
      final now = DateTime.now();
      return DateTimeRange(start: now, end: now);
    }

    return DateTimeRange(start: dates.first, end: dates.last);
  }

  /// Export all data with encryption
  static Future<void> exportData({
    required String password,
    required String recoveryPhrase,
    bool exportRecoveryTxt = true,
  }) async {
    try {
      final archive = Archive();

      // 1. Add Metadata
      final metadata = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'app': 'DoneToday',
      };
      final metadataBytes = utf8.encode(json.encode(metadata));
      archive.addFile(
        ArchiveFile('metadata.json', metadataBytes.length, metadataBytes),
      );

      // 2. Fetch all local data
      final logsData = await HiveService.getAllLogsAsync();
      final challengesData = await HiveService.getAllChallenges();
      final challengeLogsData = await HiveService.getAllLogs();
      final fullData = {
        'logs': logsData,
        'challenges': challengesData,
        'challengeLogs': challengeLogsData,
      };

      final fullJson = json.encode(fullData);

      // 3. Encrypt and Add to Archive
      final encryptedData = EncryptionHelper.encryptData(
        fullJson,
        password.trim(),
        recoveryPhrase.trim(),
      );
      final encryptedBytes = utf8.encode(json.encode(encryptedData));
      archive.addFile(
        ArchiveFile('data.json', encryptedBytes.length, encryptedBytes),
      );

      // 4. Encode and Save
      final zipData = ZipEncoder().encode(archive);
      final timestamp = TimeUtil.formatFilename(DateTime.now());
      final fileName = 'DoneToday_Backup_$timestamp.zip';

      await FileHelper.saveAndShareFile(
        Uint8List.fromList(zipData),
        fileName,
        mimeType: 'application/zip',
      );

      // 5. Optionally export recovery phrase as .txt
      if (exportRecoveryTxt) {
        final content =
            "DoneToday Recovery Phrase\n\n"
            "Keep this safe. If you lose your password, "
            "this phrase is the only way to recover your data.\n\n"
            "RECOVERY PHRASE:\n$recoveryPhrase";

        final txtTimestamp = TimeUtil.formatFilename(DateTime.now());
        await FileHelper.saveAndShareText(
          content,
          "DoneToday_Recovery_$txtTimestamp.txt",
        );
      }

      showGlobalSnackBar("Full backup created and encrypted successfully!");
    } catch (e) {
      showGlobalSnackBar("Failed to export data: $e", isError: true);
    }
  }

  /// Pick a backup file and return its bytes
  static Future<Uint8List?> pickBackupFile() async {
    return await FileHelper.pickFileBytes(allowedExtensions: ['zip']);
  }

  /// Process the imported ZIP data
  static Future<bool> processImport({
    required Uint8List zipBytes,
    required String secret,
    bool isRecoveryCode = false,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final archive = ZipDecoder().decodeBytes(zipBytes);
      if (archive.isEmpty) {
        showGlobalSnackBar("Invalid or empty archive.", isError: true);
        return false;
      }

      int logsCount = 0;
      int challengesCount = 0;
      int challengeLogsCount = 0;

      bool decryptedAny = false;

      for (final file in archive) {
        if (!file.isFile) continue;

        if (file.name == 'data.json' || file.name == 'logs.json') {
          final content = utf8.decode(file.content as List<int>);
          final encryptedData = json.decode(content) as Map<String, dynamic>;

          final decryptedJson = EncryptionHelper.decryptData(
            encryptedData,
            secret.trim(),
          );

          if (decryptedJson != null) {
            decryptedAny = true;
            final data = json.decode(decryptedJson) as Map<String, dynamic>;

            // Import Logs
            if (data.containsKey('logs')) {
              for (var jsonItem in data['logs']) {
                if (await _importItem(jsonItem, 'log')) logsCount++;
              }
            }

            // Import Challenges
            if (data.containsKey('challenges')) {
              for (var jsonItem in data['challenges']) {
                if (await _importItem(jsonItem, 'challenge')) challengesCount++;
              }
            }

            // Import Challenge Logs
            if (data.containsKey('challengeLogs')) {
              for (var jsonItem in data['challengeLogs']) {
                if (await _importItem(jsonItem, 'challengeLog'))
                  challengeLogsCount++;
              }
            }


          }
        }
      }

      if (!decryptedAny) {
        showGlobalSnackBar(
          isRecoveryCode ? "Invalid recovery code." : "Invalid password.",
          isError: true,
        );
        return false;
      }

      showGlobalSnackBar(
        "Import successful! Logs: $logsCount, Challenges: $challengesCount, Challenge Logs: $challengeLogsCount",
      );

      return true;
    } catch (e) {
      showGlobalSnackBar("Failed to import: $e", isError: true);
      return false;
    }
  }

  static Future<bool> _importItem(
    Map<String, dynamic> jsonData,
    String type,
  ) async {
    try {
      final id =
          jsonData['id'] ?? jsonData['date']; // Daily meta uses date as ID
      if (id == null) return false;

      Map<String, dynamic>? localData;
      switch (type) {
        case 'log':
          localData = HiveService.getLog(id);
          break;
        case 'challenge':
          localData = HiveService.getChallenge(id);
          break;
        case 'challengeLog':
          localData = HiveService.getLog(id);
          break;
      }

      if (localData == null) {
        // Save new
        switch (type) {
          case 'log':
            await HiveService.saveLog(jsonData);
            break;
          case 'challenge':
            await HiveService.saveChallenge(jsonData);
            break;
          case 'challengeLog':
            await HiveService.saveLog(jsonData);
            break;
        }
        return true;
      } else {
        // Update if newer
        final localUpdateStr = localData['updatedAt'] ?? '';
        final importUpdateStr = jsonData['updatedAt'] ?? '';

        final localUpdate = DateTime.tryParse(localUpdateStr);
        final importUpdate = DateTime.tryParse(importUpdateStr);

        if (importUpdate != null &&
            (localUpdate == null || importUpdate.isAfter(localUpdate))) {
          switch (type) {
            case 'log':
              await HiveService.saveLog(jsonData);
              break;
            case 'challenge':
              await HiveService.saveChallenge(jsonData);
              break;
            case 'challengeLog':
              await HiveService.saveLog(jsonData);
              break;
          }
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
