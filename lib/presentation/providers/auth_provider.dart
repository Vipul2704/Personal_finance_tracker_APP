// lib/presentation/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../models/user_model.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final OfflineAuthService _authService = OfflineAuthService();

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  // Track if signup just happened
  bool _justSignedUp = false;

  // Getters
  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _state == AuthState.authenticated && _user != null && !_justSignedUp;
  bool get isLoading => _state == AuthState.loading;
  bool get justSignedUp => _justSignedUp;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      _setState(AuthState.loading);

      // Initialize the auth service
      await _authService.initialize();

      // Check if user is logged in
      if (_authService.isLoggedIn && _authService.currentUser != null) {
        _user = _authService.currentUser;
        _userData = await _authService.getUserData();
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _setState(AuthState.unauthenticated);
    }
  }

  // Load user data
  Future<void> _loadUserData() async {
    try {
      _userData = await _authService.getUserData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print('DEBUG AuthProvider: signUp started for $email');
      _setState(AuthState.loading);
      print('DEBUG AuthProvider: Set loading state');

      print('DEBUG AuthProvider: Calling _authService.signUpWithEmailAndPassword');
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
      print('DEBUG AuthProvider: signUpWithEmailAndPassword completed. User: ${user?.email}');

      if (user != null) {
        print('DEBUG AuthProvider: User created successfully');

        // Set the state for successful signup
        print('DEBUG AuthProvider: Setting final state');
        _justSignedUp = true;
        _user = null; // Don't auto-login after signup
        _userData = null;
        _state = AuthState.unauthenticated;
        _errorMessage = null;

        print('DEBUG AuthProvider: Final state set - justSignedUp: $_justSignedUp, state: $_state');
        notifyListeners();
        print('DEBUG AuthProvider: notifyListeners called, returning true');
        return true;
      }

      print('DEBUG AuthProvider: User was null');
      _setState(AuthState.error, 'Failed to create account');
      return false;
    } catch (e) {
      print('DEBUG AuthProvider: Exception caught: $e');
      print('DEBUG AuthProvider: Exception type: ${e.runtimeType}');
      _setState(AuthState.error, e.toString());
      return false;
    }
  }

  // Sign in method - clears signup flag
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setState(AuthState.loading);

      // Clear signup flag when user manually signs in
      _justSignedUp = false;

      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (user != null) {
        _user = user;
        _state = AuthState.authenticated;
        await _loadUserData();
        notifyListeners();
        return true;
      }

      _setState(AuthState.error, 'Failed to sign in');
      return false;
    } catch (e) {
      _setState(AuthState.error, e.toString());
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setState(AuthState.loading);
      await _authService.signOut();
      _user = null;
      _userData = null;
      _justSignedUp = false;
      _state = AuthState.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setState(AuthState.error, e.toString());
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setState(AuthState.loading);
      await _authService.sendPasswordResetEmail(email);
      _setState(AuthState.unauthenticated);
      return true;
    } catch (e) {
      _setState(AuthState.error, e.toString());
      return false;
    }
  }

  // Send email verification (no-op for offline)
  Future<bool> sendEmailVerification() async {
    // Always return true for offline version
    return true;
  }

  // Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      _setState(AuthState.loading);
      await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // Update local user data
      if (displayName != null && _user != null) {
        _user = _user!.copyWith(fullName: displayName);
      }

      await _loadUserData();
      _setState(AuthState.authenticated);
      return true;
    } catch (e) {
      _setState(AuthState.error, e.toString());
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      _setState(AuthState.loading);
      await _authService.deleteAccount();
      _user = null;
      _userData = null;
      _justSignedUp = false;
      _state = AuthState.unauthenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setState(AuthState.error, e.toString());
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = (_user != null && !_justSignedUp) ? AuthState.authenticated : AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // Set state helper
  void _setState(AuthState newState, [String? error]) {
    _state = newState;
    _errorMessage = error;
    notifyListeners();
  }

  // Reload current user
  Future<void> reloadUser() async {
    try {
      if (_user != null) {
        await _loadUserData();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error reloading user: $e');
    }
  }

  // Method to manually mark signup as complete (call this from login screen if needed)
  void completeSignup() {
    _justSignedUp = false;
    notifyListeners();
  }
}