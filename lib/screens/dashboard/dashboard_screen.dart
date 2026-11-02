import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/category_avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/finance_illustration.dart';
import '../../core/widgets/section_heading.dart';
import '../../core/widgets/summary_card.dart';
import '../../models/expense.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/savings_provider.dart';
import '../../services/suggestion_service.dart';
import '../../utils/currency_formatter.dart';
import '../budget/edit_budget_screen.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_details_screen.dart';
import '../expenses/expenses_screen.dart';
import '../profile/profile_screen.dart';
import '../savings/add_goal_screen.dart';
import '../savings/goal_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final expenses = context.watch<ExpenseProvider>().expenses;
    final budgetProvider = context.watch<BudgetProvider>();
    final goals = context.watch<SavingsProvider>().goals;
    final now = DateTime.now();
    final monthExpenses = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList();
    final spent = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final budget = budgetProvider.monthlyBudget?.totalBudget ?? 0;
    final savings = goals.fold<double>(
      0,
      (sum, goal) => sum + goal.currentSaved,
    );
    final allowance = profile?.monthlyAllowance ?? 0;
    final remaining = allowance - spent - savings;
    final budgetProgress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final suggestions = SuggestionService.generateSuggestions(
      monthlyBudget: budget,
      totalSpent: spent,
      expenses: expenses,
      goals: goals,
    );
    final categoryTotals = <String, double>{};
    for (final expense in monthExpenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy, AppColors.pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('BudgetBuddy'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<ExpenseProvider>().loadExpenses(),
            context.read<BudgetProvider>().loadBudgets(),
            context.read<SavingsProvider>().loadGoals(),
          ]);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pageWidth = constraints.maxWidth > 960 ? 900.0 : 640.0;
            final content = ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: pageWidth),
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
                                    _greeting(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    profile?.name.isNotEmpty == true
                                        ? profile!.name
                                        : 'Student',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    DateFormat('EEEE, d MMMM').format(now),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 23,
                              backgroundColor: AppColors.navy.withValues(
                                alpha: .09,
                              ),
                              child: Text(
                                profile?.name.isNotEmpty == true
                                    ? profile!.name[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _BalanceCard(
                          balance: remaining,
                          spent: spent,
                          budget: budget,
                          progress: budgetProgress,
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, gridConstraints) {
                            final columns = gridConstraints.maxWidth < 440
                                ? 1
                                : 2;
                            return GridView.count(
                              crossAxisCount: columns,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisExtent: 136,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              children: [
                                SummaryCard(
                                  title: 'Monthly budget',
                                  value: budget > 0
                                      ? CurrencyFormatter.format(budget)
                                      : 'Not set',
                                  icon: Icons.payments_outlined,
                                  color: AppColors.navy,
                                  subtitle: budget > 0
                                      ? 'Your spending plan'
                                      : 'Create your monthly plan',
                                ),
                                SummaryCard(
                                  title: 'Total expenses',
                                  value: CurrencyFormatter.format(spent),
                                  icon: Icons.arrow_downward_rounded,
                                  color: AppColors.teal,
                                  subtitle: 'Spent this month',
                                ),
                                SummaryCard(
                                  title: 'Budget remaining',
                                  value: budget > 0
                                      ? CurrencyFormatter.format(budget - spent)
                                      : 'Not set',
                                  icon: Icons.account_balance_wallet_outlined,
                                  color: budget - spent < 0
                                      ? AppColors.red
                                      : AppColors.orange,
                                  subtitle: budget > 0
                                      ? '${(budgetProgress * 100).round()}% of budget used'
                                      : 'Set a budget to track',
                                  progress: budget > 0 ? budgetProgress : null,
                                ),
                                SummaryCard(
                                  title: 'Total savings',
                                  value: CurrencyFormatter.format(savings),
                                  icon: Icons.savings_outlined,
                                  color: AppColors.skyBlue,
                                  subtitle: goals.isEmpty
                                      ? 'Start a savings goal'
                                      : '${goals.length} active goal${goals.length == 1 ? '' : 's'}',
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        const SectionHeading(title: 'Quick actions'),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, actionConstraints) {
                            final columns = actionConstraints.maxWidth < 440
                                ? 1
                                : actionConstraints.maxWidth < 680
                                ? 2
                                : 3;
                            return GridView.count(
                              crossAxisCount: columns,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisExtent: 104,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              children: [
                                _QuickAction(
                                  icon: Icons.add_rounded,
                                  label: 'Add expense',
                                  description: 'Track your spending',
                                  color: AppColors.navy,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AddExpenseScreen(),
                                    ),
                                  ),
                                ),
                                _QuickAction(
                                  icon: Icons.tune_rounded,
                                  label: 'Set budget',
                                  description: 'Plan your month',
                                  color: AppColors.teal,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const EditBudgetScreen(),
                                    ),
                                  ),
                                ),
                                _QuickAction(
                                  icon: Icons.flag_rounded,
                                  label: 'New goal',
                                  description: 'Save for your dreams',
                                  color: AppColors.pink,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AddGoalScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .96),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SectionHeading(
                                title: 'Recent transactions',
                                actionLabel: expenses.isEmpty
                                    ? null
                                    : 'View all',
                                onAction: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ExpensesScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (expenses.isEmpty)
                                EmptyState(
                                  title: 'No expenses yet',
                                  subtitle: 'Add your first expense to see your spending at a glance.',
                                  illustrationType:
                                      FinanceIllustrationType.expenses,
                                  actionLabel: 'Add your first expense',
                                  onAction: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AddExpenseScreen(),
                                    ),
                                  ),
                                  compact: constraints.maxHeight < 680,
                                )
                              else
                                ...expenses
                                    .take(4)
                                    .map(
                                      (expense) =>
                                          _TransactionRow(expense: expense),
                                    ),
                            ],
                          ),
                        ),
                        if (topCategories.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const SectionHeading(
                            title: 'Top categories this month',
                          ),
                          const SizedBox(height: 8),
                          ...topCategories
                              .take(3)
                              .map(
                                (entry) => _CategorySpendRow(
                                  category: entry.key,
                                  amount: entry.value,
                                  fraction: spent > 0 ? entry.value / spent : 0,
                                ),
                              ),
                        ],
                        if (goals.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const SectionHeading(title: 'Savings goals'),
                          const SizedBox(height: 8),
                          ...goals
                              .take(2)
                              .map(
                                (goal) => Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 5,
                                    ),
                                    leading: const CategoryAvatar(
                                      category: 'Savings',
                                      size: 42,
                                    ),
                                    title: Text(
                                      goal.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: LinearProgressIndicator(
                                        value: goal.targetAmount > 0
                                            ? (goal.currentSaved /
                                                      goal.targetAmount)
                                                  .clamp(0.0, 1.0)
                                            : 0,
                                        minHeight: 5,
                                        borderRadius: BorderRadius.circular(8),
                                        backgroundColor: AppColors.border,
                                        color: AppColors.green,
                                      ),
                                    ),
                                    trailing: Text(
                                      '${goal.targetAmount > 0 ? (goal.currentSaved / goal.targetAmount * 100).clamp(0, 100).round() : 0}%',
                                      style: const TextStyle(
                                        color: AppColors.green,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            GoalDetailsScreen(goal: goal),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                        const SizedBox(height: 18),
                        const SectionHeading(title: 'Spending insights'),
                        const SizedBox(height: 8),
                        if (suggestions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: AppColors.lavender.withValues(alpha: .55),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.navy.withValues(alpha: .08),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: AppColors.navy,
                                ),
                                const SizedBox(width: 11),
                                const Expanded(
                                  child: Text(
                                    'Add a few expenses to unlock personal spending insights.',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Add expense',
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AddExpenseScreen(),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                  color: AppColors.navy,
                                ),
                              ],
                            ),
                          )
                        else
                          ...suggestions
                              .take(2)
                              .map(
                                (suggestion) => Container(
                                  margin: const EdgeInsets.only(bottom: 9),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.lightbulb_outline_rounded,
                                        color: AppColors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(suggestion)),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                if (constraints.maxWidth < 1120)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: _DashboardPromoPanel(
                          totalSaved: savings,
                          activeGoals: goals
                              .where((goal) => goal.status != 'completed')
                              .length,
                          onAddExpense: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AddExpenseScreen(),
                            ),
                          ),
                          onAddGoal: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AddGoalScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
            if (constraints.maxWidth < 1120) return content;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1360),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: content),
                    SizedBox(
                      width: 310,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(0, 18, 18, 24),
                        children: [
                          _DashboardPromoPanel(
                            totalSaved: savings,
                            activeGoals: goals
                                .where((goal) => goal.status != 'completed')
                                .length,
                            onAddExpense: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddExpenseScreen(),
                              ),
                            ),
                            onAddGoal: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddGoalScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.spent,
    required this.budget,
    required this.progress,
  });

  final double balance;
  final double spent;
  final double budget;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navySecondary, AppColors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -18,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .08),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -28,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: .22),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Available balance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '•••',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  CurrencyFormatter.format(balance),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _BalanceMeta(
                        label: 'Spent this month',
                        value: spent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BalanceMeta(
                        label: 'Monthly budget',
                        value: budget,
                      ),
                    ),
                  ],
                ),
                if (budget > 0) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      color: progress >= 1
                          ? AppColors.red
                          : const Color(0xFF72C6A7),
                      backgroundColor: Colors.white.withValues(alpha: .18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).round()}% of monthly budget used',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceMeta extends StatelessWidget {
  const _BalanceMeta({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: .78)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .19),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .84),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white70,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardPromoPanel extends StatelessWidget {
  const _DashboardPromoPanel({
    required this.totalSaved,
    required this.activeGoals,
    required this.onAddExpense,
    required this.onAddGoal,
  });

  final double totalSaved;
  final int activeGoals;
  final VoidCallback onAddExpense;
  final VoidCallback onAddGoal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF1ECFF), Color(0xFFE8F5FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: .8)),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FinanceIllustration(
                type: FinanceIllustrationType.budget,
                width: 174,
                height: 138,
              ),
              const SizedBox(height: 15),
              Text(
                'Take control of your finances',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track daily spending, plan ahead, and make room for the goals that matter.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAddExpense,
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text("Let's get started"),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .95),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              const FinanceIllustration(
                type: FinanceIllustrationType.savings,
                width: 88,
                height: 72,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your savings',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      CurrencyFormatter.format(totalSaved),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$activeGoals active goal${activeGoals == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Create a savings goal',
                onPressed: onAddGoal,
                icon: const Icon(Icons.add_circle_rounded),
                color: AppColors.pink,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        leading: CategoryAvatar(category: expense.category, size: 42),
        title: Text(
          expense.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${expense.category} · ${expense.date.day}/${expense.date.month}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Text(
          '-${CurrencyFormatter.format(expense.amount)}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExpenseDetailsScreen(expense: expense),
          ),
        ),
      ),
    );
  }
}

class _CategorySpendRow extends StatelessWidget {
  const _CategorySpendRow({
    required this.category,
    required this.amount,
    required this.fraction,
  });

  final String category;
  final double amount;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CategoryAvatar(category: category, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(category)),
                    Text(
                      CurrencyFormatter.format(amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    minHeight: 5,
                    color: AppColors.teal,
                    backgroundColor: AppColors.border,
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
