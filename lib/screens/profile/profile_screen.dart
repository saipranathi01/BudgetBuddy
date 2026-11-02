import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/section_heading.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _allowanceController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile =
        context.read<AuthProvider>().profile ??
        UserProfile(
          id: 'local-user',
          name: 'Student',
          email: 'student@budgetbuddy.app',
        );
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _allowanceController = TextEditingController(
      text: profile.monthlyAllowance.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _allowanceController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final authProvider = context.read<AuthProvider>();
    final current =
        authProvider.profile ??
        UserProfile(
          id: 'local-user',
          name: 'Student',
          email: 'student@budgetbuddy.app',
        );

    try {
      await authProvider.updateProfile(
        UserProfile(
          id: current.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          preferredCurrency: current.preferredCurrency,
          monthlyAllowance: double.parse(_allowanceController.text),
          notificationsEnabled: current.notificationsEnabled,
          themeMode: current.themeMode,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save profile: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _setNotifications(UserProfile current, bool enabled) async {
    try {
      await context.read<AuthProvider>().updateProfile(
        UserProfile(
          id: current.id,
          name: current.name,
          email: current.email,
          preferredCurrency: current.preferredCurrency,
          monthlyAllowance: current.monthlyAllowance,
          notificationsEnabled: enabled,
          themeMode: current.themeMode,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update notification preference: $error'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in with your local account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await context.read<AuthProvider>().logout();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not log out: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile =
        context.watch<AuthProvider>().profile ??
        UserProfile(
          id: 'local-user',
          name: 'Student',
          email: 'student@budgetbuddy.app',
        );
    final initials = profile.name.trim().isEmpty
        ? 'S'
        : profile.name.trim().substring(0, 1).toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & settings')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 900 ? 720 : 600,
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(17),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 29,
                            backgroundColor: AppColors.navy,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 21,
                              ),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  profile.email,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.verified_user_outlined,
                            color: AppColors.teal,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeading(title: 'Personal information'),
                  const SizedBox(height: 9),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            label: 'Display name',
                            validator: (value) => Validators.validateRequired(
                              value,
                              fieldName: 'Name',
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email address',
                            keyboardType: TextInputType.emailAddress,
                            readOnly: true,
                            validator: Validators.validateEmail,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _allowanceController,
                            label: 'Monthly allowance',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if ((double.tryParse(value ?? '') ?? -1) < 0) {
                                return 'Enter 0 or a positive amount.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeading(title: 'Preferences'),
                  const SizedBox(height: 9),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.currency_rupee_rounded,
                            color: AppColors.navy,
                          ),
                          title: const Text('Currency'),
                          subtitle: const Text('Indian Rupee (INR)'),
                          trailing: const Text(
                            'INR',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile.adaptive(
                          secondary: const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.navy,
                          ),
                          title: const Text('Budget notifications'),
                          subtitle: const Text(
                            'Get reminders about your spending',
                          ),
                          value: profile.notificationsEnabled,
                          onChanged: (value) =>
                              _setNotifications(profile, value),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        const ListTile(
                          leading: Icon(
                            Icons.light_mode_outlined,
                            color: AppColors.navy,
                          ),
                          title: Text('Appearance'),
                          subtitle: Text('Light theme'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),
                  Text(
                    'Monthly allowance preview: ${CurrencyFormatter.format(double.tryParse(_allowanceController.text) ?? 0)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Save changes',
                    icon: Icons.check_rounded,
                    isLoading: _isSaving,
                    onPressed: _saveProfile,
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    text: 'Log out',
                    icon: Icons.logout_rounded,
                    onPressed: _logout,
                    isDanger: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'BudgetBuddy demo stores your account and finance data on this device/browser.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
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
