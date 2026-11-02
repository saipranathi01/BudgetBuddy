
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(settings: settings);
    } catch (error) {
      debugPrint('Notification service initialization failed: $error');
    }
  }

  static Future<void> showBudgetWarning(
    String title,
    String body,
  ) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'budgetbuddy',
        'BudgetBuddy Alerts',
        channelDescription: 'Budget and savings alerts for BudgetBuddy',
        importance: Importance.max,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        id: 0,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (error) {
      debugPrint('Budget warning notification failed: $error');
    }
  }
}
