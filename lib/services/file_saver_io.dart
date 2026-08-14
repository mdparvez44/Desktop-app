/// File saver implementation for Native Desktop & Mobile platforms using dart:io.
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> getDownloadsDirectoryPath() async {
  try {
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null && await downloadsDir.exists()) {
      return downloadsDir.path;
    }
  } catch (_) {}

  final userHome = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  if (userHome.isNotEmpty) {
    final fallbackDownloads = p.join(userHome, 'Downloads');
    final dir = Directory(fallbackDownloads);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  final appDocDir = await getApplicationDocumentsDirectory();
  return appDocDir.path;
}

File getUniqueExportFileImpl(String savePath, String shift, DateTime date) {
  final baseName = '${shift}_${date.day}-${date.month}-${date.year}';
  String targetPath = p.join(savePath, '$baseName.xlsx');
  File file = File(targetPath);

  int counter = 1;
  while (file.existsSync()) {
    targetPath = p.join(savePath, '$baseName ($counter).xlsx');
    file = File(targetPath);
    counter++;
  }
  return file;
}

Future<String?> saveAndDownloadFile({
  required List<int> bytes,
  required String fileName,
  String? targetDirectory,
}) async {
  final savePath = (targetDirectory != null && targetDirectory.isNotEmpty && Directory(targetDirectory).existsSync())
      ? targetDirectory
      : await getDownloadsDirectoryPath();

  if (!Directory(savePath).existsSync()) {
    throw Exception('Export Save Location Unavailable: The configured folder "$savePath" does not exist.');
  }

  final nameWithoutExt = p.basenameWithoutExtension(fileName);
  final ext = p.extension(fileName);
  String targetPath = p.join(savePath, '$nameWithoutExt$ext');
  File file = File(targetPath);

  int counter = 1;
  while (file.existsSync()) {
    targetPath = p.join(savePath, '$nameWithoutExt ($counter)$ext');
    file = File(targetPath);
    counter++;
  }

  await file.writeAsBytes(bytes);
  return file.path;
}
