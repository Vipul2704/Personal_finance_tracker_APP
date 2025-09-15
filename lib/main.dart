// lib/main.dart
import 'package:flutter/material.dart';
import 'package:personal_finance_tracker/presentation/providers/budget_provider.dart';
import 'package:personal_finance_tracker/presentation/providers/category_provider.dart';
import 'package:personal_finance_tracker/presentation/providers/dashboard_provider.dart';
import 'package:personal_finance_tracker/presentation/providers/goal_provider.dart';
import 'package:personal_finance_tracker/presentation/providers/notification_provider.dart';
import 'package:personal_finance_tracker/presentation/providers/transaction_provider.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance_tracker/core/constants/app_constant.dart';
import 'package:personal_finance_tracker/core/constants/colors.dart';
import 'package:personal_finance_tracker/presentation/screens/auth/login_screen.dart';
import 'package:personal_finance_tracker/presentation/screens/auth/signup_screen.dart';
import 'package:personal_finance_tracker/presentation/screens/auth/auth_wrapper.dart';
import 'package:personal_finance_tracker/presentation/providers/auth_provider.dart';
import 'package:personal_finance_tracker/presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No Firebase initialization needed for offline version

  runApp(const PersonalFinanceTrackerApp());
}

class PersonalFinanceTrackerApp extends StatelessWidget {
  const PersonalFinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<TransactionProvider>(create: (_) => TransactionProvider()),
        ChangeNotifierProvider<BudgetProvider>(create: (_) => BudgetProvider()), // your existing one
        ChangeNotifierProvider<CategoryProvider>(create: (_) => CategoryProvider()),
        ChangeNotifierProvider<GoalProvider>(create: (_) => GoalProvider()),
        ChangeNotifierProvider<NotificationProvider>(create: (_) => NotificationProvider()),
        ChangeNotifierProvider<DashboardProvider>(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 6,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            color: Colors.white,
            shadowColor: Colors.grey.withOpacity(0.2),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: AppColors.primary,
            linearTrackColor: Colors.grey,
          ),
        ),
        // NAMED ROUTES
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}