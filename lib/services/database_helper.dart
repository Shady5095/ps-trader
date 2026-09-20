import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/trade.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ps_trades.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trades (
            id TEXT PRIMARY KEY,
            deviceType TEXT NOT NULL,
            controllers INTEGER,
            gamesCount INTEGER,
            purchaseDate TEXT NOT NULL,
            purchasePrice REAL NOT NULL,
            sellerNumber TEXT,
            sellerLocation TEXT,
            gamesIncluded TEXT,
            notes TEXT,
            sellPrice REAL,
            sellDate TEXT,
            buyerNumber TEXT,
            status TEXT NOT NULL,
            imagePath TEXT
          )
        ''');
      },
    );
  }

  Future<List<Trade>> getAllTrades() async {
    final db = await database;
    final rows = await db.query('trades', orderBy: 'purchaseDate DESC');
    return rows.map((r) => Trade.fromMap(r)).toList();
  }

  Future<void> insertTrade(Trade trade) async {
    final db = await database;
    await db.insert('trades', trade.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTrade(Trade trade) async {
    final db = await database;
    await db.update('trades', trade.toMap(),
        where: 'id = ?', whereArgs: [trade.id]);
  }

  Future<void> deleteTrade(String id) async {
    final db = await database;
    await db.delete('trades', where: 'id = ?', whereArgs: [id]);
  }
}
