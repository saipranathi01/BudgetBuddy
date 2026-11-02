import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/category_avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/finance_illustration.dart';
import '../../core/widgets/section_heading.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/currency_formatter.dart';
import 'add_expense_screen.dart';
import 'expense_details_screen.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expenses = provider.filteredExpenses;
    final total = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            tooltip: 'Add expense',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 900 ? 820.0 : 680.0;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                children: [
                  Text(
                    '${expenses.length} ${expenses.length == 1 ? 'transaction' : 'transactions'}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    CurrencyFormatter.format(total),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: provider.setSearchQuery,
                    decoration: const InputDecoration(
                      hintText: 'Search transactions',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: provider.selectedCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            isDense: true,
                          ),
                          items: ['All', ...AppConstants.expenseCategories]
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              provider.setCategoryFilter(value ?? 'All'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: provider.sortMode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Sort by',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'newest',
                              child: Text('Newest'),
                            ),
                            DropdownMenuItem(
                              value: 'oldest',
                              child: Text('Oldest'),
                            ),
                            DropdownMenuItem(
                              value: 'amount_high',
                              child: Text('High to low'),
                            ),
                            DropdownMenuItem(
                              value: 'amount_low',
                              child: Text('Low to high'),
                            ),
                          ],
                          onChanged: (value) =>
                              provider.setSortMode(value ?? 'newest'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SectionHeading(title: 'Transaction history'),
                  const SizedBox(height: 7),
                  if (provider.isLoading)
                    const SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (expenses.isEmpty)
                    EmptyState(
                      title:
                          provider.searchQuery.isNotEmpty ||
                              provider.selectedCategory != 'All'
                          ? 'No matching expenses'
                          : 'No expenses yet',
                      subtitle:
                          provider.searchQuery.isNotEmpty ||
                              provider.selectedCategory != 'All'
                          ? 'Try changing your search or category filter.'
                          : 'Add your first expense to start tracking your spending.',
                      icon: Icons.receipt_long_outlined,
                      illustrationType:
                          provider.searchQuery.isEmpty &&
                              provider.selectedCategory == 'All'
                          ? FinanceIllustrationType.expenses
                          : null,
                      actionLabel:
                          provider.searchQuery.isEmpty &&
                              provider.selectedCategory == 'All'
                          ? 'Add your first expense'
                          : null,
                      onAction:
                          provider.searchQuery.isEmpty &&
                              provider.selectedCategory == 'All'
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddExpenseScreen(),
                              ),
                            )
                          : null,
                    )
                  else
                    ...expenses.map(
                      (expense) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ExpenseItem(expense: expense),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expenses-add-expense',
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add expense'),
      ),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  const _ExpenseItem({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExpenseDetailsScreen(expense: expense),
          ),
        ),
        leading: CategoryAvatar(category: expense.category),
        title: Text(
          expense.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '${expense.category} · ${expense.date.day}/${expense.date.month}/${expense.date.year} · ${expense.paymentMethod}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        trailing: Text(
          '-${CurrencyFormatter.format(expense.amount)}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
