import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:personal_finance_tracker/presentation/providers/budget_provider.dart';
import 'package:personal_finance_tracker/models/budget_model.dart';


class BudgetPage extends StatefulWidget {
  final int userId;

  const BudgetPage({super.key, required this.userId});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  String selectedPeriod = 'monthly';
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  // Category options for dropdown
  final List<String> categoryOptions = [
    'Food & Dining',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Healthcare',
    'Bills & Utilities',
    'Education',
    'Travel',
    'Personal Care',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _initializeBudgets();
  }

  void _initializeBudgets() async {
    final budgetProvider = context.read<BudgetProvider>();
    await budgetProvider.initializeForUser(widget.userId);
  }

  @override
  void dispose() {
    categoryController.dispose();
    amountController.dispose();
    super.dispose();
  }

  double getProgressPercentage(double spent, double allocated) {
    if (allocated == 0) return 0;
    return (spent / allocated * 100).clamp(0.0, 100.0);
  }

  BudgetStatus getBudgetStatus(double spent, double allocated) {
    if (allocated == 0) return BudgetStatus.good;
    final percentage = spent / allocated * 100;
    if (percentage >= 100) return BudgetStatus.exceeded;
    if (percentage >= 80) return BudgetStatus.warning;
    return BudgetStatus.good;
  }

  Color getStatusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.exceeded:
        return Colors.red;
      case BudgetStatus.warning:
        return Colors.orange;
      case BudgetStatus.good:
        return Colors.green;
    }
  }

  Color _getCategoryColor(String category) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFF96CEB4),
      const Color(0xFFFFEAA7),
      const Color(0xFFFD79A8),
      const Color(0xFF6C5CE7),
      const Color(0xFFA29BFE),
    ];
    return colors[category.hashCode % colors.length];
  }

  String _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('food') || categoryLower.contains('dining')) return '🍽️';
    if (categoryLower.contains('transport')) return '🚗';
    if (categoryLower.contains('entertainment')) return '🎮';
    if (categoryLower.contains('shopping')) return '🛍️';
    if (categoryLower.contains('health')) return '🏥';
    if (categoryLower.contains('education')) return '📚';
    if (categoryLower.contains('utility') || categoryLower.contains('bill')) return '💡';
    if (categoryLower.contains('travel')) return '✈️';
    if (categoryLower.contains('personal') || categoryLower.contains('care')) return '💄';
    return '💰';
  }

  String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    )}';
  }

  void _showAddBudgetDialog() {
    categoryController.clear();
    amountController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) => _buildAddEditBudgetDialog(isEdit: false),
    );
  }

  void _addBudget() async {
    if (categoryController.text.isNotEmpty && amountController.text.isNotEmpty) {
      final budgetProvider = context.read<BudgetProvider>();
      final amount = double.tryParse(amountController.text) ?? 0.0;

      if (amount <= 0) {
        _showErrorSnackBar('Please enter a valid amount');
        return;
      }

      final success = await budgetProvider.createBudgetForCategory(
        widget.userId,
        categoryController.text,
        amount,
      );

      if (success) {
        categoryController.clear();
        amountController.clear();
        Navigator.pop(context);
        _showSuccessSnackBar('Budget added successfully!');
      } else {
        _showErrorSnackBar(budgetProvider.error ?? 'Failed to add budget');
      }
    } else {
      _showErrorSnackBar('Please fill in all fields');
    }
  }

  void _editBudget(BudgetModel budget) {
    categoryController.text = budget.category;
    amountController.text = budget.budgetAmount.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) => _buildAddEditBudgetDialog(
        isEdit: true,
        budget: budget,
      ),
    );
  }

  void _updateBudget(BudgetModel budget) async {
    if (categoryController.text.isNotEmpty && amountController.text.isNotEmpty) {
      final budgetProvider = context.read<BudgetProvider>();
      final amount = double.tryParse(amountController.text) ?? 0.0;

      if (amount <= 0) {
        _showErrorSnackBar('Please enter a valid amount');
        return;
      }

      final updatedBudget = budget.copyWith(
        category: categoryController.text,
        budgetAmount: amount,
        updatedAt: DateTime.now(),
      );

      final success = await budgetProvider.updateBudget(updatedBudget);

      if (success) {
        categoryController.clear();
        amountController.clear();
        Navigator.pop(context);
        _showSuccessSnackBar('Budget updated successfully!');
      } else {
        _showErrorSnackBar(budgetProvider.error ?? 'Failed to update budget');
      }
    } else {
      _showErrorSnackBar('Please fill in all fields');
    }
  }

  void _deleteBudget(BudgetModel budget) async {
    final budgetProvider = context.read<BudgetProvider>();

    // Create a deactivated version of the budget
    final deactivatedBudget = budget.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );

    final success = await budgetProvider.updateBudget(deactivatedBudget);

    if (success) {
      _showSuccessSnackBar('${budget.category} budget deleted');
    } else {
      _showErrorSnackBar(budgetProvider.error ?? 'Failed to delete budget');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _createDefaultBudgets() async {
    final budgetProvider = context.read<BudgetProvider>();
    await budgetProvider.createDefaultBudgets(widget.userId);
    _showSuccessSnackBar('Default budgets created!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Budget Management',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.read<BudgetProvider>().refreshBudgets(widget.userId),
            icon: const Icon(Icons.refresh, color: Colors.grey),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              if (value == 'create_defaults') {
                _createDefaultBudgets();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_defaults',
                child: Text('Create Default Budgets'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetProvider, child) {
          if (budgetProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (budgetProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${budgetProvider.error}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => budgetProvider.refreshBudgets(widget.userId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCards(budgetProvider),
                const SizedBox(height: 24),
                _buildPeriodSelector(),
                const SizedBox(height: 24),
                _buildAIRecommendations(budgetProvider),
                const SizedBox(height: 24),
                _buildBudgetCategories(budgetProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards(BudgetProvider budgetProvider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                title: 'Total Budget',
                amount: budgetProvider.totalCurrentMonthBudget,
                icon: Icons.account_balance_wallet,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                title: 'Total Spent',
                amount: budgetProvider.totalCurrentMonthSpent,
                icon: Icons.trending_up,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildOverviewCard(
          title: budgetProvider.totalCurrentMonthRemaining >= 0
              ? 'Remaining Budget'
              : 'Over Budget',
          amount: budgetProvider.totalCurrentMonthRemaining.abs(),
          icon: budgetProvider.totalCurrentMonthRemaining >= 0
              ? Icons.savings
              : Icons.warning,
          color: budgetProvider.totalCurrentMonthRemaining >= 0
              ? Colors.green
              : Colors.red,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(amount),
            style: TextStyle(
              fontSize: isFullWidth ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['weekly', 'monthly', 'quarterly'];

    return Row(
      children: periods.map((period) {
        final isSelected = selectedPeriod == period;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => selectedPeriod = period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  period.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAIRecommendations(BudgetProvider budgetProvider) {
    final recommendations = budgetProvider.getSpendingRecommendations();
    final alerts = budgetProvider.getBudgetAlerts();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Smart Insights & Recommendations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (alerts.isNotEmpty) ...[
            ...alerts.take(3).map((alert) => _buildRecommendationCard(
              alert['message'] as String,
              alert['severity'] as String,
            )).toList(),
          ],
          ...recommendations.take(2).map((rec) => _buildRecommendationCard(
            rec,
            'insight',
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String message, String type) {
    Color iconColor;
    IconData iconData;

    switch (type) {
      case 'critical':
        iconColor = Colors.red;
        iconData = Icons.error;
        break;
      case 'warning':
        iconColor = Colors.orange;
        iconData = Icons.warning;
        break;
      default:
        iconColor = Colors.blue;
        iconData = Icons.lightbulb;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCategories(BudgetProvider budgetProvider) {
    final budgets = budgetProvider.currentMonthBudgets;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Budget Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddBudgetDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Budget'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          if (budgets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No budgets for this month',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first budget or set up default budgets',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...budgets.map((budget) => _buildBudgetCard(budget)).toList(),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BudgetModel budget) {
    final progress = getProgressPercentage(budget.spentAmount, budget.budgetAmount);
    final status = getBudgetStatus(budget.spentAmount, budget.budgetAmount);
    final statusColor = getStatusColor(status);
    final categoryColor = _getCategoryColor(budget.category);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getCategoryIcon(budget.category),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'MONTHLY BUDGET',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _editBudget(budget);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(budget);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatCurrency(budget.spentAmount)} / ${formatCurrency(budget.budgetAmount)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Row(
                children: [
                  Icon(
                    status == BudgetStatus.exceeded
                        ? Icons.trending_up
                        : status == BudgetStatus.warning
                        ? Icons.warning
                        : Icons.check_circle,
                    color: statusColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${progress.toInt()}%',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
          if (status == BudgetStatus.exceeded) ...[
            const SizedBox(height: 8),
            Text(
              'Over budget by ${formatCurrency(budget.spentAmount - budget.budgetAmount)}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Budget'),
          content: Text('Are you sure you want to delete the budget for ${budget.category}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteBudget(budget);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddEditBudgetDialog({required bool isEdit, BudgetModel? budget}) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Budget' : 'Add New Budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEdit)
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: categoryController.text.isEmpty ? null : categoryController.text,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categoryOptions.map((category) {
                      final budgetProvider = context.read<BudgetProvider>();
                      final hasExisting = budgetProvider.hasBudget(category);

                      return DropdownMenuItem(
                        value: category,
                        enabled: !hasExisting,
                        child: Text(
                          category,
                          style: TextStyle(
                            color: hasExisting ? Colors.grey : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        categoryController.text = value;
                      }
                    },
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Budget Amount',
                    hintText: '0',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                categoryController.clear();
                amountController.clear();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (isEdit && budget != null) {
                  _updateBudget(budget);
                } else {
                  _addBudget();
                }
              },
              child: Text(isEdit ? 'Update' : 'Add Budget'),
            ),
          ],
        );
      },
    );
  }
}

// Enums
enum BudgetStatus { good, warning, exceeded }