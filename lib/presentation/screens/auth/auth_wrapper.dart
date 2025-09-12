// lib/presentation/screens/auth/auth_wrapper.dart
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

        // If user just signed up — show the LoginScreen and show a one-time message
        if (authProvider.justSignedUp) {
          // show a one-time SnackBar and then clear the flag so it doesn't repeat
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // show notification to user
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(
                content: Text('Account created. Please sign in.'),
                duration: Duration(seconds: 3),
              ),
            );
            // reset the flag so this runs only once
            authProvider.completeSignup();
          });

          return const LoginScreen();
        }

        // If authenticated (and not a just-signed-up transient state) go to Home
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }

        // Default: show login
        return const LoginScreen();
      },
    );
  }
}

/// Minimal loading screen used while auth state is being resolved.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({super.key});

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
