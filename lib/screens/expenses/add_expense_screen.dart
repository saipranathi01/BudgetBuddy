import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/section_heading.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/validators.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.expense});
  final Expense? expense;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = AppConstants.expenseCategories.first;
  String _selectedPaymentMethod = AppConstants.paymentMethods.first;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final expense = widget.expense!;
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _notesController.text = expense.notes ?? '';
      _selectedDate = expense.date;
      _selectedCategory = expense.category;
      _selectedPaymentMethod = expense.paymentMethod;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final expense = Expense(
      id: widget.expense?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: double.tryParse(_amountController.text) ?? 0,
      category: _selectedCategory,
      date: _selectedDate,
      paymentMethod: _selectedPaymentMethod,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: widget.expense?.createdAt ?? DateTime.now(),
    );

    try {
      final provider = context.read<ExpenseProvider>();
      if (widget.expense == null) {
        await provider.addExpense(expense);
      } else {
        await provider.updateExpense(expense);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save expense: $error')),
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
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add expense' : 'Edit expense'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  const SectionHeading(title: 'Expense details'),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _titleController,
                            label: 'What did you spend on?',
                            hintText: 'e.g. Lunch with friends',
                            validator: (value) =>
                                Validators.validateRequired(value, fieldName: 'Title'),
                          ),
                          const SizedBox(height: 13),
                          CustomTextField(
                            controller: _amountController,
                            label: 'Amount',
                            hintText: '0.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: Validators.validatePositiveAmount,
                          ),
                          const SizedBox(height: 13),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: AppConstants.expenseCategories
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(
                              () => _selectedCategory = value ?? _selectedCategory,
                            ),
                          ),
                          const SizedBox(height: 13),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPaymentMethod,
                            decoration: const InputDecoration(
                              labelText: 'Payment method',
                              prefixIcon: Icon(Icons.payment_outlined),
                            ),
                            items: AppConstants.paymentMethods
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(
                              () => _selectedPaymentMethod =
                                  value ?? _selectedPaymentMethod,
                            ),
                          ),
                          const SizedBox(height: 13),
                          InkWell(
                            borderRadius: BorderRadius.circular(13),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null && mounted) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              child: Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 13),
                          CustomTextField(
                            controller: _notesController,
                            label: 'Notes (optional)',
                            hintText: 'Add a note to remember the details',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  CustomButton(
                    text: widget.expense == null ? 'Save expense' : 'Update expense',
                    icon: Icons.check_rounded,
                    isLoading: _isSaving,
                    onPressed: _saveExpense,
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
