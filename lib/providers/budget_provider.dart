import 'package:flutter/foundation.dart';

import '../models/budget.dart';
import '../services/database_service.dart';

class BudgetProvider with ChangeNotifier {
  MonthlyBudget? _monthlyBudget;
  List<CategoryBudget> _categoryBudgets = [];
  bool _isLoading = false;

  MonthlyBudget? get monthlyBudget => _monthlyBudget;
  List<CategoryBudget> get categoryBudgets => _categoryBudgets;
  bool get isLoading => _isLoading;

  Future<void> loadBudgets({DateTime? month}) async {
    _isLoading = true;
    notifyListeners();

    final currentMonth = month ?? DateTime.now();
    _monthlyBudget = await DatabaseService.getMonthlyBudget(currentMonth);
    _categoryBudgets = await DatabaseService.getCategoryBudgetsForMonth(currentMonth);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setMonthlyBudget(MonthlyBudget budget) async {
    await DatabaseService.upsertMonthlyBudget(budget);
    _monthlyBudget = budget;
    notifyListeners();
  }

  Future<void> setCategoryBudget(CategoryBudget budget) async {
    await DatabaseService.upsertCategoryBudget(budget);
    final exists = _categoryBudgets.indexWhere((item) => item.category == budget.category);
    if (exists >= 0) {
      _categoryBudgets[exists] = budget;
    } else {
      _categoryBudgets.add(budget);
    }
    notifyListeners();
  }

  double getUtilization(double spent, double totalBudget) {
    if (totalBudget <= 0) return 0;
    return spent / totalBudget;
  }

  double getRemainingBudget(double spent) {
    final total = _monthlyBudget?.totalBudget ?? 0;
    return total - spent;
  }
}
