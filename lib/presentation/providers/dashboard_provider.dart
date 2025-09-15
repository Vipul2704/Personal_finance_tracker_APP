// lib/presentation/providers/dashboard_provider.dart
import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';
import '../../models/goal_model.dart';
import './transaction_provider.dart';
import './budget_provider.dart';
import './goal_provider.dart';
import './notification_provider.dart';

class DashboardProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Dashboard specific data
  Map<String, dynamic> _dashboardData = {};
  List<TransactionModel> _recentTransactions = [];
  List<BudgetModel> _currentMonthBudgets = [];
  List<GoalModel> _activeGoals = [];
  Map<String, double> _balanceSummary = {
    'income': 0.0,
    'expense': 0.0,
    'balance': 0.0,
  };
  Map<String, double> _expensesByCategory = {};
  int _unreadNotifications = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic> get dashboardData => _dashboardData;
  List<TransactionModel> get recentTransactions => _recentTransactions;
  List<BudgetModel> get currentMonthBudgets => _currentMonthBudgets;
  List<GoalModel> get activeGoals => _activeGoals;
  Map<String, double> get balanceSummary => _balanceSummary;
  Map<String, double> get expensesByCategory => _expensesByCategory;
  int get unreadNotifications => _unreadNotifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Financial metrics getters
  double get totalBalance => _balanceSummary['balance'] ?? 0.0;
  double get totalIncome => _balanceSummary['income'] ?? 0.0;
  double get totalExpense => _balanceSummary['expense'] ?? 0.0;
  double get savingsRate => totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0.0;

  // Dashboard specific getters
  List<BudgetModel> get budgetsNearingLimit =>
      _currentMonthBudgets.where((b) => (b.spentAmount / b.budgetAmount) > 0.8).toList();
  List<BudgetModel> get budgetsOverLimit =>
      _currentMonthBudgets.where((b) => b.spentAmount > b.budgetAmount).toList();
  List<GoalModel> get goalsNearingDeadline => _activeGoals.where((g) {
    final daysLeft = g.targetDate.difference(DateTime.now()).inDays;
    return daysLeft <= 30 && daysLeft > 0;
  }).toList();

  // Initialize dashboard for user
  Future<void> initializeForUser(int userId) async {
    await loadDashboardData(userId);
  }

  Future<void> loadDashboardData(int userId) async {
    _setLoading(true);
    try {
      print('=== DEBUG: Loading dashboard data for user $userId ===');

      // Load data from database helper
      _dashboardData = await _databaseHelper.getDashboardData(userId);
      print('Raw dashboard data: $_dashboardData');
      print('Dashboard data keys: ${_dashboardData.keys}');

      // Extract data from dashboard response
      _balanceSummary = _dashboardData['balance'] ?? {'income': 0.0, 'expense': 0.0, 'balance': 0.0};
      print('Balance summary: $_balanceSummary');

      final rawTransactions = _dashboardData['recentTransactions'];
      print('Raw transactions: $rawTransactions');
      print('Raw transactions length: ${rawTransactions?.length}');

      _recentTransactions = List<TransactionModel>.from(rawTransactions ?? []);
      print('Converted transactions: $_recentTransactions');
      print('Converted transactions length: ${_recentTransactions.length}');

      _currentMonthBudgets = List<BudgetModel>.from(_dashboardData['budgets'] ?? []);
      _activeGoals = List<GoalModel>.from(_dashboardData['goals'] ?? []);
      _unreadNotifications = _dashboardData['unreadNotifications'] ?? 0;

      // Load additional data
      await _loadExpensesByCategory(userId);
      print('Expenses by category: $_expensesByCategory');

      _error = null;
      print('=== DEBUG: Data loaded successfully, calling notifyListeners ===');
      notifyListeners();
    } catch (e) {
      print('=== ERROR in loadDashboardData: $e ===');
      print('Stack trace: ${StackTrace.current}');
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Load expenses by category for current month
  Future<void> _loadExpensesByCategory(int userId) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      _expensesByCategory = await _databaseHelper.getExpensesByCategory(
        userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Error loading expenses by category: $e');
    }
  }

  // Refresh dashboard data
  Future<void> refreshDashboard(int userId) async {
    await loadDashboardData(userId);
  }

  // Update data from other providers
  void updateFromProviders({
    TransactionProvider? transactionProvider,
    BudgetProvider? budgetProvider,
    GoalProvider? goalProvider,
    NotificationProvider? notificationProvider,
  }) {
    bool hasChanges = false;

    if (transactionProvider != null) {
      final newBalance = transactionProvider.balanceSummary;
      final newTransactions = transactionProvider.recentTransactions;
      final newExpenses = transactionProvider.expensesByCategory;

      if (_balanceSummary != newBalance) {
        _balanceSummary = Map.from(newBalance);
        hasChanges = true;
      }

      if (_recentTransactions != newTransactions) {
        _recentTransactions = List.from(newTransactions);
        hasChanges = true;
      }

      if (_expensesByCategory != newExpenses) {
        _expensesByCategory = Map.from(newExpenses);
        hasChanges = true;
      }
    }

    if (budgetProvider != null) {
      final newBudgets = budgetProvider.currentMonthBudgets;
      if (_currentMonthBudgets != newBudgets) {
        _currentMonthBudgets = List.from(newBudgets);
        hasChanges = true;
      }
    }

    if (goalProvider != null) {
      final newGoals = goalProvider.activeGoals;
      if (_activeGoals != newGoals) {
        _activeGoals = List.from(newGoals);
        hasChanges = true;
      }
    }

    if (notificationProvider != null) {
      final newCount = notificationProvider.unreadCount;
      if (_unreadNotifications != newCount) {
        _unreadNotifications = newCount;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  // Get spending insights for dashboard
  Map<String, dynamic> getSpendingInsights() {
    if (_expensesByCategory.isEmpty) return {};

    final total = _expensesByCategory.values.fold(0.0, (sum, amount) => sum + amount);
    if (total == 0) return {};

    // Find highest spending category
    final entries = _expensesByCategory.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    final topCategories = entries.take(3).toList();
    final highestCategory = topCategories.first;

    // Calculate percentage of highest category
    final percentage = ((highestCategory.value / total) * 100).round();

    // Compare with previous month (you can enhance this with historical data)
    return {
      'topCategory': {
        'name': highestCategory.key,
        'amount': highestCategory.value,
        'percentage': percentage,
      },
      'topCategories': topCategories.map((e) => {
        'name': e.key,
        'amount': e.value,
        'percentage': ((e.value / total) * 100).round(),
      }).toList(),
      'totalExpenses': total,
      'categoryCount': _expensesByCategory.length,
    };
  }

  // Get budget alerts
  List<Map<String, dynamic>> getBudgetAlerts() {
    final alerts = <Map<String, dynamic>>[];

    for (final budget in _currentMonthBudgets) {
      final percentage = budget.budgetAmount > 0 ?
      (budget.spentAmount / budget.budgetAmount) * 100 : 0;

      if (percentage >= 100) {
        alerts.add({
          'type': 'over_budget',
          'category': budget.category,
          'percentage': percentage.round(),
          'spent': budget.spentAmount,
          'budget': budget.budgetAmount,
          'message': '${budget.category} budget exceeded by ${(percentage - 100).round()}%',
        });
      } else if (percentage >= 80) {
        alerts.add({
          'type': 'approaching_limit',
          'category': budget.category,
          'percentage': percentage.round(),
          'spent': budget.spentAmount,
          'budget': budget.budgetAmount,
          'message': '${budget.category} budget ${percentage.round()}% used',
        });
      }
    }

    return alerts;
  }

  // Get goal progress summary
  Map<String, dynamic> getGoalsSummary() {
    if (_activeGoals.isEmpty) {
      return {
        'totalGoals': 0,
        'completedGoals': 0,
        'totalTargetAmount': 0.0,
        'totalCurrentAmount': 0.0,
        'averageProgress': 0.0,
        'goalsNearDeadline': 0,
      };
    }

    final totalTarget = _activeGoals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
    final totalCurrent = _activeGoals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
    final averageProgress = totalTarget > 0 ? (totalCurrent / totalTarget) * 100 : 0.0;

    return {
      'totalGoals': _activeGoals.length,
      'totalTargetAmount': totalTarget,
      'totalCurrentAmount': totalCurrent,
      'averageProgress': averageProgress,
      'goalsNearDeadline': goalsNearingDeadline.length,
      'topGoals': _activeGoals.take(3).map((goal) => {
        'title': goal.title,
        'progress': goal.targetAmount > 0 ?
        (goal.currentAmount / goal.targetAmount) * 100 : 0.0,
        'current': goal.currentAmount,
        'target': goal.targetAmount,
      }).toList(),
    };
  }

  // Generate AI insights for dashboard
  List<String> generateAIInsights() {
    final insights = <String>[];

    // Spending insights
    final spendingData = getSpendingInsights();
    if (spendingData.isNotEmpty && spendingData['topCategory'] != null) {
      final topCategory = spendingData['topCategory'];
      final categoryName = topCategory['name'];
      final percentage = topCategory['percentage'];

      if (percentage > 40) {
        insights.add(
            'You\'re spending $percentage% of your budget on $categoryName. Consider reducing expenses in this category.'
        );
      }
    }

    // Budget insights
    final budgetAlerts = getBudgetAlerts();
    if (budgetAlerts.isNotEmpty) {
      final overBudget = budgetAlerts.where((a) => a['type'] == 'over_budget').length;
      if (overBudget > 0) {
        insights.add(
            'You have $overBudget categories over budget this month. Review your spending patterns.'
        );
      }
    }

    // Goal insights
    final goalsSummary = getGoalsSummary();
    final averageProgress = goalsSummary['averageProgress'] ?? 0.0;
    if (averageProgress < 25 && _activeGoals.isNotEmpty) {
      insights.add(
          'Your goal progress is ${averageProgress.round()}%. Consider increasing your savings to stay on track.'
      );
    }

    // Savings rate insight
    if (savingsRate < 10 && totalIncome > 0) {
      insights.add(
          'Your savings rate is ${savingsRate.round()}%. Try to save at least 20% of your income.'
      );
    }

    // Default insight if no specific insights
    if (insights.isEmpty) {
      insights.add(
          'Keep tracking your expenses to maintain better financial health!'
      );
    }

    return insights;
  }

  // Get financial health score (0-100)
  int getFinancialHealthScore() {
    int score = 0;
    int factors = 0;

    // Savings rate factor (0-30 points)
    if (totalIncome > 0) {
      factors++;
      if (savingsRate >= 20) {
        score += 30;
      } else if (savingsRate >= 10) {
        score += 20;
      } else if (savingsRate >= 0) {
        score += 10;
      }
    }

    // Budget adherence factor (0-25 points)
    if (_currentMonthBudgets.isNotEmpty) {
      factors++;
      final overBudgetCount = budgetsOverLimit.length;
      final totalBudgets = _currentMonthBudgets.length;
      final adherenceRate = 1 - (overBudgetCount / totalBudgets);
      score += (adherenceRate * 25).round();
    }

    // Goal progress factor (0-25 points)
    if (_activeGoals.isNotEmpty) {
      factors++;
      final goalsSummary = getGoalsSummary();
      final averageProgress = goalsSummary['averageProgress'] ?? 0.0;
      score += ((averageProgress as double) / 100 * 25).round();

    }

    // Transaction tracking factor (0-20 points)
    factors++;
    if (_recentTransactions.length >= 10) {
      score += 20;
    } else if (_recentTransactions.length >= 5) {
      score += 15;
    } else if (_recentTransactions.length >= 1) {
      score += 10;
    }

    // Normalize score based on available factors
    if (factors > 0) {
      score = ((score / (factors == 4 ? 100 : factors * 25)) * 100).round();
    }

    return score.clamp(0, 100);
  }

  // Get dashboard summary for quick overview
  Map<String, dynamic> getDashboardSummary() {
    return {
      'balance': _balanceSummary,
      'recentTransactionsCount': _recentTransactions.length,
      'budgetAlertsCount': getBudgetAlerts().length,
      'activeGoalsCount': _activeGoals.length,
      'unreadNotifications': _unreadNotifications,
      'financialHealthScore': getFinancialHealthScore(),
      'savingsRate': savingsRate,
      'topSpendingCategory': getSpendingInsights()['topCategory'],
      'insights': generateAIInsights().take(1).toList(),
    };
  }

  // Clear all data (for logout)
  void clearData() {
    _dashboardData.clear();
    _recentTransactions.clear();
    _currentMonthBudgets.clear();
    _activeGoals.clear();
    _balanceSummary = {'income': 0.0, 'expense': 0.0, 'balance': 0.0};
    _expensesByCategory.clear();
    _unreadNotifications = 0;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}