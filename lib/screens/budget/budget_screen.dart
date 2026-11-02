import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/category_avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/finance_illustration.dart';
import '../../core/widgets/section_heading.dart';
import '../../providers/budget_provider.dart';
import '../../providers/expense_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/currency_formatter.dart';
import 'edit_budget_screen.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final month = DateTime.now();
    final monthExpenses = expenseProvider.expenses
        .where(
          (expense) =>
              expense.date.year == month.year &&
              expense.date.month == month.month,
        )
        .toList();
    final totalSpent = monthExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final totalBudget = budgetProvider.monthlyBudget?.totalBudget ?? 0;
    final remaining = totalBudget - totalSpent;
    final utilization = totalBudget > 0 ? totalSpent / totalBudget : 0.0;
    final statusColor = utilization >= AppConstants.criticalThreshold
        ? AppColors.red
        : utilization >= AppConstants.warningThreshold
        ? AppColors.orange
        : AppColors.green;
    final progress = utilization.clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            tooltip: 'Edit budget',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const EditBudgetScreen())),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 900 ? 820 : 680,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _monthLabel(month),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  CurrencyFormatter.format(totalBudget),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const Text(
                                  'Monthly spending limit',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Edit budget',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const EditBudgetScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedProgress, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: animatedProgress,
                            minHeight: 9,
                            color: statusColor,
                            backgroundColor: AppColors.border,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${(utilization * 100).round()}% used',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${CurrencyFormatter.format(totalSpent)} spent',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _BudgetMetric(
                              label: 'Spent',
                              amount: totalSpent,
                              icon: Icons.arrow_downward_rounded,
                              color: AppColors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BudgetMetric(
                              label: remaining >= 0
                                  ? 'Left to spend'
                                  : 'Over budget',
                              amount: remaining.abs(),
                              icon: remaining >= 0
                                  ? Icons.account_balance_wallet_outlined
                                  : Icons.warning_amber_rounded,
                              color: remaining >= 0
                                  ? AppColors.green
                                  : AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SectionHeading(
                  title: 'Category limits',
                  actionLabel: budgetProvider.categoryBudgets.isEmpty
                      ? null
                      : 'Edit',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditBudgetScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                if (budgetProvider.categoryBudgets.isEmpty)
                  EmptyState(
                    title: 'Plan category limits',
                    subtitle: 'Set flexible spending caps for food, transport, shopping and more.',
                    icon: Icons.pie_chart_outline_rounded,
                    illustrationType: FinanceIllustrationType.budget,
                    actionLabel: 'Set category limits',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditBudgetScreen(),
                      ),
                    ),
                  )
                else
                  ...budgetProvider.categoryBudgets.map((budget) {
                    final spent = monthExpenses
                        .where((expense) => expense.category == budget.category)
                        .fold<double>(
                          0,
                          (sum, expense) => sum + expense.amount,
                        );
                    final fraction = budget.limit > 0
                        ? spent / budget.limit
                        : 0.0;
                    final color = fraction >= 1
                        ? AppColors.red
                        : fraction >= AppConstants.warningThreshold
                        ? AppColors.orange
                        : AppColors.green;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 9),
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CategoryAvatar(
                                  category: budget.category,
                                  size: 40,
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        budget.category,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${CurrencyFormatter.format(spent)} of ${CurrencyFormatter.format(budget.limit)}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${(fraction * 100).round()}%',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: fraction.clamp(0.0, 1.0),
                              ),
                              duration: const Duration(milliseconds: 650),
                              curve: Curves.easeOutCubic,
                              builder: (context, animatedProgress, _) =>
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: animatedProgress,
                                      minHeight: 6,
                                      color: color,
                                      backgroundColor: AppColors.border,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditBudgetScreen()),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Edit monthly and category limits'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _monthLabel(DateTime month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }
}

class _BudgetMetric extends StatelessWidget {
  const _BudgetMetric({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  CurrencyFormatter.format(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
