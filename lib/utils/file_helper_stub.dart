import 'dart:typed_data';

Future<void> platformSaveAndShareFile(
  Uint8List bytes,
  String fileName, {
  required String mimeType,
}) {
  throw UnsupportedError(
    'Cannot save and share file without dart:html or dart:io',
  );
}

Future<String?> platformPickFile({List<String>? allowedExtensions}) {
  throw UnsupportedError('Cannot pick file without dart:html or dart:io');
}

Future<Uint8List?> platformPickFileBytes({List<String>? allowedExtensions}) {
  throw UnsupportedError('Cannot pick file bytes without dart:html or dart:io');
}

Future<void> platformSaveAndShareText(String content, String fileName) {
  throw UnsupportedError(
    'Cannot save and share text without dart:html or dart:io',
  );
}
