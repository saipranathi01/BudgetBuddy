import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/category_avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/finance_illustration.dart';
import '../../core/widgets/section_heading.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/currency_formatter.dart';
import '../expenses/add_expense_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime _selectedMonth = DateTime.now();

  Future<void> _moveMonth(int delta) async {
    final date = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    setState(() => _selectedMonth = date);
    await Future.wait([
      context.read<AnalyticsProvider>().loadAnalytics(month: date),
      context.read<BudgetProvider>().loadBudgets(month: date),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final totalSpent = analytics.getTotalSpending();
    final monthlyBudget = budgetProvider.monthlyBudget?.totalBudget ?? 0;
    final remaining = monthlyBudget - totalSpent;
    final categoryTotals = analytics.categoryTotals(_selectedMonth).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      AppColors.navy,
      AppColors.teal,
      AppColors.green,
      AppColors.orange,
      AppColors.red,
      const Color(0xFF7359A6),
      const Color(0xFFD36B52),
      AppColors.navySecondary,
    ];
    final pieSections = categoryTotals.asMap().entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.value,
        title: '',
        color: colors[entry.key % colors.length],
        radius: 20,
      );
    }).toList();
    final dailyTotals = <int, double>{};
    for (final expense in analytics.expenses) {
      dailyTotals.update(
        expense.date.day,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final trendEntries = dailyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxSpent = trendEntries.fold<double>(
      0,
      (maxValue, entry) => entry.value > maxValue ? entry.value : maxValue,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: () => _moveMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Center(
            child: Text(
              _monthLabel(_selectedMonth),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: _isCurrentMonth ? null : () => _moveMonth(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: analytics.isLoading
          ? const Center(child: CircularProgressIndicator())
          : analytics.expenses.isEmpty
              ? EmptyState(
                  title: 'No analytics for this month',
                  subtitle:
                      'Once you record expenses, you’ll see your spending patterns here.',
                  icon: Icons.insights_outlined,
                  illustrationType: FinanceIllustrationType.analytics,
                  actionLabel: 'Add expense',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddExpenseScreen(),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) => Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth > 900 ? 900 : 700,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                        children: [
                          LayoutBuilder(
                            builder: (context, box) {
                              final columns = box.maxWidth < 360 ? 1 : 2;
                              return GridView.count(
                                crossAxisCount: columns,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: columns == 1 ? 3.4 : 1.8,
                                children: [
                                  _StatCard(
                                    title: 'Total spent',
                                    value: CurrencyFormatter.format(totalSpent),
                                    icon: Icons.payments_outlined,
                                    color: AppColors.navy,
                                  ),
                                  _StatCard(
                                    title: 'Daily average',
                                    value: CurrencyFormatter.format(
                                      analytics.getAverageDailySpending(),
                                    ),
                                    icon: Icons.show_chart_rounded,
                                    color: AppColors.teal,
                                  ),
                                  _StatCard(
                                    title: 'Top category',
                                    value: analytics.getHighestSpendingCategory(
                                      month: _selectedMonth,
                                    ),
                                    icon: Icons.local_offer_outlined,
                                    color: AppColors.orange,
                                  ),
                                  _StatCard(
                                    title: remaining >= 0 ? 'Budget remaining' : 'Over budget',
                                    value: CurrencyFormatter.format(remaining.abs()),
                                    icon: remaining >= 0
                                        ? Icons.account_balance_wallet_outlined
                                        : Icons.warning_amber_rounded,
                                    color: remaining >= 0 ? AppColors.green : AppColors.red,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 22),
                          const SectionHeading(title: 'Spending trend'),
                          const SizedBox(height: 10),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 18, 18, 12),
                              child: SizedBox(
                                height: 200,
                                child: trendEntries.length < 2
                                    ? const EmptyState(
                                        title: 'Not enough data yet',
                                        subtitle: 'Add expenses on more days to see a trend.',
                                        icon: Icons.show_chart_rounded,
                                        compact: true,
                                      )
                                    : LineChart(
                                        LineChartData(
                                          minY: 0,
                                          maxY: maxSpent == 0 ? 1 : maxSpent * 1.25,
                                          gridData: FlGridData(
                                            show: true,
                                            drawVerticalLine: false,
                                            horizontalInterval:
                                                maxSpent > 0 ? maxSpent / 4 : 1,
                                            getDrawingHorizontalLine: (_) =>
                                                const FlLine(
                                              color: AppColors.border,
                                              strokeWidth: 1,
                                            ),
                                          ),
                                          borderData: FlBorderData(show: false),
                                          titlesData: FlTitlesData(
                                            topTitles: const AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                            rightTitles: const AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                            leftTitles: const AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 24,
                                                getTitlesWidget: (value, _) => Padding(
                                                  padding: const EdgeInsets.only(top: 7),
                                                  child: Text(
                                                    '${value.toInt()}',
                                                    style: const TextStyle(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          lineBarsData: [
                                            LineChartBarData(
                                              spots: trendEntries
                                                  .map((entry) => FlSpot(
                                                        entry.key.toDouble(),
                                                        entry.value,
                                                      ))
                                                  .toList(),
                                              isCurved: true,
                                              color: AppColors.teal,
                                              barWidth: 3,
                                              dotData: const FlDotData(show: true),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: AppColors.teal.withValues(
                                                  alpha: .10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const SectionHeading(title: 'Spending by category'),
                          const SizedBox(height: 10),
                          if (categoryTotals.isEmpty)
                            const EmptyState(
                              title: 'No category totals',
                              subtitle: 'Add a categorized expense to see a breakdown.',
                            )
                          else
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    if (pieSections.isNotEmpty)
                                      SizedBox(
                                        height: 190,
                                        child: PieChart(
                                          PieChartData(
                                            sections: pieSections,
                                            centerSpaceRadius: 53,
                                            sectionsSpace: 3,
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox(height: 18),
                                    ...categoryTotals.asMap().entries.map((entry) {
                                      final item = entry.value;
                                      final percentage = totalSpent > 0
                                          ? item.value / totalSpent * 100
                                          : 0.0;
                                      final color = colors[entry.key % colors.length];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 7),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 9,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: color,
                                              ),
                                            ),
                                            const SizedBox(width: 9),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  CategoryAvatar(
                                                    category: item.key,
                                                    size: 30,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(child: Text(item.key)),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${percentage.toStringAsFixed(0)}%',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              CurrencyFormatter.format(item.value),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          if (monthlyBudget > 0) ...[
                            const SizedBox(height: 20),
                            const SectionHeading(title: 'Budget vs actual'),
                            const SizedBox(height: 10),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 170,
                                      child: BarChart(
                                        BarChartData(
                                          maxY: (monthlyBudget > totalSpent
                                                      ? monthlyBudget
                                                      : totalSpent) *
                                                  1.2,
                                          minY: 0,
                                          gridData: const FlGridData(show: false),
                                          borderData: FlBorderData(show: false),
                                          titlesData: FlTitlesData(
                                            topTitles: const AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                            leftTitles: const AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                            rightTitles: const AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (value, _) => Padding(
                                                  padding: const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    value.toInt() == 0
                                                        ? 'Budget'
                                                        : 'Actual',
                                                    style: const TextStyle(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          barGroups: [
                                            _bar(0, monthlyBudget, AppColors.navy),
                                            _bar(1, totalSpent, remaining < 0
                                                ? AppColors.red
                                                : AppColors.teal),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Text('Budget  ${CurrencyFormatter.format(monthlyBudget)}'),
                                        Text('Actual  ${CurrencyFormatter.format(totalSpent)}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  bool get _isCurrentMonth =>
      _selectedMonth.year == DateTime.now().year &&
      _selectedMonth.month == DateTime.now().month;

  String _monthLabel(DateTime month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[month.month - 1]} ${month.year}';
  }

  BarChartGroupData _bar(int x, double amount, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: amount,
          color: color,
          width: 30,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
