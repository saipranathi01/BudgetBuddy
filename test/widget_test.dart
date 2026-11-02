import 'package:budget_buddy/models/expense.dart';
import 'package:budget_buddy/models/savings_goal.dart';
import 'package:budget_buddy/providers/auth_provider.dart';
import 'package:budget_buddy/screens/auth/login_screen.dart';
import 'package:budget_buddy/services/suggestion_service.dart';
import 'package:budget_buddy/core/theme/app_theme.dart';
import 'package:budget_buddy/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    test('positive amount validation rejects zero', () {
      expect(Validators.validatePositiveAmount('0'), isNotNull);
      expect(Validators.validatePositiveAmount('25.50'), isNull);
    });

    test('required field validation catches empty input', () {
      expect(
        Validators.validateRequired('', fieldName: 'Title'),
        equals('Title is required.'),
      );
    });
  });

  group('Suggestion engine', () {
    test('suggestions warn when spending exceeds budget threshold', () {
      final suggestions = SuggestionService.generateSuggestions(
        monthlyBudget: 2500,
        totalSpent: 2100,
        expenses: [
          Expense(
            id: '1',
            title: 'Groceries',
            amount: 800,
            category: 'Food',
            date: DateTime.now(),
            paymentMethod: 'UPI',
            createdAt: DateTime.now(),
          ),
          Expense(
            id: '2',
            title: 'Movies',
            amount: 600,
            category: 'Entertainment',
            date: DateTime.now(),
            paymentMethod: 'Cash',
            createdAt: DateTime.now(),
          ),
        ],
        goals: [
          SavingsGoal(
            id: 'goal-1',
            title: 'Trip',
            targetAmount: 600,
            currentSaved: 200,
            targetDate: DateTime.now().add(const Duration(days: 30)),
            description: 'Travel',
            createdAt: DateTime.now(),
            status: 'active',
          ),
        ],
      );

      expect(suggestions.any((item) => item.contains('budget')), isTrue);
      expect(
        suggestions.any((item) => item.contains('required weekly savings')),
        isTrue,
      );
    });
  });

  testWidgets('auth screens render and navigate on a phone-sized viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Let’s get you started'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    final signupException = tester.takeException();
    expect(signupException, isNull, reason: '$signupException');
  });
}
