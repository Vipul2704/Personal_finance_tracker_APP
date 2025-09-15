// lib/presentation/providers/notification_provider.dart
import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead && n.isActive).toList();
  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.isRead && n.isActive).toList();
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnreadNotifications => _unreadCount > 0;

  // Initialize notifications for user
  Future<void> initializeForUser(int userId) async {
    await Future.wait([
      loadNotifications(userId),
      loadUnreadCount(userId),
    ]);
  }

  // Load notifications
  Future<void> loadNotifications(int userId, {bool? isRead, int limit = 50}) async {
    _setLoading(true);
    try {
      _notifications = await _databaseHelper.getNotificationsByUser(
          userId,
          isRead: isRead,
          limit: limit
      );
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load unread count
  Future<void> loadUnreadCount(int userId) async {
    try {
      _unreadCount = await _databaseHelper.getUnreadNotificationCount(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  // Add new notification
  Future<bool> addNotification(NotificationModel notification) async {
    try {
      final id = await _databaseHelper.createNotification(notification);

      if (id > 0) {
        final newNotification = notification.copyWith(id: id);
        _notifications.insert(0, newNotification);

        if (!notification.isRead) {
          _unreadCount++;
        }

        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding notification: $e');
      return false;
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final result = await _databaseHelper.markNotificationAsRead(notificationId);

      if (result > 0) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final notification = _notifications[index];
          if (!notification.isRead) {
            _notifications[index] = notification.copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
            _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
            _error = null;
            notifyListeners();
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead(int userId) async {
    try {
      bool allSuccess = true;
      final unreadNotifs = unreadNotifications;

      for (final notification in unreadNotifs) {
        final success = await markAsRead(notification.id!);
        if (!success) allSuccess = false;
      }

      return allSuccess;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Get notification by id
  NotificationModel? getNotificationById(int id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type && n.isActive).toList();
  }

  // Create budget alert notification
  Future<bool> createBudgetAlert(int userId, String category, double budgetAmount, double spentAmount) async {
    final percentage = (spentAmount / budgetAmount * 100).round();

    final notification = NotificationModel(
      userId: userId,
      title: 'Budget Alert',
      message: '$category budget exceeded by $percentage%. Spent ₹${spentAmount.toInt()} of ₹${budgetAmount.toInt()}',
      type: 'budget_alert',
      iconName: 'warning',
      colorCode: '#F44336',
      createdAt: DateTime.now(),
    );

    return await addNotification(notification);
  }

  // Create goal achievement notification
  Future<bool> createGoalAchievement(int userId, String goalTitle) async {
    final notification = NotificationModel(
      userId: userId,
      title: 'Goal Achieved!',
      message: 'Congratulations! You\'ve completed your goal: $goalTitle',
      type: 'goal_achievement',
      iconName: 'check_circle',
      colorCode: '#4CAF50',
      createdAt: DateTime.now(),
    );

    return await addNotification(notification);
  }

  // Create payment reminder notification
  Future<bool> createPaymentReminder(int userId, String description, DateTime dueDate) async {
    final daysLeft = dueDate.difference(DateTime.now()).inDays;
    String message;

    if (daysLeft <= 0) {
      message = '$description payment is due today!';
    } else if (daysLeft == 1) {
      message = '$description payment is due tomorrow';
    } else {
      message = '$description payment is due in $daysLeft days';
    }

    final notification = NotificationModel(
      userId: userId,
      title: 'Payment Reminder',
      message: message,
      type: 'payment_reminder',
      iconName: 'schedule',
      colorCode: '#FF9800',
      createdAt: DateTime.now(),
    );

    return await addNotification(notification);
  }

  // Create spending insight notification
  Future<bool> createSpendingInsight(int userId, String message) async {
    final notification = NotificationModel(
      userId: userId,
      title: 'Spending Insight',
      message: message,
      type: 'spending_insight',
      iconName: 'lightbulb',
      colorCode: '#2196F3',
      createdAt: DateTime.now(),
    );

    return await addNotification(notification);
  }

  // Create general info notification
  Future<bool> createInfoNotification(int userId, String title, String message) async {
    final notification = NotificationModel(
      userId: userId,
      title: title,
      message: message,
      type: 'info',
      iconName: 'info',
      colorCode: '#2196F3',
      createdAt: DateTime.now(),
    );

    return await addNotification(notification);
  }

  // Get recent notifications (last 7 days)
  List<NotificationModel> getRecentNotifications() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _notifications.where((n) =>
    n.createdAt.isAfter(sevenDaysAgo) && n.isActive
    ).toList();
  }

  // Get notifications by date range
  List<NotificationModel> getNotificationsByDateRange(DateTime startDate, DateTime endDate) {
    return _notifications.where((n) =>
    n.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
        n.createdAt.isBefore(endDate.add(const Duration(days: 1))) &&
        n.isActive
    ).toList();
  }

  // Search notifications
  List<NotificationModel> searchNotifications(String query) {
    if (query.isEmpty) return _notifications;

    return _notifications.where((n) =>
    n.title.toLowerCase().contains(query.toLowerCase()) ||
        n.message.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Clear old notifications (older than 30 days)
  Future<void> clearOldNotifications(int userId) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final oldNotifications = _notifications.where((n) =>
        n.createdAt.isBefore(thirtyDaysAgo)
    ).toList();

    for (final notification in oldNotifications) {
      if (notification.id != null) {
        // In a real implementation, you'd want to add a delete method to database helper
        // For now, we'll just remove from local list
        _notifications.removeWhere((n) => n.id == notification.id);
      }
    }

    notifyListeners();
  }

  // Get notification statistics
  Map<String, dynamic> getNotificationStats() {
    final total = _notifications.length;
    final unread = unreadNotifications.length;
    final byType = <String, int>{};

    for (final notification in _notifications) {
      byType[notification.type] = (byType[notification.type] ?? 0) + 1;
    }

    return {
      'total': total,
      'unread': unread,
      'read': total - unread,
      'readPercentage': total > 0 ? ((total - unread) / total * 100).round() : 0,
      'byType': byType,
      'hasUnread': unread > 0,
    };
  }

  // Refresh notifications
  Future<void> refreshNotifications(int userId) async {
    await initializeForUser(userId);
  }

  // Clear all data (for logout)
  void clearData() {
    _notifications.clear();
    _unreadCount = 0;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Auto-create notifications based on spending patterns
  Future<void> checkAndCreateAutoNotifications(int userId, Map<String, dynamic> spendingData) async {
    // This method can be called periodically to create automatic notifications
    // based on spending patterns, budget alerts, etc.

    try {
      // Example: Check for budget alerts
      if (spendingData.containsKey('budgetAlerts')) {
        final alerts = spendingData['budgetAlerts'] as List<Map<String, dynamic>>;
        for (final alert in alerts) {
          await createBudgetAlert(
            userId,
            alert['category'],
            alert['budgetAmount'],
            alert['spentAmount'],
          );
        }
      }

      // Example: Check for goal achievements
      if (spendingData.containsKey('goalAchievements')) {
        final achievements = spendingData['goalAchievements'] as List<String>;
        for (final goalTitle in achievements) {
          await createGoalAchievement(userId, goalTitle);
        }
      }

      // Example: Create spending insights
      if (spendingData.containsKey('insights')) {
        final insights = spendingData['insights'] as List<String>;
        for (final insight in insights) {
          await createSpendingInsight(userId, insight);
        }
      }

    } catch (e) {
      debugPrint('Error creating auto notifications: $e');
    }
  }
}