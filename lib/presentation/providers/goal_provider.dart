// lib/presentation/providers/goal_provider.dart
import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../../models/goal_model.dart';

class GoalProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<GoalModel> _goals = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<GoalModel> get goals => _goals;
  List<GoalModel> get activeGoals => _goals.where((g) => g.isActive && !g.isCompleted).toList();
  List<GoalModel> get completedGoals => _goals.where((g) => g.isCompleted).toList();
  List<GoalModel> get upcomingGoals => _goals.where((g) =>
  g.isActive && !g.isCompleted && g.targetDate.isAfter(DateTime.now())).toList();
  List<GoalModel> get overdueGoals => _goals.where((g) =>
  g.isActive && !g.isCompleted && g.targetDate.isBefore(DateTime.now())).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistics
  int get totalGoals => _goals.length;
  int get totalActiveGoals => activeGoals.length;
  int get totalCompletedGoals => completedGoals.length;
  double get completionRate => totalGoals > 0 ? (totalCompletedGoals / totalGoals) * 100 : 0.0;

  // Initialize goals for user
  Future<void> initializeForUser(int userId) async {
    await loadGoals(userId);
  }

  // Load goals
  Future<void> loadGoals(int userId, {bool? isCompleted}) async {
    _setLoading(true);
    try {
      _goals = await _databaseHelper.getGoalsByUser(userId, isCompleted: isCompleted);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading goals: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add new goal
  Future<bool> addGoal(GoalModel goal) async {
    _setLoading(true);
    try {
      final id = await _databaseHelper.createGoal(goal);

      if (id > 0) {
        final newGoal = goal.copyWith(id: id);
        _goals.add(newGoal);
        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding goal: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update goal
  Future<bool> updateGoal(GoalModel goal) async {
    _setLoading(true);
    try {
      final result = await _databaseHelper.updateGoal(goal);

      if (result > 0) {
        final index = _goals.indexWhere((g) => g.id == goal.id);
        if (index != -1) {
          _goals[index] = goal;
          _error = null;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating goal: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update goal progress
  Future<bool> updateGoalProgress(int goalId, double amount) async {
    _setLoading(true);
    try {
      final result = await _databaseHelper.updateGoalProgress(goalId, amount);

      if (result > 0) {
        final index = _goals.indexWhere((g) => g.id == goalId);
        if (index != -1) {
          final goal = _goals[index];
          final newCurrentAmount = goal.currentAmount + amount;
          final isCompleted = newCurrentAmount >= goal.targetAmount;

          _goals[index] = goal.copyWith(
            currentAmount: newCurrentAmount,
            isCompleted: isCompleted,
            updatedAt: DateTime.now(),
          );

          _error = null;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating goal progress: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get goal by id
  GoalModel? getGoalById(int id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  // Calculate goal progress percentage
  double getGoalProgress(GoalModel goal) {
    if (goal.targetAmount <= 0) return 0.0;
    final progress = (goal.currentAmount / goal.targetAmount) * 100;
    return progress > 100 ? 100 : progress;
  }

  // Get remaining amount for goal
  double getRemainingAmount(GoalModel goal) {
    final remaining = goal.targetAmount - goal.currentAmount;
    return remaining > 0 ? remaining : 0.0;
  }

  // Get days remaining for goal
  int getDaysRemaining(GoalModel goal) {
    final now = DateTime.now();
    final difference = goal.targetDate.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  // Check if goal is overdue
  bool isGoalOverdue(GoalModel goal) {
    return !goal.isCompleted && goal.targetDate.isBefore(DateTime.now());
  }

  // Get goals by priority (based on target date)
  List<GoalModel> getGoalsByPriority() {
    final activeGoals = this.activeGoals;
    activeGoals.sort((a, b) => a.targetDate.compareTo(b.targetDate));
    return activeGoals;
  }

  // Get goals nearing completion (80% or more)
  List<GoalModel> getGoalsNearingCompletion() {
    return activeGoals.where((goal) => getGoalProgress(goal) >= 80).toList();
  }

  // Get goals that need attention (overdue or low progress with close deadline)
  List<GoalModel> getGoalsNeedingAttention() {
    final now = DateTime.now();
    return activeGoals.where((goal) {
      final isOverdue = goal.targetDate.isBefore(now);
      final daysRemaining = goal.targetDate.difference(now).inDays;
      final progress = getGoalProgress(goal);

      // Goal needs attention if it's overdue or has less than 30 days and less than 50% progress
      return isOverdue || (daysRemaining <= 30 && progress < 50);
    }).toList();
  }

  // Search goals
  List<GoalModel> searchGoals(String query) {
    if (query.isEmpty) return _goals;

    return _goals.where((goal) =>
    goal.title.toLowerCase().contains(query.toLowerCase()) ||
        (goal.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
    ).toList();
  }

  // Get total target amount for all active goals
  double getTotalTargetAmount() {
    return activeGoals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
  }

  // Get total current amount for all active goals
  double getTotalCurrentAmount() {
    return activeGoals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
  }

  // Get overall progress percentage
  double getOverallProgress() {
    final totalTarget = getTotalTargetAmount();
    if (totalTarget <= 0) return 0.0;

    final totalCurrent = getTotalCurrentAmount();
    return (totalCurrent / totalTarget) * 100;
  }

  // Mark goal as completed manually
  Future<bool> markGoalAsCompleted(int goalId) async {
    final goal = getGoalById(goalId);
    if (goal == null) return false;

    final updatedGoal = goal.copyWith(
      isCompleted: true,
      currentAmount: goal.targetAmount, // Set current amount to target
      updatedAt: DateTime.now(),
    );

    return await updateGoal(updatedGoal);
  }

  // Delete/deactivate goal
  Future<bool> deactivateGoal(int goalId) async {
    final goal = getGoalById(goalId);
    if (goal == null) return false;

    final updatedGoal = goal.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );

    return await updateGoal(updatedGoal);
  }

  // Refresh goals
  Future<void> refreshGoals(int userId) async {
    await loadGoals(userId);
  }

  // Clear all data (for logout)
  void clearData() {
    _goals.clear();
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get achievement insights
  Map<String, dynamic> getAchievementInsights() {
    return {
      'totalGoals': totalGoals,
      'completedGoals': totalCompletedGoals,
      'activeGoals': totalActiveGoals,
      'completionRate': completionRate,
      'overdueGoals': overdueGoals.length,
      'goalsNearingCompletion': getGoalsNearingCompletion().length,
      'goalsNeedingAttention': getGoalsNeedingAttention().length,
      'totalTargetAmount': getTotalTargetAmount(),
      'totalCurrentAmount': getTotalCurrentAmount(),
      'overallProgress': getOverallProgress(),
    };
  }
}