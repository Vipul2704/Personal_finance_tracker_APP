import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import 'add_expense_dialog.dart';
import 'analytics_page.dart';
import 'budget_page.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userData = authProvider.userData;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(userData?['fullName'] ?? user?.displayName ?? 'User', authProvider),
              const SizedBox(height: 24),

              // Balance Overview Card
              _buildBalanceCard(),
              const SizedBox(height: 24),

              // Quick Action Buttons
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Financial Overview Charts
              _buildFinancialOverview(),
              const SizedBox(height: 24),

              // Recent Transactions
              _buildRecentTransactions(),
              const SizedBox(height: 24),

              // Budget Overview
              _buildBudgetOverview(),
              const SizedBox(height: 24),

              // Financial Goals
              _buildFinancialGoals(),
              const SizedBox(height: 24),

              // AI Insights & Recommendations
              _buildAIInsights(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(String userName, AuthProvider authProvider) {
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
            _buildNotificationIcon(),
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

  Widget _buildNotificationIcon() {
    return IconButton(
      onPressed: () {
        _showNotifications();
      },
      icon: Stack(
        children: [
          const Icon(Icons.notifications_outlined, size: 28, color: AppColors.textSecondary),
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
              child: const Text(
                '3',
                style: TextStyle(
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

  Widget _buildBalanceCard() {
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
          const Text(
            '₹45,850.00',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem('Income', '₹25,500', Icons.trending_up, Colors.white),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white30,
              ),
              Expanded(
                child: _buildBalanceItem('Expenses', '₹18,650', Icons.trending_down, Colors.white),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildFinancialOverview() {
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
                sections: [
                  PieChartSectionData(
                    value: 35,
                    title: 'Food\n₹6,125',
                    color: AppColors.chartColors[0],
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: 25,
                    title: 'Transport\n₹4,375',
                    color: AppColors.chartColors[1],
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: 20,
                    title: 'Shopping\n₹3,500',
                    color: AppColors.chartColors[2],
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: 20,
                    title: 'Others\n₹3,500',
                    color: AppColors.chartColors[3],
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
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
          child: Column(
            children: [
              _buildTransactionItem('Grocery Shopping', 'Food & Dining', '₹1,250', Icons.shopping_cart, AppColors.expense, false),
              _buildDivider(),
              _buildTransactionItem('Salary Credit', 'Income', '₹25,000', Icons.account_balance_wallet, AppColors.income, true),
              _buildDivider(),
              _buildTransactionItem('Uber Ride', 'Transportation', '₹180', Icons.directions_car, AppColors.chartColors[1], false),
              _buildDivider(),
              _buildTransactionItem('Coffee Shop', 'Food & Drinks', '₹120', Icons.local_cafe, AppColors.categoryColors[7], false),
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

  Widget _buildTransactionItem(String title, String category, String amount, IconData icon, Color color, bool isIncome) {
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  category,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isIncome ? '+$amount' : '-$amount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIncome ? AppColors.income : AppColors.expense,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetOverview() {
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
          child: Column(
            children: [
              _buildBudgetItem('Food & Drinks', 8500, 12000, AppColors.expense),
              const SizedBox(height: 16),
              _buildBudgetItem('Transportation', 2300, 5000, AppColors.chartColors[1]),
              const SizedBox(height: 16),
              _buildBudgetItem('Shopping', 3200, 8000, AppColors.chartColors[2]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetItem(String category, double spent, double budget, Color color) {
    double percentage = spent / budget;
    bool isOverBudget = percentage > 0.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '₹${spent.toInt()} / ₹${budget.toInt()}',
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
                value: percentage,
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

  Widget _buildFinancialGoals() {
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
          child: Column(
            children: [
              _buildGoalItem('Emergency Fund', 45000, 100000, Icons.shield_outlined),
              const SizedBox(height: 16),
              _buildGoalItem('Vacation Fund', 15000, 50000, Icons.flight_takeoff),
              const SizedBox(height: 16),
              _buildGoalItem('New Laptop', 35000, 80000, Icons.laptop_mac),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalItem(String title, double current, double target, IconData icon) {
    double percentage = current / target;

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
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${current.toInt()} / ₹${target.toInt()}',
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
                      value: percentage,
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

  Widget _buildAIInsights() {
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
              const Text(
                'You\'ve been spending 23% more on food this month. Consider meal planning to save ₹2,500 monthly.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _showInsightDetails(),
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
      height: 75, // Increased height
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

  void _showAddTransaction(String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddExpenseDialog(transactionType: type);
      },
    );
  }

  void _showScanReceipt() {
    _showComingSoon('Receipt Scanning');
  }

  void _showVoiceEntry() {
    _showComingSoon('Voice Entry');
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.warning, color: AppColors.warning),
              title: Text('Budget Alert'),
              subtitle: Text('Food budget exceeded by 15%'),
            ),
            ListTile(
              leading: Icon(Icons.info, color: AppColors.info),
              title: Text('Subscription Due'),
              subtitle: Text('Netflix payment due tomorrow'),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: AppColors.success),
              title: Text('Goal Achieved'),
              subtitle: Text('Emergency fund goal completed!'),
            ),
          ],
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
      await authProvider.signOut();
    }
  }

  void _showDetailedAnalytics() {
    _showComingSoon('Detailed Analytics');
  }

  void _showAllTransactions() {
    _showComingSoon('Transaction History');
  }

  void _showAddGoal() {
    _showComingSoon('Add Financial Goal');
  }

  void _showInsightDetails() {
    _showComingSoon('AI Insight Details');
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