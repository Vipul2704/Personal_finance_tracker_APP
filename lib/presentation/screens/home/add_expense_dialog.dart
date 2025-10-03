// lib/presentation/screens/dashboard/add_expense_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/image_helper.dart';
import '../../../models/transaction_model.dart';
import '../../../models/category_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

class AddExpenseDialog extends StatefulWidget {
  final String transactionType; // 'income' or 'expense'
  final TransactionModel? editTransaction; // For editing existing transactions

  const AddExpenseDialog({
    Key? key,
    required this.transactionType,
    this.editTransaction,
  }) : super(key: key);

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<CategoryModel> _categories = [];

  // Image handling variables
  String? _selectedImagePath;
  bool _isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initializeForEdit();
  }

  void _initializeForEdit() {
    if (widget.editTransaction != null) {
      final transaction = widget.editTransaction!;
      _titleController.text = transaction.title;
      _amountController.text = transaction.amount.toString();
      _descriptionController.text = transaction.description ?? '';
      _selectedCategory = transaction.category;
      _selectedDate = transaction.date;
      _selectedImagePath = transaction.imagePath; // Load existing image path
    }
  }

  Future<void> _loadCategories() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.id != null) {
        final dbHelper = DatabaseHelper();
        final categories = await dbHelper.getCategoriesByUser(
          authProvider.user!.id!,
          type: widget.transactionType,
        );
        if (mounted) {
          setState(() {
            _categories = categories;
            // Set default category if not editing and categories exist
            if (widget.editTransaction == null && categories.isNotEmpty) {
              _selectedCategory = categories.first.name;
            }
          });
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load categories');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transactionType == 'income';
    final isEdit = widget.editTransaction != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(isIncome, isEdit),
                const SizedBox(height: 24),

                // Title Field
                _buildTitleField(),
                const SizedBox(height: 16),

                // Amount Field
                _buildAmountField(isIncome),
                const SizedBox(height: 16),

                // Category Field
                _buildCategoryField(),
                const SizedBox(height: 16),

                // Date Field
                _buildDateField(),
                const SizedBox(height: 16),

                // Image Section
                _buildImageSection(),
                const SizedBox(height: 16),

                // Description Field (Optional)
                _buildDescriptionField(),
                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(isIncome, isEdit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isIncome, bool isEdit) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isIncome ? AppColors.income : AppColors.expense).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isIncome ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: isIncome ? AppColors.income : AppColors.expense,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit
                    ? (isIncome ? 'Edit Income' : 'Edit Expense')
                    : (isIncome ? 'Add Income' : 'Add Expense'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                isEdit
                    ? 'Update your transaction details'
                    : 'Enter your ${isIncome ? 'income' : 'expense'} details',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.close),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Title *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Enter transaction title',
            prefixIcon: const Icon(Icons.edit_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Title is required';
            }
            if (value.trim().length < 2) {
              return 'Title must be at least 2 characters';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
          maxLength: 100,
        ),
      ],
    );
  }

  Widget _buildAmountField(bool isIncome) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Text(
                '₹',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? AppColors.income : AppColors.expense,
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isIncome ? AppColors.income : AppColors.expense,
                  width: 2
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Amount is required';
            }
            final amount = double.tryParse(value.trim());
            if (amount == null) {
              return 'Enter a valid amount';
            }
            if (amount <= 0) {
              return 'Amount must be greater than 0';
            }
            if (amount > 10000000) {
              return 'Amount is too large';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.category_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          hint: const Text('Select a category'),
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.name,
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category.colorCode),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(category.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Receipt/Bill (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (_selectedImagePath != null)
              TextButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Remove', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedImagePath != null)
          _buildImagePreview()
        else
          _buildImagePickerButtons(),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.file(
              File(_selectedImagePath!),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey.shade100,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Image not found', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _showImagePickerDialog,
                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildImagePickerButton(
            'Camera',
            Icons.camera_alt_outlined,
            AppColors.secondary,
                () => _pickImage(ImageSource.camera),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildImagePickerButton(
            'Gallery',
            Icons.photo_library_outlined,
            AppColors.primary,
                () => _pickImage(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isImageLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: _isImageLoading
            ? const Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 8),
            Text('Loading...', style: TextStyle(fontSize: 12)),
          ],
        )
            : Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Add a note about this transaction...',
            prefixIcon: const Icon(Icons.notes_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          maxLines: 3,
          maxLength: 255,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isIncome, bool isEdit) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncome ? AppColors.income : AppColors.expense,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              isEdit ? 'Update' : 'Save',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Image handling methods
  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isImageLoading = true;
    });

    try {
      String? imagePath;
      if (source == ImageSource.camera) {
        imagePath = await ImageHelper.pickImageFromCamera();
      } else {
        imagePath = await ImageHelper.pickImageFromGallery();
      }

      if (imagePath != null) {
        setState(() {
          _selectedImagePath = imagePath;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  void _showImagePickerDialog() {
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
              'Select Image Source',
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
                    'Camera',
                    Icons.camera_alt_outlined,
                    AppColors.secondary,
                        () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBottomSheetOption(
                    'Gallery',
                    Icons.photo_library_outlined,
                    AppColors.primary,
                        () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
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

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getCategoryColor(String colorCode) {
    try {
      return Color(int.parse(colorCode.replaceAll('#', '0xff')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      _showErrorSnackBar('Please select a category');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('User not found');
      }

      // Clean and prepare the description with better null handling
      final descriptionText = _descriptionController.text.trim();
      final cleanDescription = descriptionText.isEmpty ? null : descriptionText;
      final iconValue = widget.editTransaction?.icon?.isEmpty == true ? null : widget.editTransaction?.icon;

      final transaction = TransactionModel(
        id: widget.editTransaction?.id,
        userId: userId,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        type: widget.transactionType,
        category: _selectedCategory!,
        date: _selectedDate,
        description: cleanDescription ?? '', // Use empty string if null
        icon: iconValue ?? '', // Use empty string if null
        imagePath: _selectedImagePath, // Include image path
        createdAt: widget.editTransaction?.createdAt ?? DateTime.now(),
      );

      final dbHelper = DatabaseHelper();

      if (widget.editTransaction != null) {
        // Update existing transaction
        // Handle image cleanup if image was changed
        final oldImagePath = widget.editTransaction!.imagePath;
        if (oldImagePath != null && oldImagePath != _selectedImagePath) {
          await ImageHelper.deleteImage(oldImagePath);
        }

        await dbHelper.updateTransaction(transaction);
        _showSuccessSnackBar('Transaction updated successfully');
      } else {
        // Create new transaction
        final transactionId = await dbHelper.createTransaction(transaction);
        if (transactionId != null && transactionId > 0) {
          _showSuccessSnackBar('${widget.transactionType == 'income' ? 'Income' : 'Expense'} added successfully');
        } else {
          throw Exception('Failed to create transaction');
        }
      }

      // Refresh dashboard data
      await dashboardProvider.refreshDashboard(userId);

      // Close dialog with success result
      if (mounted) {
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      print('Error saving transaction: $e');
      _showErrorSnackBar('Failed to save transaction. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}