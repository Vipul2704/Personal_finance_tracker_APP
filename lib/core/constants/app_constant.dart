class AppConstants {
  // App Information
  static const String appName = 'Personal Finance Tracker';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'finance_tracker.db';
  static const int databaseVersion = 1;

  // Table Names
  static const String userTable = 'users';
  static const String expenseTable = 'expenses';
  static const String incomeTable = 'income';
  static const String budgetTable = 'budgets';
  static const String categoryTable = 'categories';

  // SharedPreferences Keys
  static const String isFirstTimeKey = 'is_first_time';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String themeKey = 'theme_mode';
  static const String currencyKey = 'currency';

  // Default Values
  static const String defaultCurrency = '₹';
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Groceries',
    'Others'
  ];

  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Rental',
    'Others'
  ];

  // API Endpoints (for future use)
  static const String baseUrl = 'https://api.personalfinancetracker.com';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 20;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
}