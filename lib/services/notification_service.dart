import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await NotificationService.instance.showLocal(
    title: message.notification?.title ?? 'ILYA-Chat',
    body:  message.notification?.body  ?? '',
    payload: message.data['chatId'],
  );
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _fcm   = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'ilya_chat_messages';
  static const _channelName = 'رسائل ILYA-Chat';
  static const _channelDesc = 'إشعارات الرسائل';

  Future<void> initialize() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    const androidChannel = AndroidNotificationChannel(
      _channelId, _channelName,
      description: _channelDesc,
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: (_) {},
    );

    FirebaseMessaging.onBackgroundMessage(_bgHandler);

    FirebaseMessaging.onMessage.listen((msg) {
      showLocal(
        title: msg.notification?.title ?? 'ILYA-Chat',
        body:  msg.notification?.body  ?? '',
        payload: msg.data['chatId'],
      );
    });

    _fcm.onTokenRefresh.listen((token) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    });
  }

  Future<String?> getToken() async {
    try { return await _fcm.getToken(); } catch (_) { return null; }
  }

  Future<void> showLocal({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    await _local.show(
      id, title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          enableLights: true,
          ledColor: const Color(0xFFFF0033),
          ledOnMs: 500,
          ledOffMs: 500,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> cancelAll()        => _local.cancelAll();
  Future<void> cancel(int id)     => _local.cancel(id);

  Future<void> subscribe(String topic)   => _fcm.subscribeToTopic(topic);
  Future<void> unsubscribe(String topic) => _fcm.unsubscribeFromTopic(topic);
}
