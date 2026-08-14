/// File saver stub for conditional compilation.
library;

Future<String?> saveAndDownloadFile({
  required List<int> bytes,
  required String fileName,
  String? targetDirectory,
}) async {
  throw UnsupportedError('Cannot save file without platform implementation.');
}

Future<String> getDownloadsDirectoryPath() async {
  throw UnsupportedError('Cannot get downloads path without platform implementation.');
}

dynamic getUniqueExportFileImpl(String savePath, String shift, DateTime date) {
  throw UnsupportedError('Cannot get unique export file without platform implementation.');
}
