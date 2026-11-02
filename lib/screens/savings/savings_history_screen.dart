import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/category_avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/savings_goal.dart';
import '../../services/database_service.dart';
import '../../utils/currency_formatter.dart';

class SavingsHistoryScreen extends StatefulWidget {
  const SavingsHistoryScreen({super.key});

  @override
  State<SavingsHistoryScreen> createState() => _SavingsHistoryScreenState();
}

class _SavingsHistoryScreenState extends State<SavingsHistoryScreen> {
  List<SavingsTransaction> _transactions = [];
  Map<String, String> _goalNames = {};
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final goals = await DatabaseService.getSavingsGoals();
      final allTransactions = <SavingsTransaction>[];
      for (final goal in goals) {
        allTransactions.addAll(
          await DatabaseService.getSavingsTransactionsForGoal(goal.id),
        );
      }
      allTransactions.sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        _transactions = allTransactions;
        _goalNames = {for (final goal in goals) goal.id: goal.title};
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final contributions = _transactions
        .where((item) => item.type == 'contribution')
        .fold<double>(0, (sum, item) => sum + item.amount);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings history'),
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.red, size: 40),
                        const SizedBox(height: 10),
                        const Text('Could not load savings history'),
                        const SizedBox(height: 6),
                        Text(
                          _error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _load,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _transactions.isEmpty
                  ? const EmptyState(
                      title: 'No savings activity yet',
                      subtitle:
                          'Contributions and withdrawals will appear here as you update your goals.',
                      icon: Icons.history_rounded,
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) => Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth > 900 ? 820 : 680,
                          ),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                            children: [
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const CategoryAvatar(
                                        category: 'Savings',
                                        size: 42,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Contributed so far',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              CurrencyFormatter.format(contributions),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${_transactions.length} activities',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              ..._transactions.map((item) {
                                final isContribution = item.type == 'contribution';
                                final color = isContribution
                                    ? AppColors.green
                                    : AppColors.orange;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 3,
                                    ),
                                    leading: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: .10),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Icon(
                                        isContribution
                                            ? Icons.south_west_rounded
                                            : Icons.north_east_rounded,
                                        color: color,
                                      ),
                                    ),
                                    title: Text(
                                      item.description ??
                                          (isContribution
                                              ? 'Contribution'
                                              : 'Withdrawal'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${_goalNames[item.goalId] ?? 'Savings goal'} · ${item.date.day}/${item.date.month}/${item.date.year}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing: Text(
                                      '${isContribution ? '+' : '-'}${CurrencyFormatter.format(item.amount)}',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}
