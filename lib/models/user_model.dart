// lib/models/user_model.dart
class UserModel {
  final int? id;
  final String fullName;
  final String email;
  final String passwordHash;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  UserModel({
    this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  // Convert UserModel to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  // Create UserModel from Map (from database)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      fullName: map['full_name'],
      email: map['email'],
      passwordHash: map['password_hash'],
      createdAt: DateTime.parse(map['created_at']),
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'])
          : null,
      isActive: map['is_active'] == 1,
    );
  }

  // Create copy with updated fields
  UserModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? passwordHash,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, fullName: $fullName, email: $email, createdAt: $createdAt, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.passwordHash == passwordHash &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    fullName.hashCode ^
    email.hashCode ^
    passwordHash.hashCode ^
    createdAt.hashCode ^
    lastLoginAt.hashCode ^
    isActive.hashCode;
  }
}