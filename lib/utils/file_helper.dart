import 'dart:typed_data';
import 'file_helper_stub.dart'
    if (dart.library.html) 'file_helper_web.dart'
    if (dart.library.io) 'file_helper_mobile.dart';

/// Helper to handle file saving and sharing across platforms
class FileHelper {
  /// Save and share (or download) a file
  static Future<void> saveAndShareFile(
    Uint8List bytes,
    String fileName, {
    String mimeType = 'application/json',
  }) async {
    return platformSaveAndShareFile(bytes, fileName, mimeType: mimeType);
  }

  /// Pick a file and return its content as a string
  static Future<String?> pickFile({List<String>? allowedExtensions}) async {
    return platformPickFile(allowedExtensions: allowedExtensions);
  }

  /// Pick a file and return its content as bytes
  static Future<Uint8List?> pickFileBytes({
    List<String>? allowedExtensions,
  }) async {
    return platformPickFileBytes(allowedExtensions: allowedExtensions);
  }

  /// Save and share (or download) a text file
  static Future<void> saveAndShareText(String content, String fileName) async {
    return platformSaveAndShareText(content, fileName);
  }
}
