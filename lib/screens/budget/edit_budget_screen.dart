import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/section_heading.dart';
import '../../models/budget.dart';
import '../../providers/budget_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/validators.dart';

class EditBudgetScreen extends StatefulWidget {
  const EditBudgetScreen({super.key});

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController();
  final Map<String, TextEditingController> _categoryControllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final budgetProvider = context.read<BudgetProvider>();
    final budget = budgetProvider.monthlyBudget;
    _totalController.text = (budget?.totalBudget ?? 0).toStringAsFixed(0);
    for (final category in AppConstants.expenseCategories) {
      final limit = budgetProvider.categoryBudgets.firstWhere(
        (item) => item.category == category,
        orElse: () => CategoryBudget(
          id: const Uuid().v4(),
          monthKey: DatabaseService.getMonthKey(DateTime.now()),
          category: category,
          limit: 0,
          createdAt: DateTime.now(),
        ),
      );
      _categoryControllers[category] = TextEditingController(text: limit.limit.toStringAsFixed(0));
    }
  }

  @override
  void dispose() {
    _totalController.dispose();
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final budgetProvider = context.read<BudgetProvider>();
    final totalBudget = double.tryParse(_totalController.text) ?? 0;
    final month = DateTime.now();

    try {
      await budgetProvider.setMonthlyBudget(
        MonthlyBudget(
          id: 'month-${month.year}-${month.month}',
          monthKey: DatabaseService.getMonthKey(month),
          totalBudget: totalBudget,
          createdAt: DateTime.now(),
        ),
      );

      for (final category in AppConstants.expenseCategories) {
        final limit =
            double.tryParse(_categoryControllers[category]?.text ?? '0') ?? 0;
        if (limit <= 0) continue;
        await budgetProvider.setCategoryBudget(
          CategoryBudget(
            id: '${category.toLowerCase()}-${month.year}-${month.month}',
            monthKey: DatabaseService.getMonthKey(month),
            category: category,
            limit: limit,
            createdAt: DateTime.now(),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save budget: $error')),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit budget')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  const SectionHeading(title: 'Monthly spending plan'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _totalController,
                        decoration: const InputDecoration(
                          labelText: 'Total monthly budget',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                          helperText: 'Your overall spending target for this month',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: Validators.validatePositiveAmount,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeading(title: 'Category limits'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: AppConstants.expenseCategories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              controller: _categoryControllers[category],
                              decoration: InputDecoration(
                                labelText: category,
                                prefixIcon: const Icon(Icons.sell_outlined),
                                isDense: true,
                                helperText: 'Leave at 0 to skip this category',
                                helperStyle: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                final amount = double.tryParse(value ?? '0');
                                if (amount == null || amount < 0) {
                                  return 'Enter 0 or a positive amount.';
                                }
                                return null;
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Current total: ${CurrencyFormatter.format(double.tryParse(_totalController.text) ?? 0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    text: 'Save budget',
                    icon: Icons.check_rounded,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
