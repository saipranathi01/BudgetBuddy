import 'package:flutter/foundation.dart';

import '../models/savings_goal.dart';
import '../services/database_service.dart';

class SavingsProvider with ChangeNotifier {
  List<SavingsGoal> _goals = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<SavingsGoal> get goals => _goals;

  Future<void> loadGoals() async {
    _isLoading = true;
    notifyListeners();

    _goals = await DatabaseService.getSavingsGoals();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGoal(SavingsGoal goal) async {
    await DatabaseService.insertGoal(goal);
    await loadGoals();
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    await DatabaseService.updateGoal(goal);
    await loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    await DatabaseService.deleteGoal(id);
    await loadGoals();
  }

  Future<void> addContribution(String goalId, double amount, {String description = 'Contribution'}) async {
    if (amount <= 0) throw Exception('Contribution amount must be positive.');
    final goal = _goals.firstWhere((item) => item.id == goalId, orElse: () => throw Exception('Goal not found.'));
    final newSaved = goal.currentSaved + amount;
    final updatedGoal = SavingsGoal(
      id: goal.id,
      title: goal.title,
      targetAmount: goal.targetAmount,
      currentSaved: newSaved,
      targetDate: goal.targetDate,
      description: goal.description,
      createdAt: goal.createdAt,
      status: newSaved >= goal.targetAmount ? 'completed' : 'active',
    );

    await DatabaseService.updateGoal(updatedGoal);
    await DatabaseService.insertSavingsTransaction(
      SavingsTransaction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        goalId: goalId,
        amount: amount,
        type: 'contribution',
        date: DateTime.now(),
        description: description,
      ),
    );
    await loadGoals();
  }

  Future<void> withdrawContribution(String goalId, double amount, {String description = 'Withdrawal'}) async {
    if (amount <= 0) throw Exception('Withdrawal amount must be positive.');
    final goal = _goals.firstWhere((item) => item.id == goalId, orElse: () => throw Exception('Goal not found.'));
    if (amount > goal.currentSaved) {
      throw Exception('Withdrawal exceeds the saved balance for this goal.');
    }
    final newSaved = goal.currentSaved - amount;
    final updatedGoal = SavingsGoal(
      id: goal.id,
      title: goal.title,
      targetAmount: goal.targetAmount,
      currentSaved: newSaved,
      targetDate: goal.targetDate,
      description: goal.description,
      createdAt: goal.createdAt,
      status: newSaved >= goal.targetAmount ? 'completed' : 'active',
    );

    await DatabaseService.updateGoal(updatedGoal);
    await DatabaseService.insertSavingsTransaction(
      SavingsTransaction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        goalId: goalId,
        amount: amount,
        type: 'withdrawal',
        date: DateTime.now(),
        description: description,
      ),
    );
    await loadGoals();
  }

  double totalSaved() => _goals.fold(0.0, (sum, goal) => sum + goal.currentSaved);
}
