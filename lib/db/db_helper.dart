import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'transactions.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount REAL,
            category TEXT,
            isIncome INTEGER,
            date TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE budgets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT UNIQUE,
            budget_limit REAL
          )
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS budgets(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category TEXT UNIQUE,
              budget_limit REAL
            )
          ''');
        }
      },
    );
  }

  // ---- transactions ----
  static Future<int> insertTransaction(TransactionModel txn) async {
    final db = await database;
    return await db.insert(
      'transactions',
      txn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  static Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> updateTransaction(TransactionModel txn) async {
    final db = await database;
    return await db.update(
      'transactions',
      txn.toMap(),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  // ---- budgets ----
  static Future<List<BudgetModel>> getAllBudgets() async {
    final db = await database;
    final rows = await db.query('budgets', orderBy: 'category ASC');
    return rows.map((r) => BudgetModel.fromMap(r)).toList();
  }

  static Future<BudgetModel?> getBudgetForCategory(String category) async {
    final db = await database;
    final rows = await db.query(
      'budgets',
      where: 'category = ?',
      whereArgs: [category],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BudgetModel.fromMap(rows.first);
  }

  static Future<int> upsertBudget(BudgetModel b) async {
    final db = await database;

    // check if category exists
    final existing = await db.query(
      'budgets',
      where: 'category = ?',
      whereArgs: [b.category],
      limit: 1,
    );

    // remove id field if null
    final data = b.toMap()..removeWhere((key, value) => value == null);

    if (existing.isEmpty) {
      // insert new budget
      return await db.insert(
        'budgets',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      // update existing budget (don't include id in update)
      data.remove('id');
      return await db.update(
        'budgets',
        data,
        where: 'category = ?',
        whereArgs: [b.category],
      );
    }
  }

  static Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ---- CSV export ----
  static Future<String> exportTransactionsToCsv() async {
    final txns = await getAllTransactions();
    final rows = <List<dynamic>>[];
    rows.add(['id', 'title', 'amount', 'category', 'isIncome', 'date']);
    for (var t in txns) {
      rows.add([
        t.id,
        t.title,
        t.amount,
        t.category,
        t.isIncome ? 1 : 0,
        t.date.toIso8601String(),
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    Directory dir;
    try {
      // Try Flutter directory (works in app)
      dir = await getApplicationDocumentsDirectory();
    } catch (e) {
      // Fallback for tests (no platform channel available)
      dir = Directory.systemTemp.createTempSync('spfe_csv_test');
    }

    final path = join(
      dir.path,
      'smart_expense_${DateTime.now().millisecondsSinceEpoch}.csv',
    );

    final file = File(path);
    await file.writeAsString(csv);
    return path;
  }
}
