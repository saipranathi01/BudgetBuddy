import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/finance_background.dart';
import 'navigation/bottom_navigation.dart';
import 'providers/analytics_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/savings_provider.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/budget/budget_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/expenses/expenses_screen.dart';
import 'screens/savings/savings_screen.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError;

  try {
    await DatabaseService.initialize();
  } catch (error) {
    startupError = error;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        library: 'BudgetBuddy startup',
        context: ErrorDescription('Failed to initialize the local database.'),
      ),
    );
  }

  if (!kIsWeb && startupError == null) {
    await NotificationService.initialize();
  }

  runApp(BudgetBuddyApp(startupError: startupError));
}

class BudgetBuddyApp extends StatelessWidget {
  const BudgetBuddyApp({super.key, this.startupError});

  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
      ],
      child: MaterialApp(
        title: 'BudgetBuddy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        builder: (context, child) => FinanceBackground(
          child: child ?? const SizedBox.shrink(),
        ),
        home: startupError == null
            ? const AppShell()
            : _StartupFailure(error: startupError!),
      ),
    );
  }
}

class _StartupFailure extends StatelessWidget {
  const _StartupFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.storage_rounded,
                  size: 48,
                  color: AppColors.red,
                ),
                const SizedBox(height: 14),
                Text(
                  'BudgetBuddy could not start',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The local database could not be initialized. Your data has not been changed. Check the debug console for details, then restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.red, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
      context.read<ExpenseProvider>().loadExpenses();
      context.read<BudgetProvider>().loadBudgets();
      context.read<AnalyticsProvider>().loadAnalytics();
      context.read<SavingsProvider>().loadGoals();
    });
  }

  final List<Widget> _pages = const [
    DashboardScreen(),
    ExpensesScreen(),
    BudgetScreen(),
    AnalyticsScreen(),
    SavingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (authProvider.isLoading && !authProvider.isAuthenticated) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout = constraints.maxWidth >= 1000;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              if (wideLayout)
                DesktopNavigation(
                  currentIndex: _selectedIndex,
                  onTap: _selectPage,
                ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
          bottomNavigationBar: wideLayout
              ? null
              : BottomNavigation(
                  currentIndex: _selectedIndex,
                  onTap: _selectPage,
                ),
        );
      },
    );
  }

  void _selectPage(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }
}
