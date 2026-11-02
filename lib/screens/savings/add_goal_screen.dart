import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/section_heading.dart';
import '../../models/savings_goal.dart';
import '../../providers/savings_provider.dart';
import '../../utils/validators.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key, this.goal});
  final SavingsGoal? goal;

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 120));
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      final goal = widget.goal!;
      _titleController.text = goal.title;
      _amountController.text = goal.targetAmount.toStringAsFixed(2);
      _descriptionController.text = goal.description ?? '';
      _selectedDate = goal.targetDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final goal = SavingsGoal(
      id: widget.goal?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      targetAmount: double.tryParse(_amountController.text) ?? 0,
      currentSaved: widget.goal?.currentSaved ?? 0,
      targetDate: _selectedDate,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      createdAt: widget.goal?.createdAt ?? DateTime.now(),
      status: widget.goal?.status ?? 'active',
    );

    try {
      final provider = context.read<SavingsProvider>();
      if (widget.goal == null) {
        await provider.addGoal(goal);
      } else {
        await provider.updateGoal(goal);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save goal: $error')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal == null ? 'Add savings goal' : 'Edit goal'),
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
                  const SectionHeading(title: 'Your savings goal'),
                  const SizedBox(height: 9),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _titleController,
                            label: 'What are you saving for?',
                            hintText: 'e.g. Laptop, trip or emergency fund',
                            validator: (value) => Validators.validateRequired(
                              value,
                              fieldName: 'Goal title',
                            ),
                          ),
                          const SizedBox(height: 13),
                          CustomTextField(
                            controller: _amountController,
                            label: 'Target amount',
                            hintText: '0.00',
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            validator: Validators.validatePositiveAmount,
                          ),
                          const SizedBox(height: 13),
                          InkWell(
                            borderRadius: BorderRadius.circular(13),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate:
                                    DateTime.now().subtract(const Duration(days: 365)),
                                lastDate:
                                    DateTime.now().add(const Duration(days: 3650)),
                              );
                              if (picked != null && mounted) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Target date',
                                prefixIcon: Icon(Icons.event_outlined),
                              ),
                              child: Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 13),
                          CustomTextField(
                            controller: _descriptionController,
                            label: 'Description (optional)',
                            hintText: 'Add a short note about this goal',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: widget.goal == null ? 'Create goal' : 'Update goal',
                    icon: Icons.flag_outlined,
                    isLoading: _isSaving,
                    onPressed: _saveGoal,
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
