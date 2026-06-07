import 'dart:convert';
import 'package:done_today/config/client_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

enum UpdateType { none, minor, major }

class UpdateInfo {
  final UpdateType type;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;

  UpdateInfo({
    required this.type,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}

class UpdateService {
  static const String _githubRepo = ClientConfig.gitHubRepo;
  static const String _apiUrl =
      'https://api.github.com/repos/$_githubRepo/releases/latest';

  /// Checks for updates against the latest GitHub release.
  static Future<UpdateInfo?> checkForUpdates() async {
    if (kIsWeb) return null;
    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = _cleanVersion(packageInfo.version);
      final currentParts = _parseVersion(currentVersionStr);

      if (currentParts.isEmpty) return null;

      // 2. Fetch latest release from GitHub
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestTagStr = _cleanVersion(data['tag_name'] as String? ?? '');
        final latestParts = _parseVersion(latestTagStr);

        if (latestParts.isEmpty) return null;

        final downloadUrl = data['html_url'] as String;
        final releaseNotes =
            data['body'] as String? ?? 'No release notes provided.';

        // 3. Compare versions
        final updateType = _compareVersions(currentParts, latestParts);

        if (updateType != UpdateType.none) {
          return UpdateInfo(
            type: updateType,
            latestVersion: latestTagStr,
            downloadUrl: downloadUrl,
            releaseNotes: releaseNotes,
          );
        }
      }
      return null;
    } catch (e) {
      // Silently fail if unable to check for updates (e.g., no internet)
      return null;
    }
  }

  /// Removes 'v' prefix and any build number suffixes (e.g. '+1')
  static String _cleanVersion(String version) {
    var clean = version.toLowerCase().replaceAll('v', '').trim();
    if (clean.contains('+')) {
      clean = clean.split('+').first;
    }
    return clean;
  }

  /// Parses '1.2.3' into [1, 2, 3]
  static List<int> _parseVersion(String version) {
    try {
      return version.split('.').map((s) => int.parse(s)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Compares current [1, 0, 0] with latest [2, 0, 0]
  static UpdateType _compareVersions(List<int> current, List<int> latest) {
    // Pad lists if they are short (e.g., "1.0" -> [1, 0, 0])
    while (current.length < 3) current.add(0);
    while (latest.length < 3) latest.add(0);

    // Major update
    if (latest[0] > current[0]) {
      return UpdateType.major;
    }
    // Minor or Patch update
    if (latest[0] == current[0] &&
        (latest[1] > current[1] ||
            (latest[1] == current[1] && latest[2] > current[2]))) {
      return UpdateType.minor;
    }

    return UpdateType.none;
  }
}
