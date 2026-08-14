/// Web Database initialization for Flutter Web using sqflite_common_ffi_web / IndexedDB.
library;

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

DatabaseFactory getPlatformDatabaseFactory() {
  return databaseFactoryFfiWeb;
}

Future<String> getDatabasePath(String filePath) async {
  return filePath;
}
