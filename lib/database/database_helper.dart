/// SQLite Database Helper for desktop offline storage (Production Data).
library;

import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/production.dart';
import '../utils/natural_sort.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('et_calculator.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialize FFI for desktop (Linux / Windows)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocDir.path, 'ET_Calculator', filePath);

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  FutureOr<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE production (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        machine TEXT NOT NULL,
        plant TEXT NOT NULL,
        productCode TEXT NOT NULL,
        good REAL NOT NULL,
        reject REAL NOT NULL,
        qa REAL NOT NULL,
        sample REAL NOT NULL,
        hold REAL NOT NULL DEFAULT 0.0,
        tested REAL NOT NULL,
        shift TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE production ADD COLUMN hold REAL NOT NULL DEFAULT 0.0');
    }
  }

  // --- Production CRUD Operations ---

  Future<int> insertProduction(Production prod) async {
    final db = await database;
    return await db.insert('production', prod.toMap());
  }

  Future<List<Production>> getAllProductions() async {
    final db = await database;
    final maps = await db.query('production', orderBy: 'createdAt DESC');
    final list = maps.map((m) => Production.fromMap(m)).toList();
    list.sort((a, b) {
      final comp = compareNatural(a.machine, b.machine);
      if (comp != 0) return comp;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  Future<Production?> getProductionById(int id) async {
    final db = await database;
    final maps = await db.query(
      'production',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Production.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduction(Production prod) async {
    final db = await database;
    return await db.update(
      'production',
      prod.toMap(),
      where: 'id = ?',
      whereArgs: [prod.id],
    );
  }

  Future<int> deleteProduction(int id) async {
    final db = await database;
    return await db.delete(
      'production',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllProductions() async {
    final db = await database;
    return await db.delete('production');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
