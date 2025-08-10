import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "qarshicafe.db";
  static const _databaseVersion = 1;

  static const columnId = 'id';
  static const columnLogin = 'login';
  static const columnPassword = 'password';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async =>
      _database ??= await _initiateDatabase();

  Future<Database> _initiateDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    final ourDB = await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
    return ourDB;
  }

  // UPGRADE DATABASE TABLES
  void _onUpgrade(Database db, final oldVersion, int newVersion) {
    if (oldVersion < newVersion) {}
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE Users (
            $columnId INTEGER PRIMARY KEY,
            $columnLogin TEXT,
            $columnPassword TEXT
          )
          ''');
  }

  void insert(Map<String, dynamic> row, String table) async {
    Database db = await instance.database;
    final result = await db.insert(table, row);
    print(result.toString());
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    Database db = await instance.database;
    var result = await db.query(table);
    return result;
  }

  Future<List<Map<String, dynamic>>> getPriceList() async {
    Database db = await instance.database;
    var result = await db.rawQuery('SELECT * FROM Pricelist ORDER BY Product');
    return result;
  }

  Future getUser() async {
    Database db = await database;

    List<String> columnsToSelect = [
      DatabaseHelper.columnId,
      DatabaseHelper.columnLogin,
      DatabaseHelper.columnPassword
    ];

    List<Map> result = await db.query('Users', columns: columnsToSelect);
    if (result.isNotEmpty) {
      return result[0];
    } else {
      return null;
    }
  }

  Future<int?> queryRowCount(String table) async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  void insertBatch(List<dynamic> objects, String table) async {
    try {
      Database db = await instance.database;
      Batch batch = db.batch();
      print('batch insert : ${objects.length}');

      for (var i in objects) {
        batch.insert(table, i);
      }
      final result = await batch.commit(noResult: true);
      print('batch update result: $result');
    } catch (e) {
      print('error null insert');
    }
  }

  Future<int> update(Map<String, dynamic> row, String table) async {
    Database db = await instance.database;
    String guid = row[columnId];
    return await db
        .update(table, row, where: '$columnId = ?', whereArgs: [guid]);
  }

  Future<int> delete(int id, String table) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future dropTable(String table) async {
    Database db = await instance.database;
    await db.execute('''
          DROP TABLE $table''');
  }

  Future deleteAll(String table) async {
    Database db = await instance.database;
    await db.execute('''
          DELETE FROM $table''');
  }

  Future clearTables() async {
    Database db = await instance.database;
    await db.execute('''
          DELETE FROM Users''');
  }
}
