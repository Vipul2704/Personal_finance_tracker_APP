// lib/core/services/offline_auth_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance_tracker/core/database/database_helper.dart';
import '../../models/user_model.dart';

class OfflineAuthService {
  static final OfflineAuthService _instance = OfflineAuthService._internal();
  factory OfflineAuthService() => _instance;
  OfflineAuthService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Keys for SharedPreferences
  static const String _currentUserIdKey = 'current_user_id';
  static const String _isLoggedInKey = 'is_logged_in';

  // Current user data
  UserModel? _currentUser;
  bool _isLoggedIn = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_currentUserIdKey);
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    if (userId != null && isLoggedIn) {
      _currentUser = await _dbHelper.getUserById(userId);
      _isLoggedIn = _currentUser != null;

      if (!_isLoggedIn) {
        // Clear invalid session
        await _clearSession();
      }
    }
  }

  // Sign up with email and password
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _dbHelper.getUserByEmail(email.toLowerCase());
      if (existingUser != null) {
        throw 'The account already exists for that email.';
      }

      // Validate input
      _validateSignUpInput(email, password, fullName);

      // Hash password
      final passwordHash = _hashPassword(password);

      // Create new user
      final newUser = UserModel(
        fullName: fullName.trim(),
        email: email.toLowerCase().trim(),
        passwordHash: passwordHash,
        createdAt: DateTime.now(),
      );

      // Insert user into database
      final userId = await _dbHelper.createUser(newUser);

      // Return the created user with ID
      return newUser.copyWith(id: userId);

    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Validate input
      if (email.trim().isEmpty || password.isEmpty) {
        throw 'Please enter both email and password.';
      }

      // Get user from database
      final user = await _dbHelper.getUserByEmail(email.toLowerCase().trim());
      if (user == null) {
        throw 'No user found for that email.';
      }

      // Verify password
      if (!_verifyPassword(password, user.passwordHash)) {
        throw 'Wrong password provided for that user.';
      }

      // Update last login
      await _dbHelper.updateLastLogin(user.id!);

      // Set current user and save session
      _currentUser = user.copyWith(lastLoginAt: DateTime.now());
      _isLoggedIn = true;
      await _saveSession(user.id!);

      return _currentUser;

    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _currentUser = null;
      _isLoggedIn = false;
      await _clearSession();
    } catch (e) {
      throw 'Error signing out: ${e.toString()}';
    }
  }

  // Get user data (for compatibility with existing code)
  Future<Map<String, dynamic>?> getUserData() async {
    if (_currentUser == null) return null;

    return {
      'uid': _currentUser!.id.toString(),
      'email': _currentUser!.email,
      'fullName': _currentUser!.fullName,
      'displayName': _currentUser!.fullName,
      'emailVerified': true, // Always true for offline
      'createdAt': _currentUser!.createdAt.toIso8601String(),
      'lastLoginAt': _currentUser!.lastLoginAt?.toIso8601String(),
      'isActive': _currentUser!.isActive,
    };
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL, // Ignored for offline version
  }) async {
    try {
      if (_currentUser == null) {
        throw 'No user is currently signed in.';
      }

      if (displayName != null && displayName.trim().isNotEmpty) {
        final updatedUser = _currentUser!.copyWith(
          fullName: displayName.trim(),
        );

        final result = await _dbHelper.updateUser(updatedUser);
        if (result > 0) {
          _currentUser = updatedUser;
        }
      }
    } catch (e) {
      throw 'Error updating profile: ${e.toString()}';
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      if (_currentUser == null) {
        throw 'No user is currently signed in.';
      }

      await _dbHelper.deleteUser(_currentUser!.id!);
      await signOut();
    } catch (e) {
      throw 'Error deleting account: ${e.toString()}';
    }
  }

  // Send password reset email (simulated for offline)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final user = await _dbHelper.getUserByEmail(email.toLowerCase().trim());
      if (user == null) {
        throw 'No user found for that email.';
      }

      // In a real offline app, you might show a different flow
      // For now, we'll just validate that the email exists
      // You could implement a security question system or similar

    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Send email verification (no-op for offline)
  Future<void> sendEmailVerification() async {
    // No operation needed for offline version
    return;
  }

  // PRIVATE HELPER METHODS

  // Hash password using SHA-256 with salt
  String _hashPassword(String password) {
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  // Verify password
  bool _verifyPassword(String password, String hashedPassword) {
    final parts = hashedPassword.split(':');
    if (parts.length != 2) return false;

    final salt = parts[0];
    final hash = parts[1];

    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);

    return digest.toString() == hash;
  }

  // Generate random salt
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  // Save user session
  Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentUserIdKey, userId);
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Clear user session
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Validate signup input
  void _validateSignUpInput(String email, String password, String fullName) {
    if (fullName.trim().isEmpty) {
      throw 'Please enter your full name.';
    }

    if (fullName.trim().length < 2) {
      throw 'Name must be at least 2 characters.';
    }

    if (email.trim().isEmpty) {
      throw 'Please enter your email.';
    }

    if (!_isValidEmail(email)) {
      throw 'The email address is not valid.';
    }

    if (password.isEmpty) {
      throw 'Please enter a password.';
    }

    if (password.length < 6) {
      throw 'The password provided is too weak. Use at least 6 characters.';
    }

    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{6,}$').hasMatch(password)) {
      throw 'Password must contain both letters and numbers.';
    }
  }

  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Handle auth errors
  String _handleAuthError(dynamic error) {
    if (error is String) {
      return error;
    }
    return 'Authentication failed: ${error.toString()}';
  }
}