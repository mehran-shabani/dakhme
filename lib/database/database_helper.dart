import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> initializeDatabase() async {
    final path = join(await getDatabasesPath(), 'transactions.db');
// ignore: avoid_print
   print('Database path: $path');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE transactions (id INTEGER PRIMARY KEY, type TEXT, category TEXT, amount REAL, note TEXT, date TEXT)',
        );
      },
    );
  }
}
