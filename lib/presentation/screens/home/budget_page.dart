import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  List<Budget> budgets = [
    Budget(
      id: 1,
      category: 'Food & Dining',
      allocated: 15000.0,
      spent: 11000.0,
      period: 'monthly',
      color: const Color(0xFFFF6B6B),
      icon: '🍽️',
    ),
    Budget(
      id: 2,
      category: 'Transportation',
      allocated: 8000.0,
      spent: 9600.0,
      period: 'monthly',
      color: const Color(0xFF4ECDC4),
      icon: '🚗',
    ),
    Budget(
      id: 3,
      category: 'Entertainment',
      allocated: 6000.0,
      spent: 3600.0,
      period: 'monthly',
      color: const Color(0xFF45B7D1),
      icon: '🎮',
    ),
    Budget(
      id: 4,
      category: 'Shopping',
      allocated: 10000.0,
      spent: 8500.0,
      period: 'monthly',
      color: const Color(0xFF96CEB4),
      icon: '🛍️',
    ),
    Budget(
      id: 5,
      category: 'Healthcare',
      allocated: 4000.0,
      spent: 3000.0,
      period: 'monthly',
      color: const Color(0xFFFFEAA7),
      icon: '🏥',
    ),
  ];

  String selectedPeriod = 'monthly';
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String newBudgetPeriod = 'monthly';

  final List<AIRecommendation> aiRecommendations = [
    AIRecommendation(
      type: 'warning',
      message: 'Transportation budget exceeded by ₹1,600. Consider carpooling or public transport.',
      action: 'Optimize',
    ),
    AIRecommendation(
      type: 'suggestion',
      message: 'You have ₹2,400 unused in Entertainment. Consider reallocating to savings.',
      action: 'Reallocate',
    ),
    AIRecommendation(
      type: 'insight',
      message: 'Your spending pattern shows 15% increase compared to last month.',
      action: 'Analyze',
    ),
  ];

  double get totalAllocated => budgets.fold(0.0, (sum, budget) => sum + budget.allocated);
  double get totalSpent => budgets.fold(0.0, (sum, budget) => sum + budget.spent);
  double get remainingBudget => totalAllocated - totalSpent;

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

  void _addBudget() {
    if (categoryController.text.isNotEmpty && amountController.text.isNotEmpty) {
      final newBudget = Budget(
        id: DateTime.now().millisecondsSinceEpoch,
        category: categoryController.text,
        allocated: double.tryParse(amountController.text) ?? 0.0,
        spent: 0.0,
        period: newBudgetPeriod,
        color: _getRandomColor(),
        icon: _getCategoryIcon(categoryController.text),
      );

      setState(() {
        budgets.add(newBudget);
      });

      categoryController.clear();
      amountController.clear();
      newBudgetPeriod = 'monthly';
    }
  }

  void _deleteBudget(int id) {
    setState(() {
      budgets.removeWhere((budget) => budget.id == id);
    });
  }

  void _editBudget(Budget budget) {
    categoryController.text = budget.category;
    amountController.text = budget.allocated.toString();
    newBudgetPeriod = budget.period;

    showDialog(
      context: context,
      builder: (BuildContext context) => _buildAddEditBudgetDialog(isEdit: true, budgetId: budget.id),
    );
  }

  void _updateBudget(int budgetId) {
    if (categoryController.text.isNotEmpty && amountController.text.isNotEmpty) {
      setState(() {
        final index = budgets.indexWhere((budget) => budget.id == budgetId);
        if (index != -1) {
          budgets[index] = Budget(
            id: budgetId,
            category: categoryController.text,
            allocated: double.tryParse(amountController.text) ?? 0.0,
            spent: budgets[index].spent,
            period: newBudgetPeriod,
            color: budgets[index].color,
            icon: _getCategoryIcon(categoryController.text),
          );
        }
      });

      categoryController.clear();
      amountController.clear();
      newBudgetPeriod = 'monthly';
    }
  }

  Color _getRandomColor() {
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
    return colors[budgets.length % colors.length];
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
    if (categoryLower.contains('rent') || categoryLower.contains('home')) return '🏠';
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
    newBudgetPeriod = 'monthly';

    showDialog(
      context: context,
      builder: (BuildContext context) => _buildAddEditBudgetDialog(isEdit: false),
    );
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications feature coming soon!')),
              );
            },
            icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings feature coming soon!')),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 24),
            _buildPeriodSelector(),
            const SizedBox(height: 24),
            _buildAIRecommendations(),
            const SizedBox(height: 24),
            _buildBudgetCategories(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                title: 'Total Budget',
                amount: totalAllocated,
                icon: Icons.account_balance_wallet,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                title: 'Total Spent',
                amount: totalSpent,
                icon: Icons.trending_up,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildOverviewCard(
          title: remainingBudget >= 0 ? 'Remaining Budget' : 'Over Budget',
          amount: remainingBudget.abs(),
          icon: remainingBudget >= 0 ? Icons.savings : Icons.warning,
          color: remainingBudget >= 0 ? Colors.green : Colors.red,
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

  Widget _buildAIRecommendations() {
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
          ...aiRecommendations.map((rec) => _buildRecommendationCard(rec)).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(AIRecommendation recommendation) {
    Color iconColor;
    IconData iconData;

    switch (recommendation.type) {
      case 'warning':
        iconColor = Colors.orange;
        iconData = Icons.warning;
        break;
      case 'suggestion':
        iconColor = Colors.blue;
        iconData = Icons.lightbulb;
        break;
      default:
        iconColor = Colors.green;
        iconData = Icons.trending_up;
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
                recommendation.message,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${recommendation.action} feature coming soon!')),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                recommendation.action,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCategories() {
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
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No budgets created yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "Add Budget" to create your first budget',
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

  Widget _buildBudgetCard(Budget budget) {
    final progress = getProgressPercentage(budget.spent, budget.allocated);
    final status = getBudgetStatus(budget.spent, budget.allocated);
    final statusColor = getStatusColor(status);

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
                  color: budget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  budget.icon,
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
                    Text(
                      '${budget.period.toUpperCase()} BUDGET',
                      style: TextStyle(
                        color: Colors.grey.shade600,
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
                '${formatCurrency(budget.spent)} / ${formatCurrency(budget.allocated)}',
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
              'Over budget by ${formatCurrency(budget.spent - budget.allocated)}',
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

  void _showDeleteConfirmation(Budget budget) {
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
                _deleteBudget(budget.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${budget.category} budget deleted')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddEditBudgetDialog({required bool isEdit, int? budgetId}) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Budget' : 'Add New Budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g., Groceries, Utilities',
                    border: OutlineInputBorder(),
                  ),
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
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: newBudgetPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Period',
                    border: OutlineInputBorder(),
                  ),
                  items: ['weekly', 'monthly', 'quarterly'].map((period) {
                    return DropdownMenuItem(
                      value: period,
                      child: Text(period.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      newBudgetPeriod = value ?? 'monthly';
                    });
                  },
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
                newBudgetPeriod = 'monthly';
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (isEdit && budgetId != null) {
                  _updateBudget(budgetId);
                } else {
                  _addBudget();
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Budget updated successfully!' : 'Budget added successfully!'),
                  ),
                );
              },
              child: Text(isEdit ? 'Update' : 'Add Budget'),
            ),
          ],
        );
      },
    );
  }
}

// Data Models
class Budget {
  final int id;
  final String category;
  final double allocated;
  final double spent;
  final String period;
  final Color color;
  final String icon;

  Budget({
    required this.id,
    required this.category,
    required this.allocated,
    required this.spent,
    required this.period,
    required this.color,
    required this.icon,
  });
}

class AIRecommendation {
  final String type;
  final String message;
  final String action;

  AIRecommendation({
    required this.type,
    required this.message,
    required this.action,
  });
}

enum BudgetStatus { good, warning, exceeded }