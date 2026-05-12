import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0A0F),
        systemNavigationBarIconBrightness: Brightness.light,
      ));

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await NotificationService.instance.initialize();

      await AuthService().initSuperuser();

      runApp(const ProviderScope(child: IlyaChatApp()));
    },
    (e, st) => debugPrint('Uncaught: $e\n$st'),
  );
}
