import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/finance_illustration.dart';
import '../../core/widgets/section_heading.dart';
import '../../providers/savings_provider.dart';
import '../../utils/currency_formatter.dart';
import 'add_goal_screen.dart';
import 'goal_details_screen.dart';
import 'savings_history_screen.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavingsProvider>();
    final goals = provider.goals;
    final totalSaved = provider.totalSaved();
    final activeGoals = goals
        .where((goal) => goal.status != 'completed')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings goals'),
        actions: [
          IconButton(
            tooltip: 'Savings history',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavingsHistoryScreen()),
            ),
            icon: const Icon(Icons.history_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'savings-add-goal',
        onPressed: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AddGoalScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New goal'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 900 ? 820 : 680,
            ),
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : goals.isEmpty
                ? EmptyState(
                    title: 'Start saving for something',
                    subtitle:
                        'Create a goal, add contributions and track your progress over time.',
                    icon: Icons.savings_outlined,
                    illustrationType: FinanceIllustrationType.savings,
                    actionLabel: 'Create savings goal',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddGoalScreen(),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.navy, AppColors.navySecondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.savings_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total saved',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    CurrencyFormatter.format(totalSaved),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${goals.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  '$activeGoals active',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const FinanceIllustration(
                              type: FinanceIllustrationType.savings,
                              width: 86,
                              height: 68,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      SectionHeading(
                        title: 'Your goals',
                        actionLabel: 'History',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SavingsHistoryScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      ...goals.map((goal) {
                        final progress = goal.targetAmount > 0
                            ? (goal.currentSaved / goal.targetAmount).clamp(
                                0.0,
                                1.0,
                              )
                            : 0.0;
                        final isCompleted =
                            goal.status == 'completed' ||
                            goal.currentSaved >= goal.targetAmount;
                        final isOverdue =
                            !isCompleted &&
                            goal.targetDate.isBefore(DateTime.now());
                        final status = isCompleted
                            ? 'Completed'
                            : isOverdue
                            ? 'Overdue'
                            : goal.status == 'active'
                            ? 'On track'
                            : goal.status;
                        final statusColor = isCompleted
                            ? AppColors.green
                            : isOverdue
                            ? AppColors.red
                            : AppColors.teal;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GoalDetailsScreen(goal: goal),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: AppColors.green.withValues(
                                            alpha: .10,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            13,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.flag_outlined,
                                          color: AppColors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              goal.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Target ${goal.targetDate.day}/${goal.targetDate.month}/${goal.targetDate.year}',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                            alpha: .09,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 17),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          CurrencyFormatter.format(
                                            goal.currentSaved,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'of ${CurrencyFormatter.format(goal.targetAmount)}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 7,
                                      color: statusColor,
                                      backgroundColor: AppColors.border,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    '${(progress * 100).round()}% complete · ${CurrencyFormatter.format((goal.targetAmount - goal.currentSaved).clamp(0, goal.targetAmount))} to go',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      const SectionHeading(title: 'Small steps add up'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: .07),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppColors.green.withValues(alpha: .16),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.spa_outlined, color: AppColors.green),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'A small, regular contribution can make a big goal feel more achievable.',
                                style: TextStyle(height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
