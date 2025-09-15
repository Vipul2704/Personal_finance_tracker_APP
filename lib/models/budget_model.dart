// lib/models/budget_model.dart
class BudgetModel {
  final int? id;
  final int userId;
  final String category;
  final double budgetAmount;
  final double spentAmount;
  final int month; // 1-12
  final int year;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetModel({
    this.id,
    required this.userId,
    required this.category,
    required this.budgetAmount,
    this.spentAmount = 0.0,
    required this.month,
    required this.year,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert BudgetModel to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'budget_amount': budgetAmount,
      'spent_amount': spentAmount,
      'month': month,
      'year': year,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create BudgetModel from Map (from database)
  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'],
      userId: map['user_id'],
      category: map['category'],
      budgetAmount: map['budget_amount'].toDouble(),
      spentAmount: map['spent_amount'].toDouble(),
      month: map['month'],
      year: map['year'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Create copy with updated fields
  BudgetModel copyWith({
    int? id,
    int? userId,
    String? category,
    double? budgetAmount,
    double? spentAmount,
    int? month,
    int? year,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      month: month ?? this.month,
      year: year ?? this.year,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  double get remainingAmount => budgetAmount - spentAmount;
  double get spentPercentage => budgetAmount > 0 ? (spentAmount / budgetAmount) : 0.0;
  bool get isOverBudget => spentAmount > budgetAmount;
  bool get isNearLimit => spentPercentage >= 0.8 && spentPercentage < 1.0;
  String get monthName {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  @override
  String toString() {
    return 'BudgetModel(id: $id, category: $category, budgetAmount: $budgetAmount, spentAmount: $spentAmount, month: $month, year: $year)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetModel &&
        other.id == id &&
        other.userId == userId &&
        other.category == category &&
        other.budgetAmount == budgetAmount &&
        other.spentAmount == spentAmount &&
        other.month == month &&
        other.year == year &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    userId.hashCode ^
    category.hashCode ^
    budgetAmount.hashCode ^
    spentAmount.hashCode ^
    month.hashCode ^
    year.hashCode ^
    isActive.hashCode ^
    createdAt.hashCode ^
    updatedAt.hashCode;
  }
}