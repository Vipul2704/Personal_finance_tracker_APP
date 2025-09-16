// lib/models/transaction_model.dart
class TransactionModel {
  final int? id;
  final int userId;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final DateTime date;
  final String? description;
  final String? icon;
  final DateTime createdAt;

  TransactionModel({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.description,
    this.icon,
    required this.createdAt,
  });

  // Convert TransactionModel to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
      'description': description,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'] ?? '', // Handle potential null
      amount: map['amount'].toDouble(),
      type: map['type'] ?? '', // Handle potential null
      category: map['category'] ?? '', // Handle potential null
      date: DateTime.parse(map['date']),
      description: map['description'], // This can be null - don't provide default
      icon: map['icon'], // This can be null
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // Create copy with updated fields
  TransactionModel copyWith({
    int? id,
    int? userId,
    String? title,
    double? amount,
    String? type,
    String? category,
    DateTime? date,
    String? description,
    String? icon,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  @override
  String toString() {
    return 'TransactionModel(id: $id, title: $title, amount: $amount, type: $type, category: $category, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.amount == amount &&
        other.type == type &&
        other.category == category &&
        other.date == date &&
        other.description == description &&
        other.icon == icon &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    userId.hashCode ^
    title.hashCode ^
    amount.hashCode ^
    type.hashCode ^
    category.hashCode ^
    date.hashCode ^
    description.hashCode ^
    icon.hashCode ^
    createdAt.hashCode;
  }
}