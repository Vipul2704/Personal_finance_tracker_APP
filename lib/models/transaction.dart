enum TransactionType { income, expense }

class Transaction {
  final int? id;
  final double amount;
  final String categoryId;
  final String description;
  final DateTime date;
  final TransactionType type;
  final String? receiptPath; // For receipt images
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.date,
    required this.type,
    this.receiptPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert Transaction to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'type': type.name,
      'receiptPath': receiptPath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Convert Map to Transaction from database
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as String,
      description: map['description'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      type: TransactionType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      receiptPath: map['receiptPath'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'description': description,
      'date': date.toIso8601String(),
      'type': type.name,
      'receiptPath': receiptPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert from JSON from Firebase
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int?,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      type: TransactionType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      receiptPath: json['receiptPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Create a copy with updated values
  Transaction copyWith({
    int? id,
    double? amount,
    String? categoryId,
    String? description,
    DateTime? date,
    TransactionType? type,
    String? receiptPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, amount: $amount, categoryId: $categoryId, description: $description, date: $date, type: ${type.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.amount == amount &&
        other.categoryId == categoryId &&
        other.description == description &&
        other.date == date &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, amount, categoryId, description, date, type);
  }
}