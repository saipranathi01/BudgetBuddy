class UserProfile {
  final String id;
  final String name;
  final String email;
  final String preferredCurrency;
  final double monthlyAllowance;
  final bool notificationsEnabled;
  final String themeMode;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.preferredCurrency = 'INR',
    this.monthlyAllowance = 0,
    this.notificationsEnabled = true,
    this.themeMode = 'system',
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String,
        preferredCurrency: map['preferred_currency'] as String? ?? 'INR',
        monthlyAllowance: (map['monthly_allowance'] as num?)?.toDouble() ?? 0,
        notificationsEnabled: map['notifications_enabled'] == 1,
        themeMode: map['theme_mode'] as String? ?? 'system',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'preferred_currency': preferredCurrency,
        'monthly_allowance': monthlyAllowance,
        'notifications_enabled': notificationsEnabled ? 1 : 0,
        'theme_mode': themeMode,
      };
}

class AppPreferences {
  final String currency;
  final double monthlyAllowance;
  final bool notificationsEnabled;
  final String themeMode;

  AppPreferences({
    required this.currency,
    required this.monthlyAllowance,
    required this.notificationsEnabled,
    required this.themeMode,
  });

  factory AppPreferences.fromMap(Map<String, dynamic> map) => AppPreferences(
        currency: map['currency'] as String? ?? 'INR',
        monthlyAllowance: (map['monthly_allowance'] as num?)?.toDouble() ?? 0,
        notificationsEnabled: map['notifications_enabled'] == 1,
        themeMode: map['theme_mode'] as String? ?? 'system',
      );

  Map<String, dynamic> toMap() => {
        'currency': currency,
        'monthly_allowance': monthlyAllowance,
        'notifications_enabled': notificationsEnabled ? 1 : 0,
        'theme_mode': themeMode,
      };
}
