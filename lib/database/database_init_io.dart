/// IO Database initialization for Desktop & Mobile native platforms.
library;

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

DatabaseFactory getPlatformDatabaseFactory() {
  sqfliteFfiInit();
  return databaseFactoryFfi;
}

Future<String> getDatabasePath(String filePath) async {
  try {
    final appDocDir = await getApplicationDocumentsDirectory();
    return join(appDocDir.path, 'ET_Calculator', filePath);
  } catch (_) {
    return filePath;
  }
}
