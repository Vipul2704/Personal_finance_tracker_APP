import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  User? _user;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  // NEW: Track if signup just happened
  bool _justSignedUp = false;

  // Getters
  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;
  bool get isAuthenticated => _state == AuthState.authenticated && _user != null && !_justSignedUp;
  bool get isLoading => _state == AuthState.loading;
  bool get justSignedUp => _justSignedUp;

  AuthProvider() {
    _init();
  }

  // _init: listen to Firebase auth changes but DO NOT reset _justSignedUp here.
  // Keep listening to auth state but DO NOT reset _justSignedUp here.
  void _init() {
    _authService.authStateChanges.listen((User? user) {
      if (user != null) {
        _user = user;
        // If the user was not justSignedUp, treat as normal authenticated user
        if (!_justSignedUp) {
          _state = AuthState.authenticated;
          _loadUserData();
        } else {
          // If justSignedUp is true, keep state unauthenticated so AuthWrapper shows LoginScreen
          _state = AuthState.unauthenticated;
        }
      } else {
        _user = null;
        _userData = null;
        _state = AuthState.unauthenticated;
        // IMPORTANT: do NOT reset _justSignedUp here — reset explicitly in signOut() or completeSignup()
      }
      notifyListeners();
    });
  }



  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      _userData = await _authService.getUserData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Public method so UI can trigger user data reload
  Future<void> loadUserData() async {
    await _loadUserData();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _setState(AuthState.loading);

      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (userCredential != null) {
        // Sign the user out if Firebase auto-signed them in
        await _authService.signOut();

        // AFTER signing out, mark that the user just signed up so AuthWrapper shows LoginScreen
        _justSignedUp = true;

        // Ensure provider's public state reflects "not authenticated but just signed up"
        _user = null;
        _userData = null;
        _state = AuthState.unauthenticated;
        _errorMessage = null;

        notifyListeners();
        return true;
      }

      _setState(AuthState.error, 'Failed to create account');
      return false;
    } catch (e) {
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

      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential != null) {
        _user = userCredential.user;
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

  // Method to manually mark signup as complete (call this from signup screen)
  void completeSignup() {
    _justSignedUp = false;
    notifyListeners();
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

  // Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
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
        await _user!.reload();
        _user = _authService.currentUser;
        await _loadUserData();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error reloading user: $e');
    }
  }
}