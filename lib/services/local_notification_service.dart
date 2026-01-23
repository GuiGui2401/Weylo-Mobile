import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static FlutterLocalNotificationsPlugin get instance => _notifications;

  static Future<void> initialize() async {
    if (_initialized) return;
    const darwinSettings = DarwinInitializationSettings();
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );
      await _notifications.initialize(initSettings);
      _initialized = true;
      return;
    } catch (e) {
      debugPrint('[LocalNotificationService] init failed: $e');
    }

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );
      await _notifications.initialize(initSettings);
      _initialized = true;
    } catch (e) {
      debugPrint('[LocalNotificationService] fallback init failed: $e');
      _initialized = true;
    }
  }

  static Future<void> showStoryUploaded() async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      'story_uploads',
      'Story uploads',
      channelDescription: 'Notifications de publication des statuts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
    await _notifications.show(
      1001,
      'Story publiée',
      'Votre statut a bien été publié.',
      details,
    );
  }

  static Future<void> showPostUploaded() async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      'post_uploads',
      'Post uploads',
      channelDescription: 'Notifications de publication des posts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwinDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
    await _notifications.show(
      1002,
      'Post publié',
      'Votre publication a bien été mise en ligne.',
      details,
    );
  }
}
