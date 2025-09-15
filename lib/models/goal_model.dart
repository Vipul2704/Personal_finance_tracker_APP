// lib/models/goal_model.dart
class GoalModel {
  final int? id;
  final int userId;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String iconName;
  final String colorCode;
  final bool isCompleted;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  GoalModel({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    required this.iconName,
    required this.colorCode,
    this.isCompleted = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert GoalModel to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate.toIso8601String(),
      'icon_name': iconName,
      'color_code': colorCode,
      'is_completed': isCompleted ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create GoalModel from Map (from database)
  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      description: map['description'],
      targetAmount: map['target_amount'].toDouble(),
      currentAmount: map['current_amount'].toDouble(),
      targetDate: DateTime.parse(map['target_date']),
      iconName: map['icon_name'],
      colorCode: map['color_code'],
      isCompleted: map['is_completed'] == 1,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Create copy with updated fields
  GoalModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? iconName,
    String? colorCode,
    bool? isCompleted,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      iconName: iconName ?? this.iconName,
      colorCode: colorCode ?? this.colorCode,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  double get remainingAmount => targetAmount - currentAmount;
  double get completionPercentage => targetAmount > 0 ? (currentAmount / targetAmount) : 0.0;
  int get daysRemaining {
    final now = DateTime.now();
    final difference = targetDate.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  bool get isOverdue {
    return DateTime.now().isAfter(targetDate) && !isCompleted;
  }

  String get formattedTargetDate {
    return '${targetDate.day}/${targetDate.month}/${targetDate.year}';
  }

  String get progressText {
    return '₹${currentAmount.toInt()} / ₹${targetAmount.toInt()}';
  }

  @override
  String toString() {
    return 'GoalModel(id: $id, title: $title, targetAmount: $targetAmount, currentAmount: $currentAmount, targetDate: $targetDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalModel &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.targetAmount == targetAmount &&
        other.currentAmount == currentAmount &&
        other.targetDate == targetDate &&
        other.iconName == iconName &&
        other.colorCode == colorCode &&
        other.isCompleted == isCompleted &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    userId.hashCode ^
    title.hashCode ^
    description.hashCode ^
    targetAmount.hashCode ^
    currentAmount.hashCode ^
    targetDate.hashCode ^
    iconName.hashCode ^
    colorCode.hashCode ^
    isCompleted.hashCode ^
    isActive.hashCode ^
    createdAt.hashCode ^
    updatedAt.hashCode;
  }
}