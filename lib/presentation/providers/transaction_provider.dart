// lib/presentation/providers/transaction_provider.dart
import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  Map<String, double> _balanceSummary = {
    'income': 0.0,
    'expense': 0.0,
    'balance': 0.0,
  };
  Map<String, double> _expensesByCategory = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get recentTransactions => _transactions.take(10).toList();
  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get incomeCategories => _categories.where((c) => c.isIncomeCategory).toList();
  List<CategoryModel> get expenseCategories => _categories.where((c) => c.isExpenseCategory).toList();
  Map<String, double> get balanceSummary => _balanceSummary;
  Map<String, double> get expensesByCategory => _expensesByCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalBalance => _balanceSummary['balance'] ?? 0.0;
  double get totalIncome => _balanceSummary['income'] ?? 0.0;
  double get totalExpense => _balanceSummary['expense'] ?? 0.0;

  // Initialize data for user
  Future<void> initializeForUser(int userId) async {
    _setLoading(true);
    try {
      await Future.wait([
        loadCategories(userId),
        loadTransactions(userId),
        loadBalanceSummary(userId),
        loadExpensesByCategory(userId),
      ]);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing transaction provider: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load categories
  Future<void> loadCategories(int userId) async {
    try {
      _categories = await _databaseHelper.getCategoriesByUser(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading categories: $e');
    }
  }

  // Load transactions
  Future<void> loadTransactions(int userId, {
    int limit = 100,
    int offset = 0,
    String? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (offset == 0) {
        _transactions.clear();
      }

      final newTransactions = await _databaseHelper.getTransactionsByUser(
        userId,
        limit: limit,
        offset: offset,
        type: type,
        category: category,
        startDate: startDate,
        endDate: endDate,
      );

      if (offset == 0) {
        _transactions = newTransactions;
      } else {
        _transactions.addAll(newTransactions);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading transactions: $e');
    }
  }

  // Load balance summary
  Future<void> loadBalanceSummary(int userId) async {
    try {
      _balanceSummary = await _databaseHelper.getBalanceSummary(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading balance summary: $e');
    }
  }

  // Load expenses by category for current month
  Future<void> loadExpensesByCategory(int userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      // Default to current month if no dates provided
      final now = DateTime.now();
      startDate ??= DateTime(now.year, now.month, 1);
      endDate ??= DateTime(now.year, now.month + 1, 0);

      _expensesByCategory = await _databaseHelper.getExpensesByCategory(
        userId,
        startDate: startDate,
        endDate: endDate,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading expenses by category: $e');
    }
  }

  // Add new transaction
  Future<bool> addTransaction(TransactionModel transaction) async {
    _setLoading(true);
    try {
      final id = await _databaseHelper.createTransaction(transaction);

      if (id > 0) {
        // Add to local list
        final newTransaction = transaction.copyWith(id: id);
        _transactions.insert(0, newTransaction);

        // Update balance summary
        if (transaction.isIncome) {
          _balanceSummary['income'] = (_balanceSummary['income'] ?? 0.0) + transaction.amount;
        } else {
          _balanceSummary['expense'] = (_balanceSummary['expense'] ?? 0.0) + transaction.amount;

          // Update category expenses
          _expensesByCategory[transaction.category] =
              (_expensesByCategory[transaction.category] ?? 0.0) + transaction.amount;
        }

        _balanceSummary['balance'] = (_balanceSummary['income'] ?? 0.0) - (_balanceSummary['expense'] ?? 0.0);

        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add new category
  Future<bool> addCategory(CategoryModel category) async {
    try {
      final id = await _databaseHelper.createCategory(category);

      if (id > 0) {
        final newCategory = category.copyWith(id: id);
        _categories.add(newCategory);
        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding category: $e');
      return false;
    }
  }

  // Delete transaction
  Future<bool> deleteTransaction(int transactionId) async {
    try {
      final result = await _databaseHelper.deleteTransaction(transactionId);

      if (result > 0) {
        _transactions.removeWhere((t) => t.id == transactionId);
        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting transaction: $e');
      return false;
    }
  }

  // Get transactions by date range
  List<TransactionModel> getTransactionsByDateRange(DateTime startDate, DateTime endDate) {
    return _transactions.where((transaction) {
      return transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get transactions by category
  List<TransactionModel> getTransactionsByCategory(String category) {
    return _transactions.where((transaction) => transaction.category == category).toList();
  }

  // Get monthly expense total
  double getMonthlyExpenseTotal({required int month, required int year}) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    return _transactions
        .where((transaction) =>
    transaction.isExpense &&
        transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        transaction.date.isBefore(endDate.add(const Duration(days: 1))))
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Get monthly income total
  double getMonthlyIncomeTotal({required int month, required int year}) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    return _transactions
        .where((transaction) =>
    transaction.isIncome &&
        transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        transaction.date.isBefore(endDate.add(const Duration(days: 1))))
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Get category color
  String getCategoryColor(String categoryName) {
    final category = _categories.firstWhere(
          (c) => c.name == categoryName,
      orElse: () => CategoryModel(
        userId: 0,
        name: categoryName,
        colorCode: '#757575',
        iconName: 'category',
        type: 'expense',
        createdAt: DateTime.now(),
      ),
    );
    return category.colorCode;
  }

  // Get category icon
  String getCategoryIcon(String categoryName) {
    final category = _categories.firstWhere(
          (c) => c.name == categoryName,
      orElse: () => CategoryModel(
        userId: 0,
        name: categoryName,
        colorCode: '#757575',
        iconName: 'category',
        type: 'expense',
        createdAt: DateTime.now(),
      ),
    );
    return category.iconName;
  }

  // Refresh all data
  Future<void> refreshData(int userId) async {
    await initializeForUser(userId);
  }

  // Clear all data (for logout)
  void clearData() {
    _transactions.clear();
    _categories.clear();
    _balanceSummary = {'income': 0.0, 'expense': 0.0, 'balance': 0.0};
    _expensesByCategory.clear();
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get spending insights
  Map<String, dynamic> getSpendingInsights() {
    if (_expensesByCategory.isEmpty) return {};

    final total = _expensesByCategory.values.fold(0.0, (sum, amount) => sum + amount);
    if (total == 0) return {};

    // Find highest spending category
    final highestCategory = _expensesByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    // Calculate percentage
    final percentage = ((highestCategory.value / total) * 100).round();

    return {
      'category': highestCategory.key,
      'amount': highestCategory.value,
      'percentage': percentage,
      'total': total,
    };
  }
}