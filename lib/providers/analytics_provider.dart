import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../services/database_service.dart';

class AnalyticsProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<Expense> get expenses => _expenses;

  Future<void> loadAnalytics({DateTime? month}) async {
    _isLoading = true;
    notifyListeners();

    final targetMonth = month ?? DateTime.now();
    _expenses = await DatabaseService.getExpensesForMonth(targetMonth);

    _isLoading = false;
    notifyListeners();
  }

  Map<String, double> categoryTotals(DateTime month) {
    final totals = <String, double>{};
    for (final expense in _expenses) {
      if (expense.date.year == month.year && expense.date.month == month.month) {
        totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
      }
    }
    return totals;
  }

  double getTotalSpending() => _expenses.fold(0.0, (sum, expense) => sum + expense.amount);

  double getAverageDailySpending() {
    if (_expenses.isEmpty) return 0;
    final distinctDays = <DateTime>{};
    for (final expense in _expenses) {
      distinctDays.add(DateTime(expense.date.year, expense.date.month, expense.date.day));
    }
    final days = distinctDays.isEmpty ? 1 : distinctDays.length;
    return getTotalSpending() / days;
  }

  String getHighestSpendingCategory({DateTime? month}) {
    if (_expenses.isEmpty) return 'N/A';
    final totals = categoryTotals(month ?? DateTime.now());
    if (totals.isEmpty) return 'N/A';
    final entry = totals.entries.reduce((a, b) => a.value > b.value ? a : b);
    return entry.key;
  }
}
