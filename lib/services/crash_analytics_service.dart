import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class CrashAnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;

  static Future<void> setUser(String userId, String username) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'username', value: username);
  }

  static Future<void> logEvent(String name, {Map<String, dynamic>? params}) =>
      _analytics.logEvent(name: name, parameters: params);

  static Future<void> logScreenView(String name) =>
      _analytics.logScreenView(screenName: name);

  static Future<void> logMessageSent(String chatType) =>
      logEvent('message_sent', params: {'chat_type': chatType});

  static Future<void> logLogin()    => _analytics.logLogin(loginMethod: 'custom_id');
  static Future<void> logRegister() => _analytics.logSignUp(signUpMethod: 'custom_id');

  static void recordError(Object e, StackTrace? st) =>
      debugPrint('[Error] $e\n$st');
}
