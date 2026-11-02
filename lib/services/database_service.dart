import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/budget.dart';
import '../models/expense.dart';
import '../models/profile.dart';
import '../models/savings_goal.dart';
import '../models/user_model.dart';

class DatabaseService {
  static Future<Database>? _databaseFuture;

  static Future<void> initialize() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
    await database;
  }

  static Future<Database> get database =>
      _databaseFuture ??= _initDatabase();

  static Future<Database> _initDatabase() async {
    if (kIsWeb) {
      return openDatabase(
        'budget_buddy.db',
        version: 1,
        onCreate: _onCreate,
      );
    }

    final dbDir = await getDatabasesPath();
    final path = join(dbDir, 'budget_buddy.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE monthly_budgets (
        id TEXT PRIMARY KEY,
        month_key TEXT NOT NULL,
        total_budget REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE category_budgets (
        id TEXT PRIMARY KEY,
        month_key TEXT NOT NULL,
        category TEXT NOT NULL,
        "limit" REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_saved REAL NOT NULL,
        target_date TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_transactions (
        id TEXT PRIMARY KEY,
        goal_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        preferred_currency TEXT NOT NULL,
        monthly_allowance REAL NOT NULL,
        notifications_enabled INTEGER NOT NULL,
        theme_mode TEXT NOT NULL
      )
    ''');
  }

  static String getMonthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  static Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  static Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert('expenses', expense.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  static Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Expense>> getExpenses() async {
    final db = await database;
    final rows = await db.query('expenses', orderBy: 'date DESC, created_at DESC');
    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  static Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    final key = getMonthKey(month);
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT * FROM expenses WHERE substr(date, 1, 7) = ? ORDER BY date DESC',
      [key],
    );
    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  static Future<double> getTotalExpensesForMonth(DateTime month) async {
    final key = getMonthKey(month);
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE substr(date, 1, 7) = ?',
      [key],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  static Future<double> getCategoryTotal(String category, DateTime month) async {
    final key = getMonthKey(month);
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE category = ? AND substr(date, 1, 7) = ?',
      [category, key],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  static Future<void> upsertMonthlyBudget(MonthlyBudget budget) async {
    final db = await database;
    await db.insert('monthly_budgets', budget.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<MonthlyBudget?> getMonthlyBudget(DateTime month) async {
    final db = await database;
    final key = getMonthKey(month);
    final rows = await db.query(
      'monthly_budgets',
      where: 'month_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MonthlyBudget.fromMap(rows.first);
  }

  static Future<void> upsertCategoryBudget(CategoryBudget budget) async {
    final db = await database;
    await db.insert('category_budgets', budget.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<CategoryBudget>> getCategoryBudgetsForMonth(DateTime month) async {
    final db = await database;
    final key = getMonthKey(month);
    final rows = await db.query(
      'category_budgets',
      where: 'month_key = ?',
      whereArgs: [key],
      orderBy: 'category ASC',
    );
    return rows.map((row) => CategoryBudget.fromMap(row)).toList();
  }

  static Future<void> insertGoal(SavingsGoal goal) async {
    final db = await database;
    await db.insert('savings_goals', goal.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateGoal(SavingsGoal goal) async {
    final db = await database;
    await db.update(
      'savings_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  static Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
    await db.delete('savings_transactions', where: 'goal_id = ?', whereArgs: [id]);
  }

  static Future<List<SavingsGoal>> getSavingsGoals() async {
    final db = await database;
    final rows = await db.query('savings_goals', orderBy: 'target_date ASC');
    return rows.map((row) => SavingsGoal.fromMap(row)).toList();
  }

  static Future<void> insertSavingsTransaction(SavingsTransaction transaction) async {
    final db = await database;
    await db.insert(
      'savings_transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<SavingsTransaction>> getSavingsTransactionsForGoal(String goalId) async {
    final db = await database;
    final rows = await db.query(
      'savings_transactions',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'date DESC',
    );
    return rows.map((row) => SavingsTransaction.fromMap(row)).toList();
  }

  static Future<void> upsertProfile(UserProfile profile) async {
    final db = await database;
    await db.insert('profile', profile.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<UserProfile?> getProfile() async {
    final db = await database;
    final rows = await db.query('profile', limit: 1);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('monthly_budgets');
    await db.delete('category_budgets');
    await db.delete('savings_transactions');
    await db.delete('savings_goals');
    await db.delete('profile');
  }
}
