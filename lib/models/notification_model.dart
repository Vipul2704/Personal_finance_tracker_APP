// lib/models/notification_model.dart
class NotificationModel {
  final int? id;
  final int userId;
  final String title;
  final String message;
  final String type; // 'budget_alert', 'goal_completed', 'bill_due', 'insight', 'general'
  final String iconName;
  final String colorCode;
  final bool isRead;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.iconName,
    required this.colorCode,
    this.isRead = false,
    this.isActive = true,
    required this.createdAt,
    this.readAt,
  });

  // Convert NotificationModel to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'icon_name': iconName,
      'color_code': colorCode,
      'is_read': isRead ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  // Create NotificationModel from Map (from database)
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      message: map['message'],
      type: map['type'],
      iconName: map['icon_name'],
      colorCode: map['color_code'],
      isRead: map['is_read'] == 1,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      readAt: map['read_at'] != null ? DateTime.parse(map['read_at']) : null,
    );
  }

  // Create copy with updated fields
  NotificationModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    String? type,
    String? iconName,
    String? colorCode,
    bool? isRead,
    bool? isActive,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      colorCode: colorCode ?? this.colorCode,
      isRead: isRead ?? this.isRead,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // Helper getters
  bool get isBudgetAlert => type == 'budget_alert';
  bool get isGoalCompleted => type == 'goal_completed';
  bool get isBillDue => type == 'bill_due';
  bool get isInsight => type == 'insight';
  bool get isGeneral => type == 'general';

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.message == message &&
        other.type == type &&
        other.iconName == iconName &&
        other.colorCode == colorCode &&
        other.isRead == isRead &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.readAt == readAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    userId.hashCode ^
    title.hashCode ^
    message.hashCode ^
    type.hashCode ^
    iconName.hashCode ^
    colorCode.hashCode ^
    isRead.hashCode ^
    isActive.hashCode ^
    createdAt.hashCode ^
    readAt.hashCode;
  }

  // Static methods for creating different types of notifications
  static NotificationModel createBudgetAlert({
    required int userId,
    required String category,
    required double percentage,
  }) {
    return NotificationModel(
      userId: userId,
      title: 'Budget Alert',
      message: '$category budget exceeded by ${percentage.toInt()}%',
      type: 'budget_alert',
      iconName: 'warning',
      colorCode: '#FF6B6B',
      createdAt: DateTime.now(),
    );
  }

  static NotificationModel createGoalCompleted({
    required int userId,
    required String goalTitle,
  }) {
    return NotificationModel(
      userId: userId,
      title: 'Goal Achieved!',
      message: '$goalTitle goal completed successfully!',
      type: 'goal_completed',
      iconName: 'check_circle',
      colorCode: '#4CAF50',
      createdAt: DateTime.now(),
    );
  }

  static NotificationModel createBillReminder({
    required int userId,
    required String billName,
    required DateTime dueDate,
  }) {
    return NotificationModel(
      userId: userId,
      title: 'Bill Due',
      message: '$billName payment due ${_formatDate(dueDate)}',
      type: 'bill_due',
      iconName: 'info',
      colorCode: '#2196F3',
      createdAt: DateTime.now(),
    );
  }

  static NotificationModel createInsight({
    required int userId,
    required String insight,
  }) {
    return NotificationModel(
      userId: userId,
      title: 'Smart Insight',
      message: insight,
      type: 'insight',
      iconName: 'lightbulb_outline',
      colorCode: '#9C27B0',
      createdAt: DateTime.now(),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'today';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}