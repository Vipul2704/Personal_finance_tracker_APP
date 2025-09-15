// lib/presentation/providers/category_provider.dart
import 'package:flutter/foundation.dart';
import '../../core/database/database_helper.dart';
import '../../models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.isIncomeCategory).toList();
  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => c.isExpenseCategory).toList();
  List<CategoryModel> get defaultCategories =>
      _categories.where((c) => c.isDefault).toList();
  List<CategoryModel> get customCategories =>
      _categories.where((c) => !c.isDefault).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize categories for user
  Future<void> initializeForUser(int userId) async {
    await loadCategories(userId);
  }

  // Load all categories for user
  Future<void> loadCategories(int userId, {String? type}) async {
    _setLoading(true);
    try {
      _categories = await _databaseHelper.getCategoriesByUser(userId, type: type);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add new category
  Future<bool> addCategory(CategoryModel category) async {
    _setLoading(true);
    try {
      final id = await _databaseHelper.createCategory(category);

      if (id > 0) {
        final newCategory = category.copyWith(id: id);
        _categories.add(newCategory);
        _error = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding category: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get category by name
  CategoryModel? getCategoryByName(String name) {
    try {
      return _categories.firstWhere((c) => c.name == name);
    } catch (e) {
      return null;
    }
  }

  // Get category by id
  CategoryModel? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get category color
  String getCategoryColor(String categoryName) {
    final category = getCategoryByName(categoryName);
    return category?.colorCode ?? '#757575';
  }

  // Get category icon
  String getCategoryIcon(String categoryName) {
    final category = getCategoryByName(categoryName);
    return category?.iconName ?? 'category';
  }

  // Check if category exists
  bool categoryExists(String name, int userId) {
    return _categories.any((c) => c.name.toLowerCase() == name.toLowerCase() && c.userId == userId);
  }

  // Get categories by type with search
  List<CategoryModel> searchCategories(String query, {String? type}) {
    var filteredCategories = _categories;

    if (type != null) {
      filteredCategories = filteredCategories.where((c) => c.type == type).toList();
    }

    if (query.isEmpty) return filteredCategories;

    return filteredCategories
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Refresh categories
  Future<void> refreshCategories(int userId) async {
    await loadCategories(userId);
  }

  // Clear all data (for logout)
  void clearData() {
    _categories.clear();
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get most used categories (could be enhanced with usage tracking)
  List<CategoryModel> getMostUsedCategories({String? type, int limit = 5}) {
    var filteredCategories = _categories;

    if (type != null) {
      filteredCategories = filteredCategories.where((c) => c.type == type).toList();
    }

    // For now, prioritize default categories and return limited results
    // In future, you could track usage and sort by usage frequency
    final defaultCats = filteredCategories.where((c) => c.isDefault).toList();
    final customCats = filteredCategories.where((c) => !c.isDefault).toList();

    final result = [...defaultCats, ...customCats];
    return result.take(limit).toList();
  }
}