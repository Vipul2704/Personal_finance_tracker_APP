// lib/models/category_model.dart
class CategoryModel {
  final int? id;
  final int userId;
  final String name;
  final String colorCode; // Hex color code
  final String iconName;
  final String type; // 'income' or 'expense'
  final bool isDefault; // System default categories vs user-created
  final DateTime createdAt;

  CategoryModel({
    this.id,
    required this.userId,
    required this.name,
    required this.colorCode,
    required this.iconName,
    required this.type,
    this.isDefault = false,
    required this.createdAt,
  });

  // Convert CategoryModel to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color_code': colorCode,
      'icon_name': iconName,
      'type': type,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create CategoryModel from Map (from database)
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      colorCode: map['color_code'],
      iconName: map['icon_name'],
      type: map['type'],
      isDefault: map['is_default'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // Create copy with updated fields
  CategoryModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? colorCode,
    String? iconName,
    String? type,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      colorCode: colorCode ?? this.colorCode,
      iconName: iconName ?? this.iconName,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  bool get isIncomeCategory => type == 'income';
  bool get isExpenseCategory => type == 'expense';

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, type: $type, colorCode: $colorCode, iconName: $iconName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.colorCode == colorCode &&
        other.iconName == iconName &&
        other.type == type &&
        other.isDefault == isDefault &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    userId.hashCode ^
    name.hashCode ^
    colorCode.hashCode ^
    iconName.hashCode ^
    type.hashCode ^
    isDefault.hashCode ^
    createdAt.hashCode;
  }

  // Static method to create default categories
  static List<CategoryModel> getDefaultCategories(int userId) {
    final now = DateTime.now();

    return [
      // Expense Categories
      CategoryModel(
        userId: userId,
        name: 'Food & Dining',
        colorCode: '#FF6B6B',
        iconName: 'restaurant',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        userId: userId,
        name: 'Transportation',
        colorCode: '#4ECDC4',
        iconName: 'directions_car',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        userId: userId,
        name: 'Shopping',
        colorCode: '#45B7D1',
        iconName: 'shopping_bag',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        userId: userId,
        name: 'Entertainment',
        colorCode: '#96CEB4',
        iconName: 'movie',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        userId: userId,
        name: 'Healthcare',
        colorCode: '#FFEAA7',
        iconName: 'local_hospital',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        userId: userId,
        name: 'Bills & Utilities',
        colorCode: '#DDA0DD',
        iconName: 'receipt_long',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        userId: userId,
        name: 'Education',
        colorCode: '#98D8C8',
        iconName: 'school',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        userId: userId,
        name: 'Others',
        colorCode: '#F7DC6F',
        iconName: 'category',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),

      // Income Categories
      CategoryModel(
        userId: userId,
        name: 'Salary',
        colorCode: '#2ECC71',
        iconName: 'account_balance_wallet',
        type: 'income',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        userId: userId,
        name: 'Freelance',
        colorCode: '#3498DB',
        iconName: 'work',
        type: 'income',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        userId: userId,
        name: 'Investment',
        colorCode: '#9B59B6',
        iconName: 'trending_up',
        type: 'income',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        userId: userId,
        name: 'Other Income',
        colorCode: '#1ABC9C',
        iconName: 'attach_money',
        type: 'income',
        isDefault: true,
        createdAt: now,
      ),
    ];
  }
}