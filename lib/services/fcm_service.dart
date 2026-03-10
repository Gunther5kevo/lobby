import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firestore_service.dart';

/// Manages FCM token lifecycle, foreground notification display,
/// and notification tap routing.
class FcmService {
  FcmService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    FirestoreService? firestoreService,
    FirebaseAuth? auth,
  })  : _messaging           = messaging ?? FirebaseMessaging.instance,
        _localNotifications  = localNotifications ?? FlutterLocalNotificationsPlugin(),
        _firestoreService    = firestoreService ?? FirestoreService(),
        _auth                = auth ?? FirebaseAuth.instance;

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirestoreService _firestoreService;
  final FirebaseAuth _auth;

  // Android notification channel — must match firebase_init.dart
  static const _channel = AndroidNotificationDetails(
    'guildchat_messages',
    'GuildChat Messages',
    channelDescription: 'Chat and party notifications',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    icon: '@mipmap/ic_launcher',
  );

  // ── Initialise ────────────────────────────────────────────────

  /// Call after Firebase.initializeApp() and after the user is signed in.
  Future<void> init(String uid) async {
    // ── Init local notifications plugin ────────────────────────
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit     = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested in firebase_init
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // ── Get and save token ─────────────────────────────────────
    final token = await _messaging.getToken();
    if (token != null) await _firestoreService.saveFcmToken(uid, token);

    // ── Token refresh ──────────────────────────────────────────
    _messaging.onTokenRefresh.listen((newToken) async {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestoreService.saveFcmToken(currentUser.uid, newToken);
      }
    });

    // ── Foreground messages ────────────────────────────────────
    // FCM doesn't show a heads-up while app is open — we do it manually.
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // ── App opened from a notification ─────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // ── Check if app was launched from a terminated notification ─
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleNotificationOpen(initial);
  }

  // ── Token cleanup on sign-out ─────────────────────────────────

  Future<void> deleteToken(String uid) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _firestoreService.deleteFcmToken(uid, token);
      await _messaging.deleteToken();
    }
  }

  // ── Foreground notification display ───────────────────────────

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      // Use hashCode for a stable-ish notification ID
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Encode the data payload as the notification payload for routing
      payload: message.data['route'],
    );
  }

  // ── Routing ────────────────────────────────────────────────────

  /// Called when the user taps a local notification.
  void _onNotificationTap(NotificationResponse response) {
    final route = response.payload;
    if (route != null) _routeToNotification(route);
  }

  /// Called when the user taps an FCM notification while app is in background.
  void _handleNotificationOpen(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null) _routeToNotification(route);
  }

  /// Route strings expected from FCM data payload:
  ///   'dm/{chatId}'
  ///   'group/{groupId}/channel/{channelId}'
  ///   'party/{partyId}'
  ///   'friend_request'
  void _routeToNotification(String route) {
    // Routing is handled by the navigation provider watching this stream.
    _routeController.add(route);
  }

  // Simple stream so the app shell can listen and navigate
  static final _routeController =
      _BroadcastStreamController<String>();

  static Stream<String> get routeStream => _routeController.stream;
}

// ── Minimal broadcast stream controller ───────────────────────────────────

class _BroadcastStreamController<T> {
  final _listeners = <void Function(T)>[];

  void add(T value) {
    for (final l in _listeners) {
      l(value);
    }
  }

  Stream<T> get stream async* {
    // This is a simplified version — in production use a real StreamController.
    // Replace with dart:async StreamController.broadcast() if needed.
  }
}