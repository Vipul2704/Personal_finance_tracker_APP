// lib/presentation/providers/budget_provider.dart
import 'package:flutter/foundation.dart';
import 'package:personal_finance_tracker/core/database/database_helper.dart';
import '../../models/budget_model.dart';

class BudgetProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get budgets for current month
  List<BudgetModel> get currentMonthBudgets {
    final now = DateTime.now();
    return _budgets.where((budget) =>
    budget.month == now.month &&
        budget.year == now.year &&
        budget.isActive
    ).toList();
  }

  // Get over budget categories
  List<BudgetModel> get overBudgetCategories {
    return currentMonthBudgets.where((budget) => budget.isOverBudget).toList();
  }

  // Get near limit categories (80% or more)
  List<BudgetModel> get nearLimitCategories {
    return currentMonthBudgets.where((budget) => budget.isNearLimit).toList();
  }

  // Initialize budgets for user
  Future<void> initializeForUser(int userId) async {
    _setLoading(true);
    try {
      await loadBudgets(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing budget provider: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load budgets
  Future<void> loadBudgets(int userId, {int? month, int? year}) async {
    try {
      _budgets = await _databaseHelper.getBudgetsByUser(
        userId,
        month: month,
        year: year,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading budgets: $e');
      notifyListeners();
    }
  }

  // Add new budget
  Future<bool> addBudget(BudgetModel budget) async {
    _setLoading(true);
    try {
      final id = await _databaseHelper.createBudget(budget);

      if (id > 0) {
        final newBudget = budget.copyWith(id: id);
        _budgets.add(newBudget);
        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding budget: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update budget
  Future<bool> updateBudget(BudgetModel budget) async {
    _setLoading(true);
    try {
      final result = await _databaseHelper.updateBudget(budget);

      if (result > 0) {
        final index = _budgets.indexWhere((b) => b.id == budget.id);
        if (index != -1) {
          _budgets[index] = budget;
          _error = null;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating budget: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get budget by category and month/year
  BudgetModel? getBudgetByCategory(String category, {int? month, int? year}) {
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    try {
      return _budgets.firstWhere((budget) =>
      budget.category == category &&
          budget.month == targetMonth &&
          budget.year == targetYear &&
          budget.isActive
      );
    } catch (e) {
      return null;
    }
  }

  // Check if category has budget
  bool hasBudget(String category, {int? month, int? year}) {
    return getBudgetByCategory(category, month: month, year: year) != null;
  }

  // Get total budget amount for current month
  double get totalCurrentMonthBudget {
    return currentMonthBudgets.fold(0.0, (sum, budget) => sum + budget.budgetAmount);
  }

  // Get total spent amount for current month
  double get totalCurrentMonthSpent {
    return currentMonthBudgets.fold(0.0, (sum, budget) => sum + budget.spentAmount);
  }

  // Get total remaining budget for current month
  double get totalCurrentMonthRemaining {
    return totalCurrentMonthBudget - totalCurrentMonthSpent;
  }

  // Get overall budget health percentage
  double get overallBudgetHealthPercentage {
    if (totalCurrentMonthBudget == 0) return 0.0;
    return (totalCurrentMonthSpent / totalCurrentMonthBudget) * 100;
  }

  // Create budget for category if doesn't exist
  Future<bool> createBudgetForCategory(
      int userId,
      String category,
      double budgetAmount, {
        int? month,
        int? year,
      }) async {
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    // Check if budget already exists
    if (hasBudget(category, month: targetMonth, year: targetYear)) {
      _error = 'Budget already exists for this category';
      notifyListeners();
      return false;
    }

    final budget = BudgetModel(
      userId: userId,
      category: category,
      budgetAmount: budgetAmount,
      month: targetMonth,
      year: targetYear,
      createdAt: now,
      updatedAt: now,
    );

    return await addBudget(budget);
  }

  // Update budget amount
  Future<bool> updateBudgetAmount(int budgetId, double newAmount) async {
    try {
      final budget = _budgets.firstWhere((b) => b.id == budgetId);
      final updatedBudget = budget.copyWith(
        budgetAmount: newAmount,
        updatedAt: DateTime.now(),
      );
      return await updateBudget(updatedBudget);
    } catch (e) {
      _error = 'Budget not found';
      notifyListeners();
      return false;
    }
  }

  // Get budget alerts (categories that are over 80% spent)
  List<Map<String, dynamic>> getBudgetAlerts() {
    final alerts = <Map<String, dynamic>>[];

    for (final budget in currentMonthBudgets) {
      if (budget.spentPercentage >= 0.8) {
        alerts.add({
          'budget': budget,
          'severity': budget.isOverBudget ? 'critical' : 'warning',
          'message': budget.isOverBudget
              ? '${budget.category} budget exceeded by ${((budget.spentPercentage - 1) * 100).toInt()}%'
              : '${budget.category} budget at ${(budget.spentPercentage * 100).toInt()}%',
        });
      }
    }

    // Sort by severity (critical first)
    alerts.sort((a, b) => a['severity'] == 'critical' ? -1 : 1);

    return alerts;
  }

  // Get spending recommendations
  List<String> getSpendingRecommendations() {
    final recommendations = <String>[];
    final alerts = getBudgetAlerts();

    if (alerts.isNotEmpty) {
      final criticalAlerts = alerts.where((alert) => alert['severity'] == 'critical').length;
      final warningAlerts = alerts.where((alert) => alert['severity'] == 'warning').length;

      if (criticalAlerts > 0) {
        recommendations.add('$criticalAlerts categories are over budget. Consider reducing spending.');
      }

      if (warningAlerts > 0) {
        recommendations.add('$warningAlerts categories are near their limits. Monitor spending closely.');
      }

      // Specific category recommendations
      for (final alert in alerts.take(3)) {
        final budget = alert['budget'] as BudgetModel;
        if (budget.isOverBudget) {
          final overspent = budget.spentAmount - budget.budgetAmount;
          recommendations.add('Reduce ${budget.category} spending by ₹${overspent.toInt()} to stay within budget.');
        }
      }
    } else if (currentMonthBudgets.isNotEmpty) {
      recommendations.add('All your budgets are on track this month.');
    } else {
      recommendations.add('Set up budgets for your expense categories to better track your spending.');
    }

    return recommendations;
  }

  // Get budget performance for a specific month
  Map<String, dynamic> getMonthlyBudgetPerformance(int month, int year) {
    final monthBudgets = _budgets.where((budget) =>
    budget.month == month &&
        budget.year == year &&
        budget.isActive
    ).toList();

    if (monthBudgets.isEmpty) {
      return {
        'totalBudget': 0.0,
        'totalSpent': 0.0,
        'totalRemaining': 0.0,
        'overallPercentage': 0.0,
        'categoriesOverBudget': 0,
        'categoriesOnTrack': 0,
        'budgets': <BudgetModel>[],
      };
    }

    final totalBudget = monthBudgets.fold(0.0, (sum, budget) => sum + budget.budgetAmount);
    final totalSpent = monthBudgets.fold(0.0, (sum, budget) => sum + budget.spentAmount);
    final categoriesOverBudget = monthBudgets.where((budget) => budget.isOverBudget).length;
    final categoriesOnTrack = monthBudgets.length - categoriesOverBudget;

    return {
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'totalRemaining': totalBudget - totalSpent,
      'overallPercentage': totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0,
      'categoriesOverBudget': categoriesOverBudget,
      'categoriesOnTrack': categoriesOnTrack,
      'budgets': monthBudgets,
    };
  }

  // Refresh budgets
  Future<void> refreshBudgets(int userId) async {
    await loadBudgets(userId);
  }

  // Update spent amounts based on transactions
  Future<void> updateSpentAmounts(int userId) async {
    _setLoading(true);
    try {
      // Get current month's expenses by category
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final expensesByCategory = await _databaseHelper.getExpensesByCategory(
        userId,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      // Update each budget's spent amount
      for (final budget in currentMonthBudgets) {
        final spentAmount = expensesByCategory[budget.category] ?? 0.0;
        if (budget.spentAmount != spentAmount) {
          final updatedBudget = budget.copyWith(
            spentAmount: spentAmount,
            updatedAt: DateTime.now(),
          );
          await _databaseHelper.updateBudget(updatedBudget);
        }
      }

      // Reload budgets to reflect changes
      await loadBudgets(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating spent amounts: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Clear data (for logout)
  void clearData() {
    _budgets.clear();
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Create default budgets for common categories
  Future<void> createDefaultBudgets(int userId, {int? month, int? year}) async {
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    final defaultBudgets = [
      {'category': 'Food & Dining', 'amount': 12000.0},
      {'category': 'Transportation', 'amount': 5000.0},
      {'category': 'Shopping', 'amount': 8000.0},
      {'category': 'Entertainment', 'amount': 3000.0},
      {'category': 'Bills & Utilities', 'amount': 6000.0},
      {'category': 'Healthcare', 'amount': 4000.0},
      {'category': 'Personal Care', 'amount': 2000.0},
    ];

    _setLoading(true);
    try {
      int created = 0;
      for (final budgetData in defaultBudgets) {
        final category = budgetData['category'] as String;
        final amount = budgetData['amount'] as double;

        if (!hasBudget(category, month: targetMonth, year: targetYear)) {
          final success = await createBudgetForCategory(
            userId,
            category,
            amount,
            month: targetMonth,
            year: targetYear,
          );
          if (success) created++;
        }
      }

      if (created > 0) {
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating default budgets: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete budget (soft delete by setting isActive to false)
  Future<bool> deleteBudget(BudgetModel budget) async {
    final deactivatedBudget = budget.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );

    return await updateBudget(deactivatedBudget);
  }

  // Get budgets by period
  List<BudgetModel> getBudgetsByPeriod(String period) {
    final now = DateTime.now();

    switch (period.toLowerCase()) {
      case 'weekly':
      // For weekly, we'll show current month budgets
      // You can implement more sophisticated weekly logic later
        return currentMonthBudgets;
      case 'monthly':
        return currentMonthBudgets;
      case 'quarterly':
      // Show budgets for current quarter
        final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
        return _budgets.where((budget) =>
        budget.year == now.year &&
            budget.month >= quarterStart &&
            budget.month < quarterStart + 3 &&
            budget.isActive
        ).toList();
      default:
        return currentMonthBudgets;
    }
  }
}