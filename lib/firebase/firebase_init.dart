// TODO Implement this library.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';

/// Top-level FCM background message handler.
/// Must be a top-level function (not a method) for background isolation.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background messages are handled silently.
  // For data-only messages you can trigger local notifications here.
}

/// Initialises every Firebase service the app needs.
/// Call once from [main] before [runApp].
Future<void> initFirebase() async {
  // ── Core ──────────────────────────────────────────────────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Realtime Database ─────────────────────────────────────────
  // Enable offline persistence so messages load from cache when offline.
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10 * 1024 * 1024); // 10 MB

  // ── FCM background handler ────────────────────────────────────
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ── Local notifications channel (Android 8+) ──────────────────
  const androidChannel = AndroidNotificationChannel(
    'guildchat_messages',          // channel id
    'GuildChat Messages',          // display name
    description: 'Chat and party notifications',
    importance: Importance.high,
    playSound: true,
  );

  final localNotifications = FlutterLocalNotificationsPlugin();

  await localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  // ── Request notification permission (iOS / Android 13+) ───────
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}