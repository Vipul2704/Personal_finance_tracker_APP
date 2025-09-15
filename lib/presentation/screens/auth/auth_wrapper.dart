import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance_tracker/presentation/providers/auth_provider.dart';
import 'package:personal_finance_tracker/presentation/screens/auth/login_screen.dart';
import 'package:personal_finance_tracker/presentation/screens/home/home_screen.dart';
import 'package:personal_finance_tracker/core/constants/colors.dart';
import 'package:personal_finance_tracker/core/constants/app_constant.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while provider initializes or an operation is ongoing
        if (authProvider.state == AuthState.initial || authProvider.isLoading) {
          return const _LoadingScreen();
        }

        // IMPORTANT: Use isAuthenticated getter which properly checks !_justSignedUp
        // This will be false if user just signed up, forcing them to login screen
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }

        // Show login screen for unauthenticated users OR users who just signed up
        return const LoginScreen();
      },
    );
  }
}

/// Minimal loading screen used while auth state is being resolved.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.account_balance_wallet, size: 64, color: AppColors.primary),
            SizedBox(height: 20),
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text('Initializing...', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}