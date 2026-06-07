import 'dart:typed_data';
import 'dart:io' as io;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

/// Mobile-specific implementation using share_plus
Future<void> platformSaveAndShareFile(
  Uint8List bytes,
  String fileName, {
  required String mimeType,
}) async {
  // Using Share.shareXFiles which is currently standard in share_plus
  await Share.shareXFiles([
    XFile.fromData(bytes, name: fileName, mimeType: mimeType),
  ], subject: 'Data Export');
}

/// Mobile-specific implementation for picking files as String
Future<String?> platformPickFile({List<String>? allowedExtensions}) async {
  final result = await FilePicker.platform.pickFiles(
    type: allowedExtensions != null ? FileType.custom : FileType.any,
    allowedExtensions: allowedExtensions,
  );

  if (result == null || result.files.isEmpty) return null;
  final path = result.files.first.path;
  if (path == null) return null;

  return io.File(path).readAsString();
}

/// Mobile-specific implementation for picking files as bytes
Future<Uint8List?> platformPickFileBytes({
  List<String>? allowedExtensions,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: allowedExtensions != null ? FileType.custom : FileType.any,
    allowedExtensions: allowedExtensions,
  );

  if (result == null || result.files.isEmpty) return null;
  final path = result.files.first.path;
  if (path == null) return null;

  return io.File(path).readAsBytes();
}

Future<void> platformSaveAndShareText(String content, String fileName) async {
  final bytes = utf8.encode(content);
  await Share.shareXFiles([
    XFile.fromData(bytes, name: fileName, mimeType: 'text/plain'),
  ], subject: 'Recovery Phrase');
}
