/// File saver implementation for Flutter Web using browser Blob download link.
library;

import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<String> getDownloadsDirectoryPath() async {
  return 'Browser Downloads';
}

dynamic getUniqueExportFileImpl(String savePath, String shift, DateTime date) {
  return '${shift}_${date.day}-${date.month}-${date.year}.xlsx';
}

Future<String?> saveAndDownloadFile({
  required List<int> bytes,
  required String fileName,
  String? targetDirectory,
}) async {
  final uint8List = Uint8List.fromList(bytes);
  final blob = web.Blob(
    [uint8List.toJS].toJS,
    web.BlobPropertyBag(type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return fileName;
}
