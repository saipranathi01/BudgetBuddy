class AppConstants {
  static const String appName = 'BudgetBuddy';
  static const String demoEmail = 'student@budgetbuddy.app';
  static const String demoPassword = 'budgetbuddy';
  static const String defaultCurrency = 'INR';

  static const List<String> expenseCategories = [
    'Food',
    'Transport',
    'Education',
    'Shopping',
    'Entertainment',
    'Bills',
    'Health',
    'Other',
  ];

  static const List<String> paymentMethods = [
    'Cash',
    'UPI',
    'Debit Card',
    'Credit Card',
    'Bank Transfer',
  ];

  static const double warningThreshold = 0.8;
  static const double criticalThreshold = 1.0;
}
