/// Database initialization stub for platform conditional compilation.
library;

import 'package:sqflite_common/sqlite_api.dart';

DatabaseFactory getPlatformDatabaseFactory() {
  throw UnsupportedError('Cannot get database factory without platform implementation.');
}

Future<String> getDatabasePath(String filePath) async {
  throw UnsupportedError('Cannot get database path without platform implementation.');
}
