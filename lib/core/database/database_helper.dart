// lib/core/database/database_helper.dart
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../models/budget_model.dart';
import '../../models/goal_model.dart';
import '../../models/notification_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'personal_finance.db');

    return await openDatabase(
      path,
      version: 2, // Updated version to include new tables
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_login_at TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // App settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        color_code TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
        is_default INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT NULL,
        icon TEXT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Budgets table
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        budget_amount REAL NOT NULL,
        spent_amount REAL DEFAULT 0.0,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id, category, month, year)
      )
    ''');

    // Goals table
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        target_amount REAL NOT NULL,
        current_amount REAL DEFAULT 0.0,
        target_date TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_code TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_code TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        read_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_transactions_user_date ON transactions(user_id, date DESC)');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions(category)');
    await db.execute('CREATE INDEX idx_budgets_user_month_year ON budgets(user_id, month, year)');
    await db.execute('CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC)');
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new tables for version 2
      await _createDb(db, newVersion);
    }
  }

  // ==================== USER OPERATIONS ====================

  Future<int> createUser(UserModel user) async {
    final db = await database;
    final userId = await db.insert('users', user.toMap());

    // Create default categories for new user
    await _createDefaultCategories(userId);

    return userId;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND is_active = 1',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ? AND is_active = 1',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> updateLastLogin(int userId) async {
    final db = await database;
    return await db.update(
      'users',
      {'last_login_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.update(
      'users',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ==================== CATEGORY OPERATIONS ====================

  Future<int> createCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> getCategoriesByUser(int userId, {String? type}) async {
    final db = await database;
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'is_default DESC, name ASC',
    );

    return List.generate(maps.length, (i) => CategoryModel.fromMap(maps[i]));
  }

  Future<void> _createDefaultCategories(int userId) async {
    final defaultCategories = CategoryModel.getDefaultCategories(userId);
    final db = await database;

    for (final category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  // ==================== TRANSACTION OPERATIONS ====================

  Future<int> createTransaction(TransactionModel transaction) async {
    final db = await database;
    final result = await db.insert('transactions', transaction.toMap());

    // Update budget spent amount if it's an expense
    if (transaction.isExpense) {
      await _updateBudgetSpentAmount(transaction.userId, transaction.category, transaction.amount);
    }

    return result;
  }
  // Add this method to your DatabaseHelper class in the TRANSACTION OPERATIONS section

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;

    // If it's an expense, we need to handle budget updates
    if (transaction.isExpense) {
      // Get the old transaction to calculate budget adjustment
      final oldTransactionMaps = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      if (oldTransactionMaps.isNotEmpty) {
        final oldTransaction = TransactionModel.fromMap(oldTransactionMaps.first);

        // If category or amount changed, update budget spent amounts
        if (oldTransaction.category != transaction.category ||
            oldTransaction.amount != transaction.amount) {

          // Reduce old category budget spent amount
          await _reduceBudgetSpentAmount(
              transaction.userId,
              oldTransaction.category,
              oldTransaction.amount
          );

          // Add new amount to new category budget
          await _updateBudgetSpentAmount(
              transaction.userId,
              transaction.category,
              transaction.amount
          );
        }
      }
    }

    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

// Also add this helper method for budget adjustments
  Future<void> _reduceBudgetSpentAmount(int userId, String category, double amount) async {
    final now = DateTime.now();
    final db = await database;

    await db.rawUpdate('''
    UPDATE budgets 
    SET spent_amount = CASE 
      WHEN spent_amount - ? < 0 THEN 0 
      ELSE spent_amount - ? 
    END,
    updated_at = ?
    WHERE user_id = ? AND category = ? AND month = ? AND year = ? AND is_active = 1
  ''', [amount, amount, now.toIso8601String(), userId, category, now.month, now.year]);
  }

  Future<List<TransactionModel>> getTransactionsByUser(
      int userId, {
        int limit = 50,
        int offset = 0,
        String? type,
        String? category,
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    final db = await database;
    String whereClause = 'user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type);
    }

    if (category != null) {
      whereClause += ' AND category = ?';
      whereArgs.add(category);
    }

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<Map<String, double>> getBalanceSummary(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        type,
        SUM(amount) as total
      FROM transactions 
      WHERE user_id = ? 
      GROUP BY type
    ''', [userId]);

    double income = 0.0;
    double expense = 0.0;

    for (final row in result) {
      if (row['type'] == 'income') {
        income = (row['total'] as num).toDouble();
      } else if (row['type'] == 'expense') {
        expense = (row['total'] as num).toDouble();
      }
    }

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  Future<Map<String, double>> getExpensesByCategory(int userId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String whereClause = 'user_id = ? AND type = ?';
    List<dynamic> whereArgs = [userId, 'expense'];

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT 
        category,
        SUM(amount) as total
      FROM transactions 
      WHERE $whereClause
      GROUP BY category
      ORDER BY total DESC
    ''', whereArgs);

    Map<String, double> expenses = {};
    for (final row in result) {
      expenses[row['category'] as String] = (row['total'] as num).toDouble();
    }

    return expenses;
  }

  Future<int> deleteTransaction(int transactionId) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // ==================== BUDGET OPERATIONS ====================

  Future<int> createBudget(BudgetModel budget) async {
    final db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<List<BudgetModel>> getBudgetsByUser(int userId, {int? month, int? year}) async {
    final db = await database;
    String whereClause = 'user_id = ? AND is_active = 1';
    List<dynamic> whereArgs = [userId];

    if (month != null) {
      whereClause += ' AND month = ?';
      whereArgs.add(month);
    }

    if (year != null) {
      whereClause += ' AND year = ?';
      whereArgs.add(year);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'category ASC',
    );

    return List.generate(maps.length, (i) => BudgetModel.fromMap(maps[i]));
  }

  Future<int> updateBudget(BudgetModel budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> _updateBudgetSpentAmount(int userId, String category, double amount) async {
    final now = DateTime.now();
    final db = await database;

    await db.rawUpdate('''
      UPDATE budgets 
      SET spent_amount = spent_amount + ?, updated_at = ?
      WHERE user_id = ? AND category = ? AND month = ? AND year = ? AND is_active = 1
    ''', [amount, now.toIso8601String(), userId, category, now.month, now.year]);
  }

  // Add this method to DatabaseHelper for debugging
  Future<void> debugPrintAllTransactions(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    print('=== DEBUG: All transactions for user $userId ===');
    print('Total transactions: ${maps.length}');
    for (var map in maps) {
      print('Transaction: $map');
    }
  }

  // ==================== GOAL OPERATIONS ====================

  Future<int> createGoal(GoalModel goal) async {
    final db = await database;
    return await db.insert('goals', goal.toMap());
  }

  Future<List<GoalModel>> getGoalsByUser(int userId, {bool? isCompleted}) async {
    final db = await database;
    String whereClause = 'user_id = ? AND is_active = 1';
    List<dynamic> whereArgs = [userId];

    if (isCompleted != null) {
      whereClause += ' AND is_completed = ?';
      whereArgs.add(isCompleted ? 1 : 0);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'goals',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'target_date ASC, created_at DESC',
    );

    return List.generate(maps.length, (i) => GoalModel.fromMap(maps[i]));
  }

  Future<int> updateGoal(GoalModel goal) async {
    final db = await database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> updateGoalProgress(int goalId, double amount) async {
    final db = await database;
    final now = DateTime.now();

    return await db.rawUpdate('''
      UPDATE goals 
      SET current_amount = current_amount + ?, 
          updated_at = ?,
          is_completed = CASE WHEN current_amount + ? >= target_amount THEN 1 ELSE 0 END
      WHERE id = ?
    ''', [amount, now.toIso8601String(), amount, goalId]);
  }

  // ==================== NOTIFICATION OPERATIONS ====================

  Future<int> createNotification(NotificationModel notification) async {
    final db = await database;
    return await db.insert('notifications', notification.toMap());
  }

  Future<List<NotificationModel>> getNotificationsByUser(int userId, {bool? isRead, int limit = 50}) async {
    final db = await database;
    String whereClause = 'user_id = ? AND is_active = 1';
    List<dynamic> whereArgs = [userId];

    if (isRead != null) {
      whereClause += ' AND is_read = ?';
      whereArgs.add(isRead ? 1 : 0);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => NotificationModel.fromMap(maps[i]));
  }

  Future<int> markNotificationAsRead(int notificationId) async {
    final db = await database;
    return await db.update(
      'notifications',
      {
        'is_read': 1,
        'read_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<int> getUnreadNotificationCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM notifications 
      WHERE user_id = ? AND is_read = 0 AND is_active = 1
    ''', [userId]);

    return (result.first['count'] as int);
  }

  // ==================== APP SETTINGS OPERATIONS ====================

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'];
    }
    return null;
  }

  Future<int> removeSetting(String key) async {
    final db = await database;
    return await db.delete(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  // ==================== UTILITY METHODS ====================

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('notifications');
    await db.delete('goals');
    await db.delete('budgets');
    await db.delete('transactions');
    await db.delete('categories');
    await db.delete('users');
    await db.delete('app_settings');
  }

  Future<bool> databaseExists() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'personal_finance.db');
    return File(path).exists();
  }

  // ==================== ANALYTICS HELPER METHODS ====================

  Future<Map<String, dynamic>> getDashboardData(int userId) async {
    final balanceSummary = await getBalanceSummary(userId);
    final recentTransactions = await getTransactionsByUser(userId, limit: 5);
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final budgets = await getBudgetsByUser(userId, month: currentMonth, year: currentYear);
    final goals = await getGoalsByUser(userId, isCompleted: false);
    final unreadNotifications = await getUnreadNotificationCount(userId);

    return {
      'balance': balanceSummary,
      'recentTransactions': recentTransactions,
      'budgets': budgets,
      'goals': goals,
      'unreadNotifications': unreadNotifications,
    };
  }
}

