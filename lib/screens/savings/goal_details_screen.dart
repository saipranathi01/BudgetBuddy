import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/savings_goal.dart';
import '../../providers/savings_provider.dart';
import '../../utils/currency_formatter.dart';
import 'add_goal_screen.dart';
import 'savings_history_screen.dart';

class GoalDetailsScreen extends StatelessWidget {
  const GoalDetailsScreen({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavingsProvider>();
    final currentGoal = provider.goals.firstWhere(
      (item) => item.id == goal.id,
      orElse: () => goal,
    );
    final remaining =
        (currentGoal.targetAmount - currentGoal.currentSaved)
            .clamp(0, double.infinity)
            .toDouble();
    final progress = currentGoal.targetAmount > 0
        ? (currentGoal.currentSaved / currentGoal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final daysLeft = currentGoal.targetDate.difference(DateTime.now()).inDays;
    final completed = currentGoal.status == 'completed' ||
        currentGoal.currentSaved >= currentGoal.targetAmount;
    final overdue = !completed && daysLeft < 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentGoal.title),
        actions: [
          IconButton(
            tooltip: 'Savings history',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavingsHistoryScreen()),
            ),
            icon: const Icon(Icons.history_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 900 ? 700 : 580,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
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
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.flag_outlined,
                              color: AppColors.green,
                            ),
                          ),
                          const Spacer(),
                          _GoalStatus(
                            label: completed
                                ? 'Completed'
                                : overdue
                                    ? 'Overdue'
                                    : 'In progress',
                            color: completed
                                ? AppColors.green
                                : overdue
                                    ? AppColors.red
                                    : AppColors.teal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        CurrencyFormatter.format(currentGoal.currentSaved),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'of ${CurrencyFormatter.format(currentGoal.targetAmount)} saved',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 9,
                          color: AppColors.green,
                          backgroundColor: AppColors.border,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${(progress * 100).round()}% complete',
                              style: const TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${CurrencyFormatter.format(remaining)} to go',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _GoalMeta(
                              icon: Icons.event_outlined,
                              label: 'Target date',
                              value:
                                  '${currentGoal.targetDate.day}/${currentGoal.targetDate.month}/${currentGoal.targetDate.year}',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _GoalMeta(
                              icon: Icons.hourglass_bottom_rounded,
                              label: completed
                                  ? 'Goal status'
                                  : overdue
                                      ? 'Past due'
                                      : 'Days remaining',
                              value: completed
                                  ? 'Reached!'
                                  : overdue
                                      ? '${daysLeft.abs()} days'
                                      : '$daysLeft days',
                            ),
                          ),
                        ],
                      ),
                      if (currentGoal.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 16),
                        Text(
                          currentGoal.description!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!completed) ...[
                  CustomButton(
                    text: 'Add contribution',
                    icon: Icons.add_rounded,
                    onPressed: () => _showAmountDialog(context, currentGoal, true),
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    text: 'Withdraw from goal',
                    icon: Icons.south_west_rounded,
                    isDanger: true,
                    filled: false,
                    onPressed: currentGoal.currentSaved <= 0
                        ? null
                        : () => _showAmountDialog(context, currentGoal, false),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddGoalScreen(goal: currentGoal),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit goal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAmountDialog(
    BuildContext context,
    SavingsGoal currentGoal,
    bool isContribution,
  ) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<SavingsProvider>();
    try {
      final amount = await showDialog<double>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(isContribution ? 'Add to this goal' : 'Withdraw savings'),
          content: CustomTextField(
            controller: controller,
            label: 'Amount',
            hintText: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = double.tryParse(controller.text);
                if (parsed == null || parsed <= 0) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Enter an amount greater than zero.')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, parsed);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (amount == null) return;
      if (isContribution) {
        await provider.addContribution(currentGoal.id, amount);
      } else {
        await provider.withdrawContribution(currentGoal.id, amount);
      }
      if (messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isContribution ? 'Contribution added.' : 'Withdrawal recorded.',
            ),
          ),
        );
      }
    } catch (error) {
      if (messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      controller.dispose();
    }
  }
}

class _GoalStatus extends StatelessWidget {
  const _GoalStatus({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _GoalMeta extends StatelessWidget {
  const _GoalMeta({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 7),
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
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
