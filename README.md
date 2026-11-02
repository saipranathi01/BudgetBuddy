# BudgetBuddy

BudgetBuddy is a Flutter personal-finance app for tracking expenses, setting budgets, reviewing spending, and working toward savings goals.

## Features

- Create an account and sign in
- View a dashboard with an overview of your finances
- Add, review, and manage expenses
- Set monthly and category budgets
- Review spending analytics and charts
- Create savings goals and track progress
- Store app data locally using SQLite
- Receive local notifications on supported platforms
- Use a responsive interface with bottom navigation on smaller screens and a sidebar on wide screens

## Tech stack

- Flutter and Dart
- Provider for app state management
- SQLite for local data storage
- `fl_chart` for charts
- `flutter_local_notifications` for local notifications

## Getting started

### Requirements

- Flutter SDK and the Dart SDK version required by [`pubspec.yaml`](pubspec.yaml)
- An emulator, simulator, or device supported by your Flutter installation

### Run the app

From the project directory, fetch dependencies and start the app:

```shell
flutter pub get
flutter run
```

To select a specific connected device:

```shell
flutter devices
flutter run -d <device-id>
```

## Data and privacy

BudgetBuddy stores account and finance data in a local database on the device. It does not currently provide cloud sync, so data is not automatically shared across devices. Local notification availability depends on the platform and its permissions.

## Project structure

```text
lib/
  core/        Shared theme and widgets
  models/      Finance and user data models
  navigation/  App navigation
  providers/   State management
  screens/     Authentication, dashboard, expenses, budgets, analytics, savings
  services/    Authentication, database, and notification services
  utils/       Formatting, validation, and app constants
```

## Development checks

Run the analyzer and tests with:

```shell
flutter analyze
flutter test
```
