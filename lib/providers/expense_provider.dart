import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../services/database_service.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';
  String _sortMode = 'newest';
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  List<Expense> get expenses => _expenses;
  String get selectedCategory => _selectedCategory;
  String get sortMode => _sortMode;
  String get searchQuery => _searchQuery;

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    _expenses = await DatabaseService.getExpenses();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await DatabaseService.insertExpense(expense);
    await loadExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await DatabaseService.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await DatabaseService.deleteExpense(id);
    await loadExpenses();
  }

  void setCategoryFilter(String value) {
    _selectedCategory = value;
    notifyListeners();
  }

  void setSortMode(String value) {
    _sortMode = value;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim();
    notifyListeners();
  }

  List<Expense> get filteredExpenses {
    var items = List<Expense>.from(_expenses);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((expense) {
        return expense.title.toLowerCase().contains(query) ||
            expense.category.toLowerCase().contains(query) ||
            expense.paymentMethod.toLowerCase().contains(query) ||
            (expense.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_selectedCategory != 'All') {
      items = items.where((expense) => expense.category == _selectedCategory).toList();
    }

    switch (_sortMode) {
      case 'oldest':
        items.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'amount_high':
        items.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_low':
        items.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'newest':
      default:
        items.sort((a, b) => b.date.compareTo(a.date));
        break;
    }

    return items;
  }

  double get totalMonthlySpend {
    final month = DateTime.now();
    return _expenses.where((expense) {
      final sameMonth = expense.date.year == month.year && expense.date.month == month.month;
      return sameMonth;
    }).fold(0.0, (sum, expense) => sum + expense.amount);
  }
}
