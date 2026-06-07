import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';

/// Web-specific implementation for saving files via direct download
Future<void> platformSaveAndShareFile(
  Uint8List bytes,
  String fileName, {
  required String mimeType,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();

  html.Url.revokeObjectUrl(url);
}

/// Web-specific implementation for picking files as String
Future<String?> platformPickFile({List<String>? allowedExtensions}) async {
  final completer = Completer<String?>();
  final html.FileUploadInputElement selectionInput =
      html.FileUploadInputElement();

  if (allowedExtensions != null) {
    selectionInput.accept = allowedExtensions.map((e) => '.$e').join(',');
  }

  selectionInput.onChange.listen((event) {
    final files = selectionInput.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onLoadEnd.listen((e) {
      completer.complete(reader.result as String?);
    });
    reader.onError.listen((e) {
      completer.complete(null);
    });
    reader.readAsText(files[0]);
  });

  selectionInput.click();

  return completer.future;
}

/// Web-specific implementation for picking files as bytes
Future<Uint8List?> platformPickFileBytes({
  List<String>? allowedExtensions,
}) async {
  final completer = Completer<Uint8List?>();
  final html.FileUploadInputElement selectionInput =
      html.FileUploadInputElement();

  if (allowedExtensions != null) {
    selectionInput.accept = allowedExtensions.map((e) => '.$e').join(',');
  }

  selectionInput.onChange.listen((event) {
    final files = selectionInput.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onLoadEnd.listen((e) {
      completer.complete(reader.result as Uint8List?);
    });
    reader.onError.listen((e) {
      completer.complete(null);
    });
    reader.readAsArrayBuffer(files[0]);
  });

  selectionInput.click();

  return completer.future;
}

Future<void> platformSaveAndShareText(String content, String fileName) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'text/plain');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();

  html.Url.revokeObjectUrl(url);
}
