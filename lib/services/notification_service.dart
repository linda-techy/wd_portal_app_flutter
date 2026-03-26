import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';

/// Background message handler — must be a top-level function.
/// Called when a push notification arrives while the app is terminated or in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // No local notification shown here — system tray notification is shown automatically.
}

/// Manages Firebase Cloud Messaging for the portal app.
///
/// Usage:
///   1. Register background handler in main() before runApp():
///      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
///
///   2. Call NotificationService.initialize() after the user logs in,
///      passing a callback that POSTs the FCM token to the backend.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'walldot_channel';
  static const String _channelName = 'Walldot Portal Notifications';

  // IMPORTANT: Replace with your actual VAPID key from Firebase Console
  // Firebase Console → Project Settings → Cloud Messaging → Web Push certificates → Key pair
  static const String _vapidKey =
      'BM9PxWKhyYLg8GllNdbD17SHP7vXU9ziAqAURLNvOMJu_UzsZA7-S_RcVTCNljRmmlGF4CxiW9qN1-bsNR6VSQQ';

  /// Initialize Firebase, request permissions, register handlers and send the
  /// FCM token to the backend via [onTokenReceived].
  static Future<void> initialize({
    required Future<void> Function(String token) onTokenReceived,
  }) async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Request notification permission (iOS + Android 13+)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // Initialize flutter_local_notifications for foreground display
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Get token and register with backend
    final token =
        await FirebaseMessaging.instance.getToken(vapidKey: _vapidKey);
    if (token != null) await onTokenReceived(token);

    // Refresh token handler
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await onTokenReceived(newToken);
    });

    // Foreground messages — show as local notification
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Background → foreground tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Terminated → opened via notification tap
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await _local.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data.toString(),
    );
  }

  /// Handle a notification tap.
  /// The [message.data] map contains: type, referenceId, projectId, leadId.
  /// Wire navigation here using your NavigatorKey or routing solution.
  static void _handleTap(RemoteMessage message) {
    // Example: navigate based on type
    // final type = message.data['type'];
    // NavigationService.navigateTo(type, message.data);
  }
}
