import 'dart:async';
import 'dart:io';


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/Color.dart';
import '../Common/CommonWidget.dart';
import '../Common/Constant.dart';
import 'dashboard_module/ui/dashboard_activity.dart';

import 'log_in/data_manager/LoginDataManager.dart';
import 'log_in/ui/new_login_activity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SplashScreenActivity extends StatefulWidget {
  const SplashScreenActivity({super.key});

  @override
  State<SplashScreenActivity> createState() => _SplashScreenActivityState();
}

class _SplashScreenActivityState extends State<SplashScreenActivity>
    with SingleTickerProviderStateMixin {
  SharedPreferences? sharedPreferences;
  String? userid;

  @override
  void initState() {
    super.initState();
    start();
  }
  
  start() async {
    sharedPreferences = await SharedPreferences.getInstance();
    
    // Initialize Firebase Messaging and get token
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');

      // Get Token
      if (Platform.isIOS) {
        String? apnsToken = await messaging.getAPNSToken();
        print("🔔 iOS APNS Token: $apnsToken");
        // If APNS token is null, FCM getToken() will fail on iOS
        if (apnsToken == null) {
          print("⚠️ APNS token is null. FCM registration might fail. Ensure Push Notifications capability is added in Xcode.");
        }
      }

      String? token = await messaging.getToken();
      print("🔔 FCM Token: $token");

      if (token != null) {
        sharedPreferences!.setString(Constant.fbtoken, token);
      } else {
        print("❌ FCM Token is null!");
      }

      // Listen to token refresh
      messaging.onTokenRefresh.listen((fcmToken) {
        sharedPreferences!.setString(Constant.fbtoken, fcmToken);
      }).onError((err) {
        print("Error getting token refresh");
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          if (context.mounted) {
            CommonWidget.successShowSnackBarFor(context, "${message.notification?.title}: ${message.notification?.body}");
          }
        }
      });

      // Handle message when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from a background notification!');
        // Navigation logic can go here if needed
      });

      // Handle message when app is opened from terminated state
      messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          print('App opened from a terminated notification!');
          // Navigation logic can go here if needed
        }
      });
      
    } catch (e) {
      print("Error in Firebase Messaging init: $e");
    }

    final userIdValue = sharedPreferences!.getString(Constant.id) ?? "";
    
    setState(() {
      userid = userIdValue;
    });
    
    // Check if user is logged in - navigate immediately if yes
    if (userIdValue.isNotEmpty) {
      // Sync FCM token with backend in background
      try {
        final loginDataManager = LoginDataManager(sharedPreferences!);
        await loginDataManager.syncFcmToken(context);
      } catch (e) {
        print("Error syncing FCM token: $e");
      }

      // Small delay for splash screen visibility, then navigate
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => DashboardActivity(),
            ),
            (route) => false,
          );
        }
      });
      return; // Don't show login buttons if user is logged in
    }
    
    // User is not logged in - show login buttons
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorClass.base_color,
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/vetor/car-wash-detailing-station.jpg',
                  fit: BoxFit.cover,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ColorClass.base_color.withOpacity(0),
                          ColorClass.base_color,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              decoration: BoxDecoration(
                color: ColorClass.base_color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Wheels On Demand",
                    style: TextStyle(
                      fontSize: 28,
                      fontFamily: "Pop600",
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Your trusted partner for hassle-free car wash and detailing services",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: "Pop400",
                      color: Colors.white.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  // Only show Get Started button if user is NOT logged in
                  if (userid == null || userid!.isEmpty) ...[
                    GestureDetector(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (BuildContext context) => const NewLoginActivity(),
                          ),
                          (route) => false,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Text(
                          "Get Started",
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: "Pop600",
                            color: ColorClass.base_color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          sharedPreferences = await SharedPreferences.getInstance();
                          await sharedPreferences?.setString(Constant.id, '');
                          await sharedPreferences?.setString(Constant.accessToken, '');
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) => DashboardActivity(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        child: Text(
                          "Explore as Guest",
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: "Pop600",
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
