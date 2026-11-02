import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/category_avatar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/section_heading.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../utils/currency_formatter.dart';
import 'add_expense_screen.dart';

class ExpenseDetailsScreen extends StatelessWidget {
  const ExpenseDetailsScreen({super.key, required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currentExpense = provider.expenses.firstWhere(
      (item) => item.id == expense.id,
      orElse: () => expense,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Expense details')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 900 ? 700 : 560,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CategoryAvatar(
                          category: currentExpense.category,
                          size: 58,
                        ),
                        const SizedBox(height: 13),
                        Text(
                          currentExpense.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          currentExpense.category,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          '-${CurrencyFormatter.format(currentExpense.amount)}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const SectionHeading(title: 'Transaction information'),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value:
                            '${currentExpense.date.day}/${currentExpense.date.month}/${currentExpense.date.year}',
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _DetailRow(
                        icon: Icons.payment_outlined,
                        label: 'Payment method',
                        value: currentExpense.paymentMethod,
                      ),
                      if (currentExpense.notes?.isNotEmpty == true) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _DetailRow(
                          icon: Icons.notes_rounded,
                          label: 'Notes',
                          value: currentExpense.notes!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Edit expense',
                  icon: Icons.edit_outlined,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(expense: currentExpense),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                CustomButton(
                  text: 'Delete expense',
                  icon: Icons.delete_outline_rounded,
                  isDanger: true,
                  filled: false,
                  onPressed: () => _deleteExpense(context, currentExpense.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteExpense(BuildContext context, String expenseId) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ExpenseProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
        title: const Text('Delete this expense?'),
        content: const Text('This transaction will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await provider.deleteExpense(expenseId);
      if (navigator.mounted) navigator.pop();
    } catch (error) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete expense: $error')),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.textSecondary),
          const SizedBox(width: 11),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
