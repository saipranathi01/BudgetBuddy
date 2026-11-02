import '../models/expense.dart';
import '../models/savings_goal.dart';

class SuggestionService {
  static List<String> generateSuggestions({
    required double monthlyBudget,
    required double totalSpent,
    required List<Expense> expenses,
    required List<SavingsGoal> goals,
  }) {
    final suggestions = <String>[];

    if (monthlyBudget > 0) {
      final util = totalSpent / monthlyBudget;
      if (util >= 0.8 && util < 1) {
        suggestions.add('You have used ${util * 100}% of your monthly budget. Consider reducing discretionary spending this week.');
      } else if (util >= 1) {
        suggestions.add('Your monthly budget is currently exceeded. Try to cut back on shopping or entertainment costs before the month ends.');
      } else {
        suggestions.add('You are still within budget. Keep your spending pace steady to build a stronger savings cushion.');
      }
    }

    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    if (categoryTotals.isNotEmpty) {
      final topCategory = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      suggestions.add('Food and lifestyle spending is trending higher in $topCategory. A quick review can help you keep other categories on track.');
    }

    for (final goal in goals) {
      final remaining = goal.targetAmount - goal.currentSaved;
      if (remaining <= 0) {
        continue;
      }
      final now = DateTime.now();
      final remainingDays = goal.targetDate.difference(now).inDays;
      if (remainingDays <= 0) {
        suggestions.add('${goal.title} is past its target date. Consider increasing your next contribution to catch up.');
        continue;
      }
      final remainingWeeks = (remainingDays / 7).ceil();
      final weeklyGoal = remainingWeeks > 0 ? remaining / remainingWeeks : remaining;
      suggestions.add('For ${goal.title}, your required weekly savings is ₹${weeklyGoal.toStringAsFixed(2)} to stay on schedule.');
    }

    if (suggestions.isEmpty) {
      suggestions.add('Add your first expense or savings goal to get personalized guidance.');
    }

    return suggestions.take(4).toList();
  }
}
