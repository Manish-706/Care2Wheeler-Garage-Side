import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> initialize() async {
    // Request permission (especially for iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Get the FCM token and store it securely
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");
    if (token != null) {
      await _secureStorage.write(key: 'fcm_token', value: token);
      // You can also send this token to your backend as part of login/registration
    }

    // Listen for token refreshes (e.g., when the token changes)
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print("FCM Token refreshed: $newToken");
      await _secureStorage.write(key: 'fcm_token', value: newToken);
      // Send the new token to your backend
    });

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a foreground message: ${message.notification?.body}');
      // Optionally, show a local notification (using flutter_local_notifications, for example)
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification taps (when the app is in the background or terminated)
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print(
            "App opened from terminated state: ${message.notification?.body}");
        // Handle navigation or other logic
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("App opened from background: ${message.notification?.body}");
      // Handle navigation or other logic
    });
  }

  // Background message handler
  @pragma('vm:entry-point') // Required for background execution
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print("Background message: ${message.notification?.body}");
    // Handle background messages (e.g., show a local notification)
  }

  // Retrieve the stored FCM token
  Future<String?> getFcmToken() async {
    return await _secureStorage.read(key: 'fcm_token');
  }

  // Delete the stored FCM token (e.g., on logout)
  Future<void> deleteFcmToken() async {
    await _secureStorage.delete(key: 'fcm_token');
  }
}
