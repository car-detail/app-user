import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:car_app/features/SplashScreenActivity.dart';
import 'package:car_app/features/log_in/ui/new_login_activity.dart';
import 'package:car_app/Common/Color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:car_app/Common/NotificationService.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background processing
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set the background messaging handler early on
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Show the UI immediately -- don't make the user stare at a blank
  // screen while system permission dialogs (notifications, location)
  // are pending. These used to run here, awaited, before runApp(),
  // which meant nothing rendered until both dialogs were answered.
  runApp(const MyApp());

  // Give the engine a beat to present its first frame before requesting
  // notification/location permission, so the dialogs don't interrupt
  // cold launch.
  Future.delayed(const Duration(milliseconds: 1200), () {
    // Initialize Custom Local Notifications (may prompt for permission)
    unawaited(NotificationService.initialize());

    // Only request location permission on mobile platforms, not web
    if (!kIsWeb) {
      unawaited(() async {
        var status = await Permission.locationWhenInUse.status;

        if (status.isDenied) {
          status = await Permission.locationWhenInUse.request();
        }

        if (status.isPermanentlyDenied) {
          //openAppSettings(); // optionally guide user to settings
        }
      }());
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    // Set global status bar style to green - called before build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: ColorClass.base_color,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: ColorClass.base_color,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    });
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Transparent so background shows through
        statusBarIconBrightness: Brightness.light, // White icons for visibility on green
        statusBarBrightness: Brightness.dark, // For iOS
        systemNavigationBarColor: ColorClass.base_color,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp(
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      title: 'Cahrz',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorClass.base_color),
        useMaterial3: true,
          appBarTheme: AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: ColorClass.base_color,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
          ),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const SafeArea(child: NewLoginActivity()),
      },
      home: const SafeArea(
        child: SplashScreenActivity(),
        ),
      ),
    );
  }
}


