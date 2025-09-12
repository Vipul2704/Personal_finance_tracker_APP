import 'package:flutter/material.dart';

enum CategoryType { income, expense }

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final CategoryType type;
  final bool isDefault;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Category to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
      'type': type.name,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Convert Map to Category from database
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: IconData(map['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      color: Color(map['colorValue'] as int),
      type: CategoryType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => CategoryType.expense,
      ),
      isDefault: (map['isDefault'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.value,
      'type': type.name,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Convert from JSON from Firebase
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      color: Color(json['colorValue'] as int),
      type: CategoryType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => CategoryType.expense,
      ),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Category copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    CategoryType? type,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, type: ${type.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, type);
  }

  // Default Categories
  static List<Category> getDefaultCategories() {
    return [
      // Expense Categories
      Category(
        id: 'food',
        name: 'Food & Dining',
        icon: Icons.restaurant,
        color: const Color(0xFFFF6B6B),
        type: CategoryType.expense,
        isDefault: true,
      ),
      Category(
        id: 'transport',
        name: 'Transportation',
        icon: Icons.directions_car,
        color: const Color(0xFF4ECDC4),
        type: CategoryType.expense,
        isDefault: true,
      ),
      Category(
        id: 'shopping',
        name: 'Shopping',
        icon: Icons.shopping_bag,
        color: const Color(0xFF45B7D1),
        type: CategoryType.expense,
        isDefault: true,
      ),
      Category(
        id: 'entertainment',
        name: 'Entertainment',
        icon: Icons.movie,
        color: const Color(0xFF96CEB4),
        type: CategoryType.expense,
        isDefault: true,
      ),
      Category(
        id: 'bills',
        name: 'Bills & Utilities',
        icon: Icons.receipt,
        color: const Color(0xFFFECA57),
        type: CategoryType.expense,
        isDefault: true,
      ),
      Category(
        id: 'healthcare',
        name: 'Healthcare',
        icon: Icons.local_hospital,
        color: const Color(0xFFFF9FF3),
        type: CategoryType.expense,
        isDefault: true,
      ),
      Category(
        id: 'education',
        name: 'Education',
        icon: Icons.school,
        color: const Color(0xFF54A0FF),
        type: CategoryType.expense,
        isDefault: true,
      ),
      Category(
        id: 'other_expense',
        name: 'Other',
        icon: Icons.more_horiz,
        color: const Color(0xFF8395A7),
        type: CategoryType.expense,
        isDefault: true,
      ),

      // Income Categories
      Category(
        id: 'salary',
        name: 'Salary',
        icon: Icons.work,
        color: const Color(0xFF00D2D3),
        type: CategoryType.income,
        isDefault: true,
      ),
      Category(
        id: 'freelance',
        name: 'Freelance',
        icon: Icons.computer,
        color: const Color(0xFF4834D4),
        type: CategoryType.income,
        isDefault: true,
      ),
      Category(
        id: 'investment',
        name: 'Investment',
        icon: Icons.trending_up,
        color: const Color(0xFF00A085),
        type: CategoryType.income,
        isDefault: true,
      ),
      Category(
        id: 'gift',
        name: 'Gift',
        icon: Icons.card_giftcard,
        color: const Color(0xFFE056FD),
        type: CategoryType.income,
        isDefault: true,
      ),
      Category(
        id: 'other_income',
        name: 'Other',
        icon: Icons.account_balance_wallet,
        color: const Color(0xFF7BE495),
        type: CategoryType.income,
        isDefault: true,
      ),
    ];
  }
}