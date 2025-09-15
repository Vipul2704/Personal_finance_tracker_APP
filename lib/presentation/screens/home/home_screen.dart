import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'add_expense_dialog.dart';
import 'analytics_page.dart';
import 'budget_page.dart';
import 'add_expense_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  void _initializeDashboard() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    if (authProvider.user?.id != null && !_isInitialized) {
      // Use ! to assert it's not null (safe because of the check above)
      await dashboardProvider.initializeForUser(authProvider.user!.id!);
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final user = authProvider.user;
    final userData = authProvider.userData;

    if (dashboardProvider.isLoading && !_isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (dashboardProvider.error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dashboardProvider.error!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _refreshDashboard(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(userData?['fullName'] ?? user?.fullName ?? 'User', authProvider, dashboardProvider),
                const SizedBox(height: 24),

                // Balance Overview Card
                _buildBalanceCard(dashboardProvider),
                const SizedBox(height: 24),

                // Financial Health Score
                _buildFinancialHealthCard(dashboardProvider),
                const SizedBox(height: 24),

                // Quick Action Buttons
                _buildQuickActions(),
                const SizedBox(height: 24),

                // Financial Overview Charts
                _buildFinancialOverview(dashboardProvider),
                const SizedBox(height: 24),

                // Budget Alerts (if any)
                if (dashboardProvider.getBudgetAlerts().isNotEmpty) ...[
                  _buildBudgetAlerts(dashboardProvider),
                  const SizedBox(height: 24),
                ],

                // Recent Transactions
                _buildRecentTransactions(dashboardProvider),
                const SizedBox(height: 24),

                // Budget Overview
                _buildBudgetOverview(dashboardProvider),
                const SizedBox(height: 24),

                // Financial Goals
                _buildFinancialGoals(dashboardProvider),
                const SizedBox(height: 24),

                // AI Insights & Recommendations
                _buildAIInsights(dashboardProvider),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Future<void> _refreshDashboard() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);

    final userId = authProvider.user?.id;
    if (userId != null) {
      await dashboardProvider.refreshDashboard(userId);
    }
  }

  Widget _buildHeader(String userName, AuthProvider authProvider, DashboardProvider dashboardProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildNotificationIcon(dashboardProvider.unreadNotifications),
            const SizedBox(width: 8),
            _buildProfileMenu(userName, authProvider),
          ],
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _buildNotificationIcon(int unreadCount) {
    return IconButton(
      onPressed: () {
        _showNotifications();
      },
      icon: Stack(
        children: [
          const Icon(Icons.notifications_outlined, size: 28, color: AppColors.textSecondary),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(String userName, AuthProvider authProvider) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            _showProfile();
            break;
          case 'settings':
            _showSettings();
            break;
          case 'logout':
            await _showLogoutDialog(authProvider);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20),
              SizedBox(width: 12),
              Text('Profile'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: AppColors.error),
              SizedBox(width: 12),
              Text('Logout', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary,
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(DashboardProvider dashboardProvider) {
    final balance = dashboardProvider.balanceSummary;
    final totalBalance = balance['balance'] ?? 0.0;
    final totalIncome = balance['income'] ?? 0.0;
    final totalExpense = balance['expense'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Icon(
                Icons.visibility_outlined,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${totalBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem('Income', '₹${totalIncome.toStringAsFixed(0)}', Icons.trending_up, Colors.white),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              Expanded(
                child: _buildBalanceItem('Expenses', '₹${totalExpense.toStringAsFixed(0)}', Icons.trending_down, Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialHealthCard(DashboardProvider dashboardProvider) {
    final healthScore = dashboardProvider.getFinancialHealthScore();
    final savingsRate = dashboardProvider.savingsRate;

    Color scoreColor;
    String scoreLabel;

    if (healthScore >= 80) {
      scoreColor = AppColors.success;
      scoreLabel = 'Excellent';
    } else if (healthScore >= 60) {
      scoreColor = AppColors.primary;
      scoreLabel = 'Good';
    } else if (healthScore >= 40) {
      scoreColor = AppColors.warning;
      scoreLabel = 'Fair';
    } else {
      scoreColor = AppColors.error;
      scoreLabel = 'Needs Improvement';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                '$healthScore',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial Health Score',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scoreLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Savings Rate: ${savingsRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetAlerts(DashboardProvider dashboardProvider) {
    final alerts = dashboardProvider.getBudgetAlerts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Alerts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...alerts.take(3).map((alert) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: alert['type'] == 'over_budget'
                ? AppColors.error.withOpacity(0.1)
                : AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: alert['type'] == 'over_budget'
                  ? AppColors.error.withOpacity(0.3)
                  : AppColors.warning.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                alert['type'] == 'over_budget'
                    ? Icons.error_outline
                    : Icons.warning_outlined,
                color: alert['type'] == 'over_budget'
                    ? AppColors.error
                    : AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  alert['message'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildBalanceItem(String title, String amount, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.withOpacity(0.8), size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(color: color.withOpacity(0.8), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Add Expense',
                Icons.remove_circle_outline,
                AppColors.expense,
                    () => _showAddTransaction('expense'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Add Income',
                Icons.add_circle_outline,
                AppColors.income,
                    () => _showAddTransaction('income'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Scan Receipt',
                Icons.camera_alt_outlined,
                AppColors.secondary,
                    () => _showScanReceipt(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Voice Entry',
                Icons.mic_outlined,
                AppColors.categoryColors[4],
                    () => _showVoiceEntry(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview(DashboardProvider dashboardProvider) {
    final expensesByCategory = dashboardProvider.expensesByCategory;

    if (expensesByCategory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No expense data available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // Convert expenses to chart data
    final total = expensesByCategory.values.fold(0.0, (sum, amount) => sum + amount);
    final chartSections = expensesByCategory.entries.take(4).map((entry) {
      final percentage = (entry.value / total) * 100;
      final colorIndex = expensesByCategory.keys.toList().indexOf(entry.key) % AppColors.chartColors.length;

      return PieChartSectionData(
        value: percentage,
        title: '${entry.key}\n₹${entry.value.toInt()}',
        color: AppColors.chartColors[colorIndex],
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Spending Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _showDetailedAnalytics(),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: chartSections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(DashboardProvider dashboardProvider) {
    final transactions = dashboardProvider.recentTransactions.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _showAllTransactions(),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: transactions.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No recent transactions',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          )
              : Column(
            children: [
              for (int i = 0; i < transactions.length; i++) ...[
                _buildTransactionItem(transactions[i]),
                if (i < transactions.length - 1) _buildDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.grey[200],
    );
  }

  Widget _buildTransactionItem(dynamic transaction) {
    final isIncome = transaction.type.toLowerCase() == 'income';
    final icon = _getTransactionIcon(transaction.category);
    final color = isIncome ? AppColors.income : AppColors.expense;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  transaction.category,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
        return Icons.restaurant;
      case 'transportation':
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'healthcare':
        return Icons.local_hospital;
      case 'income':
      case 'salary':
        return Icons.account_balance_wallet;
      default:
        return Icons.receipt;
    }
  }

  Widget _buildBudgetOverview(DashboardProvider dashboardProvider) {
    final budgets = dashboardProvider.currentMonthBudgets.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: budgets.isEmpty
              ? const Center(
            child: Text(
              'No budgets set for this month',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          )
              : Column(
            children: [
              for (int i = 0; i < budgets.length; i++) ...[
                _buildBudgetItem(budgets[i]),
                if (i < budgets.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetItem(dynamic budget) {
    double percentage = budget.budgetAmount > 0 ? budget.spentAmount / budget.budgetAmount : 0;
    bool isOverBudget = percentage > 0.8;
    Color color = _getBudgetColor(budget.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              budget.category,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '₹${budget.spentAmount.toInt()} / ₹${budget.budgetAmount.toInt()}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? AppColors.error : color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOverBudget ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getBudgetColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
        return AppColors.expense;
      case 'transportation':
        return AppColors.chartColors[1];
      case 'shopping':
        return AppColors.chartColors[2];
      default:
        return AppColors.primary;
    }
  }

  Widget _buildFinancialGoals(DashboardProvider dashboardProvider) {
    final goals = dashboardProvider.activeGoals.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Financial Goals',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => _showAddGoal(),
              child: const Text('Add Goal'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: goals.isEmpty
              ? const Center(
            child: Text(
              'No active goals. Create your first goal!',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          )
              : Column(
            children: [
              for (int i = 0; i < goals.length; i++) ...[
                _buildGoalItem(goals[i]),
                if (i < goals.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalItem(dynamic goal) {
    double percentage = goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0;
    IconData icon = _getGoalIcon(goal.title);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${goal.currentAmount.toInt()} / ₹${goal.targetAmount.toInt()}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage.clamp(0.0, 1.0),
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getGoalIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('emergency') || titleLower.contains('fund')) {
      return Icons.shield_outlined;
    } else if (titleLower.contains('vacation') || titleLower.contains('travel')) {
      return Icons.flight_takeoff;
    } else if (titleLower.contains('laptop') || titleLower.contains('computer')) {
      return Icons.laptop_mac;
    } else if (titleLower.contains('house') || titleLower.contains('home')) {
      return Icons.home_outlined;
    } else if (titleLower.contains('car') || titleLower.contains('vehicle')) {
      return Icons.directions_car_outlined;
    }
    return Icons.savings_outlined;
  }

  Widget _buildAIInsights(DashboardProvider dashboardProvider) {
    final insights = dashboardProvider.generateAIInsights();

    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    final mainInsight = insights.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Insights & Tips',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.categoryColors[4].withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.categoryColors[4].withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.categoryColors[4], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Smart Recommendation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.categoryColors[4],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                mainInsight,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _showInsightDetails(insights),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.categoryColors[4],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('View Details', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => _dismissInsight(),
                    child: Text(
                      'Dismiss',
                      style: TextStyle(
                        color: AppColors.categoryColors[4],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 75,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(Icons.home, 'Home', 0),
          _buildNavBarItem(Icons.bar_chart, 'Analytics', 1),
          const SizedBox(width: 40), // Space for FAB
          _buildNavBarItem(Icons.account_balance_wallet, 'Budget', 2),
          _buildNavBarItem(Icons.person, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        _navigateToPage(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.primary : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _showAddTransactionBottomSheet();
      },
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showAddTransactionBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Transaction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildBottomSheetOption(
                    'Add Expense',
                    Icons.remove_circle_outline,
                    AppColors.expense,
                        () {
                      Navigator.pop(context);
                      _showAddTransaction('expense');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBottomSheetOption(
                    'Add Income',
                    Icons.add_circle_outline,
                    AppColors.income,
                        () {
                      Navigator.pop(context);
                      _showAddTransaction('income');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBottomSheetOption(
                    'Scan Receipt',
                    Icons.camera_alt_outlined,
                    AppColors.secondary,
                        () {
                      Navigator.pop(context);
                      _showScanReceipt();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBottomSheetOption(
                    'Voice Entry',
                    Icons.mic_outlined,
                    AppColors.categoryColors[4],
                        () {
                      Navigator.pop(context);
                      _showVoiceEntry();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Navigation and interaction methods
  void _navigateToPage(int index) {
    switch (index) {
      case 0:
      // Already on Home
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnalyticsPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BudgetPage()),
        );
        break;
      case 3:
        _showComingSoon('Profile');
        break;
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showAddTransaction(String type) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddExpenseDialog(transactionType: type);
      },
    );

    // Refresh dashboard if transaction was added
    if (result == true) {
      await _refreshDashboard();
    }
  }

  void _showScanReceipt() {
    _showComingSoon('Receipt Scanning');
  }

  void _showVoiceEntry() {
    _showComingSoon('Voice Entry');
  }

  void _showNotifications() {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final budgetAlerts = dashboardProvider.getBudgetAlerts();
    final goalsNearDeadline = dashboardProvider.goalsNearingDeadline;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Budget Alerts
              ...budgetAlerts.take(2).map((alert) => ListTile(
                leading: Icon(
                  alert['type'] == 'over_budget' ? Icons.error : Icons.warning,
                  color: alert['type'] == 'over_budget' ? AppColors.error : AppColors.warning,
                ),
                title: Text('Budget Alert'),
                subtitle: Text(alert['message']),
              )),

              // Goal Deadlines
              ...goalsNearDeadline.take(2).map((goal) => ListTile(
                leading: const Icon(Icons.flag, color: AppColors.info),
                title: const Text('Goal Deadline'),
                subtitle: Text('${goal.title} target date approaching'),
              )),

              // Default notifications if none available
              if (budgetAlerts.isEmpty && goalsNearDeadline.isEmpty)
                const ListTile(
                  leading: Icon(Icons.check_circle, color: AppColors.success),
                  title: Text('All Good!'),
                  subtitle: Text('No alerts at the moment'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProfile() {
    _showComingSoon('Profile Management');
  }

  void _showSettings() {
    _showComingSoon('Settings');
  }

  Future<void> _showLogoutDialog(AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      dashboardProvider.clearData();
      await authProvider.signOut();
    }
  }

  void _showDetailedAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalyticsPage()),
    );
  }

  void _showAllTransactions() {
    _showComingSoon('Transaction History');
  }

  void _showAddGoal() {
    _showComingSoon('Add Financial Goal');
  }

  void _showInsightDetails(List<String> insights) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: AppColors.categoryColors[4]),
            const SizedBox(width: 8),
            const Text('AI Insights'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: insights.map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.categoryColors[4],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _dismissInsight() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Insight dismissed'),
        backgroundColor: AppColors.textSecondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}