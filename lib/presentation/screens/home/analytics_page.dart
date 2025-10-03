import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/database_helper.dart';
import '../../../models/transaction_model.dart';

class AnalyticsPage extends StatefulWidget {
  final int userId;

  const AnalyticsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';

  // Database instance
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Data holders
  Map<String, double> _expenseData = {};
  List<TransactionModel> _transactions = [];
  Map<String, double> _balanceSummary = {};
  bool _isLoading = true;

  // Filter variables
  String _searchQuery = '';
  String _filterType = 'All'; // All, Income, Expense
  String _filterCategory = 'All';
  DateTimeRange? _filterDateRange;
  List<TransactionModel> _filteredTransactions = [];

  // Period options
  final List<String> _periods = ['This Week', 'This Month', 'This Quarter', 'This Year'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load data from database
  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final dateRange = _getDateRangeForPeriod(_selectedPeriod);

      // Load all required data
      final futures = await Future.wait([
        _dbHelper.getExpensesByCategory(
          widget.userId,
          startDate: dateRange['startDate'],
          endDate: dateRange['endDate'],
        ),
        _dbHelper.getTransactionsByUser(
          widget.userId,
          limit: 50,
          startDate: dateRange['startDate'],
          endDate: dateRange['endDate'],
        ),
        _dbHelper.getBalanceSummary(widget.userId),
      ]);

      setState(() {
        _expenseData = futures[0] as Map<String, double>;
        _transactions = futures[1] as List<TransactionModel>;
        _balanceSummary = futures[2] as Map<String, double>;
        _filteredTransactions = _transactions;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      print('Error loading analytics data: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load analytics data');
    }
  }

  // Get date range based on selected period
  Map<String, DateTime?> _getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = now;

    switch (period) {
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'This Quarter':
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        startDate = DateTime(now.year, quarterStartMonth, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
    }

    return {'startDate': startDate, 'endDate': endDate};
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFE74C3C),
        ),
      );
    }
  }

  // Apply filters to transactions
  void _applyFilters() {
    setState(() {
      _filteredTransactions = _transactions.where((transaction) {
        // Search filter
        bool matchesSearch = _searchQuery.isEmpty ||
            transaction.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            transaction.category.toLowerCase().contains(_searchQuery.toLowerCase());

        // Type filter
        bool matchesType = _filterType == 'All' ||
            (_filterType == 'Income' && transaction.type == 'income') ||
            (_filterType == 'Expense' && transaction.type == 'expense');

        // Category filter
        bool matchesCategory = _filterCategory == 'All' ||
            transaction.category == _filterCategory;

        // Date range filter
        bool matchesDateRange = _filterDateRange == null ||
            (transaction.date.isAfter(_filterDateRange!.start.subtract(const Duration(days: 1))) &&
                transaction.date.isBefore(_filterDateRange!.end.add(const Duration(days: 1))));

        return matchesSearch && matchesType && matchesCategory && matchesDateRange;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)))
          : Column(
        children: [
          _buildPeriodSelector(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTransactionsTab(),
                _buildTrendsTab(),
                _buildInsightsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Analytics & Transactions',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF2C3E50)),
          onPressed: _loadAnalyticsData,
        ),
        IconButton(
          icon: const Icon(Icons.download, color: Color(0xFF2C3E50)),
          onPressed: _exportData,
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2E8B57)),
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          items: _periods.map((String period) {
            return DropdownMenuItem<String>(
              value: period,
              child: Text(period),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedPeriod = newValue;
              });
              _loadAnalyticsData(); // Reload data for new period
            }
          },
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF2E8B57),
        unselectedLabelColor: const Color(0xFF7F8C8D),
        indicatorColor: const Color(0xFF2E8B57),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Transactions'),
          Tab(text: 'Trends'),
          Tab(text: 'Insights'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFinancialSummary(),
          const SizedBox(height: 20),
          _buildExpensePieChart(),
          const SizedBox(height: 20),
          _buildCategoryBreakdown(),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final income = _balanceSummary['income'] ?? 0.0;
    final expense = _balanceSummary['expense'] ?? 0.0;
    final balance = _balanceSummary['balance'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E8B57), Color(0xFF4CAF80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E8B57).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total Income', '₹${income.toStringAsFixed(0)}', Icons.trending_up, const Color(0xFF27AE60)),
              _buildSummaryItem('Total Expense', '₹${expense.toStringAsFixed(0)}', Icons.trending_down, const Color(0xFFE74C3C)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const Text(
                      'Net Balance',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${balance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String amount, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        _buildTransactionFilters(),
        _buildFilterChips(),
        Expanded(
          child: _buildTransactionsList(),
        ),
      ],
    );
  }

  Widget _buildTransactionFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Color(0xFF7F8C8D)),
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _applyFilters();
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B57),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.white),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    List<Widget> chips = [];

    if (_filterType != 'All') {
      chips.add(_buildFilterChip(_filterType, () {
        setState(() {
          _filterType = 'All';
        });
        _applyFilters();
      }));
    }

    if (_filterCategory != 'All') {
      chips.add(_buildFilterChip(_filterCategory, () {
        setState(() {
          _filterCategory = 'All';
        });
        _applyFilters();
      }));
    }

    if (_filterDateRange != null) {
      chips.add(_buildFilterChip(
        '${_formatDate(_filterDateRange!.start)} - ${_formatDate(_filterDateRange!.end)}',
            () {
          setState(() {
            _filterDateRange = null;
          });
          _applyFilters();
        },
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'Active Filters: ',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: chips,
            ),
          ),
          if (chips.isNotEmpty)
            TextButton(
              onPressed: _clearAllFilters,
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: Color(0xFFE74C3C),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: const Color(0xFF2E8B57).withOpacity(0.1),
      deleteIconColor: const Color(0xFF2E8B57),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _filterType = 'All';
      _filterCategory = 'All';
      _filterDateRange = null;
      _searchQuery = '';
    });
    _applyFilters();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Filter Transactions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Filter
                const Text('Transaction Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _filterType,
                  items: ['All', 'Income', 'Expense'].map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setStateDialog(() {
                      _filterType = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Category Filter
                const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _filterCategory,
                  items: _getUniqueCategories().map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setStateDialog(() {
                      _filterCategory = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Date Range Filter
                const Text('Date Range:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _filterDateRange,
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        _filterDateRange = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _filterDateRange == null
                          ? 'Select Date Range'
                          : '${_formatDate(_filterDateRange!.start)} - ${_formatDate(_filterDateRange!.end)}',
                      style: TextStyle(
                        color: _filterDateRange == null ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {});
                  _applyFilters();
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<String> _getUniqueCategories() {
    Set<String> categories = {'All'};
    for (var transaction in _transactions) {
      categories.add(transaction.category);
    }
    return categories.toList();
  }

  Widget _buildTransactionsList() {
    if (_filteredTransactions.isEmpty) {
      return Container(
        color: const Color(0xFFF8F9FA),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Color(0xFF7F8C8D)),
              SizedBox(height: 16),
              Text(
                'No transactions found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7F8C8D),
                ),
              ),
              Text(
                'Try adjusting your filters or add transactions',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF8F9FA),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          return _buildTransactionItem(_filteredTransactions[index]);
        },
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    bool isIncome = transaction.type == 'income';
    Color amountColor = isIncome ? const Color(0xFF27AE60) : const Color(0xFFE74C3C);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome ? Icons.add : Icons.remove,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                Text(
                  _formatDate(transaction.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : ''}₹${transaction.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF7F8C8D)),
                onSelected: (String value) async {
                  switch (value) {
                    case 'edit':
                      await _showEditTransactionDialog(transaction);
                      break;
                    case 'delete':
                      await _showDeleteConfirmation(transaction);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: Color(0xFF3498DB)),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Color(0xFFE74C3C)),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Edit Transaction Dialog (similar to home screen form)
  Future<void> _showEditTransactionDialog(TransactionModel transaction) async {
    final TextEditingController titleController = TextEditingController(text: transaction.title);
    final TextEditingController amountController = TextEditingController(text: transaction.amount.toString());
    String selectedCategory = transaction.category;
    DateTime selectedDate = transaction.date;
    bool isIncome = transaction.type == 'income';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Edit ${isIncome ? 'Income' : 'Expense'}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Field
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2E8B57)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount Field
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2E8B57)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF2E8B57)),
                      ),
                    ),
                    items: (isIncome
                        ? ['Salary', 'Freelance', 'Business', 'Investment', 'Rental', 'Others']
                        : ['Food & Dining', 'Transportation', 'Shopping', 'Entertainment', 'Bills & Utilities', 'Healthcare', 'Education', 'Travel', 'Groceries', 'Others']
                    ).map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setStateDialog(() {
                        selectedCategory = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date: ${_formatDate(selectedDate)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today, color: Color(0xFF2E8B57)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                    await _updateTransaction(
                      transaction.id!,
                      titleController.text,
                      double.parse(amountController.text),
                      selectedCategory,
                      selectedDate,
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B57),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Delete Confirmation Dialog
  Future<void> _showDeleteConfirmation(TransactionModel transaction) async {
    bool isIncome = transaction.type == 'income';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: const Color(0xFFE74C3C),
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Delete Transaction'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this transaction?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isIncome ? const Color(0xFF27AE60).withOpacity(0.1) : const Color(0xFFE74C3C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          isIncome ? Icons.add : Icons.remove,
                          color: isIncome ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transaction.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Amount: ₹${transaction.amount.toStringAsFixed(0)}'),
                  Text('Category: ${transaction.category}'),
                  Text('Date: ${_formatDate(transaction.date)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Color(0xFFE74C3C),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTransaction(transaction.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensePieChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2E8B57).withOpacity(0.1),
                  const Color(0xFF3498DB).withOpacity(0.1),
                ],
              ),
            ),
            child: _expenseData.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline, size: 60, color: Color(0xFF7F8C8D)),
                  SizedBox(height: 10),
                  Text(
                    'No expense data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  Text(
                    'Add some expenses to see the chart',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            )
                : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart, size: 60, color: Color(0xFF2E8B57)),
                  SizedBox(height: 10),
                  Text(
                    'Interactive Pie Chart',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E8B57),
                    ),
                  ),
                  Text(
                    '(Chart library integration needed)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_expenseData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.category, size: 48, color: Color(0xFF7F8C8D)),
            SizedBox(height: 16),
            Text(
              'No expense categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7F8C8D),
              ),
            ),
            Text(
              'Add expenses to see category breakdown',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
      );
    }

    final totalExpenses = _expenseData.values.fold(0.0, (sum, value) => sum + value);
    final sortedEntries = _expenseData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
                'Category Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text(
                  'View All',
                  style: TextStyle(color: Color(0xFF2E8B57)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...sortedEntries.take(5).map((entry) => _buildCategoryItem(
            entry.key,
            entry.value,
            totalExpenses,
            _getCategoryIcon(entry.key),
            _getCategoryColor(entry.key),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, double total, IconData icon, Color color) {
    double percentage = total > 0 ? (amount / total) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: percentage / 100,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7F8C8D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMonthlyTrendChart(),
          const SizedBox(height: 20),
          _buildComparisonCards(),
          const SizedBox(height: 20),
          _buildSpendingPattern(),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Spending Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF27AE60).withOpacity(0.1),
                  const Color(0xFFE74C3C).withOpacity(0.1),
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 60, color: Color(0xFF27AE60)),
                  SizedBox(height: 10),
                  Text(
                    'Trends Chart Coming Soon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                  Text(
                    '(Chart library integration needed)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCards() {
    return Row(
      children: [
        Expanded(
          child: _buildComparisonCard(
            'vs Last Month',
            '+12.5%',
            'Higher expenses',
            const Color(0xFFE74C3C),
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildComparisonCard(
            'vs Last Year',
            '-8.2%',
            'Better control',
            const Color(0xFF27AE60),
            Icons.trending_down,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCard(String title, String percentage, String description, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7F8C8D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingPattern() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Pattern',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          _buildPatternItem('Total Transactions', _filteredTransactions.length.toString(), 'transactions', Icons.receipt_long),
          _buildPatternItem('Average per Transaction', _getAverageTransactionAmount(), 'per transaction', Icons.calculate),
          _buildPatternItem('Most Used Category', _getMostUsedCategory(), 'category', Icons.category),
          _buildPatternItem('Recent Activity', _getRecentActivityStatus(), 'status', Icons.timeline),
        ],
      ),
    );
  }

  String _getAverageTransactionAmount() {
    if (_filteredTransactions.isEmpty) return '₹0';
    final total = _filteredTransactions.fold(0.0, (sum, t) => sum + t.amount.abs());
    return '₹${(total / _filteredTransactions.length).toStringAsFixed(0)}';
  }

  String _getMostUsedCategory() {
    if (_filteredTransactions.isEmpty) return 'None';

    final categoryCount = <String, int>{};
    for (final transaction in _filteredTransactions) {
      categoryCount[transaction.category] = (categoryCount[transaction.category] ?? 0) + 1;
    }

    String mostUsed = categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return mostUsed;
  }

  String _getRecentActivityStatus() {
    if (_filteredTransactions.isEmpty) return 'No activity';

    final now = DateTime.now();
    final recentTransactions = _filteredTransactions.where((t) {
      final daysDifference = now.difference(t.date).inDays;
      return daysDifference <= 7;
    }).length;

    if (recentTransactions == 0) return 'Low activity';
    if (recentTransactions <= 3) return 'Moderate activity';
    return 'High activity';
  }

  Widget _buildPatternItem(String title, String value, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3498DB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF3498DB), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFinancialHealth(),
          const SizedBox(height: 20),
          _buildSmartRecommendations(),
        ],
      ),
    );
  }

  Widget _buildFinancialHealth() {
    final balance = _balanceSummary['balance'] ?? 0.0;
    final income = _balanceSummary['income'] ?? 0.0;
    final expense = _balanceSummary['expense'] ?? 0.0;

    // Calculate health score (0-100)
    int healthScore = _calculateFinancialHealthScore(income, expense, balance);
    String healthStatus = _getHealthStatus(healthScore);
    String healthMessage = _getHealthMessage(healthScore, income, expense);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            healthScore >= 70 ? const Color(0xFF27AE60) :
            healthScore >= 40 ? const Color(0xFFF39C12) : const Color(0xFFE74C3C),
            healthScore >= 70 ? const Color(0xFF2ECC71) :
            healthScore >= 40 ? const Color(0xFFE67E22) : const Color(0xFFC0392B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (healthScore >= 70 ? const Color(0xFF27AE60) :
            healthScore >= 40 ? const Color(0xFFF39C12) : const Color(0xFFE74C3C))
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                    healthScore >= 70 ? Icons.favorite :
                    healthScore >= 40 ? Icons.warning : Icons.error,
                    color: Colors.white,
                    size: 24
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
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$healthScore/100',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  healthStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  healthMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateFinancialHealthScore(double income, double expense, double balance) {
    if (income == 0) return 0;

    // Factors: savings rate (40%), expense ratio (30%), transaction count (20%), balance trend (10%)
    double savingsRate = income > 0 ? ((income - expense) / income) * 100 : 0;
    double expenseRatio = income > 0 ? (expense / income) * 100 : 100;

    // Scoring
    int savingsScore = (savingsRate * 0.4).round().clamp(0, 40);
    int expenseScore = (100 - expenseRatio).clamp(0, 100) * 0.3 ~/ 1;
    int activityScore = (_transactions.length * 2).clamp(0, 20);
    int balanceScore = balance > 0 ? 10 : 0;

    return (savingsScore + expenseScore + activityScore + balanceScore).clamp(0, 100);
  }

  String _getHealthStatus(int score) {
    if (score >= 80) return 'Excellent Financial Health';
    if (score >= 60) return 'Good Financial Control';
    if (score >= 40) return 'Fair Financial Status';
    return 'Needs Financial Attention';
  }

  String _getHealthMessage(int score, double income, double expense) {
    if (income == 0) return 'Add income transactions to get financial insights.';

    double savingsRate = ((income - expense) / income) * 100;

    if (score >= 80) {
      return 'You are maintaining excellent financial habits with ${savingsRate.toStringAsFixed(1)}% savings rate.';
    } else if (score >= 60) {
      return 'You have good financial control with ${savingsRate.toStringAsFixed(1)}% savings rate.';
    } else if (score >= 40) {
      return 'Your finances are fair but could be improved. Consider reducing expenses.';
    } else {
      return 'Your expenses are high. Focus on budgeting and expense tracking.';
    }
  }

  Widget _buildSmartRecommendations() {
    List<Map<String, dynamic>> recommendations = _generateSmartRecommendations();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFFF39C12), size: 24),
              SizedBox(width: 12),
              Text(
                'Smart Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recommendations.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: Color(0xFF27AE60)),
                  SizedBox(height: 16),
                  Text(
                    'Great job!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                  Text(
                    'Add more transactions to get personalized recommendations',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...recommendations.map((rec) => _buildRecommendationItem(
              rec['title'],
              rec['description'],
              rec['icon'],
              rec['color'],
            )).toList(),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateSmartRecommendations() {
    List<Map<String, dynamic>> recommendations = [];

    final income = _balanceSummary['income'] ?? 0.0;
    final expense = _balanceSummary['expense'] ?? 0.0;

    // High expense ratio recommendation
    if (income > 0 && (expense / income) > 0.8) {
      recommendations.add({
        'title': 'Reduce Monthly Expenses',
        'description': 'Your expenses are ${((expense/income)*100).toStringAsFixed(0)}% of income. Try to keep it below 80%.',
        'icon': Icons.trending_down,
        'color': const Color(0xFFE74C3C),
      });
    }

    // Low savings recommendation
    if (income > 0 && ((income - expense) / income) < 0.2) {
      recommendations.add({
        'title': 'Increase Savings Rate',
        'description': 'Aim to save at least 20% of your income for long-term financial security.',
        'icon': Icons.savings,
        'color': const Color(0xFF27AE60),
      });
    }

    // Category-specific recommendations
    if (_expenseData.isNotEmpty) {
      final topCategory = _expenseData.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (topCategory.value > expense * 0.4) {
        recommendations.add({
          'title': 'Monitor ${topCategory.key} Expenses',
          'description': '${topCategory.key} represents ${((topCategory.value/expense)*100).toStringAsFixed(0)}% of your expenses. Consider optimization.',
          'icon': _getCategoryIcon(topCategory.key),
          'color': const Color(0xFFF39C12),
        });
      }
    }

    // Low transaction activity
    if (_transactions.length < 5) {
      recommendations.add({
        'title': 'Track More Transactions',
        'description': 'Add more transactions to get better financial insights and recommendations.',
        'icon': Icons.add_circle,
        'color': const Color(0xFF3498DB),
      });
    }

    return recommendations;
  }

  Widget _buildRecommendationItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Database Operations
  Future<void> _updateTransaction(int transactionId, String title, double amount, String category, DateTime date) async {
    try {
      final transaction = TransactionModel(
        id: transactionId,
        userId: widget.userId,
        title: title,
        amount: amount,
        type: amount >= 0 ? 'income' : 'expense', // Maintain original type logic or adjust as needed
        category: category,
        date: date,
        createdAt: DateTime.now(),
      );

      await _dbHelper.updateTransaction(transaction);
      await _loadAnalyticsData(); // Reload data

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction updated successfully!'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      print('Error updating transaction: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to update transaction');
      }
    }
  }

  Future<void> _deleteTransaction(int transactionId) async {
    try {
      await _dbHelper.deleteTransaction(transactionId);
      await _loadAnalyticsData(); // Reload data

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully!'),
            backgroundColor: Color(0xFFE74C3C),
          ),
        );
      }
    } catch (e) {
      print('Error deleting transaction: $e');
      _showErrorSnackBar('Failed to delete transaction');
    }
  }

  // Helper Methods
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Dining':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Entertainment':
        return Icons.movie;
      case 'Bills & Utilities':
        return Icons.receipt;
      case 'Healthcare':
        return Icons.local_hospital;
      case 'Education':
        return Icons.school;
      case 'Travel':
        return Icons.flight;
      case 'Groceries':
        return Icons.local_grocery_store;
      case 'Salary':
        return Icons.work;
      case 'Freelance':
        return Icons.laptop;
      case 'Business':
        return Icons.business;
      case 'Investment':
        return Icons.trending_up;
      case 'Rental':
        return Icons.home;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    const List<Color> categoryColors = [
      Color(0xFFE74C3C), // Red
      Color(0xFF3498DB), // Blue
      Color(0xFF2ECC71), // Green
      Color(0xFFF39C12), // Orange
      Color(0xFF9B59B6), // Purple
      Color(0xFF1ABC9C), // Turquoise
      Color(0xFFF1C40F), // Yellow
      Color(0xFFE67E22), // Dark Orange
      Color(0xFF34495E), // Dark Blue
      Color(0xFF95A5A6), // Gray
    ];

    switch (category) {
      case 'Food & Dining':
        return categoryColors[3]; // Orange
      case 'Transportation':
        return categoryColors[1]; // Blue
      case 'Shopping':
        return categoryColors[4]; // Purple
      case 'Entertainment':
        return categoryColors[6]; // Yellow
      case 'Bills & Utilities':
        return categoryColors[2]; // Green
      case 'Healthcare':
        return categoryColors[0]; // Red
      case 'Education':
        return categoryColors[8]; // Dark Blue
      case 'Travel':
        return categoryColors[5]; // Turquoise
      case 'Groceries':
        return categoryColors[2]; // Green
      case 'Salary':
        return categoryColors[2]; // Green
      case 'Freelance':
        return categoryColors[4]; // Purple
      case 'Business':
        return categoryColors[1]; // Blue
      case 'Investment':
        return categoryColors[5]; // Turquoise
      case 'Rental':
        return categoryColors[7]; // Dark Orange
      default:
        return categoryColors[9]; // Gray
    }
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics report exported! (Feature coming soon)'),
        backgroundColor: Color(0xFF27AE60),
      ),
    );
  }
}