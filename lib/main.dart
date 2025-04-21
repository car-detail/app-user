import 'package:bot_toast/bot_toast.dart';
import 'package:car_app/features/SplashScreenActivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var status = await Permission.locationWhenInUse.status;

  if (status.isDenied) {
    status = await Permission.locationWhenInUse.request();
  }

  if (status.isPermanentlyDenied) {
    openAppSettings(); // optionally guide user to settings
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light), // Change color as needed
    );
    return MaterialApp(
      builder: BotToastInit(),
      title: 'Cahrz',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreenActivity(),
    );
  }
}


